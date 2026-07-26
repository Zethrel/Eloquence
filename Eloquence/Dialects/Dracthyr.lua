-- Dracthyr: precise, refined, faintly detached.
--
-- Voiced with a "proper" clear English delivery, closer to the elven registers
-- than to anything guttural -- which fits weapons of Neltharion's making who woke
-- after twenty thousand years in stasis. They speak formally and think in terms
-- of flights, Aspects and wings, and carry the odd note of someone newly awake in
-- a world that moved on without them.
local ADDON, E = ...

E.RegisterDialect("Dracthyr", {
	name = "Dracthyr",
	desc = "Precise and refined, faintly detached. Speaks of flights, wings and Aspects.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "greetings", ["hi"] = "greetings", ["hey"] = "you there",
		["greetings"] = "greetings", ["goodbye"] = "fly well", ["bye"] = "fly well",
		["farewell"] = "may the winds hold you",
		["thanks"] = "you have my thanks", ["please"] = "if you would",
		["sorry"] = "that was my error",
		["yes"] = "indeed", ["yeah"] = "indeed", ["ok"] = "very well",
		["okay"] = "very well", ["sure"] = "certain", ["maybe"] = "perhaps",
		["friend"] = "ally", ["friends"] = "my flight", ["family"] = "my flight",
		["group"] = "flight", ["team"] = "flight", ["party"] = "flight",
		["guy"] = "one", ["guys"] = "flight", ["dude"] = "you",
		["god"] = "the Aspects", ["gods"] = "the Aspects", ["leader"] = "the Aspect",
		["boss"] = "the Aspect", ["maker"] = "our maker",
		["home"] = "the Forbidden Reach", ["city"] = "Valdrakken",
		["sleep"] = "the long sleep", ["slept"] = "slumbered", ["sleeping"] = "in stasis",
		["woke"] = "awakened", ["wake"] = "awaken", ["awake"] = "awakened",
		["old"] = "older than I appear", ["young"] = "newly awakened",
		["time"] = "the long years", ["year"] = "turning", ["years"] = "turnings",
		["fly"] = "take wing", ["flying"] = "on the wing", ["flew"] = "took wing",
		["run"] = "take wing", ["jump"] = "take to the air",
		["fight"] = "give battle", ["fighting"] = "giving battle",
		["kill"] = "strike down", ["killed"] = "struck down",
		["die"] = "fall", ["died"] = "fell", ["dead"] = "fallen",
		["death"] = "the fall", ["enemy"] = "quarry", ["enemies"] = "our quarry",
		["strong"] = "formidable", ["weak"] = "unformed", ["big"] = "vast",
		["huge"] = "vast", ["small"] = "slight",
		["magic"] = "the arcane", ["fire"] = "flame", ["breath"] = "breath",
		["wing"] = "wing", ["scale"] = "scale", ["scales"] = "scales",
		["claw"] = "talon", ["claws"] = "talons",
		["human"] = "the soft-skinned", ["humans"] = "the soft-skinned",
		["help"] = "aid", ["helped"] = "aided", ["helping"] = "aiding",
		["think"] = "consider", ["want"] = "desire", ["need"] = "require",
		["hurry"] = "make haste", ["wait"] = "hold", ["look"] = "observe",
		["understand"] = "comprehend", ["talk"] = "speak",
		["good"] = "well", ["great"] = "remarkable", ["nice"] = "agreeable",
		["bad"] = "ill", ["awful"] = "grievous", ["awesome"] = "remarkable",
		["stupid"] = "unthinking", ["dumb"] = "unthinking", ["crazy"] = "unbalanced",
		["very"] = "most", ["really"] = "truly", ["money"] = "coin",
		["problem"] = "difficulty", ["mistake"] = "miscalculation",
	}),

	wordsAt = {
		[3] = {
			["world"] = "this world, changed as it is",
			["new"] = "new to me", ["modern"] = "of this age",
			["history"] = "the years I slept through",
			["war"] = "the war we were made for",
			["purpose"] = "the purpose we were given",
			["weapon"] = "weapon, as we were", ["dragon"] = "dragonkin",
			["dragons"] = "the dragonflights", ["egg"] = "clutch",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "that lies beyond my memory", nil, true },
		{ "%f[%a]i think%f[%A]", "I consider that" },
		{ "%f[%a]thank you%f[%A]", "you have my thanks" },
		{ "%f[%a]good luck%f[%A]", "may the winds favor you" },
		{ "%f[%a]be careful%f[%A]", "guard your flank" },
		{ "%f[%a]what's up%f[%A]", "what requires attention" },
		{ "%f[%a]let's go%f[%A]", "we take wing" },
		{ "%f[%a]hold on%f[%A]", "hold a moment" },
		{ "%f[%a]for the alliance%f[%A]", "for Azeroth" },
		{ "%f[%a]for the horde%f[%A]", "for Azeroth" },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Hm.", "Understood.", "By the Aspects,", "Listen well.", "Curious." },
		suffix = {
			"as the Aspects intended", "this I know", "we were made for this",
			"on my scales", "so it seems to me",
		},
	},
})
