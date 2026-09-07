#!/usr/bin/env python3
"""Compile preserved release clients and compare public APIs on iOS and macOS."""

import argparse
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CLIENTS = "Compatibility/Clients"
PLATFORMS = {
    "macOS": ("macosx", "generic/platform=macOS", "Debug", "macosx12.0"),
    "iOS": ("iphonesimulator", "generic/platform=iOS Simulator", "Debug-iphonesimulator", "ios14.0-simulator"),
}
BUILD_SETTINGS = ["SWIFT_VERSION=6", "SWIFT_TREAT_WARNINGS_AS_ERRORS=NO", "CODE_SIGNING_ALLOWED=NO",
                  "ONLY_ACTIVE_ARCH=NO"]


def output(*command, cwd=ROOT):
    return subprocess.check_output([str(value) for value in command], cwd=cwd, text=True).strip()


def run(command, log, cwd=ROOT):
    """Retain both streams, propagate failures, and keep routine console output short."""
    command = [str(value) for value in command]
    print(f"Running {shlex.join(command)}\n  Log: {log}", flush=True)
    with log.open("w") as stream:
        result = subprocess.run(command, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        print(log.read_text()[-12000:], flush=True)
        raise RuntimeError(f"Command exited {result.returncode}; see {log}")


def validate_clients(root, fixture_base):
    base = output("git", "rev-parse", "--verify", "--end-of-options", f"{fixture_base}^{{commit}}", cwd=root)
    changed = output("git", "diff", "--name-only", "--no-renames", "--diff-filter=DMRTUXB",
                     base, "--", CLIENTS, cwd=root)
    if changed:
        raise ValueError(f"Preserved clients changed or removed:\n{changed}")
    directory = root / CLIENTS
    if any(path.is_symlink() for path in [directory, *directory.rglob("*")]):
        raise ValueError("Preserved client directories and files must not be symlinks")
    releases = sorted(directory.iterdir())
    if not releases:
        raise ValueError("No release clients found")
    for release in releases:
        if not list(release.glob("*.swift")):
            raise ValueError(f"No Swift clients found: {release}")
    return releases


def validate_api(path):
    root = json.loads(path.read_text()).get("ABIRoot", {})
    declarations = [item for item in root.get("children", []) if item.get("kind") != "Import"]
    if root.get("name") != "ColorKit" or not declarations:
        raise ValueError(f"Missing or empty ColorKit API inventory: {path}")


def environment(name):
    sdk_name, destination, products, suffix = PLATFORMS[name]
    arch = platform.machine()
    if arch not in ("arm64", "x86_64"):
        raise ValueError(f"Unsupported build architecture: {arch}")
    return {
        "xcode": output("xcodebuild", "-version"),
        "swift": output("xcrun", "swiftc", "--version"),
        "developer": output("xcode-select", "-p") if not os.environ.get("DEVELOPER_DIR") else os.environ["DEVELOPER_DIR"],
        "sdk": output("xcrun", "--sdk", sdk_name, "--show-sdk-path"),
        "sdk_version": output("xcrun", "--sdk", sdk_name, "--show-sdk-version"),
        "sdk_build": output("xcrun", "--sdk", sdk_name, "--show-sdk-build-version"),
        "destination": destination, "products": products, "target": f"{arch}-apple-{suffix}",
        "settings": BUILD_SETTINGS + [f"ARCHS={arch}"],
    }


def build(root, derived, env, log):
    run(["xcodebuild", "build", "-scheme", "ColorKit", "-configuration", "Debug",
         "-destination", env["destination"], "-derivedDataPath", derived,
         "-skipPackagePluginValidation", "-skipMacroValidation", *env["settings"]], log, cwd=root)
    modules = derived / "Build/Products" / env["products"]
    if not (modules / "ColorKit.swiftmodule").is_dir():
        raise ValueError(f"Build produced no ColorKit module: {modules}")
    return modules


def compile_clients(root, clients, modules, env, log):
    run(["xcrun", "swiftc", "-typecheck", "-swift-version", "6", "-sdk", env["sdk"],
         "-target", env["target"], "-I", modules, "-module-name", "ColorKitReleaseClient",
         *sorted(clients)], log, cwd=root)


def dump_api(modules, env, path, log):
    run(["xcrun", "swift-api-digester", "-dump-sdk", "-module", "ColorKit", "-I", modules,
         "-sdk", env["sdk"], "-target", env["target"], "-swift-version", "6",
         "-abort-on-module-fail", "-o", path], log)
    validate_api(path)


def compare_api(baseline, candidate, log):
    validate_api(baseline)
    validate_api(candidate)
    run(["xcrun", "swift-api-digester", "-diagnose-sdk", "-input-paths", baseline,
         "-input-paths", candidate, "-compiler-style-diags", "-enable-remove-deprecated-check"], log)
    # The Xcode 26.5 digester prints breakages but can still exit successfully.
    if "API breakage:" in log.read_text():
        raise RuntimeError(f"Public API breakage detected; see {log}")


def check(root, storage, fixture_base):
    releases = validate_clients(root, fixture_base)
    storage.mkdir(parents=True, exist_ok=True)
    logs = Path(tempfile.mkdtemp(prefix="run-", dir=storage))
    print(f"Compatibility diagnostics: {logs}", flush=True)
    with tempfile.TemporaryDirectory(prefix="source-", dir=storage) as temporary:
        scratch = Path(temporary)
        sources = {}
        for release in releases:
            revision = (release / "revision").read_text().strip()
            resolved = output("git", "rev-parse", "--verify", "--end-of-options", f"{revision}^{{commit}}", cwd=root)
            if resolved != revision:
                raise ValueError(f"Release must pin a full commit: {release}")
            source = scratch / release.name
            source.mkdir()
            archive = scratch / "release.tar"
            run(["git", "archive", "--format=tar", "-o", archive, revision], logs / f"{release.name}-archive.log", cwd=root)
            run(["tar", "-xf", archive, "-C", source], logs / f"{release.name}-extract.log", cwd=root)
            sources[release] = source
        for name in PLATFORMS:
            env = environment(name)
            platform_logs = logs / name
            platform_logs.mkdir()
            (platform_logs / "environment.json").write_text(json.dumps(env, indent=2) + "\n")
            modules = build(root, storage / "candidate" / name, env, platform_logs / "candidate-build.log")
            candidate = platform_logs / "candidate-api.json"
            dump_api(modules, env, candidate, platform_logs / "candidate-api.log")
            for release, source in sources.items():
                release_logs = platform_logs / release.name
                release_logs.mkdir()
                clients = list(release.glob("*.swift"))
                baseline = build(source, scratch / "derived" / name / release.name, env, release_logs / "baseline-build.log")
                compile_clients(root, clients, baseline, env, release_logs / "baseline-client.log")
                api = release_logs / "baseline-api.json"
                dump_api(baseline, env, api, release_logs / "baseline-api.log")
                compile_clients(root, clients, modules, env, release_logs / "candidate-client.log")
                compare_api(api, candidate, release_logs / "api-comparison.log")
                print(f"PASS: {release.name} public clients and API comparison on {name}", flush=True)
    print("Compatibility compilation/API checks passed. Behavioral coverage runs via scripts/run_tests.sh.", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--storage", type=Path, default=ROOT / ".build/compatibility",
                        help="Build and diagnostic directory")
    parser.add_argument("--fixture-base", default="origin/main",
                        help="Trusted Git revision against which existing client records are immutable")
    args = parser.parse_args()
    try:
        check(ROOT, args.storage.resolve(), args.fixture_base)
    except (ValueError, OSError, RuntimeError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Compatibility check failed: {error}\n")
