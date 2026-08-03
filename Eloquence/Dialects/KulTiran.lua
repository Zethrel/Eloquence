-- Kul Tirans: a seafaring West Country burr.
--
-- Kul Tiras is a naval power of whalers, shipwrights and drowned-god cults, and
-- its people are voiced with a broad West Country English accent -- the running
-- joke in-game being that Jaina is the one who lost hers. Gruff, practical,
-- and everything measured against the sea.
--
-- Kept a burr rather than a pirate impression: no "arrr", no "me hearties".
local ADDON, E = ...

local gsub = string.gsub

E.RegisterDialect("KulTiran", {
	name = "Kul Tiran",
	desc = "A seafaring West Country burr. Gruff, practical, everything measured against the sea.",

	words = {
		["hello"] = "ahoy", ["hi"] = "ahoy", ["hey"] = "oi",
		["greetings"] = "ahoy there", ["goodbye"] = "fair winds",
		["bye"] = "fair winds", ["farewell"] = "fair winds and followin' seas",
		["thanks"] = "much obliged", ["sorry"] = "my mistake",
		["yes"] = "aye", ["yeah"] = "aye", ["yep"] = "aye",
		["ok"] = "right you are", ["okay"] = "right you are", ["sure"] = "certain",
		["no"] = "nay", ["nope"] = "nay",
		["you"] = "ye", ["your"] = "yer", ["you're"] = "ye're", ["yours"] = "yers",
		["you've"] = "ye've", ["you'll"] = "ye'll", ["yourself"] = "yerself",
		["my"] = "me", ["know"] = "reckon", ["knows"] = "reckons",
		["think"] = "reckon", ["thinks"] = "reckons", ["guess"] = "reckon",
		["friend"] = "shipmate", ["friends"] = "the crew", ["guy"] = "lad",
		["guys"] = "the crew", ["man"] = "lad", ["boy"] = "lad",
		["woman"] = "lass", ["girl"] = "lass", ["lady"] = "lass",
		["big"] = "sizeable", ["huge"] = "whale-sized", ["small"] = "wee",
		["strong"] = "stout", ["weak"] = "soft", ["tired"] = "dead on me feet",
		["hungry"] = "starved", ["drink"] = "grog", ["beer"] = "ale",
		["food"] = "vittles", ["water"] = "the drink",
		["sea"] = "the sea", ["ocean"] = "the deep", ["ship"] = "ship",
		["boat"] = "ship", ["storm"] = "a proper blow", ["wind"] = "the wind",
		["rain"] = "weather", ["fish"] = "the catch", ["whale"] = "the great beasts",
		["home"] = "Kul Tiras", ["city"] = "Boralus", ["money"] = "coin",
		-- "job" only: mapping the verb "work" would give "that will graft".
		["job"] = "graft", ["problem"] = "a spot o' bother",
		["trouble"] = "bother", ["danger"] = "rough water",
		["die"] = "go under", ["died"] = "went under", ["dead"] = "gone under",
		["death"] = "the deep", ["kill"] = "put down", ["fight"] = "scrap",
		["help"] = "lend a hand", ["hurry"] = "look lively", ["wait"] = "hold fast",
		["look"] = "have a look", ["stop"] = "belay that",
		["crazy"] = "barmy", ["stupid"] = "daft", ["dumb"] = "daft",
		["angry"] = "riled", ["scared"] = "windy", ["afraid"] = "windy",
		["good"] = "sound", ["great"] = "proper good", ["nice"] = "handsome",
		["bad"] = "poor", ["awful"] = "a right mess", ["awesome"] = "proper grand",
		["very"] = "right", ["really"] = "proper", ["nothing"] = "nowt",
		["something"] = "summat", ["anything"] = "owt",
	},

	wordsAt = {
		[3] = {
			["afternoon"] = "arternoon", ["morning"] = "mornin'",
			["about"] = "abaht", ["over"] = "o'er", ["ever"] = "e'er",
			["never"] = "ne'er", ["them"] = "'em", ["him"] = "'im",
			["old"] = "auld", ["child"] = "young 'un", ["children"] = "young 'uns",
			["rope"] = "line", ["left"] = "port", ["right"] = "starboard",
			["front"] = "bow", ["back"] = "stern",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "couldn't tell ye", nil, true },
		{ "%f[%a]i think%f[%A]", "way I reckon" },
		{ "%f[%a]thank you%f[%A]", "much obliged to ye" },
		{ "%f[%a]good luck%f[%A]", "fair winds to ye" },
		{ "%f[%a]be careful%f[%A]", "mind yerself" },
		{ "%f[%a]watch out%f[%A]", "look out below" },
		{ "%f[%a]what's up%f[%A]", "what's the trouble" },
		{ "%f[%a]let's go%f[%A]", "let's away" },
		{ "%f[%a]shut up%f[%A]", "stow it" },
		{ "%f[%a]for the alliance%f[%A]", "for the Alliance, and for Kul Tiras" },
	},

	post = function(chunk, ctx)
		if (ctx.strength or 2) >= 2 then
			chunk = gsub(chunk, "(%a%a%a+)ing%f[%A]", "%1in'")
		end
		return chunk
	end,

	flavor = {
		chance = 0.18,
		prefix = { "Aye,", "Right,", "Listen here,", "By the tides,", "Well now," },
		suffix = {
			-- "lad" was here and addressed everyone as a man. "shipmate" does the
			-- same job and does not care who is on the other end of the rope.
			"aye", "shipmate", "mark me words", "and that's the truth of it",
			"sure as the tide", "steady now",
		},
	},
})
