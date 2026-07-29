-- Gnomish: over-precise technical vocabulary colliding with folksy cliches.
--
-- WHY THERE IS NO GNOMISH GLOSSARY HERE
-- Darnassian and Thalassian carry glossaries of canon vocabulary. Gnomish has
-- none to carry: Blizzard never wrote any. Not a thin list like Dwarven's three
-- unusable entries -- nothing at all.
--
-- Blizzard's in-game translator generates syllables that merely look Gnomish,
-- with no dictionary behind them, and the parser reportedly shares its word pool
-- with Dwarven, Common and Gutterspeak. So the "Gnomish" a player sees in game is
-- procedural noise rather than a language, and there is nothing to source.
--
-- Inventing a vocabulary would break the rule both real glossaries state: only
-- attested material, nothing invented. Community addons do invent Gnomish words,
-- which is their authors' writing rather than lore -- and unlicensed besides.
--
-- The register below is what makes a Gnome sound like a Gnome: engineering
-- precision applied to everyday things, colliding with homely idiom. That is the
-- character, and it needs no fictional dictionary.
local ADDON, E = ...

E.RegisterDialect("Gnome", {
	name = "Gnomish",
	desc = "Brainy, over-precise vocabulary mixed with folksy cliches.",

	words = {
		["thing"] = "apparatus", ["things"] = "apparatuses", ["stuff"] = "components",
		["gadget"] = "contrivance", ["machine"] = "mechanism",
		["big"] = "sizeable", ["huge"] = "of considerable magnitude",
		["small"] = "diminutive", ["little"] = "diminutive", ["tiny"] = "sub-miniature",
		["good"] = "optimal", ["great"] = "highly optimal", ["nice"] = "agreeable",
		["bad"] = "suboptimal", ["awful"] = "catastrophically suboptimal",
		["broken"] = "nonfunctional", ["fix"] = "recalibrate", ["fixed"] = "recalibrated",
		["fixing"] = "recalibrating", ["repair"] = "recalibrate",
		["think"] = "hypothesize", ["thinking"] = "hypothesizing",
		["thought"] = "hypothesis", ["idea"] = "schematic", ["ideas"] = "schematics",
		["plan"] = "blueprint", ["plans"] = "blueprints", ["guess"] = "estimate",
		["maybe"] = "statistically possible", ["probably"] = "with high probability",
		["definitely"] = "with negligible margin of error",
		["look"] = "observe", ["looking"] = "observing", ["see"] = "observe",
		["saw"] = "observed", ["watch"] = "monitor", ["found"] = "isolated",
		["use"] = "utilize", ["used"] = "utilized", ["using"] = "utilizing",
		["make"] = "fabricate", ["made"] = "fabricated", ["making"] = "fabricating",
		["build"] = "engineer", ["built"] = "engineered", ["building"] = "engineering",
		["help"] = "assist", ["helped"] = "assisted", ["helping"] = "assisting",
		["fast"] = "expedient", ["quick"] = "expedient", ["quickly"] = "expediently",
		["slow"] = "sluggish", ["hurry"] = "expedite",
		["yes"] = "affirmative", ["yeah"] = "affirmative", ["yep"] = "affirmative",
		["ok"] = "affirmative", ["okay"] = "affirmative",
		["no"] = "negative", ["nope"] = "negative",
		["problem"] = "malfunction", ["problems"] = "malfunctions",
		["weird"] = "anomalous", ["strange"] = "anomalous", ["odd"] = "anomalous",
		["hard"] = "non-trivial", ["difficult"] = "non-trivial", ["easy"] = "trivial",
		["simple"] = "elementary", ["complicated"] = "multi-variate",
		["smart"] = "cerebral", ["clever"] = "cerebral", ["genius"] = "singular intellect",
		["stupid"] = "intellectually underdeveloped", ["dumb"] = "intellectually underdeveloped",
		["crazy"] = "statistically improbable", ["boom"] = "kaboom",
		["explode"] = "undergo rapid unplanned disassembly",
		["exploded"] = "underwent rapid unplanned disassembly",
		["magic"] = "arcane mechanics", ["spell"] = "arcane subroutine",
		["very"] = "exceedingly", ["really"] = "genuinely", ["quite"] = "measurably",
		["lots"] = "an abundance", ["many"] = "numerous",
		["work"] = "function", ["works"] = "functions", ["worked"] = "functioned",
		["try"] = "attempt", ["tried"] = "attempted", ["test"] = "trial",
		["start"] = "initialize", ["stop"] = "terminate", ["end"] = "terminate",
		["change"] = "modify", ["changed"] = "modified", ["check"] = "verify",
		["show"] = "demonstrate", ["tell"] = "apprise", ["say"] = "state",
		["get"] = "acquire", ["got"] = "acquired", ["give"] = "allocate",
		["kill"] = "neutralize", ["killed"] = "neutralized",
		["dead"] = "permanently offline", ["died"] = "went permanently offline",
		["friend"] = "colleague", ["friends"] = "colleagues", ["guy"] = "individual",
		["guys"] = "colleagues", ["people"] = "specimens", ["human"] = "tall-folk",
		["humans"] = "tall-folk", ["dwarf"] = "the bearded sort",
		["hello"] = "salutations", ["hi"] = "salutations", ["hey"] = "salutations",
		["goodbye"] = "until our next collaboration", ["bye"] = "until next time",
		["thanks"] = "my sincere appreciation", ["sorry"] = "my calculations were in error",
	},

	wordsAt = {
		[3] = {
			["water"] = "dihydrogen solution", ["fire"] = "exothermic reaction",
			["cold"] = "thermally deficient", ["hot"] = "thermally excessive",
			["food"] = "caloric intake", ["hungry"] = "caloric-deficient",
			["tired"] = "operating below nominal capacity",
			["sleep"] = "scheduled downtime", ["walk"] = "ambulate",
			["run"] = "ambulate at elevated velocity", ["fall"] = "descend involuntarily",
			["gun"] = "ballistic device",
			["sword"] = "edged implement", ["armor"] = "personal plating",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "my working hypothesis is that", nil, true },
		{ "%f[%a]i don't know%f[%A]", "the data are inconclusive", nil, true },
		{ "%f[%a]i have no idea%f[%A]", "the data are wholly inconclusive", nil, true },
		{ "%f[%a]it works%f[%A]", "it functions within tolerance" },
		{ "%f[%a]it doesn't work%f[%A]", "it operates outside tolerance" },
		{ "%f[%a]let's go%f[%A]", "let us commence" },
		{ "%f[%a]hold on%f[%A]", "one moment, recalibrating" },
		{ "%f[%a]watch out%f[%A]", "mind the blast radius" },
		{ "%f[%a]be careful%f[%A]", "observe standard safety protocol" },
		{ "%f[%a]good luck%f[%A]", "may the variables favor you" },
		{ "%f[%a]what's up%f[%A]", "what requires my attention" },
		{ "%f[%a]for the alliance%f[%A]", "for the Alliance, and for progress" },
	},

	flavor = {
		chance = 0.2,
		prefix = { "Fascinating!", "Right then,", "By my calculations,", "Ahem.", "Curious," },
		-- The folksy half of the joke.
		suffix = {
			"as they say", "if you catch my drift", "sure as gears turn",
			"give or take a decimal", "and that's the long and short of it",
			"more or less, within tolerance",
		},
	},
})
