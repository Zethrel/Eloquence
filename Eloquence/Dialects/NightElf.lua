-- Darnassian-flavoured: formal, unhurried, few contractions, some Darnassian.
-- "Ishnu'alah." "Asha'falah."
--
-- ADDING MORE DARNASSIAN
-- The GLOSSARY table below is the place for it. Everything currently in it is
-- attested in Warcraft sources (quest text, unit voice lines, Warcraft III), and
-- nothing has been invented -- if you extend it from a community translation
-- document, keep that split and leave out anything the document itself marks as
-- unknown or unconfirmed. Phrase entries are ordinary Lua patterns, matched
-- before the single-word table, so multi-word idioms win over their parts.
local ADDON, E = ...

-- English trigger -> attested Darnassian. Applied at strength 3 only, because a
-- whole message peppered with untranslated Darnassian gets hard to read fast.
local GLOSSARY_PHRASES = {
	{ "%f[%a]prepare to fight%f[%A]", "Bandu thoribas" },
	{ "%f[%a]prepare yourself%f[%A]", "Bandu thoribas" },
	{ "%f[%a]it shall be done%f[%A]", "Ash karath" },
	{ "%f[%a]let our enemies beware%f[%A]", "Tor ilisar'thera'nal" },
	{ "%f[%a]let balance be restored%f[%A]", "Andu-falah-dor" },
	{ "%f[%a]good fortune to you%f[%A]", "Ishnu-alah" },
	{ "%f[%a]good fortune to your family%f[%A]", "Ishnu-dal-dieb" },
	{ "%f[%a]may your troubles be diminished%f[%A]", "Ande'thoras-ethil" },
	{ "%f[%a]elune be with you%f[%A]", "Elune-adore" },
	{ "%f[%a]night elf%f[%A]", "kaldorei" },
	{ "%f[%a]night elves%f[%A]", "kaldorei" },
	{ "%f[%a]high elves%f[%A]", "quel'dorei" },
	{ "%f[%a]blood elves%f[%A]", "sin'dorei" },
	{ "%f[%a]world tree%f[%A]", "Nordrassil" },
}

local GLOSSARY_WORDS = {
	["teacher"] = "shan'do", ["mentor"] = "shan'do", ["master"] = "shan'do",
	["student"] = "thero'shan", ["apprentice"] = "thero'shan",
	["druid"] = "shan'do of the wild",
}

E.RegisterDialect("NightElf", {
	name = "Darnassian",
	desc = "Formal and unhurried, with Darnassian. \"Ishnu'alah, young one.\"",

	-- Night Elves speak without contractions; that expansion is the backbone.
	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "ishnu'alah", ["hi"] = "ishnu'alah", ["hey"] = "ishnu'alah",
		["greetings"] = "ishnu'alah", ["goodbye"] = "ande'thoras-ethil",
		["bye"] = "ande'thoras-ethil", ["farewell"] = "ande'thoras-ethil",
		["thanks"] = "you have my gratitude", ["luck"] = "Elune's favor",
		["yes"] = "indeed", ["yeah"] = "indeed", ["yep"] = "indeed",
		["ok"] = "very well", ["okay"] = "very well", ["sure"] = "certain",
		["no"] = "nay", ["nope"] = "nay", ["maybe"] = "perhaps",
		["friend"] = "shan'do", ["friends"] = "kin", ["ally"] = "kin",
		["god"] = "Elune", ["goddess"] = "Elune", ["moon"] = "the Mother Moon",
		["night"] = "the Mother Moon's hour", ["forest"] = "the wilds",
		["human"] = "young one", ["humans"] = "the younger races",
		["guy"] = "one", ["guys"] = "friends", ["dude"] = "friend",
		["everyone"] = "all of you", ["kid"] = "youngling", ["kids"] = "younglings",
		["good"] = "well", ["great"] = "wondrous", ["nice"] = "pleasing",
		["awesome"] = "wondrous", ["cool"] = "serene", ["bad"] = "ill",
		["crazy"] = "moonstruck", ["stupid"] = "unwise", ["dumb"] = "unwise",
		["angry"] = "displeased", ["hate"] = "abhor", ["love"] = "cherish",
		["hurry"] = "make haste", ["quick"] = "swift", ["quickly"] = "swiftly",
		["fast"] = "swift", ["slow"] = "unhurried", ["wait"] = "hold a moment",
		["soon"] = "ere long", ["now"] = "at present", ["later"] = "in time",
		["always"] = "ever", ["never"] = "never once",
		["big"] = "great", ["huge"] = "vast", ["small"] = "slight",
		["very"] = "most", ["really"] = "truly", ["quite"] = "rather",
		["magic"] = "the arcane", ["nature"] = "the balance", ["balance"] = "the balance",
		["demon"] = "the Legion's filth", ["demons"] = "the Legion's filth",
		["undead"] = "the restless dead", ["death"] = "the long sleep",
		["kill"] = "strike down", ["killed"] = "struck down", ["fight"] = "do battle",
		["help"] = "aid", ["helped"] = "aided", ["helping"] = "aiding",
		["talk"] = "speak", ["talking"] = "speaking", ["ask"] = "inquire",
		["think"] = "believe", ["want"] = "wish", ["wants"] = "wishes",
		["need"] = "require", ["needs"] = "requires", ["get"] = "obtain",
		["buy"] = "purchase", ["sell"] = "trade", ["money"] = "coin",
		["sorry"] = "my regrets", ["please"] = "if you would",
		["problem"] = "difficulty", ["mistake"] = "error in judgment",
		["stop"] = "cease", ["start"] = "begin", ["end"] = "conclude",
		["look"] = "behold", ["see"] = "observe", ["understand"] = "comprehend",
	}),

	wordsAt = {
		[3] = E.Engine.Extend(GLOSSARY_WORDS, {
			["yeah"] = "it is so", ["hello"] = "asha'falah",
			["home"] = "Teldrassil", ["city"] = "Darnassus",
			["tree"] = "the World Tree's kin", ["stars"] = "Elune's children",
			["sleep"] = "the Emerald Dream", ["dream"] = "the Emerald Dream",
			["hunter"] = "sentinel",
			["war"] = "this long war", ["long"] = "long by your reckoning",
		}),
	},

	phrasesAt = {
		[3] = GLOSSARY_PHRASES,
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "It is my belief that", nil, true },
		{ "%f[%a]i guess%f[%A]", "I surmise" },
		{ "%f[%a]i don't know%f[%A]", "That knowledge escapes me", nil, true },
		{ "%f[%a]thank you%f[%A]", "you have my gratitude" },
		{ "%f[%a]good luck%f[%A]", "may Elune light your path" },
		{ "%f[%a]be careful%f[%A]", "tread with care" },
		{ "%f[%a]what's up%f[%A]", "what troubles you" },
		{ "%f[%a]hold on%f[%A]", "hold a moment" },
		{ "%f[%a]shut up%f[%A]", "hold your tongue" },
		{ "%f[%a]for the alliance%f[%A]", "for the Alliance, and for Elune" },
		{ "%f[%a]let's go%f[%A]", "let us depart" },
		{ "%f[%a]a lot of%f[%A]", "a great many of" },
		{ "%f[%a]lots of%f[%A]", "a great many of" },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Elune-adore.", "By Elune,", "Ishnu-alah.", "Hear me,", "Asha'falah." },
		suffix = { "young one", "as Elune wills", "in time", "shan'do", "as the balance demands" },
	},
})
