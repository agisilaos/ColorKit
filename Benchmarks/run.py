#!/usr/bin/env python3
"""Build and run the macOS Release baseline, preserving raw repeated samples."""

import argparse
import datetime
import hashlib
import json
import pathlib
import platform
import statistics
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "Benchmarks"


def command(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def positive_int(value):
    result = int(value)
    if result < 1:
        raise argparse.ArgumentTypeError("must be positive")
    return result


def summarize(records):
    lines = [
        "# ColorKit macOS Release baseline", "",
        "Times include input barriers, clock reads, dispatch, and result consumption. "
        "The control substitutes a precomputed result and is an overhead estimate; "
        "it is reported without subtraction. Cache preparation is outside timing.", "",
        "| Scenario | Cache preparation | Median ns/request | Sample range | Median control ns/request |",
        "| --- | --- | ---: | ---: | ---: |",
    ]
    groups = {}
    for record in records:
        key = (record["scenario"]["id"], record["cacheMode"])
        groups.setdefault(key, []).extend(record["samples"])
    for (name, mode), samples in groups.items():
        times = [s["requestNanoseconds"] / s["requestCount"] for s in samples]
        controls = [s["controlNanoseconds"] / s["requestCount"] for s in samples]
        lines.append(
            f"| {name} | {mode} | {statistics.median(times):,.1f} | "
            f"{min(times):,.1f}–{max(times):,.1f} | {statistics.median(controls):,.1f} |"
        )
    lines.extend([
        "", "Each sample is the mean of individually timed complete requests. The table's median "
        "and range describe those sample means across runs, not individual-request latency percentiles.",
        "", "Read raw.json for every sample, fixture description, run identity, and environment. "
        "Large ranges or a control close to the request time limit useful comparisons. "
        "These are reference measurements, not speedup claims, CI thresholds, or iOS results.", "",
    ])
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=pathlib.Path, required=True, help="new directory for raw.json and summary.md")
    parser.add_argument("--runs", type=positive_int, default=3, help="independent processes per scenario/cache pair (default: 3)")
    parser.add_argument("--samples", type=positive_int, default=10, help="samples per process (default: 10; max: 1000)")
    parser.add_argument("--iterations", type=positive_int, default=100, help="requests per sample (default: 100; max: 100000)")
    args = parser.parse_args()
    if platform.system() != "Darwin":
        parser.error("the baseline requires macOS")
    if args.samples > 1000 or args.iterations > 100000:
        parser.error("samples must be <= 1000 and iterations <= 100000")
    if args.output.exists():
        parser.error("output directory already exists; choose a new directory")

    # Build before sampling. Do not mix build time with runtime measurements.
    subprocess.run(["swift", "build", "--package-path", str(PACKAGE), "-c", "release"], cwd=ROOT, check=True)
    binary = pathlib.Path(command("swift", "build", "--package-path", str(PACKAGE), "-c", "release", "--show-bin-path")) / "ColorKitBenchmarks"
    descriptions = json.loads(command(str(binary), "--list"))
    pairs = [(s["id"], mode) for s in descriptions for mode in s["modes"]]
    metadata = {
        "timestampUTC": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "revision": command("git", "rev-parse", "HEAD"),
        "trackedChanges": command("git", "diff", "HEAD", "--stat"),
        "untrackedFiles": command("git", "ls-files", "--others", "--exclude-standard"),
        "binarySHA256": hashlib.sha256(binary.read_bytes()).hexdigest(),
        "configuration": "release",
        "buildCommand": "swift build --package-path Benchmarks -c release",
        "swift": command("swift", "--version"),
        "xcode": command("xcodebuild", "-version"),
        "sdk": command("xcrun", "--show-sdk-version"),
        "os": command("sw_vers"),
        "architecture": platform.machine(),
        "hardwareModel": command("sysctl", "-n", "hw.model"),
        "cpu": command("sysctl", "-n", "machdep.cpu.brand_string"),
        "memoryBytes": int(command("sysctl", "-n", "hw.memsize")),
        "power": command("pmset", "-g", "batt"),
        "runs": args.runs, "samplesPerRun": args.samples, "requestsPerSample": args.iterations,
        "warmupRequests": 10,
        "clock": "DispatchTime.uptimeNanoseconds",
        "sampling": "Sum individually timed requests; preparation excluded; alternating request/control sample order",
    }
    # Reserve a new output directory; preserve completed records if a later process fails.
    args.output.mkdir(parents=True)
    records = []
    artifact = {"schemaVersion": 1, "complete": False, "environment": metadata, "records": records}

    def save():
        (args.output / "raw.json").write_text(json.dumps(artifact, indent=2) + "\n")

    save()
    for run in range(args.runs):
        # Reverse the fixed scenario order on alternate runs to expose order drift.
        for name, mode in (pairs if run % 2 == 0 else list(reversed(pairs))):
            print(f"Run {run + 1}/{args.runs}: {name} ({mode})", file=sys.stderr, flush=True)
            record = json.loads(command(str(binary), name, mode, str(args.samples), str(args.iterations)))
            record["run"] = run + 1
            records.append(record)
            save()
    artifact["complete"] = True
    save()
    summary = summarize(records)
    (args.output / "summary.md").write_text(summary)
    print(summary)
    print(f"Artifacts: {args.output.resolve()}")


if __name__ == "__main__":
    main()
