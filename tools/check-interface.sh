#!/usr/bin/env bash
#
# Compare the TOC's interface number against the live retail client version.
#
# This NOTIFIES. It never edits the TOC, and that is deliberate: the interface
# number is a compatibility claim, not a version string. "## Interface: 120100"
# says a human tested this addon against 12.1.0. A script bumping it says a robot
# noticed a number change on a website -- and a major patch is exactly when this
# addon is most likely to be broken. Patch 12.0 rearchitected the chat send path
# and killed outgoing dialects silently, with no Lua error. Auto-bumping would
# have published a release asserting 12.0 compatibility while the headline
# feature did nothing.
#
# Being flagged out of date is the safe failure: the addon still loads if the
# user opts in, and the label honestly says nobody has checked yet.
#
# Usage:
#   tools/check-interface.sh              # fetch, compare, report
#   CHECK_SELFTEST=1 tools/check-interface.sh   # offline, exercises the parser
#
# Exit codes:
#   0  checked successfully (drift or not -- see the "drift" output)
#   1  usage or parse error
#   2  could not reach any version source (soft failure; the caller should not
#      treat this as drift)

set -euo pipefail

cd "$(dirname "$0")/.."

ADDON="Eloquence"
TOC="$ADDON/$ADDON.toc"

# Blizzard's TACT version feeds. Public, unauthenticated, and the same source the
# game client itself uses to discover builds. All of these serve the identical
# pipe-delimited payload.
#
# They are tried in order because reachability varies by network and the first
# attempt at this got it wrong: the classic patch.battle.net endpoint listens on
# port 1119 and speaks PLAIN HTTP, so pointing https:// at it fails the TLS
# handshake -- which looks like "connection reset by peer" rather than anything
# informative. The v2 host serves the same data over ordinary HTTPS on 443, which
# also survives networks that block odd ports.
#
# Set VERSIONS_URL to override with a single source (the tests use file:// URLs).
VERSIONS_URLS=(
	"https://us.version.battle.net/v2/products/wow/versions"
	"http://us.patch.battle.net:1119/wow/versions"
	"https://eu.version.battle.net/v2/products/wow/versions"
)
if [[ -n "${VERSIONS_URL:-}" ]]; then
	VERSIONS_URLS=( "$VERSIONS_URL" )
fi

#-------------------------------------------------------------------------------
# Parsing
#-------------------------------------------------------------------------------

# The payload is pipe-delimited with a typed header, e.g.
#
#   Region!STRING:0|BuildConfig!HEX:16|...|VersionsName!String:0|...
#   ## seqn = 2245234
#   us|abc123|def456||61234|12.0.7.61234|789abc
#
# The VersionsName column is located by name rather than by position, since
# column order is not guaranteed to stay put across changes to the endpoint.
parse_versions_name() {
	awk -F'|' '
		# Header: locate the columns we need. Both are found by name -- assuming
		# Region is first is exactly the kind of thing that breaks quietly if the
		# endpoint is ever reordered.
		col == 0 && /VersionsName/ {
			for (i = 1; i <= NF; i++) {
				split($i, part, "!")
				if (part[1] == "VersionsName") { col = i }
				if (part[1] == "Region")       { regioncol = i }
			}
			next
		}
		/^#/ { next }             # "## seqn = ..." and any other comments
		col == 0 { next }         # data before a header we understood

		# Prefer the US row; fall back to the first data row if there is no
		# Region column, or no US row in it.
		#
		# `found` is not decoration: awk runs END even after `exit`, so without it
		# the fallback prints on top of the match.
		{
			if (regioncol == 0)     { found = 1; print $col; exit }
			if ($regioncol == "us") { found = 1; print $col; exit }
			if (first == "") { first = $col }
		}
		END { if (found != 1 && first != "") print first }
	'
}

# "12.0.7.61234" -> "120007". The first three components are the patch version;
# the fourth is the build number and is not part of the interface number.
#
# Mirrors the inverse conversion in tools/curseforge-upload.sh: an interface
# number is major * 10000 + minor * 100 + patch.
version_to_interface() {
	local name="$1" major minor patch
	IFS='.' read -r major minor patch _ <<< "$name"
	if [[ ! "$major" =~ ^[0-9]+$ || ! "$minor" =~ ^[0-9]+$ || ! "$patch" =~ ^[0-9]+$ ]]; then
		return 1
	fi
	printf '%d' $(( major * 10000 + minor * 100 + patch ))
}

#-------------------------------------------------------------------------------
# Self-test
#-------------------------------------------------------------------------------

# Exercises everything except the network call, so the parsing and the arithmetic
# are covered even though the live endpoint is unreachable from some sandboxes.
if [[ "${CHECK_SELFTEST:-}" == "1" ]]; then
	fails=0

	expect() {
		local label="$1" got="$2" want="$3"
		if [[ "$got" != "$want" ]]; then
			echo "  FAIL $label -> '$got' (expected '$want')"; fails=1
		else
			echo "  ok   $label -> $got"
		fi
	}

	# A realistic payload, including the comment line and a second region.
	sample='Region!STRING:0|BuildConfig!HEX:16|CDNConfig!HEX:16|KeyRing!HEX:16|BuildId!DEC:4|VersionsName!String:0|ProductConfig!HEX:16
