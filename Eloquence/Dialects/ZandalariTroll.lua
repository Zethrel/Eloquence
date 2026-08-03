-- Zandali: the speech of the Zandalari empire.
--
-- IMPORTANT: this is NOT the Darkspear dialect, and the difference is the whole
-- point of the file. Before Battle for Azeroth the Zandalari reused the jungle
-- troll voice set and sounded Jamaican like the Darkspear; since BfA they are
-- voiced with Xhosa-accented English, a South African register.
--
-- That accent lives in the delivery, not the grammar. On the page the Zandalari
-- speak formal, unhurried, imperial English -- proud, dynastic, reverent toward
-- the loa. So this dialect deliberately does none of the phonetic respelling
-- that the Darkspear dialect does: no "de" for "the", no dropped g, no patois.
-- Respelling a real accent as broken English would be both wrong about how these
-- characters actually talk and a caricature. The register is what carries it.
local ADDON, E = ...

E.RegisterDialect("ZandalariTroll", {
	name = "Zandali",
	desc = "Formal, proud and imperial. Reverent toward the loa. Not the Darkspear patois.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "greetings", ["hi"] = "greetings", ["hey"] = "you there",
		-- "greetings" carried the claim inside the greeting itself, so it survived
		-- the removal of the "friends" -> "kin" mapping below.
		["greetings"] = "greetings", ["goodbye"] = "walk with the loa",
		["bye"] = "walk with the loa", ["farewell"] = "walk with the loa",
		["thanks"] = "you have my gratitude", ["please"] = "if it pleases you",
		["sorry"] = "I regret it",
		["yes"] = "it is so", ["yeah"] = "it is so", ["yep"] = "it is so",
		["ok"] = "very well", ["okay"] = "very well", ["sure"] = "certain",
		["no"] = "it is not so", ["nope"] = "it is not so", ["maybe"] = "perhaps",
		-- "friends" and "guys" both became "kin". The Zandalari of all people
		-- draw a hard line between their own blood and everyone else, so calling
		-- a room full of outsiders kin is backwards for them specifically.
		["friend"] = "ally", ["ally"] = "ally",
		["guy"] = "one", ["guys"] = "you all", ["dude"] = "you",
		["god"] = "loa", ["gods"] = "loa", ["spirit"] = "loa",
		["spirits"] = "loa", ["luck"] = "loa's favor",
		["magic"] = "loa's gift", ["priest"] = "prelate", ["prophet"] = "prophet",
		["king"] = "the King", ["queen"] = "the Queen", ["leader"] = "the King",
		["empire"] = "the empire", ["city"] = "Dazar'alor", ["home"] = "Zuldazar",
		["troll"] = "Zandalari", ["trolls"] = "the Zandalari",
		["human"] = "the young races", ["humans"] = "the young races",
		["good"] = "worthy", ["great"] = "glorious", ["nice"] = "well done",
		["bad"] = "unworthy", ["awful"] = "shameful", ["awesome"] = "glorious",
		["cool"] = "well judged", ["stupid"] = "foolish", ["dumb"] = "foolish",
		["crazy"] = "touched by the loa", ["weird"] = "curious",
		["strong"] = "mighty", ["weak"] = "unworthy", ["big"] = "great",
		["huge"] = "vast", ["small"] = "lesser", ["old"] = "ancient",
		["fight"] = "give battle", ["war"] = "war", ["kill"] = "strike down",
		["killed"] = "struck down", ["die"] = "fall", ["died"] = "fell",
		["dead"] = "fallen", ["death"] = "loa's call",
		["enemy"] = "foe", ["enemies"] = "our foes", ["coward"] = "one without honor",
		["help"] = "aid", ["helped"] = "aided", ["helping"] = "aiding",
		["think"] = "believe", ["want"] = "desire", ["need"] = "require",
		["hurry"] = "make haste", ["wait"] = "hold", ["talk"] = "speak",
		["look"] = "behold", ["see"] = "witness", ["understand"] = "understand",
		["money"] = "gold", ["very"] = "most", ["really"] = "truly",
		["problem"] = "difficulty", ["mistake"] = "misjudgment",
	}),

	-- Zandali proper, shared with Dialects/Troll.lua, where the sourcing and the
	-- exclusions are documented. The Zandalari are the trolls least likely to use
	-- the Common word when their own exists.
	wordsAt = {
		[3] = E.Engine.Extend({
			["mother"] = "ma'da", ["mom"] = "ma'da", ["mum"] = "ma'da",
			["fire"] = "dazdooga",
			["charm"] = "juju", ["talisman"] = "juju", ["fetish"] = "juju",
			["eagle"] = "akil",
			["altar"] = "alor",
		}, {
			["history"] = "the long record", ["ancestor"] = "ancestor",
			["ancestors"] = "those who came before", ["tradition"] = "our way",
			["temple"] = "the great temple", ["throne"] = "the golden throne",
			["gold"] = "gold, as is our due", ["pride"] = "rightful pride",
			["young"] = "young, by our reckoning", ["time"] = "the long ages",
		}),
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "that is not known to me", nil, true },
		{ "%f[%a]i think%f[%A]", "I judge" },
		{ "%f[%a]i guess%f[%A]", "I suspect" },
		{ "%f[%a]thank you%f[%A]", "you have my gratitude" },
		{ "%f[%a]good luck%f[%A]", "may the loa watch over you" },
		{ "%f[%a]be careful%f[%A]", "guard yourself well" },
		{ "%f[%a]what's up%f[%A]", "what brings you" },
		{ "%f[%a]let's go%f[%A]", "we go" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and for Zandalar" },
		{ "%f[%a]shut up%f[%A]", "hold your tongue" },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Hear me.", "Behold.", "The loa are watching.", "Rise, then.", "Listen well," },
		suffix = {
			-- "child of Zandalar" was here, which told the listener both their age
			-- and their nation. It was landing on Night Elves and Draenei.
			"as the loa will it", "so the empire teaches", "so it has always been",
			"this is our way", "do not forget it",
		},
	},
})
