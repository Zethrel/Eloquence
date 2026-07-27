-- A minimal stand-in for the WoW client, enough to load Eloquence's logic
-- outside the game. Only the APIs the addon actually touches are stubbed.
--
-- Run with: lua Tests/run.lua   (Lua 5.1 or later)

local stub = {}

-- Events retired from modern retail. RegisterEvent on one of these raises a Lua
-- error in the real client, so the stub raises too -- otherwise a stale event
-- name sails through the suite and only fails in game, which is exactly what
-- happened once already.
stub.retiredEvents = {
	LEARNED_SPELL_IN_TAB = true,
	UNIT_QUEST_LOG_CHANGED_OBSOLETE = true,
}

-- Widgets: every method is a no-op that returns the frame, so long chains of
-- SetPoint():SetSize() style calls do not blow up.
local function NewFrame()
	local frame = { _events = {} }
	local methods = {
		RegisterEvent = function(self, event)
			if stub.retiredEvents[event] then
				error("Attempt to register unknown event '" .. tostring(event) .. "'", 2)
			end
			self._events[event] = true
		end,
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

	env.InCombatLockdown = function() return env._inCombat == true end
	env._inCombat = false

	-- The Settings API, modelling the 12.0 contract that matters:
	-- Settings.OpenToCategory forwards the ID to C_SettingsUtil.OpenSettingsPanel,
	-- which takes an *integer*. Passing the addon name -- as every
	-- Dragonflight-era guide recommends -- raises
	--   bad argument #1 to 'OpenSettingsPanel' (outside of expected range ...)
	-- Categories therefore get numeric IDs here and OpenToCategory rejects
	-- anything else, so the mistake fails the suite instead of only in game.
	local nextCategoryID = 100
	env._openedCategories = {}
	env.Settings = {
		RegisterCanvasLayoutCategory = function(frame, name)
			nextCategoryID = nextCategoryID + 1
			local category = { ID = nextCategoryID, name = name, frame = frame }
			function category:GetID() return self.ID end
			return category
		end,
		RegisterAddOnCategory = function(category)
			env._registeredCategory = category
		end,
		OpenToCategory = function(categoryID)
			if type(categoryID) ~= "number" then
				error(("bad argument #1 to 'OpenSettingsPanel' (outside of expected "
					.. "range -2147483648 to 2147483647), got %s"):format(tostring(categoryID)), 2)
			end
			table.insert(env._openedCategories, categoryID)
		end,
	}

	-- Patch 12.0's chat send path. Addons hook ChatFrame.OnEditBoxPreSendText
	-- and rewrite the edit box contents; the client then sends whatever the box
	-- holds. `stub.typeIntoChat` below drives the whole sequence.
	env.EventRegistry = {
		_callbacks = {},
		RegisterCallback = function(self, event, fn, owner)
			self._callbacks[event] = self._callbacks[event] or {}
			table.insert(self._callbacks[event], { fn = fn, owner = owner })
		end,
		TriggerEvent = function(self, event, ...)
			for _, entry in ipairs(self._callbacks[event] or {}) do
				entry.fn(entry.owner, ...)
			end
		end,
	}

	-- A stand-in chat edit box.
	function env.NewEditBox(text, chatType)
		local box = { _text = text, _chatType = chatType or "SAY" }
		function box:GetText() return self._text end
		function box:SetText(v) self._text = v end
		function box:GetAttribute(key)
			if key == "chatType" then return self._chatType end
		end
		return box
	end

	-- Chat bubbles. The client draws these straight from the chat event, so they
	-- never pass through a chat filter and have to be rewritten by finding the
	-- FontString after the fact. Modelled closely enough to test that: bubbles
	-- appear only after a delay, some are forbidden and must be left alone, and
	-- the text lives on a FontString nested one level down.
	env._time = 1000
	env.GetTime = function() return env._time end

	env._bubbles = {}
	env.C_ChatBubbles = {
		GetAllChatBubbles = function() return env._bubbles end,
	}

	-- Build a bubble shaped like the real thing: frame -> child -> FontString.
	function env.NewChatBubble(text, forbidden)
		local fontString = {
			_text = text,
			GetObjectType = function() return "FontString" end,
			IsForbidden = function() return false end,
		}
		function fontString:GetText() return self._text end
		function fontString:SetText(v) self._text = v end

		local child = {
			IsForbidden = function() return false end,
			GetRegions = function() return fontString end,
			GetChildren = function() return end,
		}
		local bubble = {
			IsForbidden = function() return forbidden == true end,
			GetChildren = function() return child end,
			GetRegions = function() return end,
			_fontString = fontString,
		}
		table.insert(env._bubbles, bubble)
		return bubble
	end

	-- Timers the test can pump by hand.
	env._tickers = {}
	env.C_Timer = {
		NewTicker = function(interval, callback)
			local handle = { interval = interval, callback = callback, cancelled = false }
			function handle:Cancel() self.cancelled = true end
			table.insert(env._tickers, handle)
			return handle
		end,
		After = function(_, callback) callback() end,
	}

	-- The modern client exposes this so addons can check before registering.
	-- Backed by the same retired-event list that RegisterEvent raises on.
	env._retiredEvents = stub.retiredEvents
	env.C_EventUtils = {
		IsEventValid = function(event)
			return not stub.retiredEvents[event]
		end,
	}

	-- Lua 5.4 dropped the global unpack that WoW's 5.1 provides.
	if not env.unpack then env.unpack = table.unpack end

	return env
end

-- The load order, which must match Eloquence.toc exactly. Tests/run.lua asserts
-- that it does: a file that exists and loads here but is missing from the TOC
-- would pass every test and then not load in the game at all.
stub.FILES = {
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
	"Core/Pipeline.lua", "Core/Bubbles.lua", "Core/Chat.lua", "Core/Cleanup.lua",
	"Core/Options.lua", "Core/Presets.lua", "Core/Commands.lua",
}

-- Load the addon files in TOC order and return the private namespace.
function stub.loadAddon(root)
	root = root or "Eloquence"
	local E = {}

	for _, relative in ipairs(stub.FILES) do
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

-- Drive the full 12.0 send sequence: the client fires the pre-send callback,
-- addons may rewrite the edit box, then the client sends whatever it now holds.
-- Returns the text that actually went out.
function stub.typeIntoChat(env, text, chatType)
	local box = env.NewEditBox(text, chatType or "SAY")
	env.EventRegistry:TriggerEvent("ChatFrame.OnEditBoxPreSendText", box)
	env._sent = {}
	env.SendChatMessage(box:GetText(), box:GetAttribute("chatType"))
	return env._sent[1] and env._sent[1][1]
end

-- Fire the deferred PLAYER_LOGIN work, mirroring what Core/Init.lua does in the
-- game: each module isolated by pcall, failures recorded rather than thrown.
-- Tests then assert the error list is empty, so a real failure is still loud.
function stub.login(E)
	for _, entry in ipairs(E.onLogin or {}) do
		local ok, err = pcall(entry.fn)
		if not ok then
			E.initErrors[#E.initErrors + 1] = { name = entry.name, err = tostring(err) }
		end
	end
end

return stub
