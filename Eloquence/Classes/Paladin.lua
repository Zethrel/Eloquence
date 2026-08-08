-- Paladin.
--
-- The other direction. Where the Death Knight and the warlock have the Light
-- stripped out of their flavour, a paladin leans into it -- so the same mechanism
-- that removes an idiom can add one, and a Human paladin and a Human death
-- knight no longer sound like the same person.
--
-- Nothing is excluded here: a paladin is welcome to every pious thing their race
-- already says.
local ADDON, E = ...

E.RegisterClass("PALADIN", {
	name = "Paladin",

	flavor = {
		prefix = { "By the Light,", "Hold.", "The Light guides me.", "Stand fast." },
		suffix = { "by the Light", "as the Light wills", "so I have sworn", "the Light protects" },
	},

	words = {
		["promise"] = "oath", ["promised"] = "swore", ["agreement"] = "oath",
		["duty"] = "sacred duty", ["justice"] = "the Light's justice",
		["evil"] = "the darkness", ["heal"] = "mend", ["healed"] = "mended",
	},

	wordsAt = {
		[3] = {
			-- "should" and "must" were here, both mapped to "am sworn to", which
			-- only agrees with "I": "you should go now" became "you am sworn to
			-- go now". A word mapping cannot see the subject, so the idiom moved
			-- to a phrase that carries the pronoun with it.
			["wrong"] = "unjust", ["right"] = "just",
		},
	},

	phrases = {
		{ "%f[%a]good luck%f[%A]", "may the Light watch over you" },
		{ "%f[%a]i promise%f[%A]", "I so swear" },
		{ "%f[%a]be careful%f[%A]", "walk in the Light" },
		{ "%f[%a]i should%f[%A]", "I am sworn to" },
		{ "%f[%a]i must%f[%A]", "I am sworn to" },
	},
})
