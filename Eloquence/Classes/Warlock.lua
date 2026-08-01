-- Warlock.
--
-- Same clash as the Death Knight and for a related reason: a warlock trades in
-- fel and souls, and the Light is at best an irrelevance and at worst an enemy.
-- Where the Death Knight is cold, the warlock is transactional -- everything has
-- a price and they have already agreed to pay it.
local ADDON, E = ...

E.RegisterClass("WARLOCK", {
	name = "Warlock",

	flavorExclude = { "[Ll]ight", "Elune", "[Nn]aaru", "[Bb]lessing", "bless" },

	flavor = {
		prefix = { "Naturally.", "A small price.", "The fel provides.", "Souls are cheap." },
		suffix = { "for a price", "the fel remembers", "as bargained", "power has a cost" },
	},

	words = {
		["magic"] = "the fel", ["power"] = "the fel",
		["deal"] = "pact", ["promise"] = "pact", ["agreement"] = "pact",
		["cost"] = "price", ["free"] = "unpaid for",
		["soul"] = "soul, and I know its worth",
		["pet"] = "minion", ["friend"] = "associate",
		["holy"] = "searing", ["blessed"] = "burdened",
	},

	wordsAt = {
		[3] = {
			["help"] = "bargain", ["please"] = "if the price suits",
			["dangerous"] = "expensive", ["safe"] = "paid for",
		},
	},

	phrases = {
		{ "%f[%a]good luck%f[%A]", "may your price be low" },
		{ "%f[%a]thank you%f[%A]", "your debt is noted" },
		{ "%f[%a]no problem%f[%A]", "the price was small" },
	},
})
