-- Priest.
--
-- The awkward one, and worth explaining because it constrains everything below.
--
-- The client tells an addon the class token, not the specialisation: "PRIEST"
-- covers a holy priest of the Light and a shadow priest who hears the Void, and
-- there is no way to tell them apart from a chat message. So a layer that leaned
-- into the Light would be wrong for half of them, and one that leaned into the
-- Shadow wrong for the other half.
--
-- What both actually share is the vocation rather than the source of it: faith,
-- devotion, vows, the care of other people's souls, a habit of speaking about
-- suffering as something to be tended. That is what this layer is built from,
-- and it is why nothing here names the Light or the Void.
--
-- Nothing is excluded either. A priest is welcome to every pious thing their
-- race already says, and a Forsaken shadow priest is already served by the
-- Forsaken dialect saying it in their own register.
local ADDON, E = ...

E.RegisterClass("PRIEST", {
	name = "Priest",

	flavor = {
		prefix = { "Be at peace.", "Hear me.", "Have faith.", "Take comfort." },
		suffix = { "as my vows require", "faith carries it", "so I was taught",
		           "there is comfort in that" },
	},

	words = {
		-- Only words that are the same part of speech as their replacement.
		-- "work" -> "calling" turned "that will work" into "that will calling",
		-- and "hurt" -> "suffering" turned "I hurt" into "I suffering": both were
		-- the noun sense standing in for the verb.
		["promise"] = "vow", ["promised"] = "vowed", ["belief"] = "faith",
		["pain"] = "suffering", ["suffering"] = "suffering",
		["heal"] = "tend", ["healed"] = "tended", ["healing"] = "tending",
		["duty"] = "calling", ["prayer"] = "prayer", ["prayers"] = "prayers",
	},

	wordsAt = {
		[3] = {
			["death"] = "the passing", ["dying"] = "passing",
			["sad"] = "burdened", ["tired"] = "wearied in spirit",
			["afraid"] = "troubled in spirit",
		},
	},

	phrases = {
		{ "%f[%a]good luck%f[%A]", "may you be kept whole" },
		{ "%f[%a]i promise%f[%A]", "I give you my vow" },
		{ "%f[%a]be careful%f[%A]", "guard yourself, body and spirit" },
		{ "%f[%a]thank you%f[%A]", "you have my gratitude, sincerely meant" },
		-- Carries its own pronoun, so it cannot disagree with the subject.
		{ "%f[%a]i should%f[%A]", "I am called to" },
	},
})
