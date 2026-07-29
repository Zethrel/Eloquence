-- Thalassian: elegant, clipped, faintly condescending.
-- "Anar'alah." "Selama ashal'anore."
--
-- SOURCE
-- The glossary below is attested Thalassian -- quest text, NPC voice lines and
-- Warcraft III -- gathered from Warcraft Wiki and Wowpedia, which keep confirmed
-- translations on a separate page from the speculative ones. Only the confirmed
-- side is used. Nothing here was invented, and nothing was taken from another
-- addon: several community addons carry Thalassian word lists, but they are
-- unlicensed, and an invented coinage is its author's writing rather than lore.
--
-- ADDING MORE
-- Keep the split. If a word cannot be traced to Blizzard's own material, leave
-- it out, however plausible it looks. Deliberately excluded on the same grounds
-- as the Darnassian glossary in Dialects/NightElf.lua:
--   * bare fragments that cannot substitute mid-sentence (malanore "traveller"
--     only appears inside a fixed greeting);
--   * proper nouns that are already the English word.
--
-- Belore ("the sun") lives here rather than in the Darnassian glossary -- that
-- file documents the exclusion, since the reading is Thalassian.
local ADDON, E = ...

-- English trigger -> canon Thalassian, applied at strength 3 only: a message
-- peppered with untranslated Thalassian becomes unreadable fast.
--
-- Longer phrases precede shorter ones they contain, since the first matching
-- rule wins.
local GLOSSARY_PHRASES = {
	-- Greetings and courtesies
	{ "%f[%a]greetings,? traveller%f[%A]", "Bal'a dash, malanore" },
	{ "%f[%a]greetings,? traveler%f[%A]", "Bal'a dash, malanore" },
	{ "%f[%a]how fare you%f[%A]", "Doral ana'diel" },
	{ "%f[%a]how are you%f[%A]", "Doral ana'diel" },
	{ "%f[%a]safe travels%f[%A]", "Al diel shala" },
	{ "%f[%a]speak your business%f[%A]", "Anaria shola" },
	{ "%f[%a]state your business%f[%A]", "Anaria shola" },

	-- Invocations of the sun
	{ "%f[%a]by the light of the sun%f[%A]", "Anar'alah belore" },
	{ "%f[%a]the sun guides us%f[%A]", "Anu belore dela'na" },

	-- Declarations
	{ "%f[%a]justice for our people%f[%A]", "Selama ashal'anore" },
	{ "%f[%a]they'?re breaking through%f[%A]", "Shindu fallah na" },
	{ "%f[%a]prepare to say farewell%f[%A]", "Band'or shorel'aran" },

	-- Peoples
	{ "%f[%a]blood elves%f[%A]", "sin'dorei" },
	{ "%f[%a]high elves%f[%A]", "quel'dorei" },
	{ "%f[%a]void elves%f[%A]", "ren'dorei" },
}

local GLOSSARY_WORDS = {
	["sun"] = "belore",
	["farewell"] = "shorel'aran", ["goodbye"] = "shorel'aran",
}

E.RegisterDialect("BloodElf", {
	name = "Thalassian",
	desc = "Elegant, clipped and faintly condescending. \"Anar'alah.\"",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "anar'alah", ["hi"] = "anar'alah", ["hey"] = "you there",
		["greetings"] = "anar'alah", ["goodbye"] = "selama ashal'anore",
		["bye"] = "selama ashal'anore", ["farewell"] = "selama ashal'anore",
		["thanks"] = "you have my gratitude", ["please"] = "do",
		["sorry"] = "how unfortunate",
		["yes"] = "naturally", ["yeah"] = "naturally", ["yep"] = "naturally",
		-- "sure" is the adjective here, not the affirmative: mapping it to an
		-- affirmative turns "I'm not sure" into nonsense.
		["ok"] = "if you insist", ["okay"] = "if you insist", ["sure"] = "certain",
		["no"] = "hardly", ["nope"] = "hardly", ["maybe"] = "conceivably",
		["friend"] = "friend", ["friends"] = "associates", ["guy"] = "one",
		["guys"] = "you lot", ["dude"] = "you",
		["human"] = "lesser cousin", ["humans"] = "lesser cousins",
		["orc"] = "the brutes", ["orcs"] = "the brutes", ["troll"] = "the savages",
		["dwarf"] = "the stunted sort", ["tauren"] = "the cattle",
		["good"] = "acceptable", ["great"] = "exquisite", ["nice"] = "passable",
		["fine"] = "adequate", ["bad"] = "distasteful", ["awful"] = "appalling",
		["awesome"] = "magnificent", ["cool"] = "refined", ["ugly"] = "unfortunate to look upon",
		["stupid"] = "dull", ["dumb"] = "dull", ["crazy"] = "unhinged",
		["weird"] = "vulgar", ["cheap"] = "beneath consideration",
		["magic"] = "the arcane", ["mana"] = "the arcane", ["spell"] = "working",
		["addiction"] = "our burden", ["power"] = "power, as is our right",
		["city"] = "Silvermoon", ["home"] = "Silvermoon", ["king"] = "the Regent Lord",
		["very"] = "quite", ["really"] = "truly", ["quite"] = "rather",
		["big"] = "considerable", ["small"] = "trifling", ["little"] = "trifling",
		["hurry"] = "do keep up", ["wait"] = "a moment",
		["kill"] = "dispose of", ["killed"] = "disposed of", ["fight"] = "duel",
		["die"] = "perish", ["died"] = "perished", ["dead"] = "no longer our concern",
		["help"] = "assist", ["think"] = "should think", ["want"] = "desire",
		["need"] = "require", ["get"] = "acquire", ["buy"] = "acquire",
		["money"] = "gold, naturally", ["problem"] = "trifle",
		["mistake"] = "lapse", ["talk"] = "converse", ["look"] = "observe",
		["understand"] = "grasp", ["obviously"] = "as anyone would see",
	}),

	wordsAt = {
		[3] = E.Engine.Extend(GLOSSARY_WORDS, {
			["work"] = "labor", ["food"] = "refreshment", ["drink"] = "wine",
			["clothes"] = "attire", ["armor"] = "finery", ["house"] = "estate",
			["tired"] = "fatigued", ["hungry"] = "peckish", ["angry"] = "displeased",
			["happy"] = "content", ["sad"] = "melancholy",
		}),
	},

	phrasesAt = {
		[3] = GLOSSARY_PHRASES,
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "I should think" },
		{ "%f[%a]i guess%f[%A]", "I suppose, if pressed", nil, true },
		{ "%f[%a]i don't know%f[%A]", "that is hardly my concern", nil, true },
		{ "%f[%a]thank you%f[%A]", "you have my gratitude" },
		{ "%f[%a]good luck%f[%A]", "do try not to embarrass yourself" },
		{ "%f[%a]be careful%f[%A]", "mind yourself" },
		{ "%f[%a]what's up%f[%A]", "what is it now" },
		{ "%f[%a]hurry up%f[%A]", "do keep up" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and for Quel'Thalas" },
		{ "%f[%a]let's go%f[%A]", "shall we" },
	},

	flavor = {
		chance = 0.18,
		prefix = { "Anar'alah.", "Really.", "How droll.", "Obviously,", "Spare me." },
		suffix = {
			"naturally", "if you must", "as anyone would know",
			"do keep up", "glory to Quel'Thalas",
		},
	},
})
