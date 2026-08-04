-- Gilnean: clipped, old-fashioned, faintly aristocratic English -- with a growl
-- that surfaces when the beast gets close to the surface.
local ADDON, E = ...

local gsub, rep, sub = string.gsub, string.rep, string.sub
local floor = math.floor

E.RegisterDialect("Worgen", {
	name = "Gilnean",
	desc = "Clipped aristocratic English, with a growl when riled.",

	words = {
		["hello"] = "good day", ["hi"] = "good day", ["hey"] = "I say",
		["greetings"] = "good day to you", ["goodbye"] = "good day",
		["bye"] = "cheerio", ["farewell"] = "farewell to you",
		["thanks"] = "much obliged", ["please"] = "if you would be so kind",
		["sorry"] = "do forgive me",
		["yes"] = "quite", ["yeah"] = "quite so", ["yep"] = "quite",
		["ok"] = "very good", ["okay"] = "very good", ["sure"] = "certain",
		["no"] = "certainly not", ["nope"] = "certainly not", ["maybe"] = "possibly",
		-- "old chap", "good fellows" and "gentlemen" all addressed the listener as
		-- a man. Gilnean manners are the point of this dialect, and addressing a
		-- lady as "old chap" is precisely the sort of thing they would not do.
		["friends"] = "good people", ["guy"] = "fellow",
		["guys"] = "good people", ["dude"] = "friend", ["man"] = "fellow",
		-- Safe: the word being replaced already states the gender, so the player
		-- has told us.
		--
		-- "lady" -> "madam" is gone, for the reason recorded in Dwarf.lua. Gilneas
		-- is the most title-conscious culture in the game and "Lady Jaina is here"
		-- was coming out as "Madam Jaina is here".
		["woman"] = "madam", ["women"] = "ladies",
		["good"] = "splendid", ["great"] = "capital", ["nice"] = "rather pleasant",
		["awesome"] = "positively splendid", ["cool"] = "rather good",
		["bad"] = "dreadful", ["awful"] = "perfectly dreadful", ["terrible"] = "ghastly",
		["weird"] = "peculiar", ["strange"] = "peculiar", ["crazy"] = "quite mad",
		["stupid"] = "dim", ["dumb"] = "dim", ["rude"] = "ill-mannered",
		["very"] = "terribly", ["really"] = "frightfully", ["quite"] = "rather",
		["angry"] = "positively feral", ["mad"] = "positively feral",
		["hungry"] = "ravenous", ["tired"] = "quite spent",
		["afraid"] = "uneasy", ["scared"] = "uneasy",
		["fight"] = "have at them", ["kill"] = "put down", ["killed"] = "put down",
		["die"] = "perish", ["died"] = "perished", ["dead"] = "done for",
		["help"] = "lend a hand", ["hurry"] = "look lively", ["wait"] = "hold fast",
		["run"] = "make a dash for it", ["look"] = "have a look",
		["think"] = "should say", ["want"] = "should like", ["need"] = "require",
		["money"] = "coin", ["home"] = "Gilneas", ["city"] = "Gilneas City",
		["curse"] = "the curse", ["wolf"] = "the beast", ["beast"] = "the beast",
		["problem"] = "spot of bother", ["trouble"] = "spot of bother",
		["food"] = "supper", ["drink"] = "a stiff drink",
	},

	wordsAt = {
		[3] = {
			["yes"] = "rather", ["hello"] = "how do you do",
			["work"] = "the business at hand", ["job"] = "the business at hand",
			["fast"] = "sharpish", ["big"] = "considerable", ["small"] = "slight",
			["understand"] = "follow you", ["talk"] = "have a word",
			["nonsense"] = "utter rot", ["lie"] = "utter rot",
		},
	},

	phrases = {
		{ "%f[%a]i think%f[%A]", "I should say" },
		{ "%f[%a]i guess%f[%A]", "I daresay" },
		{ "%f[%a]i don't know%f[%A]", "I couldn't say", nil, true },
		{ "%f[%a]thank you%f[%A]", "much obliged to you" },
		{ "%f[%a]good luck%f[%A]", "best of luck to you" },
		{ "%f[%a]be careful%f[%A]", "do mind yourself" },
		{ "%f[%a]what's up%f[%A]", "what seems to be the trouble" },
		{ "%f[%a]shut up%f[%A]", "kindly hold your tongue" },
		{ "%f[%a]let's go%f[%A]", "shall we be off" },
		{ "%f[%a]for the alliance%f[%A]", "for the Alliance, and for Gilneas" },
	},

	post = function(chunk, ctx)
		local excitement = ctx.excitement or 0
		local strength = ctx.strength or 2
		if excitement < 0.3 then return chunk end
		-- The growl: draw out r sounds the more worked up they are.
		local extra = 1 + floor(excitement * 2)
		local chance = excitement * 0.6 * (strength / 2)
		return (gsub(chunk, "[rR]+", function(run)
			if ctx.rng() > chance then return nil end
			return run .. rep(sub(run, -1), extra)
		end))
	end,

	flavor = {
		chance = 0.18,
		prefix = { "I say,", "Right.", "Good grief.", "*grrr*", "Steady on," },
		-- "old chap" was here. A suffix is appended to any message with no idea
		-- who is reading it, so it addressed the whole realm as a gentleman.
		suffix = { "I should think", "quite so", "if you please", "*low growl*", "and no mistake" },
	},
})
