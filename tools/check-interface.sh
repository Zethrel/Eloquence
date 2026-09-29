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
# The TOC may list several interface numbers, one per game it has been tested
# on -- "## Interface: 120100, 16001" is retail 12.1.0 and the WoW: Forever beta
# 1.60.1. Each product in PRODUCTS is checked against the TOC entry for ITS game,
# matched by major version (see toc_entry_for), so retail moving to 12.2 cannot be
# hidden by Forever being current, or the other way round.
#
# Usage:
#   tools/check-interface.sh              # fetch, compare, report
#   CHECK_SELFTEST=1 tools/check-interface.sh   # offline, exercises the parser
#
# Exit codes:
#   0  at least one product was compared (drift or not -- see the "drift" output;
#      a product whose feed could not be read is reported as "unreachable")
#   1  usage or parse error
#   2  could not reach any version source for any product (soft failure; the
#      caller should not treat this as drift)

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
# Each is a template: %s is the TACT product code.
#
# Set VERSIONS_URL to override with a single source (the tests use file:// URLs).
# A %s in it is replaced by the product code; without one, the same URL is used
# for every product.
VERSIONS_URL_TEMPLATES=(
	"https://us.version.battle.net/v2/products/%s/versions"
	"http://us.patch.battle.net:1119/%s/versions"
	"https://eu.version.battle.net/v2/products/%s/versions"
)
if [[ -n "${VERSIONS_URL:-}" ]]; then
	VERSIONS_URL_TEMPLATES=( "$VERSIONS_URL" )
fi

# The games checked, as "product:label". The label only appears in output.
#
#   wow               retail
#   wow_classic_beta  the client Battle.net installs into _classic_beta_, which in
#                     September 2026 is the WoW: Forever beta (build 1.60.1,
#                     interface 16001, confirmed in game with
#                     /dump select(4, GetBuildInfo())). Blizzard reuses this
#                     product for whichever Classic-family beta is running, so
#                     when Forever launches (November 2026) its live product code
#                     has to replace this entry -- the feed does not say which
#                     game a product is.
#
# Override with CHECK_PRODUCTS="wow:retail wow_classic_beta:forever-beta".
if [[ -n "${CHECK_PRODUCTS:-}" ]]; then
	read -r -a PRODUCTS <<< "$CHECK_PRODUCTS"
else
	PRODUCTS=( "wow:retail" "wow_classic_beta:forever-beta" )
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

# "## Interface: 120100, 16001" -> one interface number per line, in TOC order.
# The client accepts commas with or without spaces; so does this.
toc_interfaces() {
	sed -n 's/^## Interface:[[:space:]]*//p' "$1" | tr -d '\r' | head -1 \
		| tr ',' '\n' | tr -d '[:blank:]' | sed '/^$/d'
}

# The TOC entry that speaks for a live interface number: the one from the same
# game, which is the one with the same major version (live 120200 -> 120100,
# live 16002 -> 16001). Majors are what separate the games -- retail is 12, the
# Forever beta is 1 -- so a retail patch can never be compared against the
# Forever entry. If two entries share a major (Classic Era 11508 beside Forever
# 16001, say), the numerically closest one wins. Prints nothing when the TOC has
# no entry for that game at all.
toc_entry_for() {
	local live="$1"; shift
	local major=$(( live / 10000 )) best="" bestdist="" entry dist
	for entry in "$@"; do
		(( entry / 10000 == major )) || continue
		dist=$(( entry > live ? entry - live : live - entry ))
		if [[ -z "$best" || "$dist" -lt "$bestdist" ]]; then
			best="$entry"; bestdist="$dist"
		fi
	done
	[[ -n "$best" ]] && printf '%s' "$best"
	return 0
}

