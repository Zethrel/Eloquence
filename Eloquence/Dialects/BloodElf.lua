-- Thalassian: elegant, clipped, faintly condescending.
-- "Anar'alah." "Selama ashal'anore."
local ADDON, E = ...

E.RegisterDialect("BloodElf", {
	name = "Thalassian",
	desc = "Elegant, clipped and faintly condescending. \"Anar'alah.\"",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "anar'alah", ["hi"] = "anar'alah", ["hey"] = "you there",
		["greetings"] = "anar'alah", ["goodbye"] = "selama ashal'anore",
		["bye"] = "selama ashal'anore", ["farewell"] = "selama ashal'anore",
		["thanks"] = "you have my gratitude", ["please"] = "do",
		["sorry"] = "how unfortunate",
		["yes"] = "naturally", ["yeah"] = "naturally", ["yep"] = "naturally",
		-- "sure" is the adjective here, not the affirmative: mapping it to an
		-- affirmative turns "I'm not sure" into nonsense.
		["ok"] = "if you insist", ["okay"] = "if you insist", ["sure"] = "certain",
		["no"] = "hardly", ["nope"] = "hardly", ["maybe"] = "conceivably",
		["friend"] = "friend", ["friends"] = "associates", ["guy"] = "one",
		["guys"] = "you lot", ["dude"] = "you",
		["human"] = "lesser cousin", ["humans"] = "lesser cousins",
		["orc"] = "the brutes", ["orcs"] = "the brutes", ["troll"] = "the savages",
		["dwarf"] = "the stunted sort", ["tauren"] = "the cattle",
		["good"] = "acceptable", ["great"] = "exquisite", ["nice"] = "passable",
		["fine"] = "adequate", ["bad"] = "distasteful", ["awful"] = "appalling",
		["awesome"] = "magnificent", ["cool"] = "refined", ["ugly"] = "unfortunate to look upon",
		["stupid"] = "dull", ["dumb"] = "dull", ["crazy"] = "unhinged",
		["weird"] = "vulgar", ["cheap"] = "beneath consideration",
		["magic"] = "the arcane", ["mana"] = "the arcane", ["spell"] = "working",
		["addiction"] = "our burden", ["power"] = "power, as is our right",
		["city"] = "Silvermoon", ["home"] = "Silvermoon", ["king"] = "the Regent Lord",
		["very"] = "quite", ["really"] = "truly", ["quite"] = "rather",
		["big"] = "considerable", ["small"] = "trifling", ["little"] = "trifling",
		["hurry"] = "do keep up", ["wait"] = "a moment",
		["kill"] = "dispose of", ["killed"] = "disposed of", ["fight"] = "duel",
		["die"] = "perish", ["died"] = "perished", ["dead"] = "no longer our concern",
		["help"] = "assist", ["think"] = "should think", ["want"] = "desire",
		["need"] = "require", ["get"] = "acquire", ["buy"] = "acquire",
		["money"] = "gold, naturally", ["problem"] = "trifle",
		["mistake"] = "lapse", ["talk"] = "converse", ["look"] = "observe",
		["understand"] = "grasp", ["obviously"] = "as anyone would see",
	}),

	wordsAt = {
		[3] = {
			["work"] = "labor", ["food"] = "refreshment", ["drink"] = "wine",
			["clothes"] = "attire", ["armor"] = "finery", ["house"] = "estate",
			["tired"] = "fatigued", ["hungry"] = "peckish", ["angry"] = "displeased",
			["happy"] = "content", ["sad"] = "melancholy",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "I should think" },
		{ "%f[%a]i guess%f[%A]", "I suppose, if pressed", nil, true },
		{ "%f[%a]i don't know%f[%A]", "that is hardly my concern", nil, true },
		{ "%f[%a]thank you%f[%A]", "you have my gratitude" },
		{ "%f[%a]good luck%f[%A]", "do try not to embarrass yourself" },
		{ "%f[%a]be careful%f[%A]", "mind yourself" },
		{ "%f[%a]what's up%f[%A]", "what is it now" },
		{ "%f[%a]hurry up%f[%A]", "do keep up" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and for Quel'Thalas" },
		{ "%f[%a]let's go%f[%A]", "shall we" },
	},

	flavor = {
		chance = 0.18,
		prefix = { "Anar'alah.", "Really.", "How droll.", "Obviously,", "Spare me." },
		suffix = {
			"naturally", "if you must", "as anyone would know",
			"do keep up", "glory to Quel'Thalas",
		},
	},
})
