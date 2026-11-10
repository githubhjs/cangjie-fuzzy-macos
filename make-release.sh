#!/usr/bin/env bash
# Build the release zips and pin the base installer.
#   usage: ./make-release.sh VERSION BASE_TAG BASE_FULL_ZIP
#     VERSION        e.g. v0.1.0 (this repo)
#     BASE_TAG       tag of githubhjs/cangjie-fluency-macos whose install.sh is pinned, e.g. v0.3.0
#     BASE_FULL_ZIP  the full offline zip of that base release (goes into ./base/ of our full zip)
#   Writes the pinned BASE_REF / BASE_SHA into install.sh (commit that change), then dist/:
#     cangjie-fuzzy-macos-VERSION-full.zip   wrapper + the whole base bundle, works offline
#     cangjie-fuzzy-macos-VERSION-slim.zip   wrapper only (downloads the base installer, SHA-256 checked)
#     cangjie-fuzzy-macos-VERSION.SHA256SUMS
set -eu
V="${1:?version}"; BASE_TAG="${2:?base tag}"; BASE_ZIP="${3:?base full zip}"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }

W="$(mktemp -d "${TMPDIR:-/tmp}/cjfz.XXXXXX")"
trap 'rm -rf "$W"' EXIT
curl -fsSL --retry 3 -o "$W/base-install.sh" "https://raw.githubusercontent.com/githubhjs/cangjie-fluency-macos/$BASE_TAG/install.sh"
SHA="$(sha256 "$W/base-install.sh")"
# the bundled copy must be byte-identical to the pinned one
unzip -q "$BASE_ZIP" -d "$W/z"
BI="$(find "$W/z" -maxdepth 2 -name install.sh | head -n 1)"
[ "$(sha256 "$BI")" = "$SHA" ] || { echo "the install.sh inside $BASE_ZIP differs from the one at tag $BASE_TAG" >&2; exit 1; }

sed -i "s|^BASE_REF=\".*\"|BASE_REF=\"$BASE_TAG\"|; s|^BASE_SHA=\".*\"|BASE_SHA=\"$SHA\"|" install.sh
grep -q "^BASE_SHA=\"$SHA\"" install.sh || { echo "could not pin the checksum" >&2; exit 1; }
bash -n install.sh

mkdir -p dist
N="cangjie-fuzzy-macos-$V"
rm -f "dist/$N-full.zip" "dist/$N-slim.zip" "dist/$N.SHA256SUMS"
mkdir -p "$W/slim/$N" "$W/full/$N"
for d in slim full; do cp install.sh README.md LICENSE "$W/$d/$N/"; chmod +x "$W/$d/$N/install.sh"; done
mkdir -p "$W/full/$N/base"
cp -R "$(dirname "$BI")"/. "$W/full/$N/base/"
( cd "$W/slim" && zip -q -r "$HERE/dist/$N-slim.zip" "$N" )
( cd "$W/full" && zip -q -r "$HERE/dist/$N-full.zip" "$N" )
( cd dist && for f in "$N-full.zip" "$N-slim.zip"; do printf '%s  %s\n' "$(sha256 "$f")" "$f"; done > "$N.SHA256SUMS" )
cat "dist/$N.SHA256SUMS"
echo "pinned base: $BASE_TAG  sha256 $SHA"
