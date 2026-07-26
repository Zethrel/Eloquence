-- Draenei: ancient, formal, unfailingly courteous, lit by the Light.
-- "Aka'Magosh."
local ADDON, E = ...

E.RegisterDialect("Draenei", {
	name = "Draenei",
	desc = "Ancient and formal, few contractions, blessings of the Light.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "aka'magosh", ["hi"] = "aka'magosh", ["hey"] = "aka'magosh",
		["greetings"] = "aka'magosh", ["goodbye"] = "may the Light guide you",
		["bye"] = "may the Light guide you", ["farewell"] = "may the Light guide you",
		["thanks"] = "the Light bless you", ["please"] = "if it pleases you",
		["sorry"] = "I ask your forgiveness",
		["yes"] = "it is so", ["yeah"] = "it is so", ["yep"] = "it is so",
		["ok"] = "very well", ["okay"] = "very well", ["sure"] = "certain",
		["no"] = "it is not so", ["nope"] = "it is not so", ["maybe"] = "perhaps",
		["god"] = "the Naaru", ["gods"] = "the Naaru", ["heaven"] = "the Light",
		["luck"] = "the Light's favor", ["hope"] = "the Light's promise",
		["faith"] = "the Light", ["soul"] = "the spark within",
		["demon"] = "the Legion's spawn", ["demons"] = "the Legion's spawn",
		["evil"] = "the Legion's taint", ["fel"] = "that corruption",
		["home"] = "Argus, that we lost", ["friend"] = "friend",
		["friends"] = "kindred", ["human"] = "young friend",
		["humans"] = "the young races", ["guy"] = "one", ["guys"] = "friends",
		["good"] = "well", ["great"] = "most fortunate", ["nice"] = "kind",
		["bad"] = "unfortunate", ["awful"] = "grievous", ["awesome"] = "blessed",
		["cool"] = "well chosen", ["crazy"] = "troubled of mind",
		["stupid"] = "unwise", ["dumb"] = "unwise", ["angry"] = "sorrowful",
		["hate"] = "cannot abide", ["kill"] = "put an end to",
		["killed"] = "put an end to", ["die"] = "pass into the Light",
		["died"] = "passed into the Light", ["dead"] = "at rest",
		["death"] = "the Light's embrace",
		["fight"] = "stand against", ["war"] = "this long struggle",
		["help"] = "aid", ["helped"] = "aided", ["helping"] = "aiding",
		["hurry"] = "make haste", ["wait"] = "be patient",
		["quick"] = "swift", ["fast"] = "swift", ["slow"] = "measured",
		["very"] = "most", ["really"] = "truly", ["quite"] = "rather",
		["big"] = "great", ["huge"] = "vast", ["small"] = "modest",
		["think"] = "believe", ["want"] = "wish", ["need"] = "require",
		["get"] = "receive", ["give"] = "offer", ["buy"] = "purchase",
		["money"] = "coin", ["problem"] = "trial", ["mistake"] = "misstep",
		["talk"] = "speak", ["ask"] = "inquire", ["look"] = "behold",
		["understand"] = "comprehend", ["stop"] = "cease", ["start"] = "begin",
	}),

	wordsAt = {
		[3] = {
			["long"] = "long, even by our reckoning",
			["old"] = "older than your people",
			["young"] = "young, as we measure such things",
			["exile"] = "our exile", ["ship"] = "the Exodar",
			["priest"] = "anchorite", ["paladin"] = "vindicator",
			["leader"] = "prophet", ["city"] = "the Exodar",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "I believe" },
		{ "%f[%a]i guess%f[%A]", "I suspect" },
		{ "%f[%a]i don't know%f[%A]", "I do not know" },
		{ "%f[%a]thank you%f[%A]", "the Light bless you" },
		{ "%f[%a]good luck%f[%A]", "may the Light guide your hand" },
		{ "%f[%a]be careful%f[%A]", "walk in the Light's protection" },
		{ "%f[%a]let's go%f[%A]", "let us go forth" },
		{ "%f[%a]what's up%f[%A]", "how may I aid you" },
		{ "%f[%a]for the alliance%f[%A]", "for the Alliance, and for the Light" },
		{ "%f[%a]hold on%f[%A]", "a moment, please" },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Aka'Magosh.", "Be at peace.", "The Light be with you.", "Hear me, friend," },
		suffix = {
			"the Light willing", "as the Naaru intend", "may it be so",
			"friend", "in the Light's own time",
		},
	},
})
