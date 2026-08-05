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

-- A caption sitting on the same row as a control, rather than the full-width
-- paragraph MakeNote produces.
local function MakeLabel(column, text)
	local fs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fs:SetPoint("TOPLEFT", COL[column], y - 4)
	fs:SetJustifyH("LEFT")
	fs:SetText(text)
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
	cb.label = label
	allCheckboxes[#allCheckboxes + 1] = cb
	-- Exposed so the tests can assert a setting is actually reachable here.
	-- A setting that only a slash command can reach is invisible to anyone who
	-- does not already know it exists, which is how the class layer shipped
	-- switchable but undiscoverable.
	E.optionsChecks = allCheckboxes
	return cb
end

local OOC_TOOLTIP = "Party, raid, instance, officer and public channels, together. "
	.. "These are coordination rather than roleplay almost all of the time, so they "
	.. "are one switch rather than five. The Clean chat preset still turns them on, "
	.. "which is where spelling and acronym expansion earn their keep."

-- One checkbox standing in for several settings that are always wanted together.
-- Reads as ticked if any of them is on, so a setting cannot be left switched on
-- behind a box that shows empty -- and unticking clears the lot.
--
-- `store` is a function rather than the table itself: the panel is built once,
-- and every other control here reaches through E.db on each access rather than
-- closing over whatever table happened to exist at build time.
local function MakeCheckGroup(column, label, tooltip, store)
	return MakeCheck(column, label, tooltip,
		function()
			for _, key in ipairs(E.OOC_CHANNELS) do
				if store()[key] then return true end
			end
			return false
		end,
		function(v)
			for _, key in ipairs(E.OOC_CHANNELS) do store()[key] = v end
		end, 340)
end

-- A cycling button beats a slider or a dropdown here: fewer template
-- dependencies, and "Light / Medium / Heavy" is clearer than "2".
local function MakeCycleButton(column, opts)
	local labels, get, set = opts.labels, opts.get, opts.set
	local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
	btn:SetSize(opts.width or 90, 22)
	btn:SetPoint("TOPLEFT", COL[column], y + 1)
	btn:SetScript("OnClick", function(self)
		local current = get() or opts.default or 1
		set(current % #labels + 1)
		self:Refresh()
		if opts.onSet then opts.onSet() end
	end)
	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(opts.title, 1, 1, 1)
		GameTooltip:AddLine(opts.tooltip, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", GameTooltip_Hide)
	btn.Refresh = function(self)
		self:SetText(labels[get() or opts.default or 1] or labels[1])
	end
	btn.label = opts.label or opts.title
	allCheckboxes[#allCheckboxes + 1] = btn
	E.optionsChecks = allCheckboxes
	return btn
end

-- A button showing one of many choices, opened as a menu.
--
-- The cycling button used elsewhere is fine for three options and useless for
-- twenty-seven, so this opens a list. `MenuUtil` is the modern client's context
-- menu and is called through pcall like everything else that might move between
-- patches; if it is not there, the button falls back to cycling, which is
-- clumsy but never a dead control.
local function MakeChoiceButton(column, opts)
	local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
	btn:SetSize(opts.width or 200, 22)
	btn:SetPoint("TOPLEFT", COL[column], y + 1)

	local function choices() return opts.choices() end

	local function currentIndex()
		local current = opts.get()
		for i, choice in ipairs(choices()) do
			if choice.value == current then return i end
		end
		return 1
	end

	btn.Refresh = function(self)
		local list = choices()
		self:SetText(list[currentIndex()] and list[currentIndex()].label or list[1].label)
	end

	btn:SetScript("OnClick", function(self)
		local list = choices()
		local opened = false
		if MenuUtil and MenuUtil.CreateContextMenu then
			opened = pcall(MenuUtil.CreateContextMenu, self, function(_, root)
				for _, choice in ipairs(list) do
					root:CreateButton(choice.label, function()
						opts.set(choice.value)
						self:Refresh()
						if opts.onSet then opts.onSet() end
					end)
				end
			end)
		end
		if not opened then
			-- No menu API: step to the next choice so the control still works.
			local nextChoice = list[currentIndex() % #list + 1]
			opts.set(nextChoice.value)
			self:Refresh()
			if opts.onSet then opts.onSet() end
		end
	end)

	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(opts.title, 1, 1, 1)
		GameTooltip:AddLine(opts.tooltip, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", GameTooltip_Hide)

	btn.label = opts.label or opts.title
	allCheckboxes[#allCheckboxes + 1] = btn
	E.optionsChecks = allCheckboxes
	return btn
end

local function MakeStrengthButton(column, get, set)
	return MakeCycleButton(column, {
		labels = STRENGTH_LABELS,
		default = 2,
		get = get,
		set = set,
		title = "Filter strength",
		tooltip = "How aggressively this filter rewrites text. Click to cycle.",
	})
end

local SELF_MODES, GetSelfMode, SetSelfMode = E.SELF_MODES, E.GetSelfMode, E.SetSelfMode

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

-- Forward declaration: the preset buttons built below need to call Refresh, which
-- is defined after them.
local Refresh

local function Build()
	MakeTitle("Eloquence " .. E.VERSION)
	MakeNote("A revival of the classic roleplaying chat addon, by |cffffff80" .. E.AUTHOR
		.. "|r of " .. E.REALM .. ". Filters are applied to the chat you read; "
		.. "rewriting your own outgoing messages is opt-in below.")

	MakeCheck(1, "Enable Eloquence", "Master switch for every filter.",
		function() return E.db.enabled end,
		function(v) E.db.enabled = v end, 200)
	Advance(30)

	-- Presets, so the common combinations are one click rather than a tour of
	-- every checkbox below.
	MakeTitle("Presets", "GameFontNormal")
	local column = 1
	for _, key in ipairs(E.Presets.order) do
		local preset = E.Presets.list[key]
		local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
		btn:SetSize(120, 22)
		btn:SetPoint("TOPLEFT", COL[column], y)
		btn:SetText(preset.name)
		btn:SetScript("OnClick", function()
			E.Presets.Apply(key)
			Refresh()
			E.Print("preset |cffffff80" .. preset.name .. "|r applied.")
		end)
		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(preset.name, 1, 1, 1)
			GameTooltip:AddLine(preset.desc, nil, nil, nil, true)
			GameTooltip:AddLine("Leaves outgoing sending and muted races alone.", 0.6, 0.6, 0.6, true)
			GameTooltip:Show()
		end)
		btn:SetScript("OnLeave", GameTooltip_Hide)
		column = column + 1
		if column > 3 then column = 1 Advance(26) end
	end
	if column ~= 1 then Advance(26) end
	Advance(10)

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
	for i, entry in ipairs(E.IC_CHANNELS) do
		local key = entry[1]
		local column = ((i - 1) % 3) + 1
		MakeCheck(column, entry[2], nil,
			function() return E.db.incoming[key] end,
			function(v) E.db.incoming[key] = v end, 130)
		if column == 3 then Advance(26) end
	end
	if #E.IC_CHANNELS % 3 ~= 0 then Advance(26) end
	MakeCheckGroup(1, "Group and coordination chat", OOC_TOOLTIP,
		function() return E.db.incoming end)
	Advance(26)
	MakeCheck(1, "Apply the Spell Book to other people's chat",
		"Off by default. Correcting someone else's spelling also erases deliberate "
		.. "speech quirks -- rolled Rs, stretched vowels, shouting. Your own outgoing "
		.. "typos are still fixed either way.",
		function() return E.db.modules.spellbook.incoming end,
		function(v) E.db.modules.spellbook.incoming = v end, 340)
	Advance(26)
	MakeCheck(1, "Also rewrite chat bubbles",
		"The bubble above a speaker's head is drawn separately from the chat "
		.. "frame, so it needs rewriting on its own. Say and yell only.",
		function() return E.db.incoming.bubbles end,
		function(v) E.db.incoming.bubbles = v end, 320)
	Advance(30)

	-- Your own chat -------------------------------------------------------------
	MakeTitle("My own chat", "GameFontNormal")
	MakeNote("Whether your own speech is dialected, and who sees it. "
		.. "|cffff8080\"Everyone\" changes what you actually send|r -- other players see "
		.. "the dialect, and messages that grow past the 255-character limit are "
		.. "split across several lines. \"Only me\" changes nothing you send; it just "
		.. "shows your own lines to you the way your character sounds.")
	MakeLabel(1, "Show my chat in dialect to")
	MakeCycleButton(2, {
		labels = SELF_MODES,
		default = 1,
		width = 110,
		label = "Show my chat in dialect to",
		get = GetSelfMode,
		set = SetSelfMode,
		onSet = function()
			if E.db.outgoing.enabled then E.Chat.EnsureOutgoingHook() end
			Refresh()
		end,
		title = "Who sees your dialect",
		tooltip = "Off -- your own chat is shown to you as you typed it.\n\n"
			.. "Only me -- your lines appear in your race's dialect in your own chat "
			.. "frame. Nothing you send changes and nobody else is affected.\n\n"
			.. "Everyone -- your messages are rewritten before they are sent, so "
			.. "everyone reads them in dialect. Click to cycle.",
	})
	Advance(30)

	MakeNote("Which of your own channels that applies to:")

	-- NPCs have no outgoing side, so this is the in-character list minus that one.
	local outgoing = {}
	for _, entry in ipairs(E.IC_CHANNELS) do
		if entry[1] ~= "monster" then outgoing[#outgoing + 1] = entry end
	end
	for i, entry in ipairs(outgoing) do
		local key = entry[1]
		local column = ((i - 1) % 3) + 1
		MakeCheck(column, entry[2], nil,
			function() return E.db.outgoing[key] end,
			function(v) E.db.outgoing[key] = v end, 130)
		if column == 3 then Advance(26) end
	end
	if #outgoing % 3 ~= 0 then Advance(26) end
	MakeCheckGroup(1, "Group and coordination chat", OOC_TOOLTIP,
		function() return E.db.outgoing end)
	Advance(26)
	Advance(10)

	-- Presentation ------------------------------------------------------------
	MakeTitle("Presentation", "GameFontNormal")
	MakeCheck(1, "Clickable trimmed links", "Shortens long URLs and makes them clickable to copy.",
		function() return E.db.cleanup.urls end,
		function(v) E.db.cleanup.urls = v end, 180)
	MakeCheck(2, "Short channel names", "Renders \"1. General\" as \"1. G\".",
		function() return E.db.cleanup.shortChannels end,
		function(v) E.db.cleanup.shortChannels = v end, 170)
	Advance(26)
	MakeNote("Class-coloured names are handled by the game itself -- Options, Social, "
		.. "\"Chat Class Colors\". Eloquence used to do this and got it wrong, "
		.. "so it no longer touches sender names.")
	Advance(10)

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

	-- Speaking as somebody else. A character's accent is not their biology: a
	-- Night Elf raised in Ironforge sounds like Ironforge, and a Forsaken who was
	-- Gilnean in life kept the vowels. Both settings worked from the start and
	-- neither could be reached without editing saved variables.
	MakeNote("Your character's accent need not match their race. A Night Elf raised "
		.. "in Ironforge sounds like Ironforge. This changes only how |cffffff80you|r sound.")
	MakeLabel(1, "I speak as")
	MakeChoiceButton(2, {
		label = "I speak as",
		width = 210,
		choices = E.SpeakAsChoices,
		get = E.GetSpeakAs,
		set = E.SetSpeakAs,
		title = "Speak as another race",
		tooltip = "Use another race's dialect for your own speech, whatever the "
			.. "client says you are. Everyone else is still rendered by their own race.",
	})
	Advance(26)
	MakeLabel(1, "and as a")
	MakeChoiceButton(2, {
		label = "and as a",
		width = 210,
		choices = E.SpeakClassChoices,
		get = E.GetSpeakClass,
		set = E.SetSpeakClass,
		title = "Speak as another class",
		tooltip = "Use another class layer for your own speech -- a paladin who "
			.. "was raised among warlocks, or a death knight who never lost the Light.",
	})
	Advance(30)

	-- The class layer has been switchable since it was added, but only from the
	-- command line -- which is no use to anyone who does not already know it is
	-- there. It is on by default and it changes what people say, so it belongs
	-- where the rest of the dialect settings are.
	MakeCheck(1, "Adjust speech for the speaker's class",
		"A death knight stops invoking the Light and a warlock speaks in bargains, "
		.. "on top of their race's accent. Untick to have everyone speak purely as "
		.. "their race does.",
		function() return E.db.dialect.classFlavor ~= false end,
		function(v) E.db.dialect.classFlavor = v end, 340)
	Advance(26)

	Advance(14)

	content:SetHeight(-y + 20)
end

function Refresh()
	for _, widget in ipairs(allCheckboxes) do
		widget:Refresh()
	end
end

panel:SetScript("OnShow", Refresh)
E.RefreshOptions = Refresh

E.OnLogin("Options", function()
	-- Registration first. Building the widgets is the part most likely to break
	-- on an API change, and if it throws, the panel should still exist and open
	-- (empty) rather than /elo silently doing nothing.
	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(panel, "Eloquence")
		-- Do NOT overwrite category.ID.
		--
		-- Every Dragonflight-era guide says to do `category.ID = panel.name`, and
		-- it is wrong on 12.0. Settings.OpenToCategory now forwards the ID to
		-- C_SettingsUtil.OpenSettingsPanel, which requires a *number*:
		--
		--   bad argument #1 to 'OpenSettingsPanel' (outside of expected range
		--   -2147483648 to 2147483647)   -- categoryID="Eloquence"
		--
		-- The Settings system assigns a numeric ID at registration. Clobbering it
		-- with the addon name is what made /elo throw and do nothing.
		Settings.RegisterAddOnCategory(category)
		E.settingsCategory = category
		E.optionsMethod = "settings"
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
		E.optionsMethod = "legacy"
	else
		E.optionsMethod = "none"
	end

	local ok, err = pcall(function()
		Build()
		Refresh()
	end)
	if not ok then
		E.optionsBuildError = tostring(err)
	end
end)

-- Opening the panel has more ways to fail quietly than anything else in the
-- addon, and Lua errors are hidden by default in retail (`/console scriptErrors
-- 1` shows them), so a failure here looks exactly like /elo doing nothing.
-- Every path therefore ends in either an open panel or a printed explanation.
function E.OpenOptions()
	if InCombatLockdown and InCombatLockdown() then
		E.Print("the options panel cannot be opened during combat. Try |cffffff80/elo status|r.")
		return
	end

	local category = E.settingsCategory
	if Settings and Settings.OpenToCategory and category then
		-- Whatever the Settings system assigned, untouched. On 12.0 this must be
		-- a number; passing the addon name throws inside OpenSettingsPanel.
		local id
		if category.GetID then
			local okID, live = pcall(category.GetID, category)
			if okID then id = live end
		end
		if id == nil then id = category.ID end

		local opened = id ~= nil and pcall(Settings.OpenToCategory, id)
		if not opened then
			-- Older clients accepted the category name. Harmless to try, and it
			-- is the only remaining option if the ID above was rejected.
			opened = pcall(Settings.OpenToCategory, "Eloquence")
		end
		if opened then
			-- Long-standing quirk: the first call sometimes only opens the
			-- settings window on the previous category.
			pcall(Settings.OpenToCategory, id)
			if E.optionsBuildError then
				E.Print("|cffffcc00the panel opened but failed to build:|r " .. E.optionsBuildError)
			end
			return
		end
	end

	if InterfaceOptionsFrame_OpenToCategory then
		pcall(InterfaceOptionsFrame_OpenToCategory, panel)
		pcall(InterfaceOptionsFrame_OpenToCategory, panel)
		return
	end

	E.Print("|cffff4040could not open the options panel.|r Everything is available from the "
		.. "command line -- try |cffffff80/elo help|r, or |cffffff80/elo doctor|r to see why.")
	if E.optionsBuildError then
		E.Print("panel build error: " .. E.optionsBuildError)
	end
end
