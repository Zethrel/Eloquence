-- Eloquence: presets.
--
-- There is no single right answer to "which channels should be dialected", so
-- rather than argue about defaults these bundle the sensible combinations.
--
-- Two things a preset never touches, deliberately:
--   * outgoing.enabled -- that changes what other players actually receive, and
--     must stay an explicit decision rather than a side effect of a preset.
--   * dialect.races -- if you have muted a race, you meant it.
local ADDON, E = ...

local Presets = {}
E.Presets = Presets

-- Channel sets, so the intent is legible rather than a wall of booleans.
local IN_CHARACTER = {
	say = true, yell = true, emote = true, whisper = true,
	party = false, raid = false, instance = false,
	guild = false, officer = false, channel = false,
}

local EVERY_CHANNEL = {
	say = true, yell = true, emote = true, whisper = true,
	party = true, raid = true, instance = true,
	guild = true, officer = true, channel = true,
}

Presets.order = { "rp", "immersive", "clean", "off" }

Presets.list = {
	rp = {
		name = "Roleplay",
		desc = "Dialects on the in-character channels only. Coordination chat left alone.",
		incoming = E.CopyDefaults(IN_CHARACTER, { monster = false, bubbles = true, enabled = true }),
		outgoing = E.CopyDefaults(IN_CHARACTER, { whisper = false }),
		modules = {
			spellbook     = { enabled = true,  strength = 2, incoming = false },
			decompression = { enabled = true,  strength = 2, incoming = true },
			mouthwash     = { enabled = false, strength = 2, incoming = true },
			fantasy       = { enabled = false, strength = 2, incoming = true },
			dialect       = { enabled = true,  strength = 2, incoming = true },
		},
	},

	immersive = {
		name = "Immersive",
		desc = "As Roleplay, but heavier, and NPCs get dialects too.",
		incoming = E.CopyDefaults(IN_CHARACTER, { monster = true, bubbles = true, enabled = true }),
		outgoing = E.CopyDefaults(IN_CHARACTER, { whisper = false }),
		modules = {
			spellbook     = { enabled = true,  strength = 2, incoming = false },
			decompression = { enabled = true,  strength = 3, incoming = true },
			mouthwash     = { enabled = false, strength = 2, incoming = true },
			fantasy       = { enabled = true,  strength = 2, incoming = true },
			dialect       = { enabled = true,  strength = 3, incoming = true },
		},
	},

	clean = {
		name = "Clean chat",
		desc = "No dialects. Just tidier chat everywhere: spelling, acronyms, profanity.",
		incoming = E.CopyDefaults(EVERY_CHANNEL, { monster = false, bubbles = false, enabled = true }),
		outgoing = E.CopyDefaults(EVERY_CHANNEL, {}),
		modules = {
			spellbook     = { enabled = true,  strength = 2, incoming = true },
			decompression = { enabled = true,  strength = 2, incoming = true },
			mouthwash     = { enabled = true,  strength = 2, incoming = true },
			fantasy       = { enabled = false, strength = 2, incoming = true },
			dialect       = { enabled = false, strength = 2, incoming = true },
		},
	},

	off = {
		name = "Everything off",
		desc = "Every filter disabled, addon still loaded.",
		modules = {
			spellbook     = { enabled = false },
			decompression = { enabled = false },
			mouthwash     = { enabled = false },
			fantasy       = { enabled = false },
			dialect       = { enabled = false },
		},
	},
}

-- Apply by name. Returns true, or false plus the list of valid names.
function Presets.Apply(name)
	local preset = name and Presets.list[name:lower()]
	if not preset then return false end

	local db = E.db

	if preset.incoming then
		for key, value in pairs(preset.incoming) do
			db.incoming[key] = value
		end
	end

	if preset.outgoing then
		for key, value in pairs(preset.outgoing) do
			-- Never flip the master switch; see the note at the top.
			if key ~= "enabled" then db.outgoing[key] = value end
		end
	end

	for key, settings in pairs(preset.modules or {}) do
		local target = db.modules[key]
		if target then
			for field, value in pairs(settings) do
				target[field] = value
			end
		end
	end

	db.enabled = name:lower() ~= "off" or db.enabled
	return true
end
