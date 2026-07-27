-- Eloquence: the chat housekeeping the original addon shipped alongside the
-- linguistic filters -- clickable trimmed URLs, abbreviated channel headers and
-- class-coloured names.
local ADDON, E = ...

local gsub, find, sub, format = string.gsub, string.find, string.sub, string.format

local Cleanup = {}
E.Cleanup = Cleanup

--------------------------------------------------------------------------------
-- URLs
--------------------------------------------------------------------------------

local URL_COLOR = "|cff44b0ff"
local MAX_DISPLAY = 42

local function IsURL(s)
	if find(s, "^|") then return false end -- already an escape sequence
	return find(s, "^%a[%w%+%-%.]*://") ~= nil or find(s, "^www%.") ~= nil
end

-- Shorten for display while keeping enough to recognise the destination.
local function DisplayText(url)
	local shown = gsub(url, "^%a[%w%+%-%.]*://", "")
	shown = gsub(shown, "^www%.", "")
	if #shown <= MAX_DISPLAY then return shown end
	local host, rest = shown:match("^([^/]+)(/.*)$")
	if host then
		local room = MAX_DISPLAY - #host - 3
		if room > 4 then
			return host .. sub(rest, 1, room) .. "..."
		end
		return host .. "/..."
	end
	return E.SafeSub(shown, MAX_DISPLAY - 3) .. "..."
end

-- Custom link types are safe to build for display: they are only ever rendered
-- locally, never sent to the server.
local function Linkify(text)
	local segments = E.Tokenize(text)
	local changed = false
	for i = 1, #segments do
		local seg = segments[i]
		if seg.protected and IsURL(seg.text) then
			segments[i] = {
				protected = true,
				text = format("%s|Heloquence:url:%s|h[%s]|h|r", URL_COLOR, seg.text, DisplayText(seg.text)),
			}
			changed = true
		end
	end
	if not changed then return text end
	local parts = {}
	for i = 1, #segments do parts[i] = segments[i].text end
	return table.concat(parts)
end

Cleanup.Linkify = Linkify
Cleanup.DisplayText = DisplayText

StaticPopupDialogs["ELOQUENCE_COPY_URL"] = {
	text = "Eloquence: press Ctrl-C to copy this link.",
	button1 = CLOSE or "Close",
	hasEditBox = true,
	editBoxWidth = 350,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(self, data)
		local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
		if editBox then
			editBox:SetText(data or "")
			editBox:HighlightText()
			editBox:SetFocus()
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent and parent.Hide then parent:Hide() end
	end,
	EditBoxOnEscapePressed = function(self)
		local parent = self:GetParent()
		if parent and parent.Hide then parent:Hide() end
	end,
}

local function InstallURLHandler()
	-- hooksecurefunc rather than an override: our handler runs after the default
	-- one, which simply ignores link types it does not recognise. No taint.
	hooksecurefunc("SetItemRef", function(link)
		local url = link and link:match("^eloquence:url:(.+)$")
		if url then
			StaticPopup_Show("ELOQUENCE_COPY_URL", nil, nil, url)
		end
	end)
end

--------------------------------------------------------------------------------
-- Channel headers
--------------------------------------------------------------------------------

local CHANNEL_ABBREV = {
	["general"] = "G",
	["trade"] = "T",
	["localdefense"] = "LD",
	["worlddefense"] = "WD",
	["lookingforgroup"] = "LFG",
	["guildrecruitment"] = "GR",
	["newcomerchat"] = "NC",
	["services"] = "S",
}

-- Fall back to the initials of a multi-word name, or the first two letters.
local function Abbreviate(name)
	local key = gsub(name:lower(), "[^%a]", "")
	local known = CHANNEL_ABBREV[key]
	if known then return known end

	local initials = ""
	for word in name:gmatch("%a+") do
		initials = initials .. word:sub(1, 1):upper()
	end
	if #initials >= 2 then return initials end
	return name:sub(1, 2):upper()
end

Cleanup.Abbreviate = Abbreviate

--------------------------------------------------------------------------------
-- Class colours
--------------------------------------------------------------------------------

local function ClassColor(guid)
	if not guid or guid == "" or not find(guid, "^Player%-") then return nil end
	local _, englishClass = GetPlayerInfoByGUID(guid)
	if not englishClass then return nil end
	local colors = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[englishClass]
	if not colors then return nil end
	return colors.colorStr and ("|c" .. colors.colorStr) or format("|cff%02x%02x%02x",
		(colors.r or 1) * 255, (colors.g or 1) * 255, (colors.b or 1) * 255)
end

Cleanup.ClassColor = ClassColor

--------------------------------------------------------------------------------
-- Wiring
--------------------------------------------------------------------------------

-- One filter for all the presentation tweaks. Registered after the linguistic
-- filters so it sees the final text.
local function PresentationFilter(_, event, text, sender, language, channelName, ...)
	local db = E.db
	if not db or not db.enabled then return false end

	local newText, newSender, newChannel = text, sender, channelName
	local changed = false

	if db.cleanup.urls and text and (find(text, "://", 1, true) or find(text, "www%.")) then
		local linked = Linkify(text)
		if linked ~= text then newText, changed = linked, true end
	end

	if db.cleanup.shortChannels and channelName and channelName ~= "" then
		-- Channel names arrive as "1. General".
		local index, name = channelName:match("^(%d+)%.%s*(.+)$")
		if name then
			newChannel, changed = index .. ". " .. Abbreviate(name), true
		end
	end

	if db.cleanup.classColors and sender and sender ~= "" then
		-- Four payload args are named above, so arg12 sits at index 8.
		local guid = select(8, ...)
		local color = ClassColor(guid)
		if color and not find(sender, "|c", 1, true) then
			newSender, changed = color .. sender .. "|r", true
		end
	end

	if changed then
		return false, newText, newSender, language, newChannel, ...
	end
	return false
end

E.OnLogin("Cleanup", function()
	InstallURLHandler()
	for event in pairs(E.CHANNELS) do
		ChatFrame_AddMessageEventFilter(event, PresentationFilter)
	end
end)
