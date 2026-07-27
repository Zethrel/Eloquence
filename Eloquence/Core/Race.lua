-- Eloquence: working out who is talking, and therefore how they should sound.
--
-- This was the original addon's weakest point -- in 1.12 there was no reliable
-- way to learn a stranger's race from a chat message, so Eloquence guessed from
-- whatever it could scrape. Modern retail hands us the speaker's GUID as part of
-- the chat event, and GetPlayerInfoByGUID turns that straight into a race. That
-- single API makes the dialect system dramatically more accurate than it ever
-- was originally, so it is the primary path here; the unit scans below are only
-- fallbacks for the rare case where the client has no data cached for a GUID.
local ADDON, E = ...

local Race = {}
E.Race = Race

-- VERIFIED RACE TOKENS
--
-- These are the englishRace strings UnitRace actually returns, confirmed against
-- a live client with /dump select(2, UnitRace("player")), with race IDs:
--
--   Nightborne          27      MagharOrc           36
--   HighmountainTauren  28      Mechagnome          37
--   VoidElf             29      Dracthyr            52
--   LightforgedDraenei  30      EarthenDwarf        85
--   ZandalariTroll      31      Harronir            86
--   KulTiran            32
--   DarkIronDwarf       34
--   Vulpera             35
--
-- The thirteen classic races (Human, Dwarf, NightElf, Gnome, Draenei, Worgen,
-- Pandaren, Orc, Scourge, Tauren, Troll, BloodElf, Goblin) use their long-stable
-- tokens. Note Scourge, not Undead or Forsaken.
--
-- Do not "tidy" these into prettier spellings. Harronir in particular has two Rs
-- in the client but is widely written "Haranir" everywhere else, and getting it
-- wrong silently disables the dialect rather than raising an error.

-- Every playable race now has a dialect of its own, so this table is only for
-- token spelling variants and for anything Blizzard adds that we have not
-- written a dialect for yet.
--
-- It deliberately no longer maps allied races onto their parents. Doing that was
-- wrong in several places: Zandalari are Xhosa-voiced rather than Darkspear
-- Jamaican, and the earthen pointedly do not have the dwarven Scots accent.
local ALIAS = {
	-- Defensive: both earthen (IDs 84 and 85) are expected to report
	-- "EarthenDwarf", but only 85 has been seen directly.
	Earthen = "EarthenDwarf",
	-- The client reports "Harronir" (race ID 86). Much community writing spells
	-- it "Haranir", so accept that too.
	Haranir = "Harronir",
}
Race.ALIAS = ALIAS

-- englishRace -> race whose dialect file we should use.
function Race.Canonical(race)
	if not race then return nil end
	return ALIAS[race] or race
end

local guidCache = {}  -- guid -> englishRace
local nameCache = {}  -- name (with realm stripped) or full name -> englishRace

local function Remember(name, race)
	if not name or not race then return end
	nameCache[name] = race
	local short = name:match("^([^-]+)")
	if short then nameCache[short] = race end
end

-- Cache whatever the player happens to be looking at. Cheap, and it fills in
-- the gaps for people who are nearby but not grouped.
local function ScanUnit(unit)
	if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
	local _, race = UnitRace(unit)
	if not race then return end
	local name, realm = UnitName(unit)
	if not name then return end
	Remember(name, race)
	if realm and realm ~= "" then Remember(name .. "-" .. realm, race) end
	local guid = UnitGUID(unit)
	if guid then guidCache[guid] = race end
end

local function ScanGroup()
	if IsInRaid() then
		for i = 1, 40 do ScanUnit("raid" .. i) end
	elseif IsInGroup() then
		for i = 1, 4 do ScanUnit("party" .. i) end
	end
end

-- Resolve the speaker's race. `guid` is arg12 of the chat event; `name` is the
-- sender name (which may or may not carry a realm suffix).
function Race.Resolve(guid, name)
	if guid and guid ~= "" then
		local cached = guidCache[guid]
		if cached then return cached end
		-- Only player GUIDs are useful here; creature GUIDs return nil.
		if guid:find("^Player%-") then
			local _, _, _, englishRace = GetPlayerInfoByGUID(guid)
			if englishRace and englishRace ~= "" then
				guidCache[guid] = englishRace
				Remember(name, englishRace)
				return englishRace
			end
		end
	end

	if name then
		local cached = nameCache[name] or nameCache[name:match("^([^-]+)") or name]
		if cached then return cached end
	end

	return nil
end

function Race.Player()
	if E.db and E.db.dialect.selfRace then
		return E.db.dialect.selfRace
	end
	local _, race = UnitRace("player")
	return race
end

-- The dialect to use for a given race, honouring the per-race mute list.
function Race.DialectFor(race)
	local canonical = Race.Canonical(race)
	if not canonical then return nil end
	if E.db and E.db.dialect.races[canonical] == false then return nil end
	return E.DIALECTS[canonical]
end

-- Everything Eloquence knows how to speak, for the options panel and /elo.
function Race.KnownDialects()
	local list = {}
	for race in pairs(E.DIALECTS) do list[#list + 1] = race end
	table.sort(list)
	return list
end

E.OnLogin("Race", function()
	local f = CreateFrame("Frame")
	-- All optional: these only warm the fallback name cache, and GUID lookup is
	-- the primary path. Guarded because event names come and go between
	-- expansions and an unknown one raises an error.
	E.SafeRegisterEvent(f, "PLAYER_TARGET_CHANGED")
	E.SafeRegisterEvent(f, "UPDATE_MOUSEOVER_UNIT")
	E.SafeRegisterEvent(f, "GROUP_ROSTER_UPDATE")
	E.SafeRegisterEvent(f, "PLAYER_FOCUS_CHANGED")
	f:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_TARGET_CHANGED" then
			ScanUnit("target")
		elseif event == "UPDATE_MOUSEOVER_UNIT" then
			ScanUnit("mouseover")
		elseif event == "PLAYER_FOCUS_CHANGED" then
			ScanUnit("focus")
		else
			ScanGroup()
		end
	end)
	ScanGroup()
	ScanUnit("player")
end)
