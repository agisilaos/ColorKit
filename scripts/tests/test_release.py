"""Release readiness must include successful compilation and behavioral gates."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "check_release.sh"


class ReleaseCompatibilityTests(unittest.TestCase):
    def test_release_requires_both_gates_and_propagates_failures(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "Sources/ColorKit").mkdir(parents=True)
            (root / "Sources/ColorKit/ColorKit.swift").write_text('public static let version = "3.0.1"\n')
            (root / "CHANGELOG.md").write_text("## [3.0.1] - 2026-09-07\n")
            (root / "scripts/check_release.sh").write_text(SCRIPT.read_text())
            commands = {
                "git": '#!/bin/bash\ncase "$1" in\nbranch) echo main;;\nrev-parse) echo abc;;\nshow-ref) exit 1;;\nesac\n',
                "python3": '#!/bin/bash\necho "compile $*" >> "$CALLS"\nexit "$COMPILE_EXIT"\n',
                "scripts/run_tests.sh": '#!/bin/bash\necho behavior >> "$CALLS"\nexit "$BEHAVIOR_EXIT"\n',
            }
            for name, text in commands.items():
                path = root / name
                path.write_text(text)
                path.chmod(0o755)
            for compile_exit, behavior_exit in ((0, 0), (9, 0), (0, 8)):
                with self.subTest(compile_exit=compile_exit, behavior_exit=behavior_exit):
                    calls = root / "calls"
                    calls.write_text("")
                    environment = {**os.environ, "PATH": f"{root}:/usr/bin:/bin", "CALLS": str(calls),
                                   "COMPILE_EXIT": str(compile_exit), "BEHAVIOR_EXIT": str(behavior_exit)}
                    result = subprocess.run(["bash", "scripts/check_release.sh", "3.0.1"], cwd=root,
                                            env=environment, text=True, capture_output=True)
                    self.assertEqual(result.returncode, compile_exit or behavior_exit, result.stderr)
                    self.assertIn("compile scripts/check_compatibility.py", calls.read_text())
                    self.assertEqual("behavior" in calls.read_text(), compile_exit == 0)
                    self.assertEqual("is ready" in result.stdout, compile_exit == behavior_exit == 0)


if __name__ == "__main__":
    unittest.main()
