-- Orcish: blunt, martial, a few words of Orcish. "Lok'tar!" "Zug zug."
--
-- SOURCE
-- The glossary below is attested Orcish, verified entry by entry against Warcraft
-- Wiki and Wowpedia. Orcish is the best-developed of the Horde languages: unlike
-- Dwarven and Gnomish, which have no usable canon vocabulary at all (see the
-- notes in those files), Blizzard wrote real Orcish words and glossed them.
--
-- ADDING MORE
-- Same discipline as Dialects/NightElf.lua and Dialects/BloodElf.lua: attested
-- only, nothing invented, nothing taken from another addon. Deliberately excluded:
--   * "Kek" -- widely used for "lol" but explicitly unconfirmed; it is one of
--     several three-letter strings the in-game garbler happens to produce, which
--     is not the same as a translation;
--   * Nagrand ("Land of Winds") and other place names -- proper nouns already
--     identical to the English word;
--   * bare "run" for Kagh! -- the exclamation is attested, but substituting the
--     word wherever it appears turns "I run every day" into nonsense, so it is
--     bound to the imperative phrase instead.
local ADDON, E = ...

local gsub = string.gsub

-- English trigger -> canon Orcish, applied at strength 3 only: a message peppered
-- with untranslated Orcish becomes unreadable fast.
--
-- Longer phrases precede shorter ones they contain, so "victory or death" is not
-- eaten by the bare "victory" rule.
local GLOSSARY_PHRASES = {
	-- War cries and oaths
	{ "%f[%a]victory or death%f[%A]", "Lok'tar ogar" },
	{ "%f[%a]by my axe%f[%A]", "Gol'Kosh" },
	{ "%f[%a]ready for orders%f[%A]", "Lok-Regar" },
	{ "%f[%a]awaiting orders%f[%A]", "Lok-Regar" },
	{ "%f[%a]run away%f[%A]", "Kagh" },
	{ "%f[%a]run for it%f[%A]", "Kagh" },

	-- Greetings and courtesies
	{ "%f[%a]well met%f[%A]", "Throm-Ka" },
	{ "%f[%a]a blessing on you and yours%f[%A]", "Aka'Magosh" },
	{ "%f[%a]a blessing on you%f[%A]", "Aka'Magosh" },

	-- Obedience and custom
	{ "%f[%a]i obey%f[%A]", "Dabu" },
	{ "%f[%a]as you command%f[%A]", "Dabu" },
	{ "%f[%a]duel of honou?r%f[%A]", "Mak'gora" },
	{ "%f[%a]rite of honou?r%f[%A]", "Om'gora" },
}

local GLOSSARY_WORDS = {
	["victory"] = "lok'tar",
	["yes"] = "zug zug", ["yeah"] = "zug zug", ["yep"] = "zug zug",
	["ok"] = "zug zug", ["okay"] = "zug zug",
	-- Ur'gora, "not-honor": the worst thing one orc can call another.
	["coward"] = "ur'gora", ["cowards"] = "ur'gora",
	["traitor"] = "ur'gora",
}

