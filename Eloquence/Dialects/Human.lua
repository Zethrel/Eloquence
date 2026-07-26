-- Common: deliberately the lightest dialect of the set. Human speech is the
-- baseline everyone else is measured against, so this only nudges the most
-- glaringly modern turns of phrase into something in-character.
-- "King's honor, friend."
local ADDON, E = ...

E.RegisterDialect("Human", {
	name = "Common",
	desc = "A light touch of in-character phrasing. \"King's honor, friend.\"",

	words = {
		["hello"] = "well met", ["hi"] = "well met", ["hey"] = "ho there",
		["greetings"] = "well met", ["goodbye"] = "king's honor",
		["bye"] = "king's honor", ["farewell"] = "king's honor, friend",
		["thanks"] = "my thanks", ["sorry"] = "my apologies",
		["yes"] = "aye", ["yeah"] = "aye", ["yep"] = "aye",
		["no"] = "nay", ["nope"] = "nay",
		["ok"] = "very well", ["okay"] = "very well",
		["guy"] = "fellow", ["guys"] = "friends", ["dude"] = "friend",
		["awesome"] = "splendid", ["cool"] = "well done", ["nice"] = "well done",
		["crazy"] = "madness", ["stupid"] = "foolish", ["dumb"] = "foolish",
		["king"] = "the King", ["money"] = "coin", ["gold"] = "coin",
		["city"] = "Stormwind", ["home"] = "Stormwind",
	},

	wordsAt = {
		[3] = {
			["friend"] = "friend", ["help"] = "aid", ["fight"] = "do battle",
			["kill"] = "strike down", ["dead"] = "fallen", ["food"] = "provisions",
			["drink"] = "ale", ["big"] = "great", ["very"] = "most",
			["really"] = "truly", ["hurry"] = "make haste", ["wait"] = "hold",
		},
	},

	phrases = {
		{ "%f[%a]thank you%f[%A]", "my thanks to you" },
		{ "%f[%a]good luck%f[%A]", "fortune favor you" },
		{ "%f[%a]be careful%f[%A]", "mind yourself" },
		{ "%f[%a]what's up%f[%A]", "what news" },
		{ "%f[%a]let's go%f[%A]", "let us be off" },
		{ "%f[%a]for the alliance%f[%A]", "for the Alliance" },
		{ "%f[%a]good job%f[%A]", "well done" },
	},

	flavor = {
		chance = 0.12,
		prefix = { "Well met.", "Ho there,", "Right then,", "By the Light," },
		suffix = { "friend", "king's honor", "aye", "as the Light wills" },
	},
})
