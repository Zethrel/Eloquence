-- Eloquence: namespace, saved-variable handling and module registry.
local ADDON, E = ...

E.ADDON = ADDON
E.VERSION = "2.9.1"

-- Single source of truth for attribution: used by /elo status, the options panel
-- and the TOC. The original Eloquence was a Vanilla-era community addon; this is
-- a reimplementation of it from its documented feature set.
E.AUTHOR = "Zethrel"
E.REALM = "Argent Dawn EU"
E.CREDIT = E.AUTHOR .. " - " .. E.REALM

-- Ordered list of the linguistic filters. The pipeline runs them in this order:
-- normalise the text first, then layer flavour on top.
-- Lisp and Muffle come last: they are properties of the speaker's mouth rather
-- than of the language, so they distort whatever the dialect produced.
E.MODULE_ORDER = {
	"spellbook", "decompression", "mouthwash", "fantasy", "dialect",
	"lisp", "muffle",
}

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

-- The channels worth offering one at a time, and the ones worth offering as a
-- group.
--
-- Say, yell, emotes, guild, NPCs and whispers carry roleplay. Party, raid,
-- instance, officer and public channels are coordination by convention, and
-- eleven checkboxes to express "the usual five are off" is a wall of boxes that
-- says one thing.
--
-- The group is not removed outright, because the settings behind it are not only
-- about dialects: the Clean chat preset switches them all on so that spelling
-- and acronym expansion reach group chat, which is exactly where "lfm 2dps hc
-- +10 rio 2.4k" needs it most. One switch keeps that working and still gets four
-- rows off the panel.
E.IC_CHANNELS = {
	{ "say", "Say" }, { "yell", "Yell" }, { "emote", "Emotes" },
	{ "guild", "Guild" }, { "monster", "NPCs" }, { "whisper", "Whispers" },
}

E.OOC_CHANNELS = { "party", "raid", "instance", "officer", "channel" }

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
	--
	-- Only the in-character channels by default, mirroring the outgoing list.
	-- Party, raid, instance, guild, officer and public channels are coordination
	-- by convention -- dialecting "interrupt now, bloodlust on pull" makes the
	-- useful chat harder to read rather than more immersive.
	--
	-- Whispers are off on both sides. In-character whispering is conventionally
	-- done in /say with a "[low]" tag, so that nearby characters get the chance
	-- to overhear -- which leaves the actual whisper channel as out-of-character
	-- traffic, like party and guild.
	-- There was an "enabled" here as well: a second master switch, checked
	-- alongside db.enabled on the same line in Chat.lua, defaulted true, set true
	-- by every preset and set false by nothing at all. One master switch is
	-- enough, and db.enabled is the one with a control.
	incoming = {
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
		monster  = false,
		-- Chat bubbles are a separate render path from the chat frame; see
		-- Core/Bubbles.lua.
		bubbles  = true,
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
	--
	-- `incoming = false` means the filter runs on your own outgoing text but not
	-- on other people's. The Spell Book defaults that way on purpose: correcting
	-- someone else's spelling means sanding off deliberate speech quirks -- rolled
	-- Rs, stretched vowels, shouted names -- which on a roleplaying realm is
	-- destroying authored voice rather than tidying a typo. Fixing your own typos
	-- on the way out is still useful, so it stays on for that.
	modules = {
		spellbook     = { enabled = true,  strength = 2, incoming = false },
		decompression = { enabled = true,  strength = 2 },
		mouthwash     = { enabled = false, strength = 2 },
		fantasy       = { enabled = false, strength = 2 },
		dialect       = { enabled = true,  strength = 2 },
		-- Personal speech effects. Off by default and self only: they describe
		-- how your character speaks, so they are applied to your outgoing text
		-- and never to anyone else's. See Modules/Lisp.lua.
		lisp          = { enabled = false, strength = 2 },
		muffle        = { enabled = false, strength = 2 },
	},

	dialect = {
		races      = {},     -- englishRace -> false to mute a single race
		selfRace   = false,  -- override the dialect used for your own outgoing text
		selfClass  = false,  -- override the class layer used for your own text
		-- Class decides what a speaker would never say: a Death Knight does not
		-- invoke the Light, whatever their race offers. See Core/Class.lua.
		classFlavor = true,
		applyToSelf = false, -- also dialect your own messages in your chat frame
	},

	cleanup = {
		urls          = true,
		shortChannels = false,
		-- "classColors" was here and nothing read it. Eloquence used to colour
		-- sender names and got it wrong; the client does this natively, so the
		-- feature went and the setting stayed behind.
	},
}

