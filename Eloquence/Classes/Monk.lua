-- Monk.
--
-- Not only Pandaren. Monks are trained rather than born, so the layer has to sit
-- as well on a Human or a Blood Elf who studied in the Peak of Serenity as it
-- does on someone from Pandaria -- which means the idiom is the discipline, not
-- the culture. The Pandaren dialect already carries the culture, and the two
-- stack without repeating each other.
--
-- The habit is treating the self as something maintained: breath, balance, form,
-- a body that is worked on rather than simply inhabited.
local ADDON, E = ...

E.RegisterClass("MONK", {
	name = "Monk",

	flavor = {
		prefix = { "Breathe.", "Slowly.", "Find your footing.", "One thing at a time." },
		suffix = { "form before force", "the breath decides it", "so the training goes",
		           "balance first" },
	},

	words = {
		["body"] = "the vessel", ["mind"] = "the settled mind",
		["strength"] = "form", ["power"] = "what the body is taught",
		["fight"] = "spar", ["fighting"] = "sparring",
		["practice"] = "train", ["angry"] = "unbalanced", ["calm"] = "centred",
		["drunk"] = "swaying deliberately",
	},

	wordsAt = {
		[3] = {
			["hurry"] = "rush the form", ["quickly"] = "before the breath is ready",
			["tired"] = "spent, and it will pass", ["ready"] = "centred",
			["mistake"] = "a step out of form",
		},
	},

	phrases = {
		{ "%f[%a]calm down%f[%A]", "breathe, and begin again" },
		{ "%f[%a]good luck%f[%A]", "may your footing hold" },
		{ "%f[%a]be careful%f[%A]", "keep your balance" },
		{ "%f[%a]i don't know%f[%A]", "I have not trained for that", nil, true },
	},
})
