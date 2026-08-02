-- Darnassian-flavoured: formal, unhurried, few contractions, some Darnassian.
-- "Ishnu-alah." "Ande'thoras-ethil."
--
-- SOURCE
-- The glossary is drawn from "Darnassian (Canon) Translation", a community
-- document collecting every attested word and phrase and keeping the confirmed
-- translations separate from the speculative ones:
-- https://docs.google.com/document/d/1bD2qSEdWweR7xfIqUx_Iewv_4F40gboM-6ViSgfn1O8
--
-- ADDING MORE DARNASSIAN
-- The GLOSSARY table below is the place for it. Everything currently in it is
-- attested in Warcraft sources (quest text, unit voice lines, Warcraft III), and
-- nothing has been invented -- if you extend it from the document above, keep
-- that split and leave out anything it marks as unknown or unconfirmed. Phrase
-- entries are ordinary Lua patterns, matched before the single-word table, so
-- multi-word idioms win over their parts.
local ADDON, E = ...

-- English trigger -> canon Darnassian, applied at strength 3 only: a whole
-- message peppered with untranslated Darnassian becomes unreadable fast.
--
-- Every entry below is attested Darnassian. Deliberately left out:
--   * proper nouns that are already the English word (weapon and artefact names
--     like Ellemayne "Reaver", Shalla'tor "Shadow Render", Al'anath "Frostsoul",
--     Elun'dris "the Eye of Elune") -- nobody types "reaver" meaning the sword;
--   * bare grammatical fragments (Aria "we face", Bessae "from the", Finel
--     "the last") which cannot be substituted safely mid-sentence;
--   * Belore, whose "sun" reading is Thalassian rather than Darnassian.
--
-- Longer phrases are listed before shorter ones they contain, since the first
-- matching rule wins: "good fortune to your family" must precede "good fortune
-- to you".
local GLOSSARY_PHRASES = {
	-- Greetings, farewells and courtesies
	{ "%f[%a]good fortune to your family%f[%A]", "Ishnu-dal-dieb" },
	{ "%f[%a]good fortune to you%f[%A]", "Ishnu-alah" },
	{ "%f[%a]may your troubles be diminished%f[%A]", "Ande'thoras-ethil" },
	{ "%f[%a]elune be with you%f[%A]", "Elune-adore" },
	{ "%f[%a]thank you%f[%A]", "Shaha lor'ma" },
	{ "%f[%a]who goes there%f[%A]", "Fandu-dath-belore" },
	{ "%f[%a]who's there%f[%A]", "Fandu-dath-belore" },

	-- War cries and declarations
	{ "%f[%a]prepare to fight%f[%A]", "Bandu thoribas" },
	{ "%f[%a]prepare yourself%f[%A]", "Bandu thoribas" },
	{ "%f[%a]let our enemies beware%f[%A]", "Tor ilisar'thera'nal" },
	{ "%f[%a]let balance be restored%f[%A]", "Andu-falah-dor" },
	{ "%f[%a]let my will be known%f[%A]", "Anu'dorini Talah" },
	{ "%f[%a]it shall be done%f[%A]", "Ash karath" },
	{ "%f[%a]do it%f[%A]", "Ash karath" },

	-- Sayings
	{ "%f[%a]the truth is a guiding light%f[%A]", "Shanna melor'ne adala fal" },
	{ "%f[%a]finding beauty in imperfection%f[%A]", "Alara'shinu" },
	{ "%f[%a]heavy are our hearts%f[%A]", "Shu dallas na" },
	{ "%f[%a]our hearts are heavy%f[%A]", "Shu dallas na" },
	{ "%f[%a]those who remain hidden%f[%A]", "Shen'dralar" },

	-- Peoples
	{ "%f[%a]night elves%f[%A]", "kaldorei" },
	{ "%f[%a]night elf%f[%A]", "kaldorei" },
	{ "%f[%a]high elves%f[%A]", "quel'dorei" },
	{ "%f[%a]high elf%f[%A]", "quel'dorei" },

	-- The World Trees, by their meanings
	{ "%f[%a]crown of the heavens%f[%A]", "Nordrassil" },
	{ "%f[%a]crown of the earth%f[%A]", "Teldrassil" },
	{ "%f[%a]crown of harmony%f[%A]", "Amirdrassil" },
	{ "%f[%a]crown of the snow%f[%A]", "Andrassil" },
	{ "%f[%a]broken crown%f[%A]", "Vordrassil" },
	{ "%f[%a]glory of azshara%f[%A]", "Zin-Azshari" },
	{ "%f[%a]seat of the sky%f[%A]", "Lathar'Lazal" },
}

local GLOSSARY_WORDS = {
	-- Titles and kin
	["teacher"] = "shan'do", ["mentor"] = "shan'do", ["master"] = "shan'do",
	["student"] = "thero'shan", ["apprentice"] = "thero'shan",
	["father"] = "an'da", ["dad"] = "an'da", ["papa"] = "an'da",
	["mother"] = "min'da", ["mom"] = "min'da", ["mum"] = "min'da", ["mama"] = "min'da",
	["aunt"] = "shal'nar",
	["thanks"] = "shaha lor'ma",
	-- Xaxas: chaos, fury, elemental rage; and the name they give Deathwing.
	["chaos"] = "xaxas", ["fury"] = "xaxas", ["catastrophe"] = "xaxas",
	["deathwing"] = "Xaxas",
	["oblivion"] = "denalore", ["devastation"] = "denalore",
	["sea"] = "lura", ["ocean"] = "lura",
	-- A warrior armed only with words.
	["diplomat"] = "t'lara", ["orator"] = "t'lara",
	["druid"] = "shan'do of the wild",
}

E.RegisterDialect("NightElf", {
	name = "Darnassian",
	desc = "Formal and unhurried, with Darnassian. \"Ishnu-alah, kin.\"",

	-- Night Elves speak without contractions; that expansion is the backbone.
	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		-- GREETINGS AND FAREWELLS
		-- Reported: a farewell was being used as a greeting. "Asha'falah" is a
		-- goodbye, and it was serving as both the strength-3 "hello" and a flavour
		-- prefix, so Night Elves opened conversations by saying farewell.
		--
		-- Also reported: every Night Elf greeted identically, because one word was
		-- mapped to one replacement. Darnassian has three attested greetings and
		-- they are now all used -- the engine picks from a list per occurrence,
		-- seeded from the message, so the choice varies between lines but never
		-- between viewers of the same line.
		--
		-- Confirmed by Blizzard, so these are used at every strength:
		--   Ishnu-alah        good fortune to you
		--   Ishnu-dal-dieb    good fortune to your family
		--   Elune-adore       Elune be with you
		--   Ande'thoras-ethil may your troubles be diminished (a FAREWELL)
		["hello"] = { "Ishnu-alah", "Elune-adore", "Ishnu-dal-dieb" },
		["hi"] = { "Ishnu-alah", "Elune-adore" },
		["hey"] = { "Ishnu-alah", "Elune-adore" },
		["greetings"] = { "Ishnu-alah", "Elune-adore", "Ishnu-dal-dieb" },
		["goodbye"] = "Ande'thoras-ethil",
		["bye"] = "Ande'thoras-ethil", ["farewell"] = "Ande'thoras-ethil",
		["thanks"] = "you have my gratitude", ["luck"] = "Elune's favor",
		["yes"] = "indeed", ["yeah"] = "indeed", ["yep"] = "indeed",
		["ok"] = "very well", ["okay"] = "very well", ["sure"] = "certain",
		["no"] = "nay", ["nope"] = "nay", ["maybe"] = "perhaps",
		-- TERMS OF ADDRESS
		-- "friend" was mapped to "shan'do", which the glossary above correctly
		-- glosses as *teacher* -- so a Night Elf addressed everyone they met as
		-- their master. Shan'do is a title earned by someone who taught you, not a
		-- general courtesy.
		--
		-- "brother" and "sister" are the natural kaldorei alternatives, but a
		-- vocative is aimed at whoever is being spoken to and the addon has no idea
		-- who that is. Guessing would misgender people, so the neutral forms are
		-- used and the gendered ones are left for the player to type themselves.
		["friend"] = { "kin", "kindred" },
		["friends"] = "kin", ["ally"] = "kin", ["allies"] = "kin",
		["god"] = "Elune", ["goddess"] = "Elune", ["moon"] = "the Mother Moon",
		["night"] = "the Mother Moon's hour", ["forest"] = "the wilds",
		["human"] = "young one", ["humans"] = "the younger races",
		["guy"] = "one", ["guys"] = "kin", ["dude"] = "kin",
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
			["yeah"] = "it is so",
			-- Attested in Warcraft sources with a known FUNCTION but no confirmed
			-- translation, so they are held back to strength 3 where the rest of
			-- the untranslated glossary lives:
			--   Sael'ah          written as a greeting on the Encrypted Sigil
			--   En'shu falah-nah Illidan's farewell to Tyrande in Warcraft III
			--   Asha'falah       a goodbye; the reading is community guesswork
			-- We do not need the literal meaning to know which end of a
			-- conversation each belongs at, which is all a greeting has to get right.
			["hello"] = { "Ishnu-alah", "Elune-adore", "Ishnu-dal-dieb", "Sael'ah" },
			["greetings"] = { "Ishnu-alah", "Elune-adore", "Ishnu-dal-dieb", "Sael'ah" },
			["goodbye"] = { "Ande'thoras-ethil", "En'shu falah-nah", "Asha'falah" },
			["bye"] = { "Ande'thoras-ethil", "Asha'falah" },
			["farewell"] = { "Ande'thoras-ethil", "En'shu falah-nah", "Asha'falah" },
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
		-- Interjections, not salutations.
		--
		-- "Asha'falah" was here and is a farewell, which is how a goodbye ended up
		-- greeting people. Replacing it with a greeting only inverted the problem:
		-- a prefix is prepended to any message at random, so "Ishnu-alah." landed
		-- on a goodbye and produced "Ishnu-alah. Ande'thoras-ethil." -- hello,
		-- goodbye.
		--
		-- Salutations belong to the word mapping, which fires when someone actually
		-- greets or parts. What goes here has to read sensibly in front of an
		-- arbitrary sentence.
		prefix = { "By Elune,", "Hear me,", "In truth,", "Consider this,", "Elune's grace," },
		-- "young one" and "shan'do" were here. Both are wrong as general suffixes:
		-- a suffix is appended to any message regardless of who is listening, and
		-- kaldorei measure their lives in millennia, so calling another elf young
		-- is nonsense. "shan'do" had the same fault as the "friend" mapping above.
		--
		-- "young one" survives as the mapping for *human* further up, where the
		-- condescension is the point and the listener is known.
		suffix = { "kin", "as Elune wills", "in time", "kindred", "as the balance demands" },
	},
})
