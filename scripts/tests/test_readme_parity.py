"""Tests for English/Spanish documentation parity."""

import importlib.util
from pathlib import Path
import unittest


SPEC = importlib.util.spec_from_file_location(
    "check_readme_parity", Path(__file__).resolve().parents[1] / "check_readme_parity.py"
)
PARITY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PARITY)


class ReadmeParityTests(unittest.TestCase):
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