## seqn = 2245234
us|aaaaaaaaaaaaaaaa|bbbbbbbbbbbbbbbb||61234|12.0.7.61234|cccccccccccccccc
eu|aaaaaaaaaaaaaaaa|bbbbbbbbbbbbbbbb||61234|12.0.7.61234|cccccccccccccccc'
	expect "parses VersionsName" "$(printf '%s\n' "$sample" | parse_versions_name)" "12.0.7.61234"

	# Column order must not be assumed: same data, VersionsName moved to the front.
	reordered='VersionsName!String:0|Region!STRING:0|BuildId!DEC:4
## seqn = 1
12.1.0.62000|us|62000'
	expect "locates the column by name" "$(printf '%s\n' "$reordered" | parse_versions_name)" "12.1.0.62000"

	# Region selection: the US row is taken even when it is not first.
	regions='Region!STRING:0|VersionsName!String:0
tw|12.0.5.60000
us|12.0.7.61234'
	expect "picks the us row" "$(printf '%s\n' "$regions" | parse_versions_name)" "12.0.7.61234"

	expect "empty input yields nothing" "$(printf '' | parse_versions_name)" ""

	expect "12.0.7.61234"  "$(version_to_interface 12.0.7.61234)"  "120007"
	expect "12.1.0.62000"  "$(version_to_interface 12.1.0.62000)"  "120100"
	expect "11.2.5.59000"  "$(version_to_interface 11.2.5.59000)"  "110205"
	expect "1.15.8.12345"  "$(version_to_interface 1.15.8.12345)"  "11508"
	expect "12.0.7 (no build)" "$(version_to_interface 12.0.7)"    "120007"

	if version_to_interface "not.a.version" >/dev/null 2>&1; then
		echo "  FAIL rubbish input was accepted"; fails=1
	else
		echo "  ok   rubbish input is rejected"
	fi

	# The TOC must be readable and its interface number well formed, or the
	# comparison below is meaningless.
	toc_if="$(sed -n 's/^## Interface:[[:space:]]*//p' "$TOC" | tr -d '\r')"
	if [[ "$toc_if" =~ ^[0-9]+$ ]]; then
		echo "  ok   TOC interface parses -> $toc_if"
	else
		echo "  FAIL TOC interface did not parse -> '$toc_if'"; fails=1
	fi

	exit "$fails"
fi

#-------------------------------------------------------------------------------
# Check
#-------------------------------------------------------------------------------

TOC_INTERFACE="$(sed -n 's/^## Interface:[[:space:]]*//p' "$TOC" | tr -d '\r')"
if [[ ! "$TOC_INTERFACE" =~ ^[0-9]+$ ]]; then
	echo "error: no usable '## Interface:' line in $TOC" >&2
	exit 1
fi

# Try each source until one yields something parseable. A source that answers but
# returns an unusable body is treated the same as one that does not answer -- an
# error page is not a version feed -- so a single sick mirror cannot mask a real
# patch. Which source won is logged, because "it worked" and "it worked via the
# fallback" are different facts worth knowing.
payload=""
LIVE_NAME=""
SOURCE=""
for url in "${VERSIONS_URLS[@]}"; do
	body="$(curl -sSL --max-time 30 "$url" 2>/dev/null || true)"
	if [[ -z "$body" ]]; then
		echo "  no answer from $url" >&2
		continue
	fi
	name="$(printf '%s\n' "$body" | parse_versions_name || true)"
	if [[ -z "$name" ]]; then
		echo "  unusable response from $url" >&2
		continue
	fi
	payload="$body"
	LIVE_NAME="$name"
	SOURCE="$url"
	break
done

if [[ -z "$LIVE_NAME" ]]; then
	echo "no version source could be read -- nothing to compare." >&2
	exit 2
fi
echo "source: $SOURCE"

LIVE_INTERFACE="$(version_to_interface "$LIVE_NAME")" || {
	echo "error: could not read a version out of '$LIVE_NAME'." >&2
	exit 1
}

# "12.0.7.61234" -> "12.0.7", for humans.
LIVE_PATCH="${LIVE_NAME%.*}"

if [[ "$LIVE_INTERFACE" == "$TOC_INTERFACE" ]]; then
	drift=false
	echo "up to date: TOC $TOC_INTERFACE matches live $LIVE_PATCH"
else
	drift=true
	echo "DRIFT: live client is $LIVE_PATCH ($LIVE_INTERFACE), TOC says $TOC_INTERFACE"
fi

# Machine-readable results for the workflow.
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	{
		echo "drift=$drift"
		echo "live_interface=$LIVE_INTERFACE"
		echo "live_patch=$LIVE_PATCH"
		echo "live_name=$LIVE_NAME"
		echo "toc_interface=$TOC_INTERFACE"
	} >> "$GITHUB_OUTPUT"
fi
