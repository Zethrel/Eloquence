-- Tauren: unhurried, formal, reverent toward the Earth Mother.
-- "Winds be at your back!"
-- WHY THERE IS NO TAUR-AHE GLOSSARY HERE
-- The attested Taur-ahe vocabulary is names, not words. Arikara ("Vengeance"),
-- Echeyakee and Isha Awak are all creatures or spirits -- proper nouns identical
-- to what an English speaker would already type -- and Blizzard's in-game
-- translator only makes text look Taur-ahe rather than translating it. Taur-ahe is
-- also described as partly pictographic and as varying by tribe, so there is no
-- single lexicon to draw on even in principle.
--
-- Nothing here was invented to fill the gap; see Dialects/NightElf.lua for the
-- rule. The unhurried, earth-minded register below is the dialect.

local ADDON, E = ...

E.RegisterDialect("Tauren", {
	name = "Taurahe",
	desc = "Unhurried and reverent. \"Winds be at your back, young one.\"",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "well met", ["hi"] = "well met", ["hey"] = "well met",
		["greetings"] = "well met", ["goodbye"] = "winds be at your back",
		["bye"] = "winds be at your back", ["farewell"] = "winds be at your back",
		["thanks"] = "the Earth Mother smiles upon you",
		["please"] = "if you would", ["sorry"] = "I have wronged you",
		["yes"] = "it is so", ["yeah"] = "it is so", ["yep"] = "it is so",
		["ok"] = "it is well", ["okay"] = "it is well", ["sure"] = "certain",
		["no"] = "it is not so", ["nope"] = "it is not so", ["maybe"] = "perhaps",
		["god"] = "the Earth Mother", ["gods"] = "the Earth Mother",
		["sun"] = "An'she", ["moon"] = "Mu'sha", ["earth"] = "the Earth Mother",
		["nature"] = "the Earth Mother's gift", ["luck"] = "the Earth Mother's blessing",
		["land"] = "these plains", ["home"] = "Mulgore", ["city"] = "Thunder Bluff",
		["friend"] = "friend", ["friends"] = "kin", ["human"] = "little one",
		["humans"] = "the little ones", ["gnome"] = "very little one",
		["guy"] = "one", ["guys"] = "friends", ["kid"] = "calf", ["kids"] = "calves",
		["good"] = "well", ["great"] = "worthy", ["nice"] = "kind",
		["bad"] = "ill", ["awful"] = "grievous", ["awesome"] = "worthy of the ancestors",
		["cool"] = "peaceful", ["crazy"] = "troubled", ["stupid"] = "unwise",
		["dumb"] = "unwise", ["angry"] = "troubled", ["hate"] = "cannot abide",
		["hurry"] = "have patience", ["rush"] = "have patience",
		["quick"] = "swift", ["fast"] = "swift", ["quickly"] = "swiftly",
		["slow"] = "measured", ["wait"] = "be still", ["soon"] = "in time",
		["now"] = "this moment", ["later"] = "in its season",
		["kill"] = "take", ["killed"] = "took", ["killing"] = "taking",
		["hunt"] = "take only what is needed", ["die"] = "return to the earth",
		["died"] = "returned to the earth", ["dead"] = "returned to the earth",
		["death"] = "the Earth Mother's embrace", ["fight"] = "stand against",
		["war"] = "this sorrow", ["help"] = "aid", ["helped"] = "aided",
		["think"] = "believe", ["want"] = "wish", ["need"] = "require",
		["talk"] = "speak", ["ask"] = "inquire", ["look"] = "behold",
		["very"] = "most", ["really"] = "truly", ["big"] = "great",
		["huge"] = "vast", ["small"] = "little", ["money"] = "coin",
		["problem"] = "burden", ["mistake"] = "misstep", ["understand"] = "know",
		["stop"] = "be still", ["start"] = "begin", ["food"] = "what the land gives",
		["ancestor"] = "ancestor", ["spirit"] = "the spirits", ["spirits"] = "the spirits",
	}),

	wordsAt = {
		[3] = {
			["old"] = "old, as the stones are old",
			["young"] = "young, as the spring grass",
			["wind"] = "the winds", ["rain"] = "the Earth Mother's tears",
			["fire"] = "the hearth's gift", ["hunter"] = "hunter of the plains",
			["druid"] = "one who walks with the wild",
			["shaman"] = "one who hears the elements",
			["leader"] = "high chieftain", ["chief"] = "high chieftain",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "I believe" },
		{ "%f[%a]i guess%f[%A]", "I suspect" },
		{ "%f[%a]i don't know%f[%A]", "that is not mine to know", nil, true },
		{ "%f[%a]thank you%f[%A]", "the Earth Mother smiles upon you" },
		{ "%f[%a]good luck%f[%A]", "may the winds carry you" },
		{ "%f[%a]be careful%f[%A]", "walk with care, young one" },
		{ "%f[%a]let's go%f[%A]", "let us walk" },
		{ "%f[%a]hurry up%f[%A]", "there is no need for haste" },
		{ "%f[%a]what's up%f[%A]", "what weighs on you" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and for the Earth Mother" },
		{ "%f[%a]calm down%f[%A]", "be still, and breathe" },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Hmm.", "Be at peace.", "Listen, young one,", "An'she guide you.", "Patience." },
		suffix = {
			"young one", "as the Earth Mother wills", "in its own season",
			"walk with the Earth Mother", "this I have learned",
		},
	},
})
