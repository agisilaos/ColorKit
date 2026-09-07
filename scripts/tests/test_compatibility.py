"""Test release-fixture immutability and failure propagation without Xcode builds."""

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "check_compatibility", Path(__file__).resolve().parents[1] / "check_compatibility.py"
)
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class ClientInventoryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.client = self.root / "Compatibility/Clients/3.0.0/Client.swift"
        self.client.parent.mkdir(parents=True)
        self.client.write_text("import ColorKit\n")
        (self.client.parent / "revision").write_text("a" * 40 + "\n")
        self.git("init", "-q")
        self.git("add", "Compatibility")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "-qm", "Initial fixture")

    def git(self, *arguments):
        return subprocess.check_output(["git", *arguments], cwd=self.root, text=True).strip()

    def test_preserved_and_additional_clients_pass(self):
        CHECK.validate_clients(self.root, "HEAD")
        self.client.with_name("More.swift").write_text("import SwiftUI\n")
        CHECK.validate_clients(self.root, "HEAD")

    def test_changed_deleted_and_staged_clients_fail(self):
        self.client.write_text("// coverage removed\n")
        with self.assertRaisesRegex(ValueError, "Preserved clients"):
            CHECK.validate_clients(self.root, "HEAD")
        self.git("add", ".")
        with self.assertRaisesRegex(ValueError, "Preserved clients"):
            CHECK.validate_clients(self.root, "HEAD")
        self.client.unlink()
        with self.assertRaisesRegex(ValueError, "Preserved clients"):
            CHECK.validate_clients(self.root, "HEAD")

    def test_release_revision_cannot_move(self):
        (self.client.parent / "revision").write_text("b" * 40)
        with self.assertRaisesRegex(ValueError, "Preserved clients"):
            CHECK.validate_clients(self.root, "HEAD")

    def test_symlinks_cannot_import_mutable_fixture_source(self):
        target = self.root / "Mutable.swift"
        target.write_text("import ColorKit\n")
        link = self.client.with_name("Linked.swift")
        link.symlink_to(target)
        with self.assertRaisesRegex(ValueError, "must not be symlinks"):
            CHECK.validate_clients(self.root, "HEAD")

    def test_invalid_reference_does_not_disable_immutability(self):
        with self.assertRaises(subprocess.CalledProcessError):
            CHECK.validate_clients(self.root, "missing-branch")


class CommandFailureTests(unittest.TestCase):
    def test_failed_command_keeps_both_streams_and_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "failure.log"
            with self.assertRaisesRegex(RuntimeError, "exited 7"):
                CHECK.run([sys.executable, "-c", "import sys; print('stdout'); print('stderr', file=sys.stderr); sys.exit(7)"], log)
            self.assertIn("stdout", log.read_text())
            self.assertIn("stderr", log.read_text())

    def test_empty_wrong_module_and_import_only_api_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "api.json"
            for root in ({}, {"name": "Other", "children": [{"kind": "TypeDecl"}]},
                         {"name": "ColorKit", "children": [{"kind": "Import"}]}):
                path.write_text(json.dumps({"ABIRoot": root}))
                with self.subTest(root=root), self.assertRaises(ValueError):
                    CHECK.validate_api(path)

    def test_api_comparison_propagates_checker_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "api.json"
            path.write_text(json.dumps({"ABIRoot": {"name": "ColorKit", "children": [{"kind": "TypeDecl"}]}}))
            with patch.object(CHECK, "run", side_effect=RuntimeError("API break")) as run:
                with self.assertRaisesRegex(RuntimeError, "API break"):
                    CHECK.compare_api(path, path, Path(directory) / "diff.log")
                self.assertIn("-enable-remove-deprecated-check", run.call_args.args[0])

    def test_zero_exit_with_breakage_diagnostic_still_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            api = root / "api.json"
            api.write_text(json.dumps({"ABIRoot": {"name": "ColorKit", "children": [{"kind": "TypeDecl"}]}}))

            def run(command, log):
                log.write_text("API breakage: func oldName() has been removed\n")

            with patch.object(CHECK, "run", side_effect=run):
                with self.assertRaisesRegex(RuntimeError, "Public API breakage"):
                    CHECK.compare_api(api, api, root / "diff.log")


if __name__ == "__main__":
    unittest.main()
