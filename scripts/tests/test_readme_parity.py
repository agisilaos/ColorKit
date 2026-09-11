"""Tests for English/Spanish documentation parity."""

import importlib.util
import contextlib
import io
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "check_readme_parity", Path(__file__).resolve().parents[1] / "check_readme_parity.py"
)
PARITY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PARITY)


class ReadmeParityTests(unittest.TestCase):
    def test_url_strings_do_not_hide_following_code(self):
        def example(call):
            return '<!-- swift-example: sample -->\n```swift\nlet url = "https://example.com"; ' + call + '\n```'
        self.assertIn("swift-example 'sample' has different executable structure",
                      PARITY.compare(example('oldAPI()'), example('newAPI()')))

    def test_quotes_in_comments_do_not_hide_next_line(self):
        first = '// "comment\noldAPI() // "\n'
        second = '// "comentario\nnewAPI() // "\n'
        self.assertNotEqual(PARITY.normalize_swift(first), PARITY.normalize_swift(second))

    def test_git_failures_fail_the_command(self):
        for failing_command in ('diff', 'status'):
            def run(command, **kwargs):
                if command[1] == failing_command:
                    raise subprocess.CalledProcessError(128, command, stderr='missing Git history')
                return subprocess.CompletedProcess(command, 0, stdout='', stderr='')
            output = io.StringIO()
            with self.subTest(command=failing_command), patch.object(PARITY.subprocess, 'run', side_effect=run), \
                    contextlib.redirect_stdout(output):
                self.assertEqual(PARITY.main(), 1)
            self.assertIn('FAIL Git parity check unavailable', output.getvalue())
            self.assertIn('missing Git history', output.getvalue())
            self.assertNotIn('PASS', output.getvalue())

    def test_git_command_requires_success(self):
        with patch.object(PARITY.subprocess, 'run', return_value=subprocess.CompletedProcess(
                ['git'], 0, stdout='README.md\n', stderr='')) as run:
            self.assertEqual(PARITY.git_lines('diff'), ['README.md'])
        self.assertTrue(run.call_args.kwargs['check'])

    def test_committed_one_sided_changes_are_reported(self):
        def run(command, **kwargs):
            return subprocess.CompletedProcess(command, 0,
                                               stdout='README.md\n' if command[1] == 'diff' else '', stderr='')
        with patch.object(PARITY.subprocess, 'run', side_effect=run):
            results = PARITY.check()
        self.assertIn('changed-file drift: README.md changed without README.es-ES.md', results[0][2])

    def test_accepts_translated_prose_and_strings(self):
        english = '# Usage\n[Español](Usage.es-ES.md)\n<!-- swift-example: sample -->\n```swift\nprint("Hello") // greeting\n```'
        spanish = '# Uso\n[English](Usage.md)\n<!-- swift-example: sample -->\n```swift\nprint("Hola") // saludo\n```'
        self.assertEqual(PARITY.compare(english, spanish), [])

    def test_reports_structural_drift(self):
        english = "# Usage\n## Example\n```swift\nlet value = 1\n```"
        spanish = "# Uso\n```text\nlet value = 1\n```"
        issues = PARITY.compare(english, spanish)
        self.assertIn("heading hierarchy differs", issues)
        self.assertIn("code-fence count or language order differs", issues)

    def test_reports_link_drift(self):
        english = "[Contract](contract.md#result)"
        spanish = "[Contrato](contract.md)"
        self.assertEqual(PARITY.compare(english, spanish), ["link/image destinations differ"])

    def test_reports_executable_example_drift(self):
        english = '<!-- swift-example: sample -->\n```swift\nlet value = oldAPI()\n```'
        spanish = '<!-- swift-example: sample -->\n```swift\nlet value = newAPI()\n```'
        self.assertEqual(
            PARITY.compare(english, spanish),
            ["swift-example 'sample' has different executable structure"],
        )


if __name__ == "__main__":
    unittest.main()
