#!/bin/bash

set -o pipefail

usage() {
    cat <<'EOF'
Usage: scripts/run_tests.sh [--log-file path] platform destination [xcodebuild-options...]
       scripts/run_tests.sh

With no arguments, run both iOS and macOS tests and report both results.
With a platform label and destination, run only that destination. Additional
arguments are passed unchanged to xcodebuild after the shared test options.
An explicit -parallel-testing-enabled option replaces the default parallel
settings; pass -parallel-testing-enabled NO for tests that share mutable state.
Use --log-file to save raw output with tee instead of formatting with xcpretty;
the log's parent directory must already exist. This requires a single platform.

Examples:
  scripts/run_tests.sh
  scripts/run_tests.sh iOS 'platform=iOS Simulator,name=iPhone 16 Pro'
  scripts/run_tests.sh macOS 'platform=macOS,arch=arm64' -skipMacroValidation
  scripts/run_tests.sh --log-file macOS.log macOS 'platform=macOS'

Requires xcodebuild and xcpretty (or tee with --log-file). Exit status is 0 only
when every test command and output command succeeds, 1 on execution failure,
and 2 on invalid arguments. Use --help to show this message.
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
        -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData" \
        -enableCodeCoverage YES \
        "${test_options[@]}" \
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

output_command=(xcpretty)
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

ios_result=0
run_tests "iOS" "platform=iOS Simulator,name=iPhone 16 Pro" || ios_result=$?

macos_result=0
run_tests "macOS" "platform=macOS,arch=arm64" || macos_result=$?

if [[ $ios_result -eq 0 && $macos_result -eq 0 ]]; then
    printf '\nAll tests passed successfully!\n'
    exit 0
else
    printf '\nSome test runs failed (iOS: %s, macOS: %s)\n' \
        "$ios_result" "$macos_result" >&2
    exit 1
fi
