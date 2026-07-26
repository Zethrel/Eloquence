-- Eloquence: /elo
local ADDON, E = ...

local lower, format = string.lower, string.format

-- Accept both "nightelf" and "night elf" for any registered race.
local function FindRace(input)
	if not input or input == "" then return nil end
	local needle = lower(input):gsub("[^%a]", "")
	for race, dialect in pairs(E.DIALECTS) do
		if lower(race) == needle or lower(dialect.name):gsub("[^%a]", "") == needle then
			return race
		end
	end
	-- Allied race names map onto their parent culture.
	for alias, parent in pairs(E.Race.ALIAS) do
		if lower(alias) == needle then return parent end
	end
	return nil
end

local MODULE_ALIASES = {
	spellbook = "spellbook", spell = "spellbook", sb = "spellbook",
	decompression = "decompression", decomp = "decompression", acronyms = "decompression",
	mouthwash = "mouthwash", mouth = "mouthwash", profanity = "mouthwash",
	fantasy = "fantasy", fantasywriter = "fantasy", writer = "fantasy",
	dialect = "dialect", dialects = "dialect", dialectician = "dialect", accent = "dialect",
}

local function Boolean(word)
	if word == "on" or word == "true" or word == "1" or word == "yes" then return true end
	if word == "off" or word == "false" or word == "0" or word == "no" then return false end
	return nil
end

local function Status()
	E.Print(format("version %s -- %s", E.VERSION, E.db.enabled and "|cff40ff40enabled|r" or "|cffff4040disabled|r"))
	E.Print(format("  revival by |cffffff80%s|r |cff808080(%s)|r", E.AUTHOR, E.REALM))
	for _, key in ipairs(E.MODULE_ORDER) do
		local module, settings = E.MODULES[key], E.db.modules[key]
		if module then
			E.Print(format("  %-22s %s  |cff808080strength %d|r", module.name,
				settings.enabled and "|cff40ff40on |r" or "|cffff4040off|r", settings.strength or 2))
		end
	end
	local race = E.Race.Player()
	local dialect = race and E.DIALECTS[E.Race.Canonical(race)]
	E.Print(format("  your dialect: %s", dialect and dialect.name or "|cff808080none|r"))
	E.Print(format("  outgoing rewriting: %s",
		E.db.outgoing.enabled and "|cffff8040ON|r" or "|cff808080off|r"))
end

-- Run the pipeline against arbitrary text, optionally forcing a dialect, and
-- show the before and after. The main way to audition a dialect.
local function Test(args)
	local raceWord, rest = args:match("^(%S+)%s+(.+)$")
	local forced = raceWord and FindRace(raceWord)
	local text = forced and rest or args

	if not text or text == "" then
		E.Print("usage: /elo test [race] <text>")
		return
	end

	local race = forced or E.Race.Player()
	local dialect = race and E.Race.DialectFor(race)

	local ctx = E.Pipeline.NewContext(text, UnitGUID("player"), race)
	local result = text
	for _, key in ipairs(E.MODULE_ORDER) do
		local module, settings = E.MODULES[key], E.db.modules[key]
		if module and settings.enabled and (key ~= "dialect" or dialect) then
			ctx.strength = settings.strength or 2
			ctx.dialect = dialect
			local ok, out = pcall(module.Filter, result, ctx)
			if ok and type(out) == "string" and out ~= "" then result = out end
		end
	end

	E.Print(format("as %s:", dialect and dialect.name or "no dialect"))
	print("  |cff808080" .. text .. "|r")
	print("  |cffffff80" .. result .. "|r")
end

