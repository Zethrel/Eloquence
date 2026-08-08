-- Shaman.
--
-- A shaman does not command, they ask. Every source on them says the same thing:
-- the elements are not tools but parties to a conversation, they can refuse, and
-- a shaman who forgets that is a warlock with extra steps. So the idiom here is
-- consultative -- things are asked, permitted, granted, and occasionally denied.
--
-- The ancestors belong here too. Orcish, Tauren and Mag'har dialects already
-- speak of them, and this layer adds the habit to a Draenei or Dwarf shaman who
-- would otherwise have no vocabulary for it.
--
-- Nothing is excluded. A Draenei shaman invoking the Light and the elements in
-- the same breath is not a contradiction -- it is a Draenei shaman.
local ADDON, E = ...

E.RegisterClass("SHAMAN", {
	name = "Shaman",

	flavor = {
		prefix = { "The elements stir.", "Listen.", "They are willing.", "Be still a moment." },
		suffix = { "the elements permit it", "as the spirits allow", "if they are willing",
		           "the ancestors saw this too" },
	},

	words = {
		["magic"] = "the elements' gift", ["power"] = "what they lend me",
		["fire"] = "flame", ["water"] = "the waters", ["wind"] = "the winds",
		["earth"] = "the earth", ["storm"] = "the storm",
		["heal"] = "mend", ["healed"] = "mended",
		["ancestor"] = "ancestor", ["ancestors"] = "the ancestors",
	},

	wordsAt = {
		[3] = {
			-- "will" was here, mapped to "am permitted to". It is an auxiliary
			-- verb far more often than anything else, so "that will work" became
			-- "that am permitted to work".
			["want"] = "would ask", ["need"] = "must ask for",
			["angry"] = "unquiet", ["calm"] = "settled", ["quiet"] = "still",
		},
	},

	phrases = {
		{ "%f[%a]good luck%f[%A]", "may the elements favour you" },
		{ "%f[%a]i promise%f[%A]", "the spirits hear me say it" },
		{ "%f[%a]be careful%f[%A]", "walk where the earth is steady" },
		{ "%f[%a]i don't know%f[%A]", "the elements have not said", nil, true },
	},
})
