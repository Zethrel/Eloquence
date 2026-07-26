-- Forsaken: a dry, bitter sibilance that thickens the more agitated they get.
--
-- The hiss is the signature effect. Rather than blanket-doubling every S, the
-- strength of it scales with how excited the message looks (exclamation marks
-- and shouting), which is what the original addon described.
local ADDON, E = ...

local gsub, rep, sub = string.gsub, string.rep, string.sub
local floor = math.floor

E.RegisterDialect("Scourge", {
	name = "Forsaken",
	desc = "A dry hiss that thickens when they are agitated.",

	words = {
		["hello"] = "well, well", ["hi"] = "well, well", ["hey"] = "you there",
		["greetings"] = "well, well", ["goodbye"] = "rot well",
		["bye"] = "rot well", ["farewell"] = "rot well",
		["thanks"] = "how unexpectedly civil of you",
		["please"] = "if you insist", ["sorry"] = "I regret nothing",
		["yes"] = "yes", ["yeah"] = "yes", ["ok"] = "as you like",
		["okay"] = "as you like", ["no"] = "no", ["maybe"] = "perhaps",
		["friend"] = "friend, if we must use that word",
		["friends"] = "the others", ["ally"] = "useful acquaintance",
		["human"] = "breather", ["humans"] = "breathers",
		["alive"] = "still breathing", ["living"] = "the breathing",
		["life"] = "that tiresome condition", ["born"] = "made",
		["dead"] = "free", ["death"] = "sweet death", ["die"] = "rot",
		["died"] = "rotted", ["dying"] = "rotting", ["kill"] = "unmake",
		["killed"] = "unmade", ["corpse"] = "raw material",
		["sun"] = "that dreadful light", ["light"] = "that dreadful light",
		["day"] = "the daylight hours, regrettably",
		["heart"] = "what passes for a heart", ["blood"] = "what remains of blood",
		["good"] = "tolerable", ["great"] = "very nearly pleasant",
		["nice"] = "tolerable", ["bad"] = "tiresome", ["awful"] = "loathsome",
		["awesome"] = "delicious", ["cool"] = "delightfully grim",
		["happy"] = "as close to happy as I get", ["love"] = "tolerate",
		["hate"] = "loathe", ["angry"] = "seething", ["sad"] = "no more grim than usual",
		["afraid"] = "wary", ["scared"] = "wary", ["hope"] = "a breather's habit",
		["food"] = "sustenance, such as it is", ["hungry"] = "in need of nothing",
		["tired"] = "beyond tiredness", ["sleep"] = "the closest thing to death",
		["stupid"] = "witless", ["dumb"] = "witless", ["crazy"] = "quite mad",
		["problem"] = "inconvenience", ["mistake"] = "oversight",
		["help"] = "assist", ["think"] = "suspect", ["want"] = "desire",
		["very"] = "exceedingly", ["really"] = "truly", ["magic"] = "shadow magic",
		["potion"] = "concoction", ["plague"] = "our finest work",
		["queen"] = "the Dark Lady", ["leader"] = "the Dark Lady",
	},

	wordsAt = {
		[3] = {
			["yes"] = "yesss", ["always"] = "as ever", ["never"] = "not once",
			["soon"] = "soon enough", ["forever"] = "eternally",
			["body"] = "this shell", ["skin"] = "what is left of skin",
			["smell"] = "stench", ["face"] = "what remains of a face",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "I suspect" },
		{ "%f[%a]i don't know%f[%A]", "I neither know nor care", nil, true },
		{ "%f[%a]thank you%f[%A]", "how unexpectedly civil of you" },
		{ "%f[%a]good luck%f[%A]", "try not to die, it is overrated" },
		{ "%f[%a]be careful%f[%A]", "do try to keep your limbs attached" },
		{ "%f[%a]how are you%f[%A]", "still standing, more or less" },
		{ "%f[%a]what's up%f[%A]", "what do you want" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde, such as it is" },
		{ "%f[%a]let's go%f[%A]", "come along then" },
	},

	post = function(chunk, ctx)
		local excitement = ctx.excitement or 0
		local strength = ctx.strength or 2
		-- 0 when calm, up to 3 extra sibilants when shouting.
		local extra = floor(excitement * 3 + 0.5)
		local chance = (0.25 + 0.5 * excitement) * (strength / 2)
		if chance <= 0 then return chunk end
		return (gsub(chunk, "[sS]+", function(run)
			if ctx.rng() > chance then return nil end
			return run .. rep(sub(run, -1), 1 + extra)
		end))
	end,

	flavor = {
		chance = 0.16,
		prefix = { "Heh.", "How quaint.", "Spare me.", "Listen, breather,", "Mmm." },
		suffix = {
			"not that it matters", "if you must know", "such is undeath",
			"breather", "how tiresome",
		},
	},
})
