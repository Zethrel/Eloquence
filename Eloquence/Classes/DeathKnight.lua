-- Death Knight.
--
-- Reported by Môrgrith of Argent Dawn (EU), who plays one and pointed out that
-- his character had no business invoking the Light. The clearest case of the
-- problem, and the one that prompted the whole class layer.
--
-- A knight of the Ebon Blade is a corpse that kept its will: raised by the Lich
-- King, freed at Light's Hope, carrying the rune blade that did the killing.
-- They do not invoke the Light -- for most of them it actively hurts -- and they
-- do not wish anyone well in the ordinary way.
--
-- "Suffer well" is the Ebon Blade's own farewell, which is why it stands in for
-- goodbye rather than anything gentler.
--
-- What this layer does NOT do is flatten the racial voice. A Dwarf Death Knight
-- still speaks broad Scots; they simply stop thanking the Light for it.
local ADDON, E = ...

E.RegisterClass("DEATHKNIGHT", {
	name = "Death Knight",

	-- Racial flavour that a risen knight would not say. Matched against the
	-- flavour lines of whatever race the speaker happens to be, so this covers
	-- the Human Light, the Night Elf Elune and the Draenei Naaru at once.
	flavorExclude = {
		"[Ll]ight", "Elune", "[Nn]aaru", "[Bb]lessing", "bless",
		"the spirits", "Ancestors", "ancestors",
	},

	flavor = {
		prefix = { "Suffer well.", "Hmph.", "The dead do not hurry.", "I have died once already." },
		suffix = { "in death", "as the Blade wills", "nothing warms me", "I feel it still" },
	},

	words = {
		["goodbye"] = "suffer well", ["bye"] = "suffer well",
		["farewell"] = "suffer well",
		["alive"] = "still moving", ["living"] = "the warm",
		["dead"] = "dead, as I am", ["death"] = "the cold",
		["cold"] = "cold, though I hardly notice",
		["tired"] = "worn", ["hungry"] = "hollow",
		["heart"] = "what is left of my heart",
		["hope"] = "what passes for hope",
		["blessed"] = "spared", ["holy"] = "burning",
		["sword"] = "rune blade", ["blade"] = "rune blade",
	},

	wordsAt = {
		[3] = {
			["angry"] = "cold with it", ["afraid"] = "past fear",
			["friend"] = "you, who still breathe",
			["please"] = "", ["sorry"] = "it is done",
			["happy"] = "as near content as I come",
		},
	},

	phrases = {
		{ "%f[%a]good luck%f[%A]", "die well" },
		{ "%f[%a]take care%f[%A]", "suffer well" },
		{ "%f[%a]be careful%f[%A]", "death is patient" },
		{ "%f[%a]thank you%f[%A]", "you have my debt" },
		{ "%f[%a]i'm fine%f[%A]", "I am dead. I am not fine" },
		{ "%f[%a]god bless%f[%A]", "cold comfort" },
	},
})
