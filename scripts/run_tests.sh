#!/bin/bash

set -o pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
derived_data=${COLORKIT_DERIVED_DATA:-"$repo_root/.build/xcode"}

usage() {
    cat <<'EOF'
Usage: scripts/run_tests.sh [--log-file path] platform destination [xcodebuild-options...]
       scripts/run_tests.sh [--results-dir path]

With no arguments, run the CI matrix: parallel iOS and macOS tests, followed by
serialized shared-state suites on each platform. Raw logs and result bundles
are saved in a unique run directory under .build/test-results (or --results-dir).
Override destinations with COLORKIT_IOS_DESTINATION / COLORKIT_MACOS_DESTINATION,
and build storage with COLORKIT_DERIVED_DATA (default: .build/xcode).
With a platform label and destination, run only that destination. Additional
arguments are passed unchanged to xcodebuild after the shared test options.
An explicit -parallel-testing-enabled option replaces the default parallel
settings; pass -parallel-testing-enabled NO for tests that share mutable state.
Use --log-file to save raw output with tee instead of formatting with xcpretty;
the log's parent directory must already exist. This requires a single platform.

Examples:
  scripts/run_tests.sh
  scripts/run_tests.sh --results-dir TestResults
  scripts/run_tests.sh iOS 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
  scripts/run_tests.sh macOS 'platform=macOS,arch=arm64' -skipMacroValidation
  scripts/run_tests.sh --log-file macOS.log macOS 'platform=macOS'

Requires xcodebuild. Output is formatted with xcpretty when available and remains
as raw xcodebuild output otherwise. Exit status is 0 only when every test command
and output command succeeds, 1 on execution failure, and 2 on invalid arguments.
Use --help to show this message.
EOF
}

run_tests() {
    local platform=$1
    local destination=$2
    local statuses
    shift 2

    local argument
    local test_options=(-parallel-testing-enabled YES -parallel-testing-worker-count 4 "$@")
    for argument in "$@"; do
        if [[ $argument == -parallel-testing-enabled ]]; then
            test_options=("$@")
            break
        fi
    done

    printf '\nRunning tests for %s...\n' "$platform"

    if xcodebuild test \
        -scheme ColorKit \
        -destination "$destination" \
        -derivedDataPath "$derived_data" \
        -enableCodeCoverage YES \
        "${test_options[@]}" 2>&1 \
        | "${output_command[@]}"; then
        printf '%s tests passed\n' "$platform"
        return 0
    else
        # Capture both statuses before another command overwrites PIPESTATUS.
        statuses=("${PIPESTATUS[@]}")
        printf '%s test run failed (xcodebuild: %s, %s: %s)\n' \
            "$platform" "${statuses[0]}" "${output_command[0]}" "${statuses[1]}" >&2
        return 1
    fi
}

if [[ $# -eq 1 && $1 == --help ]]; then
    usage
    exit 0
fi

results_parent="$repo_root/.build/test-results"
if [[ ${1:-} == --results-dir ]]; then
    if [[ $# -ne 2 || -z $2 || $2 == -* ]]; then
        usage >&2
        exit 2
    fi
    results_parent=$2
    shift 2
fi

if command -v xcpretty >/dev/null 2>&1; then
    output_command=(xcpretty)
else
    output_command=(cat)
fi
if [[ ${1:-} == --log-file ]]; then
    if [[ $# -lt 4 || -z $2 || $2 == -* ]]; then
        usage >&2
        exit 2
    fi
    output_command=(tee "$2")
    shift 2
fi

if [[ $# -gt 0 ]]; then
    if [[ $# -lt 2 || -z $1 || -z $2 || $1 == -* || $2 == -* ]]; then
        usage >&2
        exit 2
    fi
    run_tests "$@"
    exit $?
fi

mkdir -p "$results_parent" || exit 1
results_dir=$(mktemp -d "$results_parent/run.XXXXXX") || exit 1
printf 'Test artifacts: %s\n' "$results_dir"

ios_destination=${COLORKIT_IOS_DESTINATION:-'platform=iOS Simulator,name=iPhone 17,OS=26.5'}
macos_destination=${COLORKIT_MACOS_DESTINATION:-'platform=macOS,arch=arm64'}
shared_suites=(ColorCacheIntegrationTests ThemeManagerIntegrationTests)
parallel_options=()
serial_options=(-parallel-testing-enabled NO)
for suite in "${shared_suites[@]}"; do
    parallel_options+=("-skip-testing:ColorKitTests/$suite")
    serial_options+=("-only-testing:ColorKitTests/$suite")
done

matrix_result=0
run_phase() {
    local label=$1
    shift
    output_command=(tee "$results_dir/$label.log")
    run_tests "$label" "$@" \
        -resultBundlePath "$results_dir/$label.xcresult" \
        -skipPackagePluginValidation -skipMacroValidation || matrix_result=1
}

run_phase iOS "$ios_destination" "${parallel_options[@]}"
run_phase macOS "$macos_destination" "${parallel_options[@]}"
run_phase SharedStateiOS "$ios_destination" "${serial_options[@]}"
run_phase SharedStatemacOS "$macos_destination" "${serial_options[@]}"
printf '\nTest matrix exit status: %s. Artifacts: %s\n' "$matrix_result" "$results_dir"
exit "$matrix_result"
