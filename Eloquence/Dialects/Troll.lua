-- Trollish: thick Jamaican basilectic patois, with the odd bit of Zandali.
-- "Tas'dingo!"
--
-- SOURCE
-- The glossary below is attested Zandali, verified entry by entry against
-- Warcraft Wiki and Wowpedia. Blizzard never released a full Zandali dictionary
-- and the in-game translator only makes words look Zandali, so what exists is a
-- short list of glossed terms rather than a language.
--
-- ADDING MORE
-- Same discipline as the Darnassian, Thalassian and Orcish glossaries: attested
-- only, nothing invented, nothing taken from another addon. Deliberately excluded:
--   * Jin, which the wiki glosses as "possibly leader or elder" -- "possibly" is
--     not a confirmation;
--   * Atal'ai ("Devoted Ones") and Bwon'tulak ("Death singer"), which name a sect
--     and a title rather than supplying vocabulary anyone types;
--   * tribe and place names, which are proper nouns already identical to the
--     English word.
local ADDON, E = ...

-- English trigger -> canon Zandali, applied at strength 3 only.
local GLOSSARY_WORDS = {
	["mother"] = "ma'da", ["mom"] = "ma'da", ["mum"] = "ma'da", ["mama"] = "ma'da",
	["fire"] = "dazdooga",
	["charm"] = "juju", ["charms"] = "juju", ["talisman"] = "juju",
	["fetish"] = "juju", ["trinket"] = "juju",
	["eagle"] = "akil",
	["temple"] = "alor", ["altar"] = "alor",
}

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
		-- "friends" and "guys" both became "bruddahs", which addresses a whole
		-- group as men. "folk" carries the accent without the claim.
		--
		-- "mon" is kept deliberately. It is the signature of the accent, and in
		-- the patois it is drawn from it works as a particle attached to anything
		-- said to anyone rather than as a statement about who is listening.
		["friend"] = "mon", ["friends"] = "folk", ["man"] = "mon", ["men"] = "mon",
		["sir"] = "mon", ["guy"] = "mon", ["guys"] = "folk", ["dude"] = "mon",
		-- Reached only by writing "brother" or "sister", so the player chose.
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
		["god"] = "loa", ["gods"] = "loa", ["death"] = "da long sleep",
		["food"] = "grub", ["hungry"] = "hungry hungry", ["strange"] = "strange strange",
		["crazy"] = "mad mon", ["stupid"] = "fool fool", ["tired"] = "weary",
		["money"] = "coin", ["please"] = "please mon", ["sorry"] = "me bad",
		["problem"] = "trouble", ["danger"] = "bad juju", ["luck"] = "loa's favor",
	},

	wordsAt = {
		[3] = E.Engine.Extend(GLOSSARY_WORDS, {
			["is"] = "be", ["are"] = "be", ["am"] = "be", ["was"] = "was",
			["a"] = "a", ["for"] = "fo", ["her"] = "har", ["never"] = "neva",
			["work"] = "wuk", ["working"] = "wukkin", ["walk"] = "wok",
			["talk"] = "chat", ["talking"] = "chattin", ["look"] = "look see",
			["come"] = "come", ["coming"] = "comin", ["girl"] = "gyal",
			["boy"] = "bwoy", ["child"] = "pickney", ["children"] = "pickney",
			["head"] = "head top", ["eat"] = "nyam", ["eating"] = "nyammin",
		}),
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
			-- Non-rhotic endings: "-er" and "-or" become "-a". Trollish patois
			-- writes water as wata and doctor as dokta.
			--
			-- This used to delete the r and leave the vowel, which is not the same
			-- thing at all -- it truncated words rather than respelling them, so
			-- "elder" came out "elde", "matter" "matte", "honor" "hono" and
			-- "warrior" "warrio". Every word that read correctly was an explicit
			-- entry in the tables above (wata, ova, betta, anudda); the rule
			-- itself only ever produced what looked like typos. Its own comment
			-- claimed "over -> ova", which the rule never did -- "over" is mapped,
			-- so the example could not fail.
			--
			-- A letter is required before the vowel, or the conjunction "or"
			-- becomes "a". "-ar", "-ir" and "-ur" are left alone: "star" has no
			-- respelling that is not just a misspelling.
			chunk = gsub(chunk, "(%a)([eo])r%f[%A]", "%1a")
		end
		return chunk
	end,

	flavor = {
		chance = 0.2,
		prefix = { "Ya know,", "Hey mon,", "Listen up,", "Tas'dingo!", "Ah,", "Mon," },
		-- "bruddah" was here and is gone: a suffix lands on any message regardless
		-- of who reads it. "mon" stays, for the reason given above the words.
		suffix = { "mon", "ya know", "fo' real", "irie", "so it be", "no lie" },
	},
})
