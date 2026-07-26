-- Nightborne (shal'dorei): ten thousand years of Suramar, and it shows.
--
-- Night elves by origin, but sealed inside Suramar for ten millennia and grown
-- dependent on the Nightwell. The result is not the Darnassian register: where
-- Darnassian is reverent and unhurried, shal'dorei is aloof, exacting and faintly
-- bitter -- they chose the Horde partly because they found their Kaldorei kin
-- insufferably pretentious.
local ADDON, E = ...

E.RegisterDialect("Nightborne", {
	name = "Shal'dorei",
	desc = "Aloof, exacting and faintly bitter. Ten thousand years of Suramar.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "you have my attention", ["hi"] = "you have my attention",
		["hey"] = "you there", ["greetings"] = "well met, if it must be said",
		["goodbye"] = "go, then", ["bye"] = "go, then", ["farewell"] = "go well, I suppose",
		["thanks"] = "I acknowledge it", ["please"] = "do",
		["sorry"] = "a rare admission, but yes",
		["yes"] = "quite", ["yeah"] = "quite", ["yep"] = "quite",
		["ok"] = "very well", ["okay"] = "very well", ["sure"] = "certain",
		["no"] = "no", ["nope"] = "hardly", ["maybe"] = "conceivably",
		["friend"] = "acquaintance", ["friends"] = "associates",
		["guy"] = "one", ["guys"] = "you lot", ["dude"] = "you",
		["human"] = "short-lived one", ["humans"] = "the short-lived",
		["magic"] = "the arcane", ["mana"] = "the arcane", ["power"] = "the arcane",
		["addiction"] = "our long dependence", ["nightwell"] = "the Nightwell",
		["home"] = "Suramar", ["city"] = "Suramar", ["queen"] = "the Grand Magistrix",
		["leader"] = "the Grand Magistrix",
		["good"] = "adequate", ["great"] = "remarkable", ["nice"] = "passable",
		["fine"] = "adequate", ["bad"] = "regrettable", ["awful"] = "insupportable",
		["awesome"] = "remarkable", ["cool"] = "tolerable",
		["stupid"] = "dull", ["dumb"] = "dull", ["crazy"] = "unwell",
		["weird"] = "provincial", ["rude"] = "beneath comment",
		["new"] = "untested", ["young"] = "an infant", ["old"] = "properly aged",
		["big"] = "considerable", ["small"] = "trifling", ["little"] = "trifling",
		["very"] = "quite", ["really"] = "truly", ["quite"] = "rather",
		["hurry"] = "I do not hurry", ["rush"] = "I do not hurry",
		["wait"] = "wait, as we have waited", ["fast"] = "hasty",
		["die"] = "perish", ["died"] = "perished", ["dead"] = "dust",
		["death"] = "dust", ["kill"] = "unmake", ["killed"] = "unmade",
		["fight"] = "duel", ["war"] = "the tedious business of war",
		["help"] = "assist", ["helped"] = "assisted",
		["think"] = "consider", ["want"] = "require", ["need"] = "require",
		["talk"] = "converse", ["look"] = "observe", ["understand"] = "grasp",
		["food"] = "sustenance", ["drink"] = "wine", ["sleep"] = "I have slept enough",
		["money"] = "coin", ["problem"] = "trifle", ["mistake"] = "lapse",
	}),

	wordsAt = {
		[3] = {
			["year"] = "decade", ["years"] = "decades",
			["time"] = "a century or two", ["long"] = "long, by your reckoning",
			["forever"] = "ten thousand years, and counting",
			["history"] = "what I remember of it",
			["outside"] = "the world beyond the shield",
			["free"] = "free, at considerable cost",
			["night elf"] = "our estranged kin", ["exile"] = "our long seclusion",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "I have not troubled myself to learn", nil, true },
		{ "%f[%a]i think%f[%A]", "I should think" },
		{ "%f[%a]i guess%f[%A]", "I suppose, if pressed", nil, true },
		{ "%f[%a]thank you%f[%A]", "I acknowledge it" },
		{ "%f[%a]good luck%f[%A]", "try not to disappoint" },
		{ "%f[%a]be careful%f[%A]", "mind yourself" },
		{ "%f[%a]what's up%f[%A]", "what is it" },
		{ "%f[%a]hurry up%f[%A]", "I have waited ten thousand years; you may wait a moment" },
		{ "%f[%a]let's go%f[%A]", "come, then" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde -- curious as that still sounds" },
	},

	flavor = {
		chance = 0.18,
		-- Comma-terminated prefixes have to be discourse markers: a noun phrase
		-- like "Ten thousand years," reads badly in front of a capitalised
		-- sentence, so that idea lives in the suffixes instead.
		prefix = { "Hm.", "Indeed.", "How novel.", "Very well.", "Spare me." },
		suffix = {
			"naturally", "as ever", "if you insist", "for whatever that is worth",
			"in time, which I have in abundance",
		},
	},
})