local function Help()
	E.Print("commands:")
	print("  |cffffff80/elo|r                      open the options panel")
	print("  |cffffff80/elo on|off|r               master switch")
	print("  |cffffff80/elo status|r               show what is enabled")
	print("  |cffffff80/elo test <text>|r          preview your own dialect")
	print("  |cffffff80/elo test <race> <text>|r   preview a specific dialect")
	print("  |cffffff80/elo <filter> on|off|r      spellbook, decomp, mouthwash, fantasy, dialect")
	print("  |cffffff80/elo <filter> 1|2|3|r       filter strength: light, medium, heavy")
	print("  |cffffff80/elo race <race> on|off|r   mute or unmute one race's dialect")
	print("  |cffffff80/elo races|r                list every dialect")
	print("  |cffffff80/elo out on|off|r           rewrite your outgoing chat")
	print("  |cffffff80/elo reset|r                restore defaults")
end

local function Races()
	E.Print("dialects:")
	for _, race in ipairs(E.Race.KnownDialects()) do
		local dialect = E.DIALECTS[race]
		local muted = E.db.dialect.races[race] == false
		print(format("  %s%-14s|r %s", muted and "|cff808080" or "|cffffff80", race, dialect.desc))
	end
end

local function Handler(input)
	input = E.Trim(input or "")
	local command, rest = input:match("^(%S+)%s*(.*)$")
	command = command and lower(command) or ""

	if command == "" then
		E.OpenOptions()
		return
	end

	if command == "help" or command == "?" then Help() return end
	if command == "status" then Status() return end
	if command == "races" then Races() return end
	if command == "test" then Test(rest) return end

	if command == "debug" then
		E.db.debug = not E.db.debug
		E.Print("debug " .. (E.db.debug and "on" or "off"))
		return
	end

	if command == "reset" then
		for key in pairs(E.db) do E.db[key] = nil end
		E.CopyDefaults(E.DEFAULTS, E.db)
		if E.RefreshOptions then E.RefreshOptions() end
		E.Print("settings restored to defaults.")
		return
	end

	local boolean = Boolean(command)
	if boolean ~= nil then
		E.db.enabled = boolean
		if E.RefreshOptions then E.RefreshOptions() end
		E.Print(boolean and "enabled." or "disabled.")
		return
	end

	if command == "out" or command == "outgoing" then
		local value = Boolean(lower(rest))
		if value == nil then
			E.Print("usage: /elo out on|off")
			return
		end
		E.db.outgoing.enabled = value
		if value then E.Chat.EnsureOutgoingHook() end
		if E.RefreshOptions then E.RefreshOptions() end
		E.Print("outgoing rewriting " .. (value and "|cffff8040on|r -- other players will see your dialect." or "off."))
		return
	end

	if command == "race" then
		local raceWord, state = rest:match("^(%S+)%s*(%S*)$")
		local race = FindRace(raceWord or "")
		if not race then
			E.Print("unknown race. Try /elo races")
			return
		end
		local value = Boolean(lower(state or ""))
		if value == nil then
			value = E.db.dialect.races[race] == false
		end
		-- Note: `value and nil or false` would always evaluate to false.
		if value then
			E.db.dialect.races[race] = nil
		else
			E.db.dialect.races[race] = false
		end
		if E.RefreshOptions then E.RefreshOptions() end
		E.Print(format("%s dialect %s", race, value and "enabled." or "muted."))
		return
	end

	local moduleKey = MODULE_ALIASES[command]
	if moduleKey then
		local settings = E.db.modules[moduleKey]
		local word = lower(E.Trim(rest))
		local value = Boolean(word)
		local level = tonumber(word)

		if value ~= nil then
			settings.enabled = value
		elseif level and level >= 1 and level <= 3 then
			settings.strength = math.floor(level)
			settings.enabled = true
		elseif word == "" then
			settings.enabled = not settings.enabled
		else
			E.Print(format("usage: /elo %s on|off|1|2|3", command))
			return
		end

		if E.RefreshOptions then E.RefreshOptions() end
		E.Print(format("%s: %s, strength %d", E.MODULES[moduleKey].name,
			settings.enabled and "on" or "off", settings.strength or 2))
		return
	end

	E.Print("unknown command. Try /elo help")
end

SLASH_ELOQUENCE1 = "/elo"
SLASH_ELOQUENCE2 = "/eloquence"
SlashCmdList["ELOQUENCE"] = Handler

E.CommandHandler = Handler
