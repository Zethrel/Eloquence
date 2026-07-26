-- A minimal stand-in for the WoW client, enough to load Eloquence's logic
-- outside the game. Only the APIs the addon actually touches are stubbed.
--
-- Run with: lua Tests/run.lua   (Lua 5.1 or later)

local stub = {}

-- Widgets: every method is a no-op that returns the frame, so long chains of
-- SetPoint():SetSize() style calls do not blow up.
local function NewFrame()
	local frame = { _events = {} }
	local methods = {
		RegisterEvent = function(self, event) self._events[event] = true end,
		UnregisterEvent = function(self, event) self._events[event] = nil end,
		SetScript = function(self, which, fn) self["_" .. which] = fn end,
		GetScript = function(self, which) return self["_" .. which] end,
		Fire = function(self, event, ...)
			if self._OnEvent then self._OnEvent(self, event, ...) end
		end,
		CreateFontString = function() return NewFrame() end,
		GetStringHeight = function() return 12 end,
		GetChecked = function(self) return self._checked end,
		SetChecked = function(self, v) self._checked = v end,
	}
	return setmetatable(frame, {
		__index = function(t, key)
			if methods[key] then return methods[key] end
			return function() return t end
		end,
	})
end

function stub.install(env)
	env = env or _G

	env.CreateFrame = function() return NewFrame() end
	env.UIParent = NewFrame()
	env.GameTooltip = NewFrame()
	env.GameTooltip_Hide = function() end
	env.StaticPopupDialogs = {}
	env.StaticPopup_Show = function() end
	env.SlashCmdList = {}
	env.CLOSE = "Close"
	env.hooksecurefunc = function() end
	env.ChatFrame_AddMessageEventFilter = function(event, fn)
		env._filters = env._filters or {}
		env._filters[event] = env._filters[event] or {}
		table.insert(env._filters[event], fn)
	end
	env.SendChatMessage = function(...)
		env._sent = env._sent or {}
		table.insert(env._sent, { ... })
	end

	-- Player / unit information.
	env._playerRace = "Human"
	env._playerGUID = "Player-1-0000AAAA"
	env.UnitGUID = function(unit) return unit == "player" and env._playerGUID or nil end
	env.UnitRace = function(unit)
		if unit == "player" then return env._playerRace, env._playerRace end
	end
	env.UnitName = function() return nil end
	env.UnitExists = function() return false end
	env.UnitIsPlayer = function() return false end
	env.IsInRaid = function() return false end
	env.IsInGroup = function() return false end

	-- GUID -> race table the tests can populate.
	env._guidRaces = {}
	env.GetPlayerInfoByGUID = function(guid)
		local entry = env._guidRaces[guid]
		if not entry then return nil end
		return entry.class or "Warrior", (entry.class or "WARRIOR"):upper(),
			entry.race, entry.race, 2, entry.name or "Tester", ""
	end

	-- Languages the character understands.
	env._languages = { "Common", "Orcish" }
	env.GetNumLanguages = function() return #env._languages end
	env.GetLanguageByIndex = function(i) return env._languages[i] end

	env.RAID_CLASS_COLORS = {
		WARRIOR = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
	}

	-- Lua 5.4 dropped the global unpack that WoW's 5.1 provides.
	if not env.unpack then env.unpack = table.unpack end

	return env
end

-- Load the addon files in TOC order and return the private namespace.
function stub.loadAddon(root)
	root = root or "Eloquence"
	local E = {}
	local files = {
		"Core/Init.lua", "Core/Util.lua", "Core/Engine.lua", "Core/Race.lua",
		"Dialects/Human.lua", "Dialects/Dwarf.lua", "Dialects/Gnome.lua",
		"Dialects/NightElf.lua", "Dialects/Draenei.lua", "Dialects/Worgen.lua",
		"Dialects/Orc.lua", "Dialects/Troll.lua", "Dialects/Tauren.lua",
		"Dialects/Scourge.lua", "Dialects/BloodElf.lua", "Dialects/Goblin.lua",
		"Dialects/Pandaren.lua", "Dialects/ZandalariTroll.lua",
		"Dialects/Nightborne.lua", "Dialects/VoidElf.lua", "Dialects/KulTiran.lua",
		"Dialects/Vulpera.lua", "Dialects/Dracthyr.lua", "Dialects/EarthenDwarf.lua",
		"Dialects/Harronir.lua",
		"Dialects/Variants.lua",
		"Modules/SpellBook.lua", "Modules/Decompression.lua", "Modules/Mouthwash.lua",
		"Modules/FantasyWriter.lua", "Modules/Dialectician.lua",
		"Core/Pipeline.lua", "Core/Chat.lua", "Core/Cleanup.lua",
		"Core/Options.lua", "Core/Commands.lua",
	}

	for _, relative in ipairs(files) do
		local path = root .. "/" .. relative
		local chunk, err = loadfile(path)
		if not chunk then
			error("failed to load " .. path .. ": " .. tostring(err))
		end
		chunk("Eloquence", E)
	end

	-- ADDON_LOADED normally does this.
	E.db = E.CopyDefaults(E.DEFAULTS, {})
	return E
end

-- Fire the deferred PLAYER_LOGIN work.
function stub.login(E)
	for _, fn in ipairs(E.onLogin or {}) do fn() end
end

return stub