# One product's verdict against the TOC list:
#   up-to-date    the TOC entry for this game equals the live interface
#   drift         the TOC entry for this game is a different number
#   not-declared  the TOC has no entry for this game at all
verdict_for() {
	local live="$1"; shift
	local entry; entry="$(toc_entry_for "$live" "$@")"
	if [[ -z "$entry" ]]; then echo "not-declared"
	elif [[ "$entry" == "$live" ]]; then echo "up-to-date"
	else echo "drift"; fi
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

	# The interface list, with and without spaces, and with a CRLF ending.
	tmp_toc="$(mktemp)"
	printf '## Title: X\r\n## Interface: 120100, 16001\r\n' > "$tmp_toc"
	expect "TOC list with spaces" "$(toc_interfaces "$tmp_toc" | paste -sd' ')" "120100 16001"
	printf '## Interface:120100,16001\n' > "$tmp_toc"
	expect "TOC list without spaces" "$(toc_interfaces "$tmp_toc" | paste -sd' ')" "120100 16001"
	printf '## Interface: 120100\n' > "$tmp_toc"
	expect "single-entry TOC still reads" "$(toc_interfaces "$tmp_toc" | paste -sd' ')" "120100"
	rm -f "$tmp_toc"

	# Each game is compared with its own entry, never the other game's.
	expect "retail current"              "$(verdict_for 120100 120100 16001)" "up-to-date"
	expect "Forever current"             "$(verdict_for 16001 120100 16001)"  "up-to-date"
	expect "retail moved on"             "$(verdict_for 120200 120100 16001)" "drift"
	expect "Forever moved on"            "$(verdict_for 16002 120100 16001)"  "drift"
	expect "Forever unaffected by retail" "$(verdict_for 16001 120200 16001)" "up-to-date"
	expect "game missing from the TOC"   "$(verdict_for 16001 120100)"        "not-declared"
	expect "entry picked by major"       "$(toc_entry_for 120200 120100 16001)" "120100"
	expect "closest entry within a major" "$(toc_entry_for 16002 11508 16001)" "16001"
	expect "Classic Era keeps its own"   "$(toc_entry_for 11508 11508 16001)"  "11508"

	# The real TOC must parse, and every entry must be a plain number, or the
	# comparison below is meaningless.
	mapfile -t real < <(toc_interfaces "$TOC")
	bad=0
	for entry in "${real[@]}"; do [[ "$entry" =~ ^[0-9]+$ ]] || bad=1; done
	if [[ "${#real[@]}" -gt 0 && "$bad" == 0 ]]; then
		echo "  ok   TOC interfaces parse -> ${real[*]}"
	else
		echo "  FAIL TOC interfaces did not parse -> '${real[*]}'"; fails=1
	fi

	exit "$fails"
fi

#-------------------------------------------------------------------------------
# Check
#-------------------------------------------------------------------------------

mapfile -t TOC_INTERFACES < <(toc_interfaces "$TOC")
if [[ "${#TOC_INTERFACES[@]}" -eq 0 ]]; then
	echo "error: no usable '## Interface:' line in $TOC" >&2
	exit 1
fi
for entry in "${TOC_INTERFACES[@]}"; do
	if [[ ! "$entry" =~ ^[0-9]+$ ]]; then
		echo "error: '$entry' in the '## Interface:' line of $TOC is not a number" >&2
		exit 1
	fi
done
TOC_LIST="$(IFS=,; echo "${TOC_INTERFACES[*]}" | sed 's/,/, /g')"
echo "TOC declares: $TOC_LIST"

# One line per product: label|product|verdict|live_patch|live_interface|toc_entry
RESULTS=()
compared=0
any_drift=false

for spec in "${PRODUCTS[@]}"; do
	product="${spec%%:*}"
	label="${spec#*:}"

	# Try each source until one yields something parseable. A source that answers
	# but returns an unusable body is treated the same as one that does not answer
	# -- an error page is not a version feed -- so a single sick mirror cannot mask
	# a real patch. Which source won is logged, because "it worked" and "it worked
	# via the fallback" are different facts worth knowing.
	live_name=""
	source=""
	for template in "${VERSIONS_URL_TEMPLATES[@]}"; do
		# shellcheck disable=SC2059  # the template is ours, %s is the product
		url="$(printf "$template" "$product")"
		body="$(curl -sSL --max-time 30 "$url" 2>/dev/null || true)"
		if [[ -z "$body" ]]; then
			echo "  $label: no answer from $url" >&2
			continue
		fi
		name="$(printf '%s\n' "$body" | parse_versions_name || true)"
		if [[ -z "$name" ]]; then
			echo "  $label: unusable response from $url" >&2
			continue
		fi
		live_name="$name"
		source="$url"
		break
	done

	if [[ -z "$live_name" ]]; then
		echo "$label ($product): no version source could be read -- not compared."
		RESULTS+=( "$label|$product|unreachable|||" )
		continue
	fi

	live_interface="$(version_to_interface "$live_name")" || {
		echo "error: could not read a version out of '$live_name' for $product." >&2
		exit 1
	}
	# "12.0.7.61234" -> "12.0.7", for humans.
	live_patch="${live_name%.*}"
	entry="$(toc_entry_for "$live_interface" "${TOC_INTERFACES[@]}")"
	verdict="$(verdict_for "$live_interface" "${TOC_INTERFACES[@]}")"
	compared=$(( compared + 1 ))

	case "$verdict" in
		up-to-date)
			echo "$label ($product): up to date -- TOC $entry matches live $live_patch  [source: $source]" ;;
		drift)
			any_drift=true
			echo "$label ($product): DRIFT -- live client is $live_patch ($live_interface), TOC entry is $entry  [source: $source]" ;;
		not-declared)
			any_drift=true
			echo "$label ($product): NOT DECLARED -- live client is $live_patch ($live_interface) and the TOC has no entry for this game  [source: $source]" ;;
	esac
	RESULTS+=( "$label|$product|$verdict|$live_patch|$live_interface|$entry" )
done

# Machine-readable results for the workflow.
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	{
		echo "drift=$any_drift"
		echo "compared=$compared"
		echo "toc_interfaces=$TOC_LIST"
		echo "results<<RESULTS_EOF"
		printf '%s\n' "${RESULTS[@]}"
		echo "RESULTS_EOF"
	} >> "$GITHUB_OUTPUT"
fi

if [[ "$compared" -eq 0 ]]; then
	echo "no version source could be read for any product -- nothing to compare." >&2
	exit 2
fi
