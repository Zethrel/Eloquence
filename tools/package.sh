#!/usr/bin/env bash
#
# Build a release zip that can be dropped straight into Interface/AddOns.
#
# The zip contains a single top-level Eloquence/ folder, which is what both a
# manual install and every addon manager expect. Development files -- the test
# suite, this script, CI config -- are left out.
#
# Usage:  tools/package.sh [output-dir]     (default: dist/)

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
ADDON="Eloquence"
OUT_DIR="${1:-dist}"

if [[ ! -f "$ADDON/$ADDON.toc" ]]; then
	echo "error: $ADDON/$ADDON.toc not found; run this from the repository." >&2
	exit 1
fi

VERSION="$(sed -n 's/^## Version:[[:space:]]*//p' "$ADDON/$ADDON.toc" | tr -d '\r')"
if [[ -z "$VERSION" ]]; then
	echo "error: no '## Version:' line in the TOC." >&2
	exit 1
fi

# The '## Interface:' line lists one number per game the addon has been tested
# on, comma-separated ("120100, 16001"). Each is reported with the client it
# belongs to, so the summary and the install hint name the right folder.
mapfile -t INTERFACES < <(sed -n 's/^## Interface:[[:space:]]*//p' "$ADDON/$ADDON.toc" \
	| tr -d '\r' | head -1 | tr ',' '\n' | tr -d '[:blank:]' | sed '/^$/d')
if (( ${#INTERFACES[@]} == 0 )); then
	echo "error: no '## Interface:' line in the TOC." >&2
	exit 1
fi
for n in "${INTERFACES[@]}"; do
	if [[ ! "$n" =~ ^[0-9]+$ ]]; then
		echo "error: '## Interface:' entry '$n' is not a number." >&2
		exit 1
	fi
done

# Interface numbers are packed as MMmmpp: 120100 -> 12.1.0, 16001 -> 1.60.1.
interface_to_name() {
	local n="$1"
	printf '%d.%d.%d' $(( n / 10000 )) $(( (n / 100) % 100 )) $(( n % 100 ))
}

# Which client an interface number belongs to, as "label|install folder".
# The major separates the games; within major 1, Classic Era (1.15) and the
# Forever beta (1.60) are told apart by the minor. Only labels the output --
# an unrecognised number is still packaged. The Forever folder is the beta's;
# update it here when Forever launches (November) if the live client differs.
client_for_interface() {
	local n="$1" major=$(( $1 / 10000 )) minor=$(( ($1 / 100) % 100 ))
	if (( major >= 12 )); then echo "Retail|_retail_"
	elif (( major == 1 && minor >= 60 )); then echo "Forever beta|_classic_beta_"
	elif (( major == 1 )); then echo "Classic Era|_classic_era_"
	else echo "unrecognised client|"
	fi
}

echo "Eloquence $VERSION"
INSTALL_LINES=()
for n in "${INTERFACES[@]}"; do
	IFS='|' read -r label folder <<<"$(client_for_interface "$n")"
	printf '  interface %-6s = %-7s %s\n' "$n" "$(interface_to_name "$n")" "$label"
	if [[ -n "$folder" ]]; then
		INSTALL_LINES+=("$label $(interface_to_name "$n"): World of Warcraft/$folder/Interface/AddOns/")
	else
		INSTALL_LINES+=("interface $n ($(interface_to_name "$n")): the matching World of Warcraft/<client>/Interface/AddOns/")
	fi
done

# --- Validate before packaging -------------------------------------------------
#
# A file present on disk but missing from the TOC will not be loaded by the game,
# even though the test harness loads it happily. That mismatch would ship a
# silently broken addon, so it is a hard failure here.

toc_list="$(mktemp)"
disk_list="$(mktemp)"
trap 'rm -f "$toc_list" "$disk_list"' EXIT

grep -E '^[A-Za-z].*\.lua' "$ADDON/$ADDON.toc" | tr -d '\r' | tr '\\' '/' | sort > "$toc_list"
(cd "$ADDON" && find . -name '*.lua' | sed 's|^\./||' | sort) > "$disk_list"

if ! diff -q "$toc_list" "$disk_list" >/dev/null; then
	echo "error: the TOC and the files on disk disagree." >&2
	echo "  '<' is in the TOC only, '>' is on disk only:" >&2
	diff "$toc_list" "$disk_list" >&2 || true
	exit 1
fi
echo "  $(wc -l < "$toc_list" | tr -d ' ') Lua files, TOC matches disk"

# Every listed file must also parse.
if command -v luac5.4 >/dev/null 2>&1; then LUAC=luac5.4
elif command -v luac >/dev/null 2>&1; then LUAC=luac
else LUAC=""; fi

if [[ -n "$LUAC" ]]; then
	while IFS= read -r file; do
		if ! "$LUAC" -p "$ADDON/$file" 2>/dev/null; then
			echo "error: $file does not parse." >&2
			exit 1
		fi
	done < "$toc_list"
	echo "  all files parse"
else
	echo "  warning: no luac found, skipping the syntax check" >&2
fi

# --- Build ---------------------------------------------------------------------

STAGE="$(mktemp -d)"
trap 'rm -f "$toc_list" "$disk_list"; rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/$ADDON"
# Copy the addon itself, plus the docs, which are useful to have inside the
# installed folder.
(cd "$ADDON" && find . -name '*.lua' -o -name '*.toc' | sed 's|^\./||' | while IFS= read -r f; do
	mkdir -p "$STAGE/$ADDON/$(dirname "$f")"
	cp "$ADDON/$f" "$STAGE/$ADDON/$f" 2>/dev/null || cp "$f" "$STAGE/$ADDON/$f"
done)
cp README.md LICENSE "$STAGE/$ADDON/" 2>/dev/null || true

mkdir -p "$OUT_DIR"
ZIP="$ROOT/$OUT_DIR/$ADDON-$VERSION.zip"
rm -f "$ZIP"
(cd "$STAGE" && zip -qr9 "$ZIP" "$ADDON" -x '*.DS_Store' -x '__MACOSX*')

echo "  wrote $OUT_DIR/$ADDON-$VERSION.zip ($(du -h "$ZIP" | cut -f1 | tr -d ' '))"
echo
echo "Contents:"
unzip -l "$ZIP" | sed -n '4,8p'
echo "  ..."
echo
echo "Install: unzip into the AddOns folder of the client you play:"
for line in "${INSTALL_LINES[@]}"; do echo "  $line"; done

# In CI, hand the release step the same list as Markdown bullets.
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	{
		echo "install_md<<INSTALL_EOF"
		for line in "${INSTALL_LINES[@]}"; do
			echo "- ${line%%: *}: \`${line#*: }\`"
		done
		echo "INSTALL_EOF"
	} >> "$GITHUB_OUTPUT"
fi
