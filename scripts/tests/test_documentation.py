"""Regression coverage for the Markdown coverage boundary."""

import importlib.util
from pathlib import Path
import tempfile
import unittest


SPEC = importlib.util.spec_from_file_location(
    "check_documentation", Path(__file__).resolve().parents[1] / "check_documentation.py"
)
DOCS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DOCS)


class DocumentationContract(unittest.TestCase):
    def extract(self, text, expected=frozenset({"sample"})):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "example.md"
            path.write_text(text)
            return DOCS.extract_examples(path, expected)

    def test_extracts_actual_code_and_original_line_number(self):
        self.assertEqual(self.extract("Title\n<!-- swift-example: sample -->\n```swift\nlet color = Color.red\n```"),
                         {"sample": (4, "let color = Color.red")})

    def test_missing_duplicate_unknown_empty_and_unclosed_examples_fail(self):
        valid = "<!-- swift-example: sample -->\n```swift\nlet value = 1\n```\n"
        for text in ("", valid + valid, valid.replace("sample", "unknown"),
                     valid.replace("let value = 1", ""), valid.removesuffix("```\n"),
                     valid.replace("```swift", "```text")):
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.extract(text)

    def test_behavior_checks_are_required_in_both_readme_inventories(self):
        self.assertEqual(set(DOCS.README_CHECKS), {"hsl", "cmyk", "lab"})
        for path in ("README.md", "README.es-ES.md"):
            self.assertLessEqual(DOCS.README_CHECKS.keys(), DOCS.EXAMPLES[path])

    def test_runtime_checks_follow_the_unmodified_published_code(self):
        code = "let cmyk = Color.red.cmykComponents()"
        source = DOCS.example_source(Path('a"b.md'), 3, 12, code, DOCS.README_CHECKS["cmyk"])
        self.assertIn('import ColorKit\n@MainActor func example_3()', source)
        self.assertIn('#sourceLocation(file: "a\\"b.md", line: 12)\n' + code, source)
        self.assertIn(code + "\n#sourceLocation()\n" + DOCS.README_CHECKS["cmyk"], source)


if __name__ == "__main__":
    unittest.main()
