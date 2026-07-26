-- Harronir: guardians of the rootways, from Harandar.
--
-- NOTE ON SPELLING: the client reports this race as "Harronir" (englishRace
-- token, race ID 86) -- two Rs. A good deal of community writing spells it
-- "Haranir", so that spelling is aliased onto this one in Core\Race.lua and is
-- accepted by /elo race. The token is what UnitRace actually returns, and it is
-- what the dialect is registered under.
--
-- The harronir are voiced with the same Xhosa-accented English as the Zandalari,
-- described as a soft, melodic, rhythmic delivery. As with Zandali, that accent
-- is carried by the voice acting rather than by the grammar, so this dialect
-- renders their register -- unhurried, warm, formal, spoken by people whose whole
-- culture is rooted in secrecy and stewardship -- rather than respelling an
-- accent phonetically.
--
-- Their vocabulary comes from their own lore: they keep the rootways where the
-- roots of the World Trees converge, they revere Aln'hara, they rootwalk, and
-- they live beside the Rift of Aln where dreams turn dangerous.
local ADDON, E = ...

E.RegisterDialect("Harronir", {
	name = "Harronir",
	desc = "Soft and melodic, unhurried. Speaks of roots, dreams and what is kept.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "well met, traveler", ["hi"] = "well met", ["hey"] = "ah, traveler",
		["greetings"] = "well met, traveler",
		["goodbye"] = "walk the rootways gently", ["bye"] = "walk gently",
		["farewell"] = "may the roots carry you home",
		["thanks"] = "the roots remember your kindness",
		["please"] = "if you would", ["sorry"] = "the fault is mine to tend",
		["yes"] = "it is so", ["yeah"] = "it is so", ["ok"] = "it is well",
		["okay"] = "it is well", ["sure"] = "certain",
		["no"] = "it is not so", ["maybe"] = "perhaps, in time",
		["friend"] = "traveler", ["friends"] = "travelers", ["stranger"] = "one not yet known",
		["guy"] = "one", ["guys"] = "travelers", ["people"] = "the many",
		["god"] = "Aln'hara", ["goddess"] = "Aln'hara", ["gods"] = "Aln'hara",
		["home"] = "Harandar", ["forest"] = "the rootways", ["jungle"] = "the rootways",
		["root"] = "root", ["roots"] = "the rootways", ["path"] = "rootway",
		["tree"] = "kin of the World Trees", ["trees"] = "the World Trees' kin",
		["dream"] = "the Dream", ["dreams"] = "the Dream", ["dreaming"] = "walking the Dream",
		["sleep"] = "the Dream", ["nightmare"] = "an echo from the Rift",
		["nature"] = "the living world", ["earth"] = "the deep roots",
		["water"] = "the deep springs", ["light"] = "the glowlight",
		["dark"] = "the deep dark", ["darkness"] = "the deep dark",
		["secret"] = "that which is kept", ["secrets"] = "that which is kept",
		["hidden"] = "kept", ["hide"] = "keep from sight", ["guard"] = "keep",
		["protect"] = "keep", ["protecting"] = "keeping", ["duty"] = "the keeping",
		["danger"] = "a stirring in the Rift", ["dangerous"] = "unquiet",
		["fear"] = "unease", ["afraid"] = "uneasy", ["scared"] = "uneasy",
		["grow"] = "grow", ["plant"] = "seedling", ["seed"] = "seed",
		["heal"] = "tend", ["healed"] = "tended", ["healing"] = "tending",
		["help"] = "tend to", ["sick"] = "withered", ["hurt"] = "bruised",
		["strong"] = "deep-rooted", ["weak"] = "shallow-rooted",
		["old"] = "ancient as the roots", ["young"] = "new-grown",
		["die"] = "return to the roots", ["died"] = "returned to the roots",
		["dead"] = "returned to the roots", ["death"] = "the returning",
		["kill"] = "end", ["killed"] = "ended", ["fight"] = "stand against",
		["hurry"] = "the roots do not hurry", ["rush"] = "the roots do not hurry",
		["wait"] = "be still", ["quick"] = "swift", ["slow"] = "unhurried",
		["magic"] = "the old growth", ["spirit"] = "echo", ["spirits"] = "echoes",
		["time"] = "the seasons", ["year"] = "turning", ["years"] = "turnings",
		["think"] = "believe", ["want"] = "wish", ["need"] = "require",
		["talk"] = "speak", ["look"] = "behold", ["understand"] = "know",
		["angry"] = "unquiet", ["calm"] = "still", ["good"] = "well",
		["great"] = "a gladness", ["bad"] = "ill", ["awful"] = "grievous",
		["very"] = "most", ["really"] = "truly", ["big"] = "great", ["small"] = "slight",
	}),

	wordsAt = {
		[3] = {
			["dance"] = "the rootwalking dance", ["ritual"] = "the keeping-rites",
			["song"] = "root-song", ["memory"] = "what the roots remember",
			["remember"] = "hold as the roots do", ["forget"] = "let the roots release",
			["mushroom"] = "the glowcaps", ["glow"] = "the glowlight",
			["deep"] = "deep, where the roots meet", ["above"] = "the sunlit world",
			["world"] = "the living world", ["azeroth"] = "the great root",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "that has not yet grown to me", nil, true },
		{ "%f[%a]i think%f[%A]", "I believe" },
		{ "%f[%a]thank you%f[%A]", "the roots remember your kindness" },
		{ "%f[%a]good luck%f[%A]", "may the roots guide your step" },
		{ "%f[%a]be careful%f[%A]", "tread softly, the roots listen" },
		{ "%f[%a]calm down%f[%A]", "be still, and let the roots hold you" },
		{ "%f[%a]hurry up%f[%A]", "haste tears the root" },
		{ "%f[%a]what's up%f[%A]", "what stirs" },
		{ "%f[%a]let's go%f[%A]", "let us walk the rootways" },
		{ "%f[%a]trust me%f[%A]", "the roots do not lie" },
	},

	flavor = {
		chance = 0.18,
		prefix = { "Listen.", "Be still.", "The roots whisper of this.", "Ah, traveler.", "Softly, now." },
		suffix = {
			"traveler", "as the roots will it", "in its season",
			"so the Dream shows it", "Aln'hara willing", "the roots remember",
		},
	},
})
