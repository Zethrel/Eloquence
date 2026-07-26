-- Eloquence: the options panel.
--
-- Built from plain widgets on a canvas category rather than the declarative
-- Settings helpers, because the canvas API and the handful of templates used
-- here (UICheckButtonTemplate, UIPanelButtonTemplate) have been stable for
-- years, while the declarative helper signatures have shifted between patches.
local ADDON, E = ...

local STRENGTH_LABELS = { "Light", "Medium", "Heavy" }

local panel = CreateFrame("Frame")
panel.name = "Eloquence"

local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 12, -12)
scroll:SetPoint("BOTTOMRIGHT", -30, 12)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(560, 1)
scroll:SetScrollChild(content)

local y = 0
local COL = { 8, 200, 380 }

local function Advance(px)
	y = y - px
end

local function MakeTitle(text, size)
	local fs = content:CreateFontString(nil, "ARTWORK", size or "GameFontNormalLarge")
	fs:SetPoint("TOPLEFT", COL[1], y)
	fs:SetText(text)
	Advance(26)
	return fs
end

local function MakeNote(text)
	local fs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	fs:SetPoint("TOPLEFT", COL[1] + 4, y)
	fs:SetWidth(520)
	fs:SetJustifyH("LEFT")
	fs:SetText(text)
	Advance(fs:GetStringHeight() + 10)
	return fs
end

local allCheckboxes = {}

