-- Pandaren: calm, patient, fond of proverbs and of food as metaphor.
local ADDON, E = ...

E.RegisterDialect("Pandaren", {
	name = "Pandaren",
	desc = "Calm and patient, fond of proverbs and food metaphors.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "greetings, friend", ["hi"] = "greetings", ["hey"] = "ah, greetings",
		["greetings"] = "greetings, friend", ["goodbye"] = "travel well",
		["bye"] = "travel well", ["farewell"] = "may your road be gentle",
		["thanks"] = "you have my thanks", ["please"] = "if you would",
		["sorry"] = "the fault is mine",
		["yes"] = "it is so", ["yeah"] = "it is so", ["ok"] = "it is well",
		["okay"] = "it is well", ["sure"] = "certain", ["no"] = "it is not so",
		["maybe"] = "perhaps, perhaps not",
		["friend"] = "friend", ["friends"] = "friends", ["guy"] = "one",
		["guys"] = "friends", ["enemy"] = "one who has lost their way",
		["hurry"] = "slow down", ["rush"] = "slow down", ["fast"] = "hasty",
		["quickly"] = "without haste", ["slow"] = "measured", ["wait"] = "be patient",
		["angry"] = "carrying a heavy burden", ["mad"] = "carrying a heavy burden",
		["worry"] = "trouble yourself", ["worried"] = "troubled",
		["afraid"] = "uncertain", ["scared"] = "uncertain",
		["sad"] = "heavy of heart", ["happy"] = "at peace", ["calm"] = "at peace",
		["good"] = "well", ["great"] = "most welcome", ["nice"] = "kind",
		["bad"] = "unfortunate", ["awful"] = "most unfortunate",
		["awesome"] = "a joy", ["cool"] = "pleasing",
		["stupid"] = "unwise", ["dumb"] = "unwise", ["crazy"] = "restless",
		["fight"] = "test one another", ["fighting"] = "testing one another",
		["kill"] = "end", ["killed"] = "ended", ["die"] = "pass on",
		["died"] = "passed on", ["dead"] = "at rest", ["death"] = "the long rest",
		["war"] = "this great sadness", ["help"] = "lend my hands",
		["think"] = "believe", ["want"] = "wish", ["need"] = "require",
		["problem"] = "knot to be untied", ["problems"] = "knots to be untied",
		["mistake"] = "lesson", ["mistakes"] = "lessons", ["failure"] = "lesson",
		["beer"] = "brew", ["ale"] = "brew", ["drink"] = "brew",
		["food"] = "a good meal", ["hungry"] = "in need of a good meal",
		["eat"] = "share a meal", ["tired"] = "in need of rest",
		["money"] = "coin", ["home"] = "Pandaria", ["very"] = "most",
		["really"] = "truly", ["big"] = "great", ["small"] = "modest",
	}),

	wordsAt = {
		[3] = {
			["life"] = "the river of life", ["time"] = "the turning of seasons",
			["mind"] = "the still pond", ["balance"] = "balance, always balance",
			["monk"] = "one who walks the path", ["train"] = "temper yourself",
			["strong"] = "well tempered", ["weak"] = "not yet tempered",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "I believe" },
		{ "%f[%a]i don't know%f[%A]", "that answer has not yet found me", nil, true },
		{ "%f[%a]thank you%f[%A]", "you have my thanks" },
		{ "%f[%a]good luck%f[%A]", "may your road be gentle" },
		{ "%f[%a]be careful%f[%A]", "walk with care" },
		{ "%f[%a]calm down%f[%A]", "breathe, and let it pass" },
		{ "%f[%a]hurry up%f[%A]", "haste spills the tea" },
		{ "%f[%a]what's up%f[%A]", "what troubles you, friend" },
		{ "%f[%a]let's go%f[%A]", "let us walk together" },
		{ "%f[%a]shut up%f[%A]", "words are better left unsaid" },
	},

	flavor = {
		chance = 0.18,
		prefix = { "Ah.", "Hmm.", "Slowly, now.", "Consider this:", "Patience, friend." },
		suffix = {
			"as the old ones say", "in time", "such is the way of things",
			"friend", "the slow path is the sure path",
		},
	},
})
