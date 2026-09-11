#!/usr/bin/env python3
"""Check structural and changed-file parity for English/Spanish documentation."""

from pathlib import Path
import re
import subprocess


ROOT = Path(__file__).resolve().parents[1]
PAIRS = (
    ("README.md", "README.es-ES.md"),
    ("docs/Usage.md", "docs/Usage.es-ES.md"),
)
PATHS = tuple(path for pair in PAIRS for path in pair)


def captures(text, pattern):
    return re.findall(pattern, text, re.MULTILINE)


def normalize_link(target):
    if re.fullmatch(r"(?:\.\./)?README(?:\.es-ES)?\.md", target):
        return "<counterpart-readme>"
    if re.fullmatch(r"(?:docs/)?Usage(?:\.es-ES)?\.md", target):
        return "<counterpart-usage>"
    return target


def normalize_swift(code):
    code = re.sub(r"//.*$", "", code, flags=re.MULTILINE)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '"<translated-text>"', code)
    return re.sub(r"\s+", "", code)


def examples(text):
    pattern = r"<!-- swift-example: ([a-z0-9-]+) -->\s*```swift\s*([\s\S]*?)```"
    return dict(re.findall(pattern, text))


def compare(english, spanish):
    issues = []
    if [len(value) for value in captures(english, r"^(#{1,6})\s+")] != [
            len(value) for value in captures(spanish, r"^(#{1,6})\s+")]:
        issues.append("heading hierarchy differs")
    if captures(english, r"^```([^\n]*)$") != captures(spanish, r"^```([^\n]*)$"):
        issues.append("code-fence count or language order differs")
    link_pattern = r"(?:!?\[[^\]]*\])\(([^)]+)\)"
    if [normalize_link(link) for link in captures(english, link_pattern)] != [
            normalize_link(link) for link in captures(spanish, link_pattern)]:
        issues.append("link/image destinations differ")

    english_examples = examples(english)
    spanish_examples = examples(spanish)
    if list(english_examples) != list(spanish_examples):
        issues.append("swift-example IDs or order differ")
    else:
        for name, code in english_examples.items():
            if normalize_swift(code) != normalize_swift(spanish_examples[name]):
                issues.append(f"swift-example '{name}' has different executable structure")
    return issues


def git_lines(*arguments):
    result = subprocess.run(("git", *arguments), cwd=ROOT, text=True, capture_output=True)
    return result.stdout.splitlines() if result.returncode == 0 else []


def changed_paths():
    changed = set(git_lines("diff", "--name-only", "origin/main...HEAD", "--", *PATHS))
    for line in git_lines("status", "--porcelain", "--", *PATHS):
        path = line[3:].strip().split(" -> ")[-1]
        if path:
            changed.add(path)
    return changed


def check():
    changed = changed_paths()
    results = []
    for english_path, spanish_path in PAIRS:
        english = ROOT / english_path
        spanish = ROOT / spanish_path
        if not english.exists() and not spanish.exists():
            continue
        issues = []
        if not english.exists() or not spanish.exists():
            issues.append(f"missing {english_path if not english.exists() else spanish_path}")
        else:
            issues.extend(compare(english.read_text(), spanish.read_text()))
        if (english_path in changed) != (spanish_path in changed):
            changed_path, stale_path = ((english_path, spanish_path) if english_path in changed
                                       else (spanish_path, english_path))
            issues.append(f"changed-file drift: {changed_path} changed without {stale_path}")
        results.append((english_path, spanish_path, issues))
    return results


def main():
    results = check()
    for english, spanish, issues in results:
        print(f"{'PASS' if not issues else 'FAIL'} {english} ↔ {spanish}")
        for issue in issues:
            print(f"  - {issue}")
    if not results:
        print("FAIL no English/Spanish documentation pair found")
        return 1
    if any(issues for _, _, issues in results):
        print("Update both documents together and rerun this check.")
        return 1
    print("Structural parity passes; semantic translation still requires review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
