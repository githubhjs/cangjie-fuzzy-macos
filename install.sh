#!/usr/bin/env bash
# cangjie-fuzzy-macos: Cangjie with adjacent-key typo tolerance as the DEFAULT schema (macOS: Squirrel / 鼠鬚管).
# 倉頡（鄰鍵容錯為預設方案）安裝程式。macOS：鼠鬚管（Squirrel）。
#
#   curl -fsSL https://raw.githubusercontent.com/githubhjs/cangjie-fuzzy-macos/main/install.sh | bash
#   bash install.sh [options of the base installer, e.g. --with-cangjie5 --fuzzy-range wide]
#
# This is a thin front for the base installer of githubhjs/cangjie-fluency-macos, which already contains the full cj*fluency
# (tables, word list, language model) and the typo-tolerant schemas. This script only makes the typo-tolerant schema the FIRST
# (default) one. Inside the release zip the base installer sits in ./base/ (fully offline); otherwise it is downloaded from the
# release tag below and checked against the SHA-256 pinned here.
set -eu

BASE_REPO="githubhjs/cangjie-fluency-macos"
BASE_REF="v0.3.1"                      # pinned by make-release.sh
BASE_SHA="d11097561c8e1feb9502b899b6830d020814bd709a7b719c926866975b9f0a99"                  # pinned by make-release.sh (SHA-256 of install.sh at BASE_REF)

say() { printf '[cangjie-fuzzy-macos] %s\n' "$1"; [ -z "${2:-}" ] || printf '[cangjie-fuzzy-macos] %s\n' "$2"; }
die() { printf '[cangjie-fuzzy-macos] ERROR: %s\n' "$1" >&2; [ -z "${2:-}" ] || printf '[cangjie-fuzzy-macos] 錯誤：%s\n' "$2" >&2; exit 1; }

HERE=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; fi

if [ -n "$HERE" ] && [ -f "$HERE/base/install.sh" ]; then
  say "using the bundled base installer (offline bundle)" "使用隨附的基礎安裝程式（離線包）"
  exec bash "$HERE/base/install.sh" --fuzzy-default "$@"
fi

case "$BASE_SHA" in @*) die "this copy has no pinned base checksum (run make-release.sh)" "這份沒有釘住基礎安裝程式的雜湊值（請先執行 make-release.sh）" ;; esac
sha256_of() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/cjf-fuzzy.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
URL="https://raw.githubusercontent.com/$BASE_REPO/$BASE_REF/install.sh"
say "downloading the base installer $BASE_REPO@$BASE_REF" "下載基礎安裝程式 $BASE_REPO@$BASE_REF"
if command -v curl >/dev/null 2>&1; then curl -fsSL --retry 3 -o "$TMP/install.sh" "$URL" || die "download failed: $URL" "下載失敗：$URL"
elif command -v wget >/dev/null 2>&1; then wget -q -O "$TMP/install.sh" "$URL" || die "download failed: $URL" "下載失敗：$URL"
else die "need curl or wget" "需要 curl 或 wget"; fi
[ "$(sha256_of "$TMP/install.sh")" = "$BASE_SHA" ] || die "the base installer does not match the pinned SHA-256, refusing to run it" "基礎安裝程式的 SHA-256 與釘住的不符，不執行"
bash "$TMP/install.sh" --fuzzy-default "$@" </dev/null
