-- Demon Hunter.
--
-- An Illidari burned out their own eyes and swallowed a demon to hunt demons.
-- They are contemptuous of comfort, they see by fel sight rather than light, and
-- the Light is the thing they gave up. Sharper and more impatient than the
-- warlock, who at least enjoys the bargain.
local ADDON, E = ...

E.RegisterClass("DEMONHUNTER", {
	name = "Demon Hunter",

	flavorExclude = { "[Ll]ight", "Elune", "[Nn]aaru", "[Bb]lessing", "bless" },

	flavor = {
		prefix = { "I have sacrificed everything.", "Hmph.", "You see nothing.", "The hunt continues." },
		suffix = { "as the hunt demands", "I gave my eyes for this", "there is no going back" },
	},

	words = {
		["see"] = "sense", ["saw"] = "sensed", ["look"] = "sense",
		["eyes"] = "what I gave up", ["blind"] = "sighted, in the way that matters",
		["demon"] = "prey", ["demons"] = "prey",
		["sacrifice"] = "the price I paid", ["holy"] = "searing",
		["patience"] = "time I do not have",
	},

	wordsAt = {
		[3] = {
			["wait"] = "the hunt does not wait", ["slow"] = "too slow",
			["afraid"] = "past fear", ["rest"] = "there is no rest",
		},
	},

	phrases = {
		{ "%f[%a]good luck%f[%A]", "hunt well" },
		{ "%f[%a]trust me%f[%A]", "I gave everything for this" },
		{ "%f[%a]i understand%f[%A]", "I have seen worse" },
	},
})
