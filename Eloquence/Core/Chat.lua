-- Eloquence: hooking the chat system.
--
-- Incoming is the primary direction and the one the original addon was built
-- around: everything is done with ChatFrame_AddMessageEventFilter, which is the
-- sanctioned way to rewrite a chat line before it is displayed. Nothing is sent
-- to the server and nothing is protected, so there is no taint risk at all.
--
-- Outgoing is opt-in, because it changes what you actually say. The wrapper
-- around SendChatMessage is only installed once you turn it on, so a player who
-- never enables it never carries the extra surface.
local ADDON, E = ...

local Chat = {}
E.Chat = Chat

--------------------------------------------------------------------------------
-- Incoming
--------------------------------------------------------------------------------

-- Chat payload layout (retail): arg1 text, arg2 sender, arg3 language,
-- ... arg12 sender GUID. Declaring (self, event, text, sender, ...) leaves the
-- varargs starting at arg3, so arg12 lives at index 10 and arg3 at index 1.
local LANGUAGE_INDEX = 1
local GUID_INDEX = 10

local function ShouldFilterSelf(guid)
	local db = E.db
	-- If we are already rewriting outgoing text, the copy that comes back has
	-- been transformed once already -- do not do it twice.
	if db.outgoing.enabled then return false end
	return db.dialect.applyToSelf
end

local function MakeFilter(settingKey)
	return function(_, event, text, sender, ...)
		local db = E.db
		if not db or not db.enabled or not db.incoming.enabled then return false end
		if not db.incoming[settingKey] then return false end
		if not text or text == "" then return false end

		local language = select(LANGUAGE_INDEX, ...)
		local guid = select(GUID_INDEX, ...)

		if guid and guid ~= "" and guid == UnitGUID("player") and not ShouldFilterSelf(guid) then
			return false
		end

		local race
		if settingKey ~= "monster" then
			race = E.Race.Resolve(guid, sender)
		end

		local result = E.Pipeline.Run(text, guid, race, language)
		if result and result ~= text then
			return false, result, sender, ...
		end
		return false
	end
end

-- Recorded so /elo doctor can prove the filters actually attached.
Chat.installedFilters = 0

function Chat.InstallIncoming()
	for event, settingKey in pairs(E.CHANNELS) do
		ChatFrame_AddMessageEventFilter(event, MakeFilter(settingKey))
		Chat.installedFilters = Chat.installedFilters + 1
	end
end

--------------------------------------------------------------------------------
-- Outgoing
--------------------------------------------------------------------------------

local outgoingInstalled = false
local sending = false

-- WoW caps a chat message at 255 bytes. A dialect can easily make a message
-- longer ("I don't know" -> "Ah dinnae ken"), so anything that overflows is
-- split on word boundaries rather than truncated.
local MAX_BYTES = 255

local function TransformOutgoing(text, chatType)
	local db = E.db
	if not db or not db.enabled or not db.outgoing.enabled then return nil end

	local settingKey = E.OUTGOING_TYPES[chatType or "SAY"]
	if not settingKey or not db.outgoing[settingKey] then return nil end
	if E.Pipeline.ShouldSkip(text) then return nil end

	local race = E.Race.Player()
	local result = E.Pipeline.Run(text, UnitGUID("player"), race, nil)
	if not result or result == text then return nil end
	return result
end

function Chat.EnsureOutgoingHook()
	if outgoingInstalled then return end
	outgoingInstalled = true

	local original = SendChatMessage
	Chat.originalSendChatMessage = original

	-- SendChatMessage takes exactly (message, chatType, languageID, target).
	SendChatMessage = function(text, chatType, languageID, target)
		if sending or type(text) ~= "string" then
			return original(text, chatType, languageID, target)
		end

		local ok, transformed = pcall(TransformOutgoing, text, chatType)
		if not ok or not transformed then
			return original(text, chatType, languageID, target)
		end

		local chunks
		if #transformed <= MAX_BYTES then
			chunks = { transformed }
		else
			ok, chunks = pcall(E.SplitMessage, transformed, MAX_BYTES)
			if not ok or type(chunks) ~= "table" or #chunks == 0 then
				return original(text, chatType, languageID, target)
			end
		end

		sending = true
		local sent = true
		for _, chunk in ipairs(chunks) do
			if not pcall(original, chunk, chatType, languageID, target) then
				sent = false
				break
			end
		end
		sending = false

		-- Never swallow a message because our rewrite misbehaved.
		if not sent then
			return original(text, chatType, languageID, target)
		end
	end
	E.Debug("outgoing hook installed")
end

function Chat.IsOutgoingHooked()
	return outgoingInstalled
end

--------------------------------------------------------------------------------

E.OnLogin("Chat", function()
	Chat.InstallIncoming()
	if E.db.outgoing.enabled then
		Chat.EnsureOutgoingHook()
	end
end)
