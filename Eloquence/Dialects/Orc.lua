-- Orcish: blunt, martial, a few words of Orcish. "Lok'tar!" "Zug zug."
local ADDON, E = ...

local gsub = string.gsub

E.RegisterDialect("Orc", {
	name = "Orcish",
	desc = "Blunt and martial, with Orcish phrases. \"Lok'tar! Zug zug.\"",

	words = {
		["yes"] = "zug zug", ["yeah"] = "zug zug", ["yep"] = "zug zug",
		["ok"] = "zug zug", ["okay"] = "zug zug", ["sure"] = "certain",
		["no"] = "no", ["nope"] = "no",
		["hello"] = "lok'tar", ["hi"] = "lok'tar", ["hey"] = "lok'tar",
		["greetings"] = "lok'tar", ["goodbye"] = "lok'tar ogar", ["bye"] = "lok'tar ogar",
		["farewell"] = "lok'tar ogar", ["thanks"] = "you have my honor",
		["please"] = "", ["sorry"] = "I do not apologize",
		["friend"] = "brother", ["friends"] = "brothers", ["ally"] = "blood brother",
		["human"] = "pinkskin", ["humans"] = "pinkskins",
		["gnome"] = "tiny one", ["gnomes"] = "tiny ones",
		["dwarf"] = "stunted one", ["elf"] = "pointed-ear", ["elves"] = "pointed-ears",
		["enemy"] = "prey", ["enemies"] = "prey", ["coward"] = "gutless whelp",
		["weak"] = "weakling", ["weakness"] = "shame", ["afraid"] = "without honor",
		["scared"] = "without honor", ["run"] = "flee like a coward",
		["fight"] = "battle", ["fighting"] = "battle", ["fought"] = "waged battle",
		["kill"] = "slay", ["killed"] = "slew", ["killing"] = "slaying",
		["die"] = "fall", ["died"] = "fell", ["dead"] = "slain",
		["win"] = "claim victory", ["won"] = "claimed victory", ["victory"] = "victory or death",
		["lose"] = "know defeat", ["lost"] = "knew defeat",
		["strong"] = "strong as a kodo", ["strength"] = "strength",
		["good"] = "strong", ["great"] = "mighty", ["bad"] = "weak",
		["nice"] = "acceptable", ["awesome"] = "worthy of song", ["cool"] = "worthy",
		["stupid"] = "witless", ["crazy"] = "blood-mad",
		["magic"] = "magics", ["spell"] = "magics", ["shaman"] = "spirit-speaker",
		["work"] = "work", ["food"] = "meat", ["hungry"] = "in need of meat",
		["drink"] = "grog", ["beer"] = "grog", ["ale"] = "grog",
		["tired"] = "weary from battle", ["hurry"] = "move",
		["wait"] = "hold", ["help"] = "aid", ["helped"] = "aided",
		["talk"] = "speak", ["talking"] = "speaking", ["chat"] = "speak",
		["maybe"] = "perhaps", ["probably"] = "likely", ["definitely"] = "without question",
		["problem"] = "obstacle", ["mistake"] = "dishonor", ["luck"] = "the spirits' favor",
		["war"] = "war", ["blood"] = "blood", ["honor"] = "honor",
		["chief"] = "warchief", ["leader"] = "warchief", ["boss"] = "warchief",
	},

	-- Orcs do not waste breath on contractions or hedging.
	wordsAt = {
		[2] = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS),
		[3] = {
			["very"] = "", ["really"] = "", ["just"] = "", ["actually"] = "",
			["kind"] = "", ["little"] = "small", ["sort"] = "",
		},
	},

	phrases = {
		{ "%f[%a]for the horde%f[%A]", "LOK'TAR OGAR" },
		{ "%f[%a]let's go%f[%A]", "we march" },
		{ "%f[%a]come on%f[%A]", "move" },
		{ "%f[%a]i think%f[%A]", "I say" },
		{ "%f[%a]i guess%f[%A]", "I say" },
		{ "%f[%a]i don't know%f[%A]", "I do not know" },
		{ "%f[%a]thank you%f[%A]", "you have my honor" },
		{ "%f[%a]good job%f[%A]", "well fought" },
		{ "%f[%a]well done%f[%A]", "well fought" },
		{ "%f[%a]good luck%f[%A]", "may the spirits favor you" },
		{ "%f[%a]be careful%f[%A]", "guard your back" },
		{ "%f[%a]are you ready%f[%A]", "do you thirst for battle" },
	},

	post = function(chunk, ctx)
		-- Removing words leaves double spaces behind.
		chunk = gsub(chunk, "  +", " ")
		chunk = gsub(chunk, " ([,.!?])", "%1")
		return chunk
	end,

	flavor = {
		chance = 0.16,
		prefix = { "Lok'tar!", "Hrmph.", "Throm-Ka,", "Listen well.", "Dabu." },
		suffix = { "for the Horde", "blood and thunder", "as it should be", "nothing more" },
	},
})
