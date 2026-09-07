"""Test release-fixture immutability and failure propagation without Xcode builds."""

import copy
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
        self.manifest = {"3.0.0": {"revision": "a" * 40, "clients": {
            "Clients/3.0.0/Client.swift": CHECK.digest(self.client.read_bytes())
        }}}
        self.save()
        self.git("init", "-q")
        self.git("add", "Compatibility")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "-qm", "Initial fixture")

    def git(self, *arguments):
        return subprocess.check_output(["git", *arguments], cwd=self.root, text=True).strip()

    def save(self):
        (self.root / CHECK.MANIFEST).write_text(json.dumps(self.manifest))

    def validate(self):
        return CHECK.validate_clients(self.root, "HEAD")

    def test_preserved_clients_pass(self):
        self.assertEqual(self.validate(), self.manifest)

    def test_editing_client_and_checksum_together_still_fails(self):
        self.client.write_text("// Changed to accommodate a broken API\n")
        self.manifest["3.0.0"]["clients"]["Clients/3.0.0/Client.swift"] = CHECK.digest(self.client.read_bytes())
        self.save()
        with self.assertRaisesRegex(ValueError, "Preserved client changed"):
            self.validate()

    def test_changed_source_without_new_checksum_fails(self):
        self.client.write_text("// coverage removed\n")
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            self.validate()

    def test_release_revision_cannot_move(self):
        self.manifest["3.0.0"]["revision"] = "b" * 40
        self.save()
        with self.assertRaisesRegex(ValueError, "baseline changed"):
            self.validate()

    def test_old_release_cannot_be_removed(self):
        self.manifest["3.1.0"] = self.manifest.pop("3.0.0")
        self.save()
        with self.assertRaisesRegex(ValueError, "baseline changed or removed"):
            self.validate()

    def test_additional_client_can_extend_coverage(self):
        new = self.client.with_name("More.swift")
        new.write_text("import SwiftUI\n")
        self.manifest["3.0.0"]["clients"]["Clients/3.0.0/More.swift"] = CHECK.digest(new.read_bytes())
        self.save()
        self.validate()

    def test_unregistered_and_missing_clients_fail(self):
        extra = self.client.with_name("Unregistered.swift")
        extra.write_text("import ColorKit\n")
        with self.assertRaisesRegex(ValueError, "inventory mismatch"):
            self.validate()
        extra.unlink()
        self.client.unlink()
        with self.assertRaises(FileNotFoundError):
            self.validate()

    def test_invalid_reference_does_not_disable_immutability(self):
        with self.assertRaises(subprocess.CalledProcessError):
            CHECK.validate_clients(self.root, "missing-branch")

    def test_empty_and_malformed_manifests_fail(self):
        invalid = [{}, [], {"3.0.0": {"revision": "main", "clients": {}}}]
        for name in ("../Client.swift", "Clients/../../Client.swift", "Clients/Client.txt", "/Client.swift"):
            record = copy.deepcopy(self.manifest)
            record["3.0.0"]["clients"] = {name: "b" * 64}
            invalid.append(record)
        for value in invalid:
            with self.subTest(value=value), self.assertRaises(ValueError):
                CHECK.load_manifest(json.dumps(value))


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


class BaselineCacheTests(unittest.TestCase):
    def test_cache_requires_matching_environment_clients_and_intact_inventory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cache = root / "cache"
            cache.mkdir()
            logs = root / "logs"
            logs.mkdir()
            baseline = {"revision": "a" * 40, "clients": {"Clients/Client.swift": "b" * 64}}

            def dump(modules, env, path, log):
                path.write_text(json.dumps({"ABIRoot": {"name": "ColorKit", "children": [{"kind": "TypeDecl"}]}}))

            with patch.object(CHECK, "output", return_value="a" * 40), patch.object(CHECK, "run"), \
                    patch.object(CHECK, "build", return_value=root), patch.object(CHECK, "compile_clients") as compile_client, \
                    patch.object(CHECK, "dump_api", side_effect=dump):
                first = CHECK.baseline_api(root, "3.0.0", baseline, {"sdk": "one"}, cache, logs)
                self.assertEqual(CHECK.baseline_api(root, "3.0.0", baseline, {"sdk": "one"}, cache, logs), first)
                self.assertEqual(compile_client.call_count, 1)
                second = CHECK.baseline_api(root, "3.0.0", baseline, {"sdk": "two"}, cache, logs)
                self.assertNotEqual(first, second)
                baseline["clients"]["Clients/More.swift"] = "c" * 64
                third = CHECK.baseline_api(root, "3.0.0", baseline, {"sdk": "two"}, cache, logs)
                self.assertNotEqual(second, third)
                self.assertEqual(compile_client.call_count, 3)
                third.write_text("{}")
                with self.assertRaisesRegex(ValueError, "Invalid baseline cache"):
                    CHECK.baseline_api(root, "3.0.0", baseline, {"sdk": "two"}, cache, logs)

    def test_baseline_compile_failure_never_publishes_cache_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            baseline = {"revision": "a" * 40, "clients": {"Clients/Client.swift": "b" * 64}}
            with patch.object(CHECK, "output", return_value="a" * 40), patch.object(CHECK, "run"), \
                    patch.object(CHECK, "build", return_value=root), \
                    patch.object(CHECK, "compile_clients", side_effect=RuntimeError("old client fails")):
                with self.assertRaisesRegex(RuntimeError, "old client fails"):
                    CHECK.baseline_api(root, "3.0.0", baseline, {}, root, root)
            self.assertEqual(list(root.rglob("complete.json")), [])


if __name__ == "__main__":
    unittest.main()
