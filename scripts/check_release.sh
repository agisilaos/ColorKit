#!/bin/bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/check_release.sh version

Verify that the current checkout is the clean, synchronized main commit ready
to receive the requested release tag. The version must omit the leading "v".
EOF
}

if [[ $# -ne 1 || ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    usage >&2
    exit 2
fi

release_version=$1
release_tag="v$release_version"

if [[ $(git branch --show-current) != main ]]; then
    printf 'Release checks must run from main.\n' >&2
    exit 1
fi

if [[ -n $(git status --porcelain) ]]; then
    printf 'Release checks require a clean working tree.\n' >&2
    exit 1
fi

git fetch --quiet origin main --tags

if [[ $(git rev-parse HEAD) != $(git rev-parse origin/main) ]]; then
    printf 'Local main is not synchronized with origin/main.\n' >&2
    exit 1
fi

source_version=$(sed -n 's/.*public static let version = "\([^"]*\)".*/\1/p' Sources/ColorKit/ColorKit.swift)
if [[ $source_version != "$release_version" ]]; then
    printf 'ColorKit.version is %s; expected %s.\n' "$source_version" "$release_version" >&2
    exit 1
fi

if ! grep -Fq "## [$release_version] - " CHANGELOG.md; then
    printf 'CHANGELOG.md has no dated %s release heading.\n' "$release_version" >&2
    exit 1
fi

if git show-ref --verify --quiet "refs/tags/$release_tag"; then
    printf 'Tag %s already exists.\n' "$release_tag" >&2
    exit 1
fi

printf 'Release %s is ready at %s.\n' "$release_version" "$(git rev-parse HEAD)"
