-- Mouthwash: swaps profanity and slurs for period-appropriate euphemisms.
--
-- This is a display filter -- it changes what you read, not what anyone said,
-- and it is off by default. Common letter-substitution dodges (f*ck, sh1t) are
-- caught by normalising a token before it is looked up.
local ADDON, E = ...

local gsub, lower = string.gsub, string.lower

-- Mild, in-universe replacements. Warcraft has its own swearing to borrow from.
local EUPHEMISMS = {
	-- General profanity
	["fuck"] = "fel", ["fucks"] = "fel", ["fucked"] = "felled",
	["fucking"] = "blasted", ["fucker"] = "wretch", ["fuckers"] = "wretches",
	["shit"] = "muck", ["shits"] = "muck", ["shitty"] = "wretched",
	["bullshit"] = "nonsense", ["ass"] = "backside", ["asses"] = "backsides",
	["asshole"] = "cur", ["assholes"] = "curs", ["arse"] = "backside",
	["bitch"] = "harpy", ["bitches"] = "harpies", ["bitching"] = "complaining",
	["bastard"] = "knave", ["bastards"] = "knaves",
	["damn"] = "curse it", ["damned"] = "accursed", ["damnit"] = "curse it",
	["dammit"] = "curse it", ["goddamn"] = "confounded",
	["hell"] = "the Nether", ["crap"] = "rubbish", ["crappy"] = "shoddy",
	["piss"] = "vex", ["pissed"] = "vexed", ["pissing"] = "vexing",
	["dick"] = "cad", ["dicks"] = "cads", ["prick"] = "cad",
	["cock"] = "rooster", ["twat"] = "fool", ["wanker"] = "layabout",
	["bollocks"] = "nonsense", ["bugger"] = "blighter", ["bloody"] = "blasted",
	["slut"] = "wastrel", ["whore"] = "wastrel", ["cunt"] = "wretch",
	["douche"] = "boor", ["douchebag"] = "boor", ["jackass"] = "dolt",
	["moron"] = "dullard", ["idiot"] = "dullard", ["retard"] = "dullard",
	["retarded"] = "witless", ["stupid"] = "witless", ["dumbass"] = "dullard",
	["gay"] = "unpleasant", ["fag"] = "boor", ["faggot"] = "boor",
	["screw"] = "bother", ["screwed"] = "bothered", ["suck"] = "disappoint",
	["sucks"] = "disappoints", ["sucked"] = "disappointed",
	["jesus"] = "by the Light", ["christ"] = "by the Light",
	-- Common obfuscations, normalised forms
	["fk"] = "fel", ["fck"] = "fel", ["fuk"] = "fel", ["fking"] = "blasted",
	["fkin"] = "blasted", ["fukin"] = "blasted", ["sht"] = "muck",
	["stfu"] = "hold your tongue", ["gtfo"] = "be gone",
	["wtf"] = "what the fel", ["ffs"] = "for the Light's sake",
	["omfg"] = "by the Light", ["lmfao"] = "laughing hard",
	["af"] = "exceedingly", ["azz"] = "backside", ["biatch"] = "harpy",
}

local module = E.RegisterModule("mouthwash", {
	name = "Mouthwash",
	desc = "Replaces profanity with period-appropriate euphemisms. Display only.",
})

-- Collapse the usual dodges so a single dictionary catches the variants:
-- f*ck / f**k / sh1t / a$$ / fuuuck all normalise onto a dictionary key.
local SUBSTITUTIONS = {
	["*"] = "", ["@"] = "a", ["$"] = "s", ["!"] = "i", ["1"] = "i",
	["0"] = "o", ["3"] = "e", ["4"] = "a", ["5"] = "s", ["7"] = "t", ["+"] = "t",
}

-- Two normalised forms are produced, and the order they are tried in matters:
--   1. de-substituted only        a$$    -> ass   (the doubling is the word)
--   2. de-substituted + collapsed  daaaamn -> damn
-- Collapsing first would reduce "a$$" to "as" and miss the dictionary entirely.
local function Normalise(token)
	local desubbed = gsub(lower(token), "[%*@%$!1034578%+]", function(c)
		return SUBSTITUTIONS[c] or ""
	end)
	local collapsed = E.CollapseRuns(desubbed, function(c)
		return c:match("%a") and 1 or nil
	end)
	return desubbed, collapsed
end

-- Decoration on the ends of a token ("hell!", "**damn**") has to come off
-- before lookup -- but the same characters can *be* the obfuscation ("a$$"), so
-- the whole token is always tried before the stripped one.
local EDGE = "^([%*!%+'@%$]*)(.-)([%*!%+'@%$]*)$"

function module.Filter(text, ctx)
	local strength = ctx.strength

	return E.MapPlain(text, function(chunk)
		return (gsub(chunk, "[%a%*@%$!%d%+']+", function(token)
			local lead, core, trail = token:match(EDGE)
			if not core or core == "" then
				lead, core, trail = "", token, ""
			end

			-- Whole token first, then the stripped core. Each candidate carries
			-- the decoration that has to be put back afterwards.
			local candidates = { { token, "", "" } }
			if core ~= token then
				candidates[2] = { core, lead, trail }
			end

			for _, candidate in ipairs(candidates) do
				local word, before, after = candidate[1], candidate[2], candidate[3]
				local replacement = EUPHEMISMS[lower(word)]

				if not replacement and strength >= 2 then
					local desubbed, collapsed = Normalise(word)
					replacement = EUPHEMISMS[desubbed] or EUPHEMISMS[collapsed]
				end

				if not replacement and strength >= 3 then
					-- Catch compounds too: "motherfucking", "shitstorm".
					local desubbed = Normalise(word)
					for bad, good in pairs(EUPHEMISMS) do
						if #bad >= 4 and desubbed:find(bad, 1, true) then
							replacement = good
							break
						end
					end
				end

				if replacement then
					return before .. E.MatchCase(word, replacement) .. after
				end
			end

			return nil
		end))
	end)
end

module.Normalise = Normalise
