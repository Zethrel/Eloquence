-- The Fantasy Writer: drags modern, out-of-character vocabulary into the sort of
-- language you would find in a fantasy novel.
local ADDON, E = ...

local module = E.RegisterModule("fantasy", {
	name = "Fantasy Writer",
	desc = "Rewrites modern, out-of-character expressions in the language of fantasy literature.",
})

local RULES = {
	words = {
		-- Anachronisms
		["car"] = "wagon", ["cars"] = "wagons", ["truck"] = "cart",
		["bus"] = "coach", ["train"] = "caravan", ["plane"] = "gryphon",
		["phone"] = "sending stone", ["email"] = "missive", ["emails"] = "missives",
		["text"] = "missive", ["computer"] = "arcane engine",
		["internet"] = "the weave", ["online"] = "abroad", ["offline"] = "at rest",
		["tv"] = "scrying pool", ["television"] = "scrying pool",
		["movie"] = "tale", ["movies"] = "tales", ["video"] = "vision",
		["photo"] = "portrait", ["camera"] = "portrait-glass",
		["gun"] = "crossbow", ["guns"] = "crossbows", ["bullet"] = "bolt",
		["bomb"] = "alchemist's flask", ["battery"] = "mana crystal",
		["hospital"] = "infirmary", ["doctor"] = "healer", ["nurse"] = "healer",
		["medicine"] = "tonic", ["pill"] = "draught", ["surgery"] = "the knife",
		["police"] = "the guard", ["cop"] = "guardsman", ["cops"] = "guardsmen",
		["prison"] = "the stockade", ["jail"] = "the stockade",
		["restaurant"] = "tavern", ["cafe"] = "tavern", ["bar"] = "tavern",
		["hotel"] = "inn", ["shop"] = "merchant's stall", ["store"] = "merchant's stall",
		["mall"] = "the bazaar", ["market"] = "the bazaar",
		["school"] = "academy", ["college"] = "academy", ["university"] = "academy",
		["teacher"] = "mentor", ["student"] = "apprentice", ["homework"] = "studies",
		["job"] = "trade", ["work"] = "labour", ["boss"] = "liege",
		["office"] = "the guild hall", ["money"] = "coin", ["cash"] = "coin",
		["dollar"] = "gold piece", ["dollars"] = "gold pieces",
		["bathroom"] = "privy", ["toilet"] = "privy", ["kitchen"] = "the hearth",
		["news"] = "tidings", ["newspaper"] = "the broadsheets",
		["book"] = "tome", ["books"] = "tomes", ["letter"] = "missive",
		["story"] = "tale", ["stories"] = "tales", ["music"] = "song",
		["party"] = "revel", ["weekend"] = "feast days", ["holiday"] = "festival",
		["birthday"] = "name day", ["family"] = "kin", ["parents"] = "elders",
		-- Register
		["hi"] = "hail", ["hello"] = "hail", ["hey"] = "ho there",
		["bye"] = "farewell", ["goodbye"] = "farewell",
		["yes"] = "aye", ["yeah"] = "aye", ["yep"] = "aye", ["yup"] = "aye",
		["no"] = "nay", ["nope"] = "nay", ["ok"] = "very well", ["okay"] = "very well",
		["guy"] = "fellow", ["guys"] = "friends", ["dude"] = "friend",
		["man"] = "fellow", ["kid"] = "youngling", ["kids"] = "younglings",
		["awesome"] = "wondrous", ["amazing"] = "wondrous", ["cool"] = "splendid",
		["great"] = "splendid", ["nice"] = "fair", ["good"] = "well",
		["bad"] = "ill", ["terrible"] = "dire", ["awful"] = "dire",
		["weird"] = "curious", ["strange"] = "curious", ["crazy"] = "mad",
		["angry"] = "wroth", ["mad"] = "wroth", ["happy"] = "glad",
		["sad"] = "sorrowful", ["tired"] = "weary", ["hungry"] = "famished",
		["scared"] = "afeared", ["afraid"] = "afeared", ["brave"] = "valiant",
		["strong"] = "stout", ["weak"] = "frail", ["fast"] = "swift",
		["slow"] = "sluggard", ["big"] = "great", ["huge"] = "vast",
		["small"] = "slight", ["food"] = "victuals", ["drink"] = "ale",
		["friend"] = "companion", ["friends"] = "companions",
		["enemy"] = "foe", ["enemies"] = "foes", ["fight"] = "do battle",
		["kill"] = "slay", ["killed"] = "slain", ["dead"] = "fallen",
		["die"] = "perish", ["died"] = "perished",
		-- Function words
		["really"] = "verily", ["very"] = "most", ["totally"] = "wholly",
		["maybe"] = "perchance", ["probably"] = "like as not",
		["almost"] = "nigh", ["near"] = "nigh", ["enough"] = "enow",
		["often"] = "oft", ["always"] = "ever", ["never"] = "ne'er",
		["over"] = "o'er", ["about"] = "concerning", ["before"] = "ere",
		["while"] = "whilst", ["among"] = "amongst", ["between"] = "betwixt",
		["because"] = "for", ["quickly"] = "with haste", ["soon"] = "ere long",
		["now"] = "at once", ["today"] = "this day", ["tomorrow"] = "the morrow",
		["yesterday"] = "yestereve", ["minute"] = "moment", ["second"] = "heartbeat",
		["hour"] = "turn of the glass", ["week"] = "sennight", ["month"] = "moon",
	},

	wordsAt = {
		[3] = {
			-- Full archaic second person, for the truly committed.
			["you"] = "thou", ["your"] = "thy", ["yours"] = "thine",
			["yourself"] = "thyself", ["you're"] = "thou art",
			["are"] = "art", ["my"] = "mine", ["do"] = "dost",
			["does"] = "doth", ["has"] = "hath", ["have"] = "hast",
			["will"] = "shall", ["cannot"] = "canst not", ["here"] = "hither",
			["there"] = "thither", ["where"] = "whither", ["when"] = "whensoever",
			["if"] = "an", ["think"] = "deem", ["know"] = "wot",
			["said"] = "quoth", ["say"] = "speak", ["go"] = "hie",
		},
	},

	phrases = {
		{ "%f[%a]what's up%f[%A]", "what news" },
		{ "%f[%a]how's it going%f[%A]", "how fares the day" },
		{ "%f[%a]see you later%f[%A]", "until we meet again" },
		{ "%f[%a]thank you%f[%A]", "my thanks to you" },
		{ "%f[%a]no problem%f[%A]", "think nothing of it" },
		{ "%f[%a]good luck%f[%A]", "fortune favour you" },
		{ "%f[%a]be careful%f[%A]", "guard yourself well" },
		{ "%f[%a]hold on%f[%A]", "stay a moment" },
		{ "%f[%a]shut up%f[%A]", "hold thy tongue" },
		{ "%f[%a]let's go%f[%A]", "let us away" },
		{ "%f[%a]i think%f[%A]", "methinks" },
		{ "%f[%a]i don't know%f[%A]", "I know not" },
		{ "%f[%a]a lot of%f[%A]", "a great many" },
		{ "%f[%a]right now%f[%A]", "this very moment" },
		{ "%f[%a]in real life%f[%A]", "beyond the veil" },
	},
}

function module.Filter(text, ctx)
	-- An idiom the speaker's class has its own answer for is left alone here, so
	-- it survives to the Dialectician. Otherwise a Death Knight's "good luck"
	-- became "fortune favour you" before the class could turn it into "die well".
	return E.Engine.Apply(RULES, text, ctx, ctx.classClaims)
end

module.RULES = RULES