E.RegisterDialect("Orc", {
	name = "Orcish",
	desc = "Blunt and martial, with Orcish phrases. \"Lok'tar! Zug zug.\"",

	words = {
		["yes"] = "zug zug", ["yeah"] = "zug zug", ["yep"] = "zug zug",
		["ok"] = "zug zug", ["okay"] = "zug zug", ["sure"] = "certain",
		["no"] = "no", ["nope"] = "no",
		["hello"] = "lok'tar", ["hi"] = "lok'tar", ["hey"] = "lok'tar",
		["greetings"] = "lok'tar", ["goodbye"] = "lok'tar ogar", ["bye"] = "lok'tar ogar",
		["farewell"] = "lok'tar ogar", ["thanks"] = "you have my honor",
		["please"] = "", ["sorry"] = "I do not apologize",
		["friend"] = "brother", ["friends"] = "brothers", ["ally"] = "blood brother",
		["human"] = "pinkskin", ["humans"] = "pinkskins",
		["gnome"] = "tiny one", ["gnomes"] = "tiny ones",
		["dwarf"] = "stunted one", ["elf"] = "pointed-ear", ["elves"] = "pointed-ears",
		["enemy"] = "prey", ["enemies"] = "prey", ["coward"] = "gutless whelp",
		["weak"] = "weakling", ["weakness"] = "shame", ["afraid"] = "without honor",
		["scared"] = "without honor", ["run"] = "flee", ["runs"] = "flees",
		["fight"] = "battle", ["fighting"] = "battle", ["fought"] = "waged battle",
		["kill"] = "slay", ["killed"] = "slew", ["killing"] = "slaying",
		["die"] = "fall", ["died"] = "fell", ["dead"] = "slain",
		["win"] = "claim victory", ["won"] = "claimed victory",
		["lose"] = "know defeat", ["lost"] = "knew defeat",
		["strong"] = "strong as a kodo", ["strength"] = "strength",
		["good"] = "strong", ["great"] = "mighty", ["bad"] = "weak",
		["nice"] = "acceptable", ["awesome"] = "worthy of song", ["cool"] = "worthy",
		["stupid"] = "witless", ["crazy"] = "blood-mad",
		["magic"] = "magics", ["spell"] = "magics", ["shaman"] = "spirit-speaker",
		["work"] = "work", ["food"] = "meat", ["hungry"] = "in need of meat",
		["drink"] = "grog", ["beer"] = "grog", ["ale"] = "grog",
		["tired"] = "weary from battle", ["hurry"] = "move",
		["wait"] = "hold", ["help"] = "aid", ["helped"] = "aided",
		["talk"] = "speak", ["talking"] = "speaking", ["chat"] = "speak",
		["maybe"] = "perhaps", ["probably"] = "likely", ["definitely"] = "without question",
		["problem"] = "obstacle", ["mistake"] = "dishonor", ["luck"] = "the spirits' favor",
		["war"] = "war", ["blood"] = "blood", ["honor"] = "honor",
		["chief"] = "warchief", ["leader"] = "warchief", ["boss"] = "warchief",
	},

	-- Orcs do not waste breath on contractions or hedging.
	wordsAt = {
		[2] = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS),
		[3] = E.Engine.Extend(GLOSSARY_WORDS, {
			["very"] = "", ["really"] = "", ["just"] = "", ["actually"] = "",
			["kind"] = "", ["little"] = "small", ["sort"] = "",
		}),
	},

	phrasesAt = {
		[3] = GLOSSARY_PHRASES,
	},

	phrases = {
		-- The contempt belongs on the phrase, not the bare word: as a word rule
		-- this turned "run away" into "flee like a coward away" and "I run every
		-- day" into "I flee like a coward every day".
		{ "%f[%a]run away%f[%A]", "flee like a coward" },
		{ "%f[%a]run for it%f[%A]", "flee like a coward" },
		{ "%f[%a]for the horde%f[%A]", "LOK'TAR OGAR" },
		{ "%f[%a]let's go%f[%A]", "we march" },
		{ "%f[%a]come on%f[%A]", "move" },
		{ "%f[%a]i think%f[%A]", "I say" },
		{ "%f[%a]i guess%f[%A]", "I say" },
		{ "%f[%a]i don't know%f[%A]", "I do not know" },
		{ "%f[%a]thank you%f[%A]", "you have my honor" },
		{ "%f[%a]good job%f[%A]", "well fought" },
		{ "%f[%a]well done%f[%A]", "well fought" },
		{ "%f[%a]good luck%f[%A]", "may the spirits favor you" },
		{ "%f[%a]be careful%f[%A]", "guard your back" },
		{ "%f[%a]are you ready%f[%A]", "do you thirst for battle" },
	},

	post = function(chunk, ctx)
		-- Removing words leaves double spaces behind.
		chunk = gsub(chunk, "  +", " ")
		chunk = gsub(chunk, " ([,.!?])", "%1")
		return chunk
	end,

	flavor = {
		chance = 0.16,
		prefix = { "Lok'tar!", "Hrmph.", "Throm-Ka,", "Listen well.", "Dabu." },
		suffix = { "for the Horde", "blood and thunder", "as it should be", "nothing more" },
	},
})
