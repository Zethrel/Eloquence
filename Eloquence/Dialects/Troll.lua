-- Trollish: thick Jamaican basilectic patois, with the odd bit of Zandali.
-- "Tas'dingo!"
local ADDON, E = ...

local gsub = string.gsub

E.RegisterDialect("Troll", {
	name = "Trollish",
	desc = "Thick Jamaican patois with some Zandali. \"Tas'dingo, mon!\"",

	words = {
		["the"] = "de", ["them"] = "dem", ["they"] = "dey", ["they're"] = "dey be",
		["their"] = "dere", ["theirs"] = "deres", ["there"] = "dere", ["there's"] = "dere be",
		["this"] = "dis", ["that"] = "dat", ["that's"] = "dat be", ["these"] = "dese",
		["those"] = "dose", ["then"] = "den", ["than"] = "dan", ["though"] = "doh",
		["with"] = "wit", ["within"] = "witin", ["without"] = "witout",
		["think"] = "tink", ["thinking"] = "tinkin", ["thought"] = "tought",
		["thing"] = "ting", ["things"] = "tings", ["through"] = "tru", ["throw"] = "trow",
		["three"] = "tree", ["thank"] = "tank", ["thanks"] = "tanks", ["thick"] = "tick",
		["nothing"] = "nuttin", ["something"] = "sumting", ["anything"] = "anyting",
		["everything"] = "everyting", ["together"] = "togedda",
		["i"] = "me", ["i'm"] = "me be", ["i've"] = "me got", ["i'll"] = "me gonna",
		["i'd"] = "me would", ["my"] = "me", ["myself"] = "meself",
		["you"] = "ya", ["your"] = "ya", ["you're"] = "ya be", ["yours"] = "ya own",
		["you've"] = "ya got", ["you'll"] = "ya gonna", ["yourself"] = "yaself",
		["going"] = "goin", ["gonna"] = "gonna", ["doing"] = "doin",
		["isn't"] = "ain't", ["aren't"] = "ain't", ["wasn't"] = "weren't",
		["don't"] = "don'", ["doesn't"] = "don'", ["didn't"] = "din'",
		["can't"] = "cyan't", ["can"] = "cyan", ["won't"] = "nah gonna",
		["yes"] = "ya mon", ["yeah"] = "ya mon", ["yep"] = "ya mon",
		["ok"] = "irie", ["okay"] = "irie", ["fine"] = "irie",
		["no"] = "nah", ["nope"] = "nah mon", ["never"] = "neva",
		["hello"] = "hey dere", ["hi"] = "hey", ["hey"] = "hey", ["greetings"] = "tas'dingo",
		["goodbye"] = "swim wit da tide", ["bye"] = "later mon",
		["friend"] = "mon", ["friends"] = "bruddahs", ["man"] = "mon", ["men"] = "mon",
		["sir"] = "mon", ["guy"] = "mon", ["guys"] = "bruddahs", ["dude"] = "mon",
		["brother"] = "bruddah", ["sister"] = "sistah", ["mother"] = "mudda",
		["father"] = "fadda", ["family"] = "fambly", ["people"] = "folk",
		["good"] = "irie", ["great"] = "wicked irie", ["nice"] = "sweet",
		["bad"] = "bad mon", ["awesome"] = "wicked", ["cool"] = "cool runnin'",
		["little"] = "likkle", ["small"] = "likkle", ["big"] = "big big",
		["very"] = "real", ["really"] = "fo' real", ["quite"] = "real",
		["over"] = "ova", ["other"] = "udda", ["another"] = "anudda",
		["water"] = "wata", ["later"] = "lata", ["better"] = "betta",
		["ever"] = "eva", ["whatever"] = "whateva", ["forever"] = "foreva",
		["here"] = "hea", ["hear"] = "hea", ["more"] = "mo", ["before"] = "befo",
		["sure"] = "sho", ["four"] = "fo", ["door"] = "doa", ["floor"] = "floa",
		["understand"] = "undastan", ["remember"] = "membah",
		["about"] = "'bout", ["because"] = "cuz", ["around"] = "'round",
		["want"] = "wan", ["wants"] = "wan",
		["kill"] = "mash up", ["killed"] = "mash up", ["fight"] = "rumble",
		["magic"] = "voodoo", ["spirit"] = "loa", ["spirits"] = "loa",
		["god"] = "loa", ["gods"] = "da loa", ["death"] = "da long sleep",
		["food"] = "grub", ["hungry"] = "hungry hungry", ["strange"] = "strange strange",
		["crazy"] = "mad mon", ["stupid"] = "fool fool", ["tired"] = "weary",
		["money"] = "coin", ["please"] = "please mon", ["sorry"] = "me bad",
		["problem"] = "trouble", ["danger"] = "bad juju", ["luck"] = "da loa's favor",
	},

	wordsAt = {
		[3] = {
			["is"] = "be", ["are"] = "be", ["am"] = "be", ["was"] = "was",
			["a"] = "a", ["for"] = "fo", ["her"] = "har", ["never"] = "neva",
			["work"] = "wuk", ["working"] = "wukkin", ["walk"] = "wok",
			["talk"] = "chat", ["talking"] = "chattin", ["look"] = "look see",
			["come"] = "come", ["coming"] = "comin", ["girl"] = "gyal",
			["boy"] = "bwoy", ["child"] = "pickney", ["children"] = "pickney",
			["head"] = "head top", ["eat"] = "nyam", ["eating"] = "nyammin",
		},
	},

	phrases = {
		{ "%f[%a]what's up%f[%A]", "wha' gwaan" },
		{ "%f[%a]what is up%f[%A]", "wha' gwaan" },
		{ "%f[%a]how are you%f[%A]", "how ya keepin'" },
		{ "%f[%a]i am%f[%A]", "me be" },
		{ "%f[%a]i was%f[%A]", "me was" },
		{ "%f[%a]i have%f[%A]", "me got" },
		{ "%f[%a]i had%f[%A]", "me had" },
		{ "%f[%a]i don't know%f[%A]", "me nah know" },
		{ "%f[%a]do you%f[%A]", "ya" },
		{ "%f[%a]going to%f[%A]", "gonna" },
		{ "%f[%a]want to%f[%A]", "wanna" },
		{ "%f[%a]let's go%f[%A]", "we gwaan" },
		{ "%f[%a]for the horde%f[%A]", "fo' de Horde" },
		{ "%f[%a]no problem%f[%A]", "no worries mon" },
	},

	post = function(chunk, ctx)
		local strength = ctx.strength or 2
		-- Drop the g from -ing.
		chunk = gsub(chunk, "(%a%a%a+)ing%f[%A]", "%1in")
		if strength >= 3 then
			-- Any remaining word-initial "th" becomes "d".
			chunk = gsub(chunk, "%f[%a]([Tt])h", function(t)
				return t == "T" and "D" or "d"
			end)
			-- Soften post-vocalic r at the end of words: over -> ova.
			chunk = gsub(chunk, "([aeiou])r%f[%A]", "%1")
		end
		return chunk
	end,

	flavor = {
		chance = 0.2,
		prefix = { "Ya know,", "Hey mon,", "Listen up,", "Tas'dingo!", "Ah,", "Mon," },
		suffix = { "mon", "ya know", "fo' real", "irie", "so it be", "bruddah" },
	},
})
