-- Void elves (ren'dorei): elven composure with something else leaking through.
--
-- Void elves hear the Void constantly and spend their lives refusing it, and
-- this file used to act that out: random whispers -- "let go", "it is already
-- too late" -- inserted into the message in a dim violet, more often the more
-- agitated the speaker sounded.
--
-- REMOVED, and the reason is worth keeping.
--
-- REPORTS
-- Anadelonbrin and Vynlor, both of Argent Dawn (EU): one creeped out by the
-- voices in her head, the other saying creepy stuff -- both due to a void elf
-- bug. Their words, and better than any summary of the fault.
--
-- Every other filter here *translates* what somebody typed. The whispers
-- invented text nobody wrote and attributed it to them, and they were wrapped in
-- asterisks, which on a roleplaying realm means an emote. So a Void Elf appeared
-- to perform an action they had not performed:
--
--   [Vynlor Dawnfall] says: *it is already too late* Gold! Come here, girl!
--
-- Worse, it ran on the outgoing path too, so with outgoing rewriting on the
-- invented emote was actually broadcast to everyone in range. Lisp and Muffle
-- are self-only precisely so the addon never puts words in someone's mouth;
-- this put whole actions there, for other people to read as roleplay.
--
-- It also hid for five versions. The escape guard added in 2.7.1 threw away any
-- transform whose escapes changed, and a whisper adds a colour code, so from
-- 2.7.1 to 2.8.2 the whispers silently never appeared -- and took the rest of
-- the dialect with them. Fixing that guard in 2.8.3 brought them back, and the
-- first thing that happened was a bug report from a live realm.
--
-- What is left is the register: formal, unhurried, contractions expanded, and a
-- vocabulary that keeps circling back to silence and the dark. That says the
-- same thing about the character without writing their lines for them.
local ADDON, E = ...

E.RegisterDialect("VoidElf", {
	name = "Ren'dorei",
	desc = "Restrained elven formality. Careful, quiet, and circling the dark.",

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
		-- "blood elf" was here and never fired: a word lookup is a single token.
		-- It is a phrase below now.
		["human"] = "the short-lived",
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
		{ "%f[%a]blood elf%f[%A]", "our estranged kin" },
		{ "%f[%a]blood elves%f[%A]", "our estranged kin" },
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

	flavor = {
		chance = 0.14,
		prefix = { "Hm.", "Quiet, you.", "Forgive me,", "One moment." },
		suffix = { "if you will excuse me", "as I said", "it is nothing", "never mind them" },
	},
})
