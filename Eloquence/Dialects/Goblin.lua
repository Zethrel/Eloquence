-- Goblin: fast-talking, transactional, cheerfully reckless.
local ADDON, E = ...

E.RegisterDialect("Goblin", {
	name = "Goblin",
	desc = "Fast-talking and transactional. Everything is a deal.",

	words = {
		["hello"] = "heya", ["hi"] = "heya", ["hey"] = "heya",
		["greetings"] = "heya pal", ["goodbye"] = "pleasure doin' business",
		["bye"] = "pleasure doin' business", ["farewell"] = "don't be a stranger",
		["thanks"] = "I owe ya one", ["please"] = "c'mon", ["sorry"] = "no refunds",
		["yes"] = "deal", ["yeah"] = "yeah yeah", ["yep"] = "deal",
		["ok"] = "deal", ["okay"] = "deal",
		["no"] = "no deal", ["nope"] = "no deal", ["maybe"] = "make me an offer",
		["friend"] = "pal", ["friends"] = "associates", ["guy"] = "pal",
		["guys"] = "folks", ["dude"] = "pal", ["boss"] = "the boss",
		["money"] = "profit", ["gold"] = "profit", ["coin"] = "profit",
		["cheap"] = "a steal", ["expensive"] = "a premium investment",
		["free"] = "free, and nothin's free", ["buy"] = "invest in",
		["sell"] = "move", ["trade"] = "do business", ["deal"] = "deal",
		["job"] = "the job", ["help"] = "cut you a deal",
		["good"] = "profitable", ["great"] = "very profitable",
		["nice"] = "not bad", ["bad"] = "a bad investment",
		["awful"] = "a total write-off", ["awesome"] = "pure profit",
		["cool"] = "slick", ["problem"] = "opportunity",
		["problems"] = "opportunities", ["danger"] = "acceptable risk",
		["dangerous"] = "an acceptable risk", ["safe"] = "insured, mostly",
		["explode"] = "go kaboom", ["exploded"] = "went kaboom",
		["explosion"] = "kaboom", ["boom"] = "kaboom", ["bomb"] = "investment",
		["dead"] = "written off", ["die"] = "get written off",
		["died"] = "got written off", ["kill"] = "liquidate",
		["killed"] = "liquidated", ["fight"] = "hostile takeover",
		["mistake"] = "rounding error", ["accident"] = "unscheduled event",
		["stupid"] = "bad for business", ["crazy"] = "aggressive",
		["hurry"] = "time is money", ["wait"] = "the meter's runnin'",
		["fast"] = "quick", ["slow"] = "costin' me money",
		["big"] = "big-ticket", ["huge"] = "market-movin'", ["small"] = "small-time",
		["very"] = "real", ["really"] = "seriously", ["think"] = "figure",
		["thought"] = "figured", ["guess"] = "figure", ["want"] = "want",
		["need"] = "gotta have", ["understand"] = "get it",
		["contract"] = "the fine print", ["law"] = "the fine print",
		["home"] = "Kezan, may she rest", ["city"] = "Bilgewater Harbor",
	},

	wordsAt = {
		[3] = {
			["yes"] = "you got it", ["magic"] = "unlicensed arcane services",
			["food"] = "the catering budget", ["drink"] = "the good stuff",
			["friend"] = "valued customer", ["enemy"] = "the competition",
			["enemies"] = "the competition", ["war"] = "a growth market",
			["plan"] = "the business plan", ["luck"] = "market timing",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "way I figure it", nil, true },
		{ "%f[%a]i don't know%f[%A]", "that's above my pay grade", nil, true },
		{ "%f[%a]thank you%f[%A]", "I owe ya one" },
		{ "%f[%a]good luck%f[%A]", "don't get liquidated out there" },
		{ "%f[%a]be careful%f[%A]", "mind the blast radius" },
		{ "%f[%a]what's up%f[%A]", "what's the deal" },
		{ "%f[%a]no problem%f[%A]", "no problem, for a modest fee" },
		{ "%f[%a]trust me%f[%A]", "trust me, it's in the contract" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and a cut of the profits" },
		{ "%f[%a]let's go%f[%A]", "time is money, let's move" },
	},

	post = function(chunk, ctx)
		if (ctx.strength or 2) >= 2 then
			chunk = string.gsub(chunk, "(%a%a%a+)ing%f[%A]", "%1in'")
		end
		return chunk
	end,

	flavor = {
		chance = 0.2,
		prefix = { "Listen,", "Heh,", "Okay okay,", "Straight up,", "Between you and me," },
		suffix = {
			"pal", "no refunds", "and that's the deal", "time is money",
			"terms and conditions apply", "cash up front",
		},
	},
})
