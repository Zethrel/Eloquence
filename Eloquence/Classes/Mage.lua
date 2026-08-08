-- Mage.
--
-- A mage's idiom is pedantry with a licence. Magic is a discipline with a
-- literature, a mage has read it, and the tell is precision: not "roughly" but
-- "within a margin", not "it worked" but "it held". Kirin Tor habits of speech
-- outlast whatever race is speaking them.
--
-- The line held here is that a mage is precise, not that a mage is arrogant.
-- Blood Elf and Nightborne dialects already do superiority far better, and
-- stacking a second layer of it would make every mage of those races unbearable.
--
-- Nothing is excluded. A pious mage is perfectly ordinary; the arcane is a field
-- of study rather than a rival faith.
local ADDON, E = ...

E.RegisterClass("MAGE", {
	name = "Mage",

	flavor = {
		prefix = { "Precisely.", "A moment -- the theory matters.", "Observe.",
		           "That is nearly right." },
		suffix = { "within an acceptable margin", "the theory is sound",
		           "as the literature has it", "assuming nothing else interferes" },
	},

	words = {
		["magic"] = "the arcane", ["spell"] = "the working", ["spells"] = "workings",
		["power"] = "the arcane", ["guess"] = "estimate", ["think"] = "reason",
		["maybe"] = "probably, though I would want to check",
		["broken"] = "unstable", ["worked"] = "held", ["works"] = "holds",
	},

	wordsAt = {
		[3] = {
			-- "about" was here: "about to leave" would have become "approximately
			-- to leave". "a lot" was too, and could never have matched -- word
			-- mappings are single tokens, so a key with a space is dead weight.
			["nearly"] = "to within a margin", ["obviously"] = "demonstrably",
			["wrong"] = "unsupported by the evidence", ["sure"] = "confident",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "I would not care to state it without checking", nil, true },
		{ "%f[%a]good luck%f[%A]", "may your variables hold" },
		{ "%f[%a]i think%f[%A]", "the evidence suggests" },
		{ "%f[%a]be careful%f[%A]", "mind the reagents" },
	},
})
