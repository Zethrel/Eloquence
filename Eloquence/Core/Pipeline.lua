-- Eloquence: the filter pipeline.
--
-- One entry point that both the incoming chat filters and the outgoing hook use,
-- so a message you send reads the same way to you as it does to anyone else
-- running the addon.
local ADDON, E = ...

local Pipeline = {}
E.Pipeline = Pipeline

-- Messages Eloquence should never touch.
local function ShouldSkip(text)
	if not text or text == "" then return true end
	-- Slash commands and addon-ish payloads.
	if text:sub(1, 1) == "/" then return true end
	-- Nothing to do when the message is all escape sequences -- a bare item
	-- link, for instance. Measured on the prose only, so the words inside a
	-- link's display text do not count as something to translate.
	local prose = E.PlainText(text):gsub("[^%a]", "")
	if #prose < 2 then return true end
	return false
end

-- Would the player even understand this? If someone speaks Orcish at an
-- Alliance character, WoW has already replaced the text with gibberish -- there
-- is nothing to dialect, and mangling it further just looks broken.
--
-- This check must FAIL OPEN. It is the only thing standing between an incoming
-- message and the filters, and it is fed by an API that can legitimately return
-- nothing -- too early in login, or if the call moves in a future patch. A empty
-- language table used to mean "you understand nothing", which silently dropped
-- every incoming message while leaving outgoing (which passes no language at
-- all) working perfectly. Dialecting the occasional line of gibberish is a far
-- smaller failure than the whole incoming half of the addon going quiet.
local knownLanguages
local languageLookupFailed = false

local function RefreshLanguages()
	local found = {}
	local count = 0
	if type(GetNumLanguages) == "function" and type(GetLanguageByIndex) == "function" then
		local ok, total = pcall(GetNumLanguages)
		if ok and type(total) == "number" then
			for i = 1, total do
				local okName, name = pcall(GetLanguageByIndex, i)
				if okName and name and name ~= "" then
					found[name] = true
					count = count + 1
				end
			end
		end
	end
	knownLanguages = found
	languageLookupFailed = count == 0
end

local function Understood(language)
	if not language or language == "" then return true end
	if not knownLanguages then RefreshLanguages() end
	-- Nothing known means the lookup failed, not that the character is a mute.
	if languageLookupFailed then return true end
	return knownLanguages[language] == true
end

-- Exposed so the login/zone handlers and the test suite can force a re-read.
Pipeline.RefreshLanguages = RefreshLanguages

-- Exposed for /elo doctor.
function Pipeline.LanguageInfo()
	if not knownLanguages then RefreshLanguages() end
	local list = {}
	for name in pairs(knownLanguages) do list[#list + 1] = name end
	table.sort(list)
	return list, languageLookupFailed
end

E.OnLogin("Pipeline", function()
	RefreshLanguages()
	-- The set of known languages only changes on login or when a character
	-- learns one, which is rare enough that this is plenty.
	local f = CreateFrame("Frame")
	E.SafeRegisterEvent(f, "PLAYER_ENTERING_WORLD")
	-- LEARNED_SPELL_IN_TAB was retired; LEARNED_SPELL_IN_SKILL_LINE replaced it.
	-- Both are attempted and neither is required -- the language list only
	-- changes when a character learns a language, which is rare, and
	-- PLAYER_ENTERING_WORLD already covers every practical case.
	E.SafeRegisterEvent(f, "LEARNED_SPELL_IN_SKILL_LINE")
	E.SafeRegisterEvent(f, "LEARNED_SPELL_IN_TAB")
	f:SetScript("OnEvent", RefreshLanguages)
end)

Pipeline.Understood = Understood

-- Build the per-message context. Everything random downstream is driven from
-- `rng`, which is seeded from the speaker and the message so the same line
-- always renders identically.
function Pipeline.NewContext(text, guid, race, extraSeed)
	local seed = E.Hash((guid or "") .. "\0" .. text .. "\0" .. (extraSeed or ""))
	return {
		rng = E.NewRNG(seed),
		excitement = E.Excitement(text),
		race = race,
		dialect = race and E.Race.DialectFor(race) or nil,
		strength = 2,
	}
end

-- Run the enabled modules over `text`.
--   guid  - speaker GUID, used for race lookup and seeding
--   race  - optional pre-resolved race (the outgoing path knows it already)
function Pipeline.Run(text, guid, race, language)
	local db = E.db
	if not db or not db.enabled then return text end
	if ShouldSkip(text) then return text end
	if not Understood(language) then return text end

	local ctx = Pipeline.NewContext(text, guid, race)
	local original = text

	for _, key in ipairs(E.MODULE_ORDER) do
		local settings = db.modules[key]
		local module = E.MODULES[key]
		if module and settings and settings.enabled then
			-- Skip the dialect pass entirely when we could not work out a race.
			if key ~= "dialect" or ctx.dialect then
				ctx.strength = settings.strength or 2
				local ok, result = pcall(module.Filter, text, ctx)
				if ok and type(result) == "string" and result ~= "" then
					text = result
				elseif not ok then
					E.Debug("module error in", key, result)
				end
			end
		end
	end

	if text ~= original then
		E.Debug(original, "->", text)
	end
	return text
end

E.Pipeline.ShouldSkip = ShouldSkip
