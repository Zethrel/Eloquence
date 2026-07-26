-- Dwarven: broad Scots.
-- The original addon's signature line was
--   "I'm not sure if that will work, friend."  ->
--   "Ah'm no' shuir if that wull wirk, laddie."
-- and the word list below is built to reproduce exactly that.
local ADDON, E = ...

local gsub = string.gsub

E.RegisterDialect("Dwarf", {
	name = "Dwarven",
	desc = "Broad Scots. \"Ah'm no' shuir if that wull wirk, laddie.\"",

	words = {
		["i"] = "Ah", ["i'm"] = "ah'm", ["i've"] = "ah've", ["i'll"] = "ah'll", ["i'd"] = "ah'd",
		["my"] = "mah", ["mine"] = "mahn", ["me"] = "me",
		["you"] = "ye", ["your"] = "yer", ["you're"] = "yer", ["yours"] = "yers",
		["you've"] = "ye've", ["you'll"] = "ye'll", ["yourself"] = "yersel",
		["not"] = "no'", ["no"] = "nae", ["don't"] = "dinnae", ["doesn't"] = "disnae",
		["didn't"] = "didnae", ["can't"] = "cannae", ["cannot"] = "cannae",
		["won't"] = "willnae", ["wouldn't"] = "wouldnae", ["couldn't"] = "couldnae",
		["shouldn't"] = "shouldnae", ["isn't"] = "isnae", ["wasn't"] = "wisnae",
		["aren't"] = "urnae", ["weren't"] = "wurnae", ["haven't"] = "huvnae",
		["hasn't"] = "husnae", ["ain't"] = "isnae",
		["was"] = "wis", ["will"] = "wull", ["shall"] = "sall",
		["do"] = "dae", ["does"] = "dis", ["done"] = "din",
		["have"] = "hae", ["has"] = "hus", ["had"] = "hud", ["give"] = "gie", ["given"] = "gien",
		["going"] = "gaun", ["gone"] = "gane", ["go"] = "gang",
		["know"] = "ken", ["knows"] = "kens", ["knew"] = "kent", ["known"] = "kent",
		["sure"] = "shuir", ["work"] = "wirk", ["works"] = "wirks", ["worked"] = "wirked",
		["working"] = "wirkin'",
		["yes"] = "aye", ["yeah"] = "aye", ["yep"] = "aye", ["ok"] = "aye", ["okay"] = "aye",
		["of"] = "o'", ["to"] = "tae", ["too"] = "tae", ["from"] = "frae", ["for"] = "fer",
		["with"] = "wi'", ["without"] = "wi'oot", ["about"] = "aboot", ["out"] = "oot",
		["down"] = "doon", ["around"] = "aroond", ["now"] = "noo", ["how"] = "hoo",
		["house"] = "hoose", ["town"] = "toon", ["mouth"] = "mooth", ["south"] = "sooth",
		["all"] = "aw", ["also"] = "an' aw", ["always"] = "aye",
		["old"] = "auld", ["cold"] = "cauld", ["gold"] = "gowd", ["hold"] = "haud",
		["bold"] = "bauld", ["told"] = "tellt", ["sold"] = "selt",
		["dead"] = "deid", ["death"] = "daith", ["head"] = "heid", ["bread"] = "breid",
		["one"] = "ane", ["two"] = "twa", ["more"] = "mair", ["most"] = "maist",
		["right"] = "richt", ["night"] = "nicht", ["light"] = "licht",
		["might"] = "micht", ["fight"] = "fecht", ["eight"] = "aicht",
		["very"] = "verra", ["really"] = "richt",
		["well"] = "weel", ["water"] = "watter", ["after"] = "efter",
		["over"] = "ower", ["other"] = "ither", ["another"] = "anither",
		["both"] = "baith", ["been"] = "bin", ["before"] = "afore",
		["who"] = "wha", ["what"] = "whit", ["where"] = "whaur",
		["when"] = "whan", ["which"] = "whilk",
		["small"] = "wee", ["little"] = "wee", ["tiny"] = "wee bit o' a",
		["big"] = "muckle", ["large"] = "muckle", ["huge"] = "muckle great",
		["child"] = "bairn", ["children"] = "bairns", ["kid"] = "bairn", ["kids"] = "bairns",
		["man"] = "laddie", ["boy"] = "laddie", ["lad"] = "laddie", ["guy"] = "laddie",
		["woman"] = "lassie", ["girl"] = "lassie", ["lady"] = "lassie",
		["friend"] = "laddie", ["friends"] = "lads", ["mate"] = "laddie",
		["guys"] = "lads", ["everyone"] = "aw ye", ["everybody"] = "awbody",
		["nobody"] = "naebody", ["nothing"] = "nowt", ["something"] = "somethin'",
		["anything"] = "owt", ["someone"] = "somebody",
		["church"] = "kirk", ["home"] = "hame", ["stone"] = "stane", ["bone"] = "bane",
		["food"] = "scran", ["hungry"] = "hungert", ["drunk"] = "steamin'",
		["beer"] = "ale", ["ale"] = "ale", ["mug"] = "tankard", ["money"] = "siller",
		["fight"] = "stramash", ["trouble"] = "bother", ["mountain"] = "ben",
		["please"] = "gie's", ["thanks"] = "ta", ["sorry"] = "ma apologies",
		["hello"] = "hae ye", ["hi"] = "och", ["hey"] = "och",
		["great"] = "braw", ["good"] = "guid", ["nice"] = "braw", ["awesome"] = "pure braw",
		["bad"] = "clarty", ["crazy"] = "aff his heid", ["tired"] = "wabbit",
		["stupid"] = "glaikit", ["clumsy"] = "sclaffin'", ["dirty"] = "clarty",
	},

	wordsAt = {
		[3] = {
			["horse"] = "cuddy", ["dog"] = "dug", ["cow"] = "coo", ["bird"] = "burdie",
			["eye"] = "ee", ["eyes"] = "een", ["foot"] = "fit", ["arm"] = "airm",
			["clothes"] = "claes", ["shoes"] = "buits", ["coat"] = "jaicket",
			["remember"] = "mind", ["talk"] = "blether", ["talking"] = "bletherin'",
			["shout"] = "roar", ["cry"] = "greet", ["crying"] = "greetin'",
			["throw"] = "chuck", ["broken"] = "broke", ["ruined"] = "ruint",
			["afraid"] = "feart", ["scared"] = "feart", ["angry"] = "radge",
			["strange"] = "unco", ["quite"] = "gey", ["enough"] = "eneuch",
		},
	},

	phrases = {
		{ "%f[%a]going to%f[%A]", "gaun tae" },
		{ "%f[%a]want to%f[%A]", "wantae" },
		{ "%f[%a]got to%f[%A]", "gottae" },
		{ "%f[%a]have to%f[%A]", "huv tae" },
		{ "%f[%a]out of%f[%A]", "oot o'" },
		{ "%f[%a]a lot of%f[%A]", "a hale lot o'" },
		{ "%f[%a]kind of%f[%A]", "kindae" },
		{ "%f[%a]sort of%f[%A]", "sortae" },
		{ "%f[%a]let me%f[%A]", "lemme" },
		{ "%f[%a]i think%f[%A]", "Ah reckon" },
		{ "%f[%a]i don't know%f[%A]", "Ah dinnae ken" },
		{ "%f[%a]shut up%f[%A]", "haud yer wheesht" },
		{ "%f[%a]be quiet%f[%A]", "haud yer wheesht" },
		{ "%f[%a]look out%f[%A]", "watch yersel" },
		{ "%f[%a]for the alliance%f[%A]", "fer the Alliance" },
	},

	-- Scots drops the g from -ing endings. The three-letter stem requirement
	-- keeps "king", "thing", "ring" and friends intact.
	post = function(chunk, ctx)
		if (ctx.strength or 2) >= 2 then
			chunk = gsub(chunk, "(%a%a%a+)ing%f[%A]", "%1in'")
		end
		return chunk
	end,

	flavor = {
		chance = 0.18,
		prefix = { "Och,", "Aye,", "Weel noo,", "Haud on,", "By me beard,", "Hoots!" },
		suffix = { "laddie", "lassie", "ye ken", "mind ye", "aye", "an' nae mistake" },
	},
})
