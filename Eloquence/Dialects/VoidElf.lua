-- Void elves (ren'dorei): elven composure with something else leaking through.
--
-- Void elves hear the Void constantly and spend their lives refusing it. That is
-- the whole character, so it is the mechanic here: alongside a restrained,
-- formal register, whispers surface between sentences, and they get louder the
-- more agitated the speaker is -- the same idea as the Forsaken hiss.
--
-- Whispers are rendered in a dim violet so they read as intrusions rather than
-- as something the speaker chose to say.
local ADDON, E = ...

local gsub, find = string.gsub, string.find
local floor = math.floor

local WHISPERS = {
	"it hungers", "they are watching", "give in", "so much dark",
	"you will fall", "we are always here", "let go", "there is no light",
	"listen to us", "it is already too late",
}

E.RegisterDialect("VoidElf", {
	name = "Ren'dorei",
	desc = "Restrained elven formality, with Void whispers surfacing when agitated.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "greetings", ["hi"] = "greetings", ["hey"] = "you there",
		["goodbye"] = "go, while you can", ["bye"] = "go safely",
		["farewell"] = "may the silence find you",
		["thanks"] = "you have my gratitude", ["sorry"] = "my regrets",
		["yes"] = "indeed", ["yeah"] = "indeed", ["ok"] = "very well",
		["okay"] = "very well", ["sure"] = "certain", ["maybe"] = "perhaps",
		["friend"] = "friend", ["friends"] = "the few who remain",
		["guy"] = "one", ["guys"] = "you all",
		["void"] = "the Void", ["dark"] = "the dark", ["darkness"] = "the Void",
		["shadow"] = "the shadow", ["light"] = "that other thing",
		["magic"] = "the Void's gift", ["power"] = "the Void's power",
		["voice"] = "the whisper", ["voices"] = "the whispers",
		["quiet"] = "never quiet", ["silence"] = "the silence I do not get",
		["alone"] = "never alone", ["sleep"] = "sleep, when they permit it",
		["dream"] = "the whispers", ["dreams"] = "the whispers",
		["mad"] = "touched", ["crazy"] = "touched", ["insane"] = "far gone",
		["afraid"] = "wary", ["scared"] = "wary", ["fear"] = "a familiar companion",
		["control"] = "control, always control", ["calm"] = "held together",
		["home"] = "Telogrus Rift", ["exile"] = "our exile",
		["blood elf"] = "our estranged kin", ["human"] = "the short-lived",
		["good"] = "well", ["great"] = "remarkable", ["bad"] = "ill",
		["stupid"] = "unwise", ["dumb"] = "unwise",
		["think"] = "consider", ["want"] = "desire", ["need"] = "require",
		["help"] = "assist", ["hurry"] = "make haste", ["wait"] = "hold",
		["look"] = "observe", ["understand"] = "comprehend",
		["kill"] = "unmake", ["killed"] = "unmade", ["die"] = "be unmade",
		["dead"] = "unmade", ["death"] = "the quiet",
		["very"] = "most", ["really"] = "truly", ["money"] = "coin",
	}),

	wordsAt = {
		[3] = {
			["listen"] = "listen -- though I hear enough already",
			["hear"] = "hear, always hear", ["mind"] = "what is left of my mind",
			["forever"] = "eternally, and they will still be talking",
			["nothing"] = "the nothing", ["everything"] = "all of it, unmade",
			["star"] = "the dark between stars", ["stars"] = "the dark between stars",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "the whispers do not say", nil, true },
		{ "%f[%a]i think%f[%A]", "I believe -- I think it is mine to believe" },
		{ "%f[%a]thank you%f[%A]", "you have my gratitude" },
		{ "%f[%a]good luck%f[%A]", "may they leave you be" },
		{ "%f[%a]be careful%f[%A]", "guard your thoughts" },
		{ "%f[%a]are you ok%f[%A]", "I am in control" },
		{ "%f[%a]are you okay%f[%A]", "I am in control" },
		{ "%f[%a]what's up%f[%A]", "what is it" },
		{ "%f[%a]let's go%f[%A]", "let us be away from here" },
		{ "%f[%a]shut up%f[%A]", "quiet -- I have enough voices" },
	},

	-- The whispers. Inserted after a sentence boundary, or appended if the
	-- message has none; frequency and count rise with agitation.
	post = function(chunk, ctx)
		local excitement = ctx.excitement or 0
		local strength = ctx.strength or 2
		local chance = (0.12 + 0.4 * excitement) * (strength / 2)
		if ctx.rng() > chance then return chunk end

		local whisper = WHISPERS[floor(ctx.rng() * #WHISPERS) + 1]
		local rendered = " |cff9a70c8*" .. whisper .. "*|r"

		-- Prefer to slip in after the first sentence ending.
		local inserted = false
		local result = gsub(chunk, "([%.!%?])%s", function(punctuation)
			if inserted then return nil end
			inserted = true
			return punctuation .. rendered .. " "
		end, 1)
		if inserted then return result end

		if find(chunk, "%S") then return chunk .. rendered end
		return chunk
	end,

	flavor = {
		chance = 0.14,
		prefix = { "Hm.", "Quiet, you.", "Forgive me,", "One moment." },
		suffix = { "if you will excuse me", "as I said", "it is nothing", "never mind them" },
	},
})
