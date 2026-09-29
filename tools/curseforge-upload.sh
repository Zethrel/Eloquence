#!/usr/bin/env bash
#
# Upload a built zip to CurseForge.
#
# Needs:
#   CF_API_KEY      from CurseForge account settings -> API Tokens
#   CF_PROJECT_ID   the numeric Project ID shown on the project page
#
# Usage: tools/curseforge-upload.sh dist/Eloquence-2.0.0.zip
#
# The only fiddly part is that CurseForge wants its own numeric game-version ID
# rather than an interface number, so each interface number on the TOC's
# '## Interface:' line ("120100, 16001") is converted to a version name
# ("12.1.0", "1.60.1") and looked up. A name CurseForge does not list (a beta
# client, typically) is skipped with a warning; the upload fails only when none
# of them resolve.
#
# Run with CF_DRY_RUN=1 to print what would be sent without uploading.

set -euo pipefail

cd "$(dirname "$0")/.."

# Interface numbers are packed as MMmmpp: 120007 -> 12.0.7, 110205 -> 11.2.5.
interface_to_name() {
	local n="$1"
	printf '%d.%d.%d' $(( n / 10000 )) $(( (n / 100) % 100 )) $(( n % 100 ))
}

# The version names for a whole '## Interface:' value, space-separated:
# "120100, 16001" -> "12.1.0 1.60.1".
interface_names() {
	local n out=()
	for n in $(tr ',' ' ' <<<"$1"); do out+=("$(interface_to_name "$n")"); done
	echo "${out[*]}"
}

# Exercise the conversion without credentials, a zip, or a network. Runs in CI.
if [[ "${CF_SELFTEST:-}" == "1" ]]; then
	fails=0
	check() {
		local got; got="$(interface_to_name "$1")"
		if [[ "$got" != "$2" ]]; then
			echo "  FAIL $1 -> $got (expected $2)"; fails=1
		else
			echo "  ok   $1 -> $got"
		fi
	}
	check 120007 "12.0.7"
	check 120000 "12.0.0"
	check 110205 "11.2.5"
	check 110107 "11.1.7"
	check 100207 "10.2.7"
	check 11508  "1.15.8"
	check 50504  "5.5.4"
	check 40402  "4.4.2"
	check 16001  "1.60.1"
	list() {
		local got; got="$(interface_names "$1")"
		if [[ "$got" != "$2" ]]; then
			echo "  FAIL '$1' -> '$got' (expected '$2')"; fails=1
		else
			echo "  ok   '$1' -> '$got'"
		fi
	}
	list "120100, 16001" "12.1.0 1.60.1"
	list "120100,16001"  "12.1.0 1.60.1"
	list "120100"        "12.1.0"
	exit "$fails"
fi

ZIP="${1:-}"
if [[ -z "$ZIP" || ! -f "$ZIP" ]]; then
	echo "usage: tools/curseforge-upload.sh <zip>" >&2
	exit 1
fi

TOC="Eloquence/Eloquence.toc"
VERSION="$(sed -n 's/^## Version:[[:space:]]*//p' "$TOC" | tr -d '\r')"
INTERFACE="$(sed -n 's/^## Interface:[[:space:]]*//p' "$TOC" | tr -d '\r')"
GAME_VERSION_NAMES="$(interface_names "$INTERFACE")"

: "${CF_API_KEY:?set CF_API_KEY}"
: "${CF_PROJECT_ID:?set CF_PROJECT_ID}"

echo "Eloquence $VERSION -> CurseForge project $CF_PROJECT_ID"
echo "  interface $INTERFACE = game versions $GAME_VERSION_NAMES"
echo "  zip $ZIP ($(du -h "$ZIP" | cut -f1 | tr -d ' '))"

# Checked before any network call so a dry run works entirely offline.
if [[ "${CF_DRY_RUN:-}" == "1" ]]; then
	echo "  dry run: would resolve the game version ids for $GAME_VERSION_NAMES,"
	echo "           then POST the zip to project $CF_PROJECT_ID. Nothing sent."
	exit 0
fi

versions_json="$(curl -sS --fail-with-body \
	-H "X-Api-Token: $CF_API_KEY" \
	https://wow.curseforge.com/api/game/versions)"

# Prints the resolved ids comma-separated on stdout, and one warning per name
# CurseForge does not list on stderr.
GAME_VERSION_IDS="$(GAME_VERSION_NAMES="$GAME_VERSION_NAMES" python3 -c '
import json, os, sys
entries = json.load(sys.stdin)
ids = []
for target in os.environ["GAME_VERSION_NAMES"].split():
    found = [e["id"] for e in entries if e.get("name") == target]
    if found:
        ids.append(str(found[0]))
    else:
        close = sorted(e.get("name", "") for e in entries
                       if e.get("name", "").startswith(target.split(".")[0] + "."))
        print("  warning: CurseForge lists no game version named %s; skipped. "
              "Names with the same major: %s" % (target, ", ".join(close)[:300] or "none"),
              file=sys.stderr)
print(",".join(ids))
' <<<"$versions_json")"

if [[ -z "$GAME_VERSION_IDS" ]]; then
	echo "error: none of $GAME_VERSION_NAMES is a CurseForge game version." >&2
	exit 1
fi
echo "  resolved game version ids $GAME_VERSION_IDS"

metadata="$(VERSION="$VERSION" GAME_VERSION_IDS="$GAME_VERSION_IDS" python3 -c '
import json, os
print(json.dumps({
    "changelog": os.environ.get("CF_CHANGELOG", "See the GitHub release for details."),
    "changelogType": "markdown",
    "displayName": "Eloquence " + os.environ["VERSION"],
    "gameVersions": [int(i) for i in os.environ["GAME_VERSION_IDS"].split(",")],
    "releaseType": os.environ.get("CF_RELEASE_TYPE", "release"),
}))
')"

curl -sS --fail-with-body \
	-H "X-Api-Token: $CF_API_KEY" \
	-F "metadata=$metadata" \
	-F "file=@$ZIP" \
	"https://wow.curseforge.com/api/projects/$CF_PROJECT_ID/upload-file"
echo
echo "  uploaded."
