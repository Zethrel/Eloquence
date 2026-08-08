-- Druid.
--
-- Druids think in cycles and in seasons, and they measure time badly on purpose:
-- someone who has spent decades asleep in the Dream does not say "soon" the way
-- a soldier does. The idiom is patience, growth, and the balance -- the thing
-- druids are actually sworn to, rather than nature as scenery.
--
-- The shapeshifting is deliberately absent. A druid saying "in my bear form"
-- unprompted would be the addon narrating their abilities at them, and what a
-- character does is theirs to write.
--
-- Nothing is excluded. Night Elf druids revere Elune, Tauren druids the Earth
-- Mother, and both belong to the races that already say so.
local ADDON, E = ...

E.RegisterClass("DRUID", {
	name = "Druid",

	flavor = {
		prefix = { "In time.", "Consider the season.", "Patience.", "The balance holds." },
		suffix = { "as the balance requires", "in its own season", "growth is slow",
		           "the cycle turns regardless" },
	},

	words = {
		["nature"] = "the balance", ["balance"] = "the balance",
		["magic"] = "the wild's gift", ["forest"] = "the wilds", ["tree"] = "the old growth",
		["heal"] = "restore", ["healed"] = "restored", ["healing"] = "restoring",
		["dream"] = "the Dream", ["dreams"] = "the Dream",
		["grow"] = "come into season", ["die"] = "return to the soil",
	},

	wordsAt = {
		[3] = {
			["soon"] = "in a season or two", ["quickly"] = "sooner than growth allows",
			["wait"] = "let it come round", ["hurry"] = "force what should ripen",
			["destroy"] = "unmake what took an age", ["change"] = "turn",
		},
	},

	phrases = {
		{ "%f[%a]good luck%f[%A]", "may the wilds keep you" },
		{ "%f[%a]be careful%f[%A]", "tread lightly" },
		{ "%f[%a]calm down%f[%A]", "let it settle" },
		{ "%f[%a]right now%f[%A]", "in its own time" },
	},
})