local function MakeCheck(column, label, tooltip, get, set, width)
	local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
	cb:SetSize(24, 24)
	cb:SetPoint("TOPLEFT", COL[column], y)

	local fs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fs:SetPoint("LEFT", cb, "RIGHT", 2, 1)
	fs:SetWidth(width or 150)
	fs:SetJustifyH("LEFT")
	fs:SetText(label)

	cb:SetScript("OnClick", function(self)
		set(self:GetChecked() and true or false)
	end)
	if tooltip then
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(label, 1, 1, 1)
			GameTooltip:AddLine(tooltip, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		cb:SetScript("OnLeave", GameTooltip_Hide)
	end

	cb.Refresh = function(self) self:SetChecked(get() and true or false) end
	allCheckboxes[#allCheckboxes + 1] = cb
	return cb
end

-- A three-state cycling button beats a slider here: fewer template
-- dependencies, and "Light / Medium / Heavy" is clearer than "2".
local function MakeStrengthButton(column, get, set)
	local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
	btn:SetSize(90, 22)
	btn:SetPoint("TOPLEFT", COL[column], y + 1)
	btn:SetScript("OnClick", function(self)
		local current = get() or 2
		set(current % 3 + 1)
		self:Refresh()
	end)
	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Filter strength", 1, 1, 1)
		GameTooltip:AddLine("How aggressively this filter rewrites text. Click to cycle.", nil, nil, nil, true)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", GameTooltip_Hide)
	btn.Refresh = function(self)
		self:SetText(STRENGTH_LABELS[get() or 2] or "Medium")
	end
	allCheckboxes[#allCheckboxes + 1] = btn
	return btn
end

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

local function Build()
	MakeTitle("Eloquence " .. E.VERSION)
	MakeNote("A revival of the classic roleplaying chat addon, by |cffffff80" .. E.AUTHOR
		.. "|r of " .. E.REALM .. ". Filters are applied to the chat you read; "
		.. "rewriting your own outgoing messages is opt-in below.")

	MakeCheck(1, "Enable Eloquence", "Master switch for every filter.",
		function() return E.db.enabled end,
		function(v) E.db.enabled = v end, 200)
	Advance(30)

	-- Filters -----------------------------------------------------------------
	MakeTitle("Filters", "GameFontNormal")
	for _, key in ipairs(E.MODULE_ORDER) do
		local module = E.MODULES[key]
		if module then
			local settings = key
			MakeCheck(1, module.name, module.desc,
				function() return E.db.modules[settings].enabled end,
				function(v) E.db.modules[settings].enabled = v end, 180)
			MakeStrengthButton(3,
				function() return E.db.modules[settings].strength end,
				function(v) E.db.modules[settings].strength = v end)
			Advance(28)
		end
	end
	Advance(8)

	-- Incoming ----------------------------------------------------------------
	MakeTitle("Filter which incoming chat", "GameFontNormal")
	local incoming = {
		{ "say", "Say" }, { "yell", "Yell" }, { "emote", "Emotes" },
		{ "whisper", "Whispers" }, { "party", "Party" }, { "raid", "Raid" },
		{ "instance", "Instance" }, { "guild", "Guild" }, { "officer", "Officer" },
		{ "channel", "Channels" }, { "monster", "NPCs" },
	}
	for i, entry in ipairs(incoming) do
		local key = entry[1]
		local column = ((i - 1) % 3) + 1
		MakeCheck(column, entry[2], nil,
			function() return E.db.incoming[key] end,
			function(v) E.db.incoming[key] = v end, 130)
		if column == 3 then Advance(26) end
	end
	if #incoming % 3 ~= 0 then Advance(26) end
	Advance(10)

	-- Outgoing ----------------------------------------------------------------
	MakeTitle("Your own outgoing chat", "GameFontNormal")
	MakeNote("|cffff8080Changes what you actually send.|r Other players see the dialect, and messages that "
		.. "grow past the 255-character limit are split across several lines.")
	MakeCheck(1, "Rewrite my outgoing chat", "Applies your race's dialect to messages you send.",
		function() return E.db.outgoing.enabled end,
		function(v)
			E.db.outgoing.enabled = v
			if v then E.Chat.EnsureOutgoingHook() end
		end, 260)
	Advance(30)

	local outgoing = {
		{ "say", "Say" }, { "yell", "Yell" }, { "emote", "Emotes" },
		{ "whisper", "Whispers" }, { "party", "Party" }, { "raid", "Raid" },
		{ "instance", "Instance" }, { "guild", "Guild" }, { "officer", "Officer" },
		{ "channel", "Channels" },
	}
	for i, entry in ipairs(outgoing) do
		local key = entry[1]
		local column = ((i - 1) % 3) + 1
		MakeCheck(column, entry[2], nil,
			function() return E.db.outgoing[key] end,
			function(v) E.db.outgoing[key] = v end, 130)
		if column == 3 then Advance(26) end
	end
	if #outgoing % 3 ~= 0 then Advance(26) end
	Advance(10)

	-- Presentation ------------------------------------------------------------
	MakeTitle("Presentation", "GameFontNormal")
	MakeCheck(1, "Clickable trimmed links", "Shortens long URLs and makes them clickable to copy.",
		function() return E.db.cleanup.urls end,
		function(v) E.db.cleanup.urls = v end, 180)
	MakeCheck(2, "Short channel names", "Renders \"1. General\" as \"1. G\".",
		function() return E.db.cleanup.shortChannels end,
		function(v) E.db.cleanup.shortChannels = v end, 170)
	MakeCheck(3, "Class-coloured names", "Colours sender names by class.",
		function() return E.db.cleanup.classColors end,
		function(v) E.db.cleanup.classColors = v end, 170)
	Advance(36)

	-- Dialects ----------------------------------------------------------------
	MakeTitle("Dialects", "GameFontNormal")
	MakeNote("Untick a race to leave its speakers alone. Allied races inherit their parent culture's speech.")
	local races = E.Race.KnownDialects()
	for i, race in ipairs(races) do
		local dialect = E.DIALECTS[race]
		local column = ((i - 1) % 3) + 1
		MakeCheck(column, dialect.name, dialect.desc,
			function() return E.db.dialect.races[race] ~= false end,
			-- `v and nil or false` would always be false; spell it out.
			function(v)
				if v then E.db.dialect.races[race] = nil else E.db.dialect.races[race] = false end
			end, 150)
		if column == 3 then Advance(26) end
	end
	if #races % 3 ~= 0 then Advance(26) end
	Advance(10)

	MakeCheck(1, "Also apply a dialect to my own messages",
		"Shows your own chat in your race's dialect, without changing what you send.",
		function() return E.db.dialect.applyToSelf end,
		function(v) E.db.dialect.applyToSelf = v end, 340)
	Advance(40)

	content:SetHeight(-y + 20)
end

local function Refresh()
	for _, widget in ipairs(allCheckboxes) do
		widget:Refresh()
	end
end

panel:SetScript("OnShow", Refresh)
E.RefreshOptions = Refresh

E.OnLogin(function()
	Build()
	Refresh()

	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(panel, "Eloquence")
		category.ID = "Eloquence"
		Settings.RegisterAddOnCategory(category)
		E.settingsCategory = category
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	end
end)

function E.OpenOptions()
	if Settings and Settings.OpenToCategory and E.settingsCategory then
		Settings.OpenToCategory(E.settingsCategory.ID)
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(panel)
		InterfaceOptionsFrame_OpenToCategory(panel)
	else
		E.Print("Could not open the options panel; use /elo for command-line options.")
	end
end
