#!/usr/bin/env python3
"""Compile public Markdown examples and verify selected conversion results."""

import argparse
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
DOCC = "Sources/ColorKit/Documentation.docc/"
# Explicit inventory makes deleting a marker a failure, not a silent coverage loss.
README_EXAMPLES = {"accessible-palette", "enhancement", "catalog", "previews", "comparison", "budget",
                   "hsl", "cmyk", "lab"}
EXAMPLES = {
    "README.md": README_EXAMPLES,
    "README.es-ES.md": README_EXAMPLES,
    DOCC + "Color-Spaces-article.md": {"rgb", "hsl", "lab"},
    DOCC + "Theming-article.md": {"dynamic-theme"},
    "PERFORMANCE_IMPROVEMENTS.md": {"cache", "benchmark"},
    "MIGRATION.md": {"cvd", "enhancement-budget"},
}
MARKER = re.compile(r"<!-- swift-example: ([a-z0-9-]+) -->")
# Postconditions use the actual README variables, not copied example implementations.
# Renaming a variable requires updating its check; removing a result cannot pass silently.
README_CHECKS = {
    "hsl": """
guard let hsl else { failExample("Named red must resolve to HSL") }
checkExample([hsl.hue, hsl.saturation, hsl.lightness].allSatisfy {
    $0.isFinite && (0...1).contains($0)
}, "Expected finite normalized HSL for the current appearance")
""",
    "cmyk": """
guard let cmyk else { failExample("Fixed red must resolve to CMYK") }
checkExample(abs(cmyk.cyan) < 0.001 && abs(cmyk.magenta - 1) < 0.001
    && abs(cmyk.yellow - 1) < 0.001 && abs(cmyk.key) < 0.001,
    "Expected red CMYK (0, 1, 1, 0)")
""",
    "lab": """
guard let lab else { failExample("Fixed red must resolve to LAB") }
checkExample(abs(lab.L - 53.24) < 0.01 && abs(lab.a - 80.09) < 0.01
    && abs(lab.b - 67.20) < 0.01, "Expected red D65 LAB (53.24, 80.09, 67.20)")
""",
}


def extract_examples(path, expected):
    """Fail closed on missing, duplicated, unknown, or malformed marked fences."""
    lines = path.read_text().splitlines()
    examples = {}
    for index, line in enumerate(lines):
        match = MARKER.fullmatch(line)
        if not match:
            if "<!-- swift-example:" in line:
                raise ValueError(f"{path}:{index + 1}: malformed example marker")
            continue
        name = match[1]
        if name in examples or name not in expected:
            raise ValueError(f"{path}:{index + 1}: duplicate or unknown example {name}")
        if index + 1 >= len(lines) or lines[index + 1] != "```swift":
            raise ValueError(f"{path}:{index + 1}: marker must precede a Swift fence")
        end = index + 2
        while end < len(lines) and lines[end] != "```":
            end += 1
        if end == len(lines):
            raise ValueError(f"{path}:{index + 1}: unterminated Swift fence")
        code = "\n".join(lines[index + 2:end])
        if not code.strip():
            raise ValueError(f"{path}:{index + 1}: empty example")
        examples[name] = (index + 3, code)
    if examples.keys() != expected:
        raise ValueError(f"{path}: missing examples: {sorted(expected - examples.keys())}")
    return examples


def run(*arguments):
    subprocess.run([str(argument) for argument in arguments], cwd=ROOT, check=True)


def example_source(path, index, line, code, checks=""):
    """Wrap the published code without rewriting it; append optional postconditions."""
    location = str(path).replace("\\", "\\\\").replace('"', '\\"')
    return ("import SwiftUI\nimport ColorKit\n"
            f"@MainActor func example_{index}() {{\n"
            f'#sourceLocation(file: "{location}", line: {line})\n{code}\n'
            f"#sourceLocation()\n{checks}\n}}\n")


def check(derived_data):
    sources = []
    for relative, expected in EXAMPLES.items():
        path = ROOT / relative
        for name, (line, code) in extract_examples(path, expected).items():
            # Imports belong at file scope, not inside the example's isolation function.
            code = re.sub(r"^import (SwiftUI|ColorKit)$", "", code, flags=re.MULTILINE)
            sources.append((path, name, line, code))

    run("xcodebuild", "build", "-scheme", "ColorKit", "-destination", "generic/platform=macOS",
        "-derivedDataPath", derived_data, "-skipPackagePluginValidation", "-skipMacroValidation")
    sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()
    architecture = subprocess.check_output(["uname", "-m"], text=True).strip()
    compiler = ["xcrun", "swiftc", "-swift-version", "6", "-sdk", sdk,
                "-target", f"{architecture}-apple-macosx12.0"]
    modules = derived_data / "Build/Products/Debug"
    with tempfile.TemporaryDirectory(prefix="colorkit-examples-") as temporary:
        scratch = Path(temporary)
        files = []
        runtime_files = []
        runtime_calls = []
        for index, (path, name, line, code) in enumerate(sources):
            source = scratch / f"example_{index}.swift"
            source.write_text(example_source(path, index, line, code))
            files.append(source)
            if path.name in ("README.md", "README.es-ES.md") and name in README_CHECKS:
                runtime = scratch / f"runtime_{index}.swift"
                runtime.write_text(example_source(path, index, line, code, README_CHECKS[name]))
                runtime_files.append(runtime)
                runtime_calls.append(f'print("Checking {path.name}: {name}"); example_{index}()')
        run(*compiler, "-typecheck", "-I", modules, *files)
        print(f"Compiled {len(files)} public examples (including both README languages).", flush=True)
        entry = scratch / "run_examples.swift"
        entry.write_text(
            "import Darwin\n"
            "func failExample(_ message: String) -> Never {\n"
            '    print("Documentation behavior failed: \\(message)"); exit(1)\n}\n'
            "func checkExample(_ condition: Bool, _ message: String) {\n"
            "    if !condition { failExample(message) }\n}\n"
            "@main struct RunExamples {\n    @MainActor static func main() {\n"
            + "\n".join(runtime_calls) + "\n    }\n}\n"
        )
        executable = scratch / "check-example-results"
        # Xcode's package object can carry coverage instrumentation. Link its runtime
        # explicitly and keep the standalone executable's profile in the scratch directory.
        run(*compiler, "-profile-generate", "-parse-as-library", "-I", modules, *runtime_files, entry,
            modules / "ColorKit.o", "-o", executable)
        run("env", f"LLVM_PROFILE_FILE={scratch / 'examples.profraw'}", executable)
        print(f"Verified results of {len(runtime_files)} actual README conversion examples.", flush=True)
        emitter = scratch / "emit-theme"
        run(*compiler, "-parse-as-library",
            ROOT / "Sources/ColorKit/PreviewCatalog/ThemeCodeGenerator.swift",
            ROOT / "Sources/ColorKit/Utilities/ResolvedSRGBA.swift",
            ROOT / "scripts/fixtures/emit_theme.swift", "-o", emitter)
        for fixture in ("named", "fixed"):
            generated = scratch / f"theme_{fixture}.swift"
            generated.write_text(subprocess.check_output([str(emitter), fixture], text=True))
            run(*compiler, "-typecheck", generated)
        print("Compiled actual theme-generator output for named, translucent, P3, and grayscale colors.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--derived-data", type=Path, default=ROOT / ".build/xcode")
    args = parser.parse_args()
    try:
        check(args.derived_data.resolve())
    except (ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Documentation check failed: {error}\n")
