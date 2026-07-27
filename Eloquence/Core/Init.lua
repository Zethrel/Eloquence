-- Eloquence: namespace, saved-variable handling and module registry.
local ADDON, E = ...

E.ADDON = ADDON
E.VERSION = "2.0.4"

-- Single source of truth for attribution: used by /elo status, the options panel
-- and the TOC. The original Eloquence was a Vanilla-era community addon; this is
-- a reimplementation of it from its documented feature set.
E.AUTHOR = "Zethrel"
E.REALM = "Argent Dawn EU"
E.CREDIT = E.AUTHOR .. " - " .. E.REALM

-- Ordered list of the linguistic filters. The pipeline runs them in this order:
-- normalise the text first, then layer flavour on top.
E.MODULE_ORDER = { "spellbook", "decompression", "mouthwash", "fantasy", "dialect" }

E.MODULES = {}   -- key -> module table (populated by Modules\*.lua)
E.DIALECTS = {}  -- englishRace -> dialect definition (populated by Dialects\*.lua)

-- Chat message types Eloquence understands, mapped to the setting that governs them.
E.CHANNELS = {
	CHAT_MSG_SAY                  = "say",
	CHAT_MSG_YELL                 = "yell",
	CHAT_MSG_EMOTE                = "emote",
	CHAT_MSG_WHISPER              = "whisper",
	CHAT_MSG_WHISPER_INFORM       = "whisper",
	CHAT_MSG_PARTY                = "party",
	CHAT_MSG_PARTY_LEADER         = "party",
	CHAT_MSG_RAID                 = "raid",
	CHAT_MSG_RAID_LEADER          = "raid",
	CHAT_MSG_RAID_WARNING         = "raid",
	CHAT_MSG_INSTANCE_CHAT        = "instance",
	CHAT_MSG_INSTANCE_CHAT_LEADER = "instance",
	CHAT_MSG_GUILD                = "guild",
	CHAT_MSG_OFFICER              = "officer",
	CHAT_MSG_CHANNEL              = "channel",
	CHAT_MSG_MONSTER_SAY          = "monster",
	CHAT_MSG_MONSTER_YELL         = "monster",
	CHAT_MSG_MONSTER_EMOTE        = "monster",
	CHAT_MSG_MONSTER_WHISPER      = "monster",
}

-- Outgoing chat types (as passed to SendChatMessage) mapped to the same settings keys.
E.OUTGOING_TYPES = {
	SAY = "say", YELL = "yell", EMOTE = "emote", WHISPER = "whisper",
	PARTY = "party", PARTY_LEADER = "party",
	RAID = "raid", RAID_LEADER = "raid", RAID_WARNING = "raid",
	INSTANCE_CHAT = "instance", INSTANCE_CHAT_LEADER = "instance",
	GUILD = "guild", OFFICER = "officer", CHANNEL = "channel",
}

E.DEFAULTS = {
	enabled = true,
	debug = false,

	-- Which incoming chat types get filtered.
	incoming = {
		enabled  = true,
		say      = true,
		yell     = true,
		emote    = true,
		whisper  = true,
		party    = true,
		raid     = true,
		instance = true,
		guild    = true,
		officer  = true,
		channel  = true,
		monster  = false,
	},

	-- Rewriting your own outgoing text so other players see the dialect.
	-- Off by default: it changes what you actually send to the server.
	outgoing = {
		enabled  = false,
		say      = true,
		yell     = true,
		emote    = true,
		whisper  = false,
		party    = false,
		raid     = false,
		instance = false,
		guild    = false,
		officer  = false,
		channel  = false,
	},

	-- Per-filter toggles. strength 1 = light, 2 = medium, 3 = heavy.
	modules = {
		spellbook     = { enabled = true,  strength = 2 },
		decompression = { enabled = true,  strength = 2 },
		mouthwash     = { enabled = false, strength = 2 },
		fantasy       = { enabled = false, strength = 2 },
		dialect       = { enabled = true,  strength = 2 },
	},

	dialect = {
		races      = {},     -- englishRace -> false to mute a single race
		selfRace   = false,  -- override the dialect used for your own outgoing text
		applyToSelf = false, -- also dialect your own messages in your chat frame
	},

	cleanup = {
		urls          = true,
		shortChannels = false,
		classColors   = false,
	},
}

local function CopyDefaults(src, dst)
	if type(dst) ~= "table" then dst = {} end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = CopyDefaults(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end
E.CopyDefaults = CopyDefaults

function E.Print(...)
	print("|cff8080ffEloquence:|r", ...)
end

function E.Debug(...)
	if E.db and E.db.debug then
		print("|cff8080ffEloquence|r |cff808080debug|r", ...)
	end
end

-- Registration helpers used by the module and dialect files.
function E.RegisterModule(key, module)
	module.key = key
	E.MODULES[key] = module
	return module
end

function E.RegisterDialect(race, dialect)
	dialect.race = race
	E.DIALECTS[race] = dialect
	return dialect
end

-- Diagnostics, surfaced by /elo doctor.
E.initErrors = {}      -- { name = "Chat", err = "..." }
E.skippedEvents = {}   -- events the client rejected

-- Registering an event name the client does not know raises a Lua error, and an
-- error thrown during setup used to abort every module that had not initialised
-- yet -- which is how one stale event name could silently disable the whole
-- addon. Events change between expansions, so registration is always guarded.
function E.SafeRegisterEvent(frame, event)
	if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event) then
		E.skippedEvents[#E.skippedEvents + 1] = event
		return false
	end
	local ok = pcall(frame.RegisterEvent, frame, event)
	if not ok then
		E.skippedEvents[#E.skippedEvents + 1] = event
		return false
	end
	return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON then
		EloquenceDB = CopyDefaults(E.DEFAULTS, EloquenceDB)
		E.db = EloquenceDB
	elseif event == "PLAYER_LOGIN" then
		-- Each module is isolated: one failing must not stop the rest from
		-- setting up, and it must be visible rather than silent.
		for _, entry in ipairs(E.onLogin or {}) do
			local ok, err = pcall(entry.fn)
			if not ok then
				E.initErrors[#E.initErrors + 1] = { name = entry.name, err = tostring(err) }
				print(("|cff8080ffEloquence:|r |cffff4040%s failed to start.|r Run |cffffff80/elo doctor|r.")
					:format(entry.name))
			end
		end
	end
end)

E.onLogin = {}

-- `name` identifies the module in /elo doctor when its setup fails.
function E.OnLogin(name, fn)
	table.insert(E.onLogin, { name = name, fn = fn })
end
