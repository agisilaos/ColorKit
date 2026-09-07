#!/usr/bin/env python3
"""Compile preserved release clients and compare public APIs on iOS and macOS."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = "Compatibility/baselines.json"
PLATFORMS = {
    "macOS": ("macosx", "generic/platform=macOS", "Debug", "macosx12.0"),
    "iOS": ("iphonesimulator", "generic/platform=iOS Simulator", "Debug-iphonesimulator", "ios14.0-simulator"),
}
BUILD_SETTINGS = ["SWIFT_VERSION=6", "SWIFT_TREAT_WARNINGS_AS_ERRORS=NO", "CODE_SIGNING_ALLOWED=NO",
                  "ONLY_ACTIVE_ARCH=NO"]


def digest(data):
    return hashlib.sha256(data).hexdigest()


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


def load_manifest(text):
    baselines = json.loads(text)
    if not isinstance(baselines, dict) or not baselines:
        raise ValueError("A nonempty release baseline inventory is required")
    for release, baseline in baselines.items():
        if not re.fullmatch(r"\d+\.\d+\.\d+", release):
            raise ValueError(f"Invalid release: {release}")
        if not isinstance(baseline, dict) or set(baseline) != {"revision", "clients"}:
            raise ValueError(f"Invalid baseline record: {release}")
        if not re.fullmatch(r"[0-9a-f]{40}", baseline["revision"]):
            raise ValueError(f"Baseline must pin a full commit: {release}")
        if not isinstance(baseline["clients"], dict) or not baseline["clients"]:
            raise ValueError(f"Release has no clients: {release}")
        for name, checksum in baseline["clients"].items():
            path = Path(name)
            if (not name.startswith("Clients/") or path.suffix != ".swift" or ".." in path.parts
                    or path.as_posix() != name or not re.fullmatch(r"[0-9a-f]{64}", checksum)):
                raise ValueError(f"Invalid client entry: {name}")
    return baselines


def validate_clients(root, fixture_base):
    baselines = load_manifest((root / MANIFEST).read_text())
    base = output("git", "rev-parse", "--verify", "--end-of-options", f"{fixture_base}^{{commit}}", cwd=root)
    prior_paths = output("git", "ls-tree", "--name-only", base, "--", MANIFEST, cwd=root)
    if prior_paths:
        previous = load_manifest(output("git", "show", f"{base}:{MANIFEST}", cwd=root))
        for release, old in previous.items():
            current = baselines.get(release)
            if current is None or current["revision"] != old["revision"]:
                raise ValueError(f"Published release baseline changed or removed: {release}")
            for name, checksum in old["clients"].items():
                if current["clients"].get(name) != checksum:
                    raise ValueError(f"Preserved client changed or removed: {name}")
    tracked = set()
    for baseline in baselines.values():
        for name, checksum in baseline["clients"].items():
            path = root / "Compatibility" / name
            if path.is_symlink() or not path.resolve().is_relative_to((root / "Compatibility").resolve()):
                raise ValueError(f"Client must be inside Compatibility: {name}")
            if digest(path.read_bytes()) != checksum:
                raise ValueError(f"Client checksum mismatch: {name}")
            tracked.add(name)
    actual = {path.relative_to(root / "Compatibility").as_posix()
              for path in (root / "Compatibility/Clients").rglob("*.swift")}
    if actual != tracked:
        raise ValueError(f"Client inventory mismatch: {sorted(actual ^ tracked)}")
    return baselines


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
         *[root / "Compatibility" / name for name in sorted(clients)]], log, cwd=root)


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


def baseline_api(root, release, baseline, env, cache, logs):
    # Client hashes belong in the key because reuse also certifies release-client compilation.
    identity = {"schema": 1, "baseline": baseline, "environment": env,
                "checker": digest(Path(__file__).read_bytes())}
    key = digest(json.dumps(identity, sort_keys=True).encode())
    entry = cache / key
    entry.mkdir(parents=True, exist_ok=True)
    api = entry / "api.json"
    receipt = entry / "complete.json"
    if receipt.exists():
        saved = json.loads(receipt.read_text())
        if saved != {"key": key, "api_sha256": digest(api.read_bytes())}:
            raise ValueError(f"Invalid baseline cache receipt: {entry}; remove it and rerun")
        validate_api(api)
        print(f"Reusing verified {release} baseline: {entry}", flush=True)
        return api
    revision = baseline["revision"]
    resolved = output("git", "rev-parse", "--verify", f"{revision}^{{commit}}", cwd=root)
    if resolved != revision:
        raise ValueError(f"Release commit unavailable: {revision}; fetch complete history and tags")
    with tempfile.TemporaryDirectory(prefix="baseline-", dir=cache) as temporary:
        scratch = Path(temporary)
        source = scratch / "source"
        source.mkdir()
        archive = scratch / "release.tar"
        run(["git", "archive", "--format=tar", "-o", archive, revision], logs / "archive.log", cwd=root)
        run(["tar", "-xf", archive, "-C", source], logs / "extract.log", cwd=root)
        modules = build(source, scratch / "derived", env, logs / "baseline-build.log")
        compile_clients(root, baseline["clients"], modules, env, logs / "baseline-client.log")
        dump_api(modules, env, api, logs / "baseline-api.log")
    receipt.write_text(json.dumps({"key": key, "api_sha256": digest(api.read_bytes())}) + "\n")
    return api


def check(root, storage, fixture_base):
    baselines = validate_clients(root, fixture_base)
    storage.mkdir(parents=True, exist_ok=True)
    cache = storage / "cache"
    cache.mkdir(exist_ok=True)
    logs = Path(tempfile.mkdtemp(prefix="run-", dir=storage))
    print(f"Compatibility diagnostics: {logs}", flush=True)
    for name in PLATFORMS:
        env = environment(name)
        platform_logs = logs / name
        platform_logs.mkdir()
        (platform_logs / "environment.json").write_text(json.dumps(env, indent=2) + "\n")
        modules = build(root, storage / "candidate" / name, env, platform_logs / "candidate-build.log")
        candidate = platform_logs / "candidate-api.json"
        dump_api(modules, env, candidate, platform_logs / "candidate-api.log")
        for release, baseline in baselines.items():
            release_logs = platform_logs / release
            release_logs.mkdir()
            api = baseline_api(root, release, baseline, env, cache, release_logs)
            compile_clients(root, baseline["clients"], modules, env, release_logs / "candidate-client.log")
            compare_api(api, candidate, release_logs / "api-comparison.log")
            print(f"PASS: {release} public clients and API comparison on {name}", flush=True)
    print("Compatibility compilation/API checks passed. Behavioral coverage runs via scripts/run_tests.sh.", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--storage", type=Path, default=ROOT / ".build/compatibility",
                        help="Build, baseline cache, and diagnostic directory")
    parser.add_argument("--fixture-base", default="origin/main",
                        help="Trusted Git revision against which existing client records are immutable")
    args = parser.parse_args()
    try:
        check(ROOT, args.storage.resolve(), args.fixture_base)
    except (ValueError, OSError, RuntimeError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Compatibility check failed: {error}\n")
