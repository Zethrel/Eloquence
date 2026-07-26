-- The Decompression Engine: expands MMO and Warcraft shorthand back into words.
--
-- Deliberately avoids bare digits ("2" -> "to") because "level 2" would become
-- "level to". Only tokens that mix letters and digits ("b4", "gr8", "any1") are
-- treated as shorthand.
local ADDON, E = ...

local gsub, lower = string.gsub, string.lower

local ACRONYMS = {
	-- Conversational
	lol = "laugh out loud", lmao = "laughing hard", rofl = "rolling on the floor laughing",
	lulz = "laughs",
	brb = "be right back", bbl = "be back later", bbs = "be back soon",
	afk = "away from keyboard", bio = "stepping away briefly", brt = "be right there",
	gtg = "got to go", ttyl = "talk to you later", cya = "see you", cu = "see you",
	ty = "thank you", tyvm = "thank you very much", thx = "thanks", tks = "thanks",
	np = "no problem", yw = "you are welcome", nvm = "never mind",
	omw = "on my way", omg = "oh my goodness", wtf = "what the fel",
	ffs = "for the Light's sake", smh = "shaking my head",
	idk = "I do not know", idc = "I do not care", ikr = "I know, right",
	imo = "in my opinion", imho = "in my honest opinion", tbh = "to be honest",
	btw = "by the way", fyi = "for your information", asap = "as soon as possible",
	irl = "in real life", atm = "at the moment", jk = "just kidding",
	srsly = "seriously", ez = "easy", gg = "good game", gl = "good luck",
	hf = "have fun", glhf = "good luck and have fun", wp = "well played",
	gj = "good job", gz = "congratulations", grats = "congratulations",
	congratz = "congratulations", gratz = "congratulations",
	pls = "please", plz = "please", plox = "please", sec = "one moment",
	rly = "really", def = "definitely", obv = "obviously", ofc = "of course",
	prob = "probably", msg = "message", pm = "private message",
	-- Warcraft and group play
	wtb = "want to buy", wts = "want to sell", wtt = "want to trade",
	lfg = "looking for group", lfm = "looking for more", lfw = "looking for work",
	lfr = "the raid finder", pug = "pick-up group", pst = "please send me a tell",
	dps = "damage dealer", heals = "healer",
	mt = "main tank", ot = "off tank", oom = "out of mana",
	aoe = "area of effect", cc = "crowd control", dot = "damage over time",
	hot = "heal over time", cd = "cooldown", gcd = "global cooldown",
	aggro = "the enemy's attention",
	rez = "resurrect", res = "resurrect",
	summ = "summon", debuff = "affliction",
	boe = "bind on equip", bop = "bind on pickup",
	bis = "best in slot", ilvl = "item level", xp = "experience",
	os = "off specialisation", ms = "main specialisation",
	sr = "soft reserve", ml = "master looter", gdkp = "a gold-share run",
	alt = "alternate character", toon = "character",
	mob = "creature", mobs = "creatures",
	gank = "ambush", ganked = "ambushed",
	ooc = "out of character", rp = "roleplay",
	afaik = "as far as I know", ftw = "for the win", op = "overpowered",
	inc = "incoming", brez = "battle resurrection",
	-- Class shorthand
	pally = "paladin", lock = "warlock", dk = "death knight",
	dh = "demon hunter", sham = "shaman", boomkin = "druid",
}

-- Letters-and-digits shorthand. Applied as patterns so digits are matched.
local LEET = {
	{ "%f[%w]b4%f[%W]", "before" },
	{ "%f[%w]l8r%f[%W]", "later" },
	{ "%f[%w]m8%f[%W]", "mate" },
	{ "%f[%w]gr8%f[%W]", "great" },
	{ "%f[%w]str8%f[%W]", "straight" },
	{ "%f[%w]w8%f[%W]", "wait" },
	{ "%f[%w]l8%f[%W]", "late" },
	{ "%f[%w]any1%f[%W]", "anyone" },
	{ "%f[%w]some1%f[%W]", "someone" },
	{ "%f[%w]no1%f[%W]", "no one" },
	{ "%f[%w]every1%f[%W]", "everyone" },
	{ "%f[%w]2day%f[%W]", "today" },
	{ "%f[%w]2morrow%f[%W]", "tomorrow" },
	{ "%f[%w]2nite%f[%W]", "tonight" },
	{ "%f[%w]4u%f[%W]", "for you" },
	{ "%f[%w]2u%f[%W]", "to you" },
	{ "%f[%w]1st%f[%W]", "first" },
	{ "%f[%w]2nd%f[%W]", "second" },
	{ "%f[%w]3rd%f[%W]", "third" },
}

-- Very short stand-ins for whole words. Riskier (a stray "r" in an otherwise
-- normal sentence is not always shorthand), so gated behind strength 2.
local SHORTHAND = {
	u = "you", ur = "your", urs = "yours", r = "are", y = "why",
	k = "okay", kk = "okay", tho = "though", thru = "through",
	ppl = "people", sry = "sorry", tmr = "tomorrow",
	wana = "want to", wud = "would", cud = "could", shud = "should",
	dis = "this", dat = "that", da = "the", nite = "night",
}

local PHRASES = {
	{ "%f[%a]tl;dr%f[%A]", "in short" },
	{ "%f[%a]lf%s*1%s*m%f[%W]", "looking for one more" },
	{ "%f[%a]lf%s*2%s*m%f[%W]", "looking for two more" },
	{ "%f[%a]afk%s*brb%f[%A]", "away from keyboard, back shortly" },
	{ "%f[%a]xd%f[%A]", "*laughs*" },
	{ "%f[%a]o7%f[%W]", "*salutes*" },
	-- "<" is not a letter, so this one cannot use an %f[%a] frontier.
	{ "<3", "*fondly*", true },
}

local module = E.RegisterModule("decompression", {
	name = "Decompression Engine",
	desc = "Expands MMO and Warcraft acronyms and text-speak back into full words.",
})

function module.Filter(text, ctx)
	local strength = ctx.strength

	return E.MapPlain(text, function(chunk)
		for i = 1, #PHRASES do
			local entry = PHRASES[i]
			if entry[3] then
				chunk = gsub(chunk, entry[1], entry[2])
			else
				chunk = gsub(chunk, "(" .. entry[1] .. ")", function(m)
					return E.MatchCase(m, entry[2])
				end)
			end
		end

		for i = 1, #LEET do
			local pattern, replacement = LEET[i][1], LEET[i][2]
			chunk = gsub(chunk, "(" .. pattern .. ")", function(m)
				return E.MatchCase(m, replacement)
			end)
		end

		chunk = gsub(chunk, "[%a']+", function(token)
			local core, trail = token:match("^(.-)('*)$")
			local lead
			lead, core = core:match("^('*)(.*)$")
			if core == "" then return nil end
			local key = lower(core)
			local expansion = ACRONYMS[key]
			if not expansion and strength >= 2 and #key <= 5 then
				expansion = SHORTHAND[key]
			end
			if not expansion then return nil end
			return lead .. E.MatchCase(core, expansion) .. trail
		end)

		return chunk
	end)
end