-- Who sees your own chat in dialect.
--
-- Two settings back this, and the panel used to expose both: "Rewrite my
-- outgoing chat" (outgoing.enabled) and, four sections further down, "Also apply
-- a dialect to my own messages" (dialect.applyToSelf). They read as two ways of
-- saying one thing. They are not -- one changes what leaves your client, the
-- other only changes what you see -- but they are not independent either:
-- Chat.ShouldFilterSelf refuses to dialect your own incoming copy while outgoing
-- rewriting is on, because that copy was already rewritten on the way out.
--
-- So the four tick combinations only ever produced three behaviours, and the
-- fourth silently ignored a box the player had ticked. Three behaviours want one
-- three-way control.
--
-- These live here rather than in the options panel because they are the meaning
-- of the settings rather than a way of drawing them: the slash command needs the
-- same three states, and Init loads first.
E.SELF_MODES = { "Off", "Only me", "Everyone" }

function E.GetSelfMode()
	if E.db.outgoing.enabled then return 3 end
	if E.db.dialect.applyToSelf then return 2 end
	return 1
end

function E.SetSelfMode(mode)
	if mode == 3 then
		-- applyToSelf is left as it was: it is inert while this is on, and
		-- preserving it means dropping back to "Only me" remembers the choice.
		E.db.outgoing.enabled = true
	else
		E.db.outgoing.enabled = false
		E.db.dialect.applyToSelf = (mode == 2)
	end
end

-- Speaking as somebody else.
--
-- `dialect.selfRace` and `dialect.selfClass` override the dialect and class
-- layer used for your own speech. Both worked from the start and neither could
-- be set: no command, no control, saved-variable editing only. That is the third
-- setting to ship that way, after the class layer and applyToSelf.
--
-- The reason to have it at all is that a character's accent is not their
-- biology. A Night Elf raised in Ironforge sounds like Ironforge; a Forsaken who
-- was Gilnean in life kept the vowels. The addon defaulting to your race is a
-- good guess and a bad rule, and this only ever changes how *you* sound, so
-- there is nothing here to use against anybody else.
--
-- `false` means "whatever I actually am".
function E.SetSpeakAs(race)
	E.db.dialect.selfRace = race or false
end

function E.GetSpeakAs()
	return E.db.dialect.selfRace or false
end

function E.SetSpeakClass(token)
	E.db.dialect.selfClass = token or false
end

function E.GetSpeakClass()
	return E.db.dialect.selfClass or false
end

-- The choices, in the order they should be offered: "my own" first, then every
-- dialect by name. Returns a list of { value, label }, where `value` is false
-- for the default.
function E.SpeakAsChoices()
	local _, own = UnitRace("player")
	local choices = {
		{ value = false, label = "My own (" .. (own or "unknown") .. ")" },
	}
	for _, race in ipairs(E.Race.KnownDialects()) do
		local dialect = E.DIALECTS[race]
		choices[#choices + 1] = {
			value = race,
			label = (dialect and dialect.name or race) .. " (" .. race .. ")",
		}
	end
	return choices
end

function E.SpeakClassChoices()
	local choices = { { value = false, label = "My own class" } }
	local tokens = {}
	for token in pairs(E.CLASSES) do tokens[#tokens + 1] = token end
	table.sort(tokens)
	for _, token in ipairs(tokens) do
		choices[#choices + 1] = { value = token, label = E.CLASSES[token].name or token }
	end
	return choices
end

-- Find a choice by anything a player might reasonably type: the race token, the
-- dialect's name, or either with the spaces and punctuation left out.
local function Loosen(text)
	return (tostring(text):lower():gsub("[^%a]", ""))
end

local function MatchChoice(choices, wanted)
	local want = Loosen(wanted)
	if want == "" then return nil end
	for _, choice in ipairs(choices) do
		if choice.value then
			if Loosen(choice.value) == want then return choice end
		end
	end
	-- Second pass over the display names, so "Dark Iron" and "Ren'dorei" work.
	for _, choice in ipairs(choices) do
		if choice.value and Loosen(choice.label):find(want, 1, true) then return choice end
	end
	return nil
end

E.MatchSpeakChoice = MatchChoice

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
