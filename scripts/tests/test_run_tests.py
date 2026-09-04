"""Exercise the runner at its CLI boundary without launching Xcode."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


RUNNER = Path(__file__).resolve().parents[1] / "run_tests.sh"


class TestRunnerContract(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.runner = self.root / "scripts/run_tests.sh"
        self.runner.parent.mkdir()
        self.runner.write_text(RUNNER.read_text())
        self.calls = self.root / "calls.jsonl"
        fake = self.root / "xcodebuild"
        fake.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "with open(os.environ['RUNNER_CALLS'], 'a') as log:\n"
            "    log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "print('raw xcodebuild output')\n"
            "print('xcodebuild diagnostic', file=sys.stderr)\n"
            "sys.exit(65 if os.environ.get('RUNNER_FAIL') == '1' else 0)\n"
        )
        fake.chmod(0o755)
        self.environment = {
            **os.environ,
            "PATH": f"{self.root}:/usr/bin:/bin",
            "RUNNER_CALLS": str(self.calls),
            "COLORKIT_DERIVED_DATA": str(self.root / "derived data"),
        }
        for name in ("COLORKIT_IOS_DESTINATION", "COLORKIT_MACOS_DESTINATION"):
            self.environment.pop(name, None)

    def run_script(self, *arguments):
        return subprocess.run(
            ["bash", str(self.runner), *arguments], env=self.environment,
            text=True, capture_output=True, check=False,
        )

    def recorded_calls(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def test_matrix_uses_pinned_destinations_and_isolates_shared_suites(self):
        result = self.run_script("--results-dir", str(self.root / "results"))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.recorded_calls()
        self.assertEqual(len(calls), 4)
        suites = ["ColorCacheIntegrationTests", "ThemeManagerIntegrationTests"]
        for index, call in enumerate(calls):
            destination = call[call.index("-destination") + 1]
            self.assertEqual(destination, "platform=iOS Simulator,name=iPhone 17,OS=26.5"
                             if index % 2 == 0 else "platform=macOS,arch=arm64")
            serial = index >= 2
            self.assertEqual(call[call.index("-parallel-testing-enabled") + 1],
                             "NO" if serial else "YES")
            for suite in suites:
                selector = "only" if serial else "skip"
                self.assertIn(f"-{selector}-testing:ColorKitTests/{suite}", call)
            self.assertIn("-resultBundlePath", call)
        logs = list((self.root / "results").glob("run.*/*.log"))
        self.assertEqual(len(logs), 4)
        self.assertTrue(all("raw xcodebuild output" in path.read_text() for path in logs))

    def test_matrix_continues_after_failures_and_returns_failure(self):
        self.environment["RUNNER_FAIL"] = "1"
        result = self.run_script("--results-dir", str(self.root / "results"))
        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(self.recorded_calls()), 4)

    def test_zero_argument_runs_matrix_and_preserves_previous_artifacts(self):
        for _ in range(2):
            result = self.run_script()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.recorded_calls()), 8)
        directories = list((self.root / ".build/test-results").glob("run.*"))
        self.assertEqual(len(directories), 2)
        self.assertTrue(all(len(list(path.glob("*.log"))) == 4 for path in directories))

    def test_output_failures_are_not_reported_as_success(self):
        result = self.run_script("--log-file", str(self.root / "missing/log"), "macOS", "platform=macOS")
        self.assertEqual(result.returncode, 1)
        formatter = self.root / "xcpretty"
        formatter.write_text("#!/bin/bash\ncat >/dev/null\nexit 1\n")
        formatter.chmod(0o755)
        result = self.run_script("macOS", "platform=macOS")
        self.assertEqual(result.returncode, 1)

    def test_matrix_logs_retain_both_streams_on_success_and_failure(self):
        for failure in ("0", "1"):
            with self.subTest(failure=failure):
                self.environment["RUNNER_FAIL"] = failure
                parent = self.root / f"logs-{failure}"
                result = self.run_script("--results-dir", str(parent))
                self.assertEqual(result.returncode, int(failure))
                logs = list(parent.glob("run.*/*.log"))
                self.assertEqual(len(logs), 4)
                for path in logs:
                    self.assertIn("raw xcodebuild output", path.read_text())
                    self.assertIn("xcodebuild diagnostic", path.read_text())

    def test_explicit_run_preserves_arguments_and_serial_override(self):
        result = self.run_script("macOS", "platform=macOS", "-parallel-testing-enabled", "NO",
                                 "-only-testing:ColorKitTests/ThemeTests")
        self.assertEqual(result.returncode, 0, result.stderr)
        call, = self.recorded_calls()
        self.assertEqual(call.count("-parallel-testing-enabled"), 1)
        self.assertNotIn("-parallel-testing-worker-count", call)
        self.assertIn("-only-testing:ColorKitTests/ThemeTests", call)

    def test_explicit_log_retains_both_streams_on_failure(self):
        self.environment["RUNNER_FAIL"] = "1"
        log = self.root / "explicit.log"
        result = self.run_script("--log-file", str(log), "macOS", "platform=macOS")
        self.assertEqual(result.returncode, 1)
        self.assertIn("raw xcodebuild output", log.read_text())
        self.assertIn("xcodebuild diagnostic", log.read_text())

    def test_destination_overrides_apply_to_both_phases(self):
        self.environment["COLORKIT_IOS_DESTINATION"] = "platform=iOS Simulator,id=chosen"
        result = self.run_script("--results-dir", str(self.root / "results"))
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.recorded_calls()
        for call in (calls[0], calls[2]):
            self.assertEqual(call[call.index("-destination") + 1], "platform=iOS Simulator,id=chosen")

    def test_invalid_arguments_do_not_launch_xcode(self):
        for arguments in (("--results-dir",), ("--results-dir", "x", "extra"), ("iOS",)):
            with self.subTest(arguments=arguments):
                self.assertEqual(self.run_script(*arguments).returncode, 2)
        self.assertFalse(self.calls.exists())


if __name__ == "__main__":
    unittest.main()
