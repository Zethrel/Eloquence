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
	lisp = "lisp", lisping = "lisp",
	muffle = "muffle", muffled = "muffle", helm = "muffle",
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
			E.Print(format("  %-22s %s  |cff808080strength %d%s|r", module.name,
				settings.enabled and "|cff40ff40on |r" or "|cffff4040off|r", settings.strength or 2,
				settings.incoming == false and ", outgoing only" or ""))
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
		if module and settings.enabled and settings.incoming ~= false
			and (key ~= "dialect" or dialect) then
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

-- A self-check that answers "why is nothing happening?" without needing the
-- player to read Lua errors. Reports what actually initialised, then proves the
-- pipeline end to end by running a sample through it.
local function Doctor()
	local ok = "|cff40ff40OK|r"
	local bad = "|cffff4040FAIL|r"
	local warn = "|cffffcc00--|r"

	E.Print(format("doctor -- Eloquence %s (%s)", E.VERSION, E.CREDIT))

	-- 1. Did every module survive login?
	if #E.initErrors == 0 then
		print("  " .. ok .. "   all modules started")
	else
		print("  " .. bad .. " " .. #E.initErrors .. " module(s) failed to start:")
		for _, entry in ipairs(E.initErrors) do
			print(format("       |cffff8080%s|r: %s", entry.name, entry.err))
		end
		print("       |cffffcc00This is why nothing is happening. Please report the above.|r")
	end

	if #E.skippedEvents > 0 then
		print("  " .. warn .. "   events this client does not know (harmless): "
			.. table.concat(E.skippedEvents, ", "))
	end

	-- 2. Are the hooks actually attached?
	local filters = (E.Chat and E.Chat.installedFilters) or 0
	print(format("  %s   incoming chat filters attached: %d", filters > 0 and ok or bad, filters))

	local hooked = E.Chat and E.Chat.IsOutgoingHooked()
	if E.db.outgoing.enabled then
		-- Reporting "hook installed" alone was a false green: the legacy
		-- SendChatMessage wrapper installs fine but the 12.0 chat path never
		-- calls it, so say *which* hook is carrying the message.
		local method = E.Chat and E.Chat.outgoingMethod
		if not hooked then
			print("  " .. bad .. " outgoing rewriting on but no hook installed")
		elseif method == "editbox" then
			print("  " .. ok .. "   outgoing via the edit box hook (correct for 12.0+)")
		else
			print("  " .. bad .. " outgoing only has the legacy SendChatMessage wrapper.")
			print("       |cffffcc00This client rearchitected chat sending; typed messages will")
			print("       not be transformed. EventRegistry callback unavailable.|r")
		end
	else
		print("  " .. warn .. "   outgoing rewriting is off (only you see dialects)")
	end

	-- 2b. Can the options panel actually open?
	if E.optionsBuildError then
		print("  " .. bad .. " the options panel failed to build:")
		print("       |cffff8080" .. E.optionsBuildError .. "|r")
	elseif E.optionsMethod == "settings" and E.settingsCategory then
		print("  " .. ok .. "   options panel registered (Settings API)")
	elseif E.optionsMethod == "legacy" then
		print("  " .. warn .. "   options panel registered (legacy API)")
	else
		print("  " .. bad .. " options panel is not registered -- /elo will not open it")
	end

	-- 2c. Is incoming chat actually reaching the filter?
	local stats = E.Chat and E.Chat.stats
	if stats then
		if stats.calls == 0 then
			print("  " .. bad .. " no incoming chat has reached the filter yet.")
			print("       |cffffcc00Either nobody has spoken since login, or the filter is not")
			print("       being called at all. Say something and re-run this.|r")
		else
			print(format("  %s   incoming seen: %d, rewritten: %d", ok, stats.calls, stats.changed))
			local skips = {}
			if stats.skippedSelf > 0 then skips[#skips + 1] = stats.skippedSelf .. " own" end
			if stats.skippedOff > 0 then skips[#skips + 1] = stats.skippedOff .. " channel off" end
			if stats.skippedLanguage > 0 then skips[#skips + 1] = stats.skippedLanguage .. " language" end
			if #skips > 0 then
				print("       |cff808080skipped: " .. table.concat(skips, ", ") .. "|r")
			end
		end
		local last = E.Chat.lastSeen
		if last then
			print(format("       last: %s from %s -- %s",
				tostring(last.event), tostring(last.sender), tostring(last.verdict)))
		end
	end

	if E.db.incoming.bubbles then
		if E.Bubbles and E.Bubbles.supported then
			print(format("  %s   chat bubbles supported, rewritten so far: %d",
				ok, E.Bubbles.rewritten or 0))
		else
			print("  " .. warn .. "   chat bubbles unavailable on this client")
		end
	else
		print("  " .. warn .. "   chat bubble rewriting is off")
	end

	local languages, languageFailed = E.Pipeline.LanguageInfo()
	if languageFailed then
		print("  " .. warn .. "   could not read your known languages; "
			.. "filtering everything rather than nothing")
	else
		print(format("  %s   languages understood: %s", ok, table.concat(languages, ", ")))
	end

	-- Secret values: names the client will not let an addon inspect. Harmless in
	-- itself -- those speakers fall back to GUID lookup -- but worth showing,
	-- since a sudden count means the client changed what it hands out.
	local secrets = E.Race.secretsSkipped or 0
	if secrets > 0 then
		print(format("  %s   names the client kept secret: %d (resolved by GUID instead)",
			warn, secrets))
	end

	-- Self-only filters need the outgoing path to reach anyone at all.
	local stranded = {}
	for _, key in ipairs(E.MODULE_ORDER) do
		local m, settings = E.MODULES[key], E.db.modules[key]
		if m and m.selfOnly and settings and settings.enabled and not E.db.outgoing.enabled then
			stranded[#stranded + 1] = m.name
		end
	end
	if #stranded > 0 then
		print(format("  %s   %s on, but outgoing rewriting is off -- nothing you type changes",
			bad, table.concat(stranded, " and ")))
	end

	-- Class layer, which decides what this character would never say.
	local classToken = E.Class.Player()
	local layer = classToken and E.CLASSES[classToken]
	if E.db.dialect.classFlavor == false then
		print(format("  %s   class flavour is off -- everyone speaks purely by race", warn))
	elseif layer then
		print(format("  %s   class layer: %s", ok, layer.name))
	else
		print(format("  %s   no class layer for %s (its race dialect is used as is)",
			ok, tostring(classToken)))
	end

	-- 3. Who are we, and does that resolve to a dialect?
	local race = E.Race.Player()
	local dialect = race and E.Race.DialectFor(race)
	print(format("  %s   your race %s -> dialect %s",
		dialect and ok or bad,
		tostring(race),
		dialect and dialect.name or "|cffff4040none|r"))
	if race and not dialect then
		if E.db.dialect.races[E.Race.Canonical(race)] == false then
			print("       that race is muted; /elo race " .. tostring(race) .. " on")
		else
			print("       |cffffcc00no dialect registered for that token -- please report it.|r")
		end
	end

	-- 4. Which filters are live?
	local live = {}
	for _, key in ipairs(E.MODULE_ORDER) do
		if E.db.modules[key] and E.db.modules[key].enabled then
			live[#live + 1] = E.MODULES[key].name
		end
	end
	print(format("  %s   enabled filters: %s",
		#live > 0 and ok or bad,
		#live > 0 and table.concat(live, ", ") or "|cffff4040none|r"))

	if not E.db.enabled then
		print("  " .. bad .. " master switch is OFF -- /elo on")
	end

	-- 5. Prove it end to end.
	local sample = "I don't know if that will work, friend."
	local result = E.Pipeline.Run(sample, UnitGUID("player"), race, nil)
	local changed = result ~= sample
	print(format("  %s   pipeline test:", changed and ok or bad))
	print("       |cff808080" .. sample .. "|r")
	print("       |cffffff80" .. tostring(result) .. "|r")
	if not changed then
		print("       |cffffcc00The pipeline returned the text unchanged. If everything above")
		print("       is OK, the sample simply had no matching words.|r")
	end
end

local function Help()
	E.Print("commands:")
	print("  |cffffff80/elo|r                      open the options panel")
	print("  |cffffff80/elo config|r               same, if bare /elo misbehaves")
	print("  |cffffff80/elo on|off|r               master switch")
	print("  |cffffff80/elo status|r               show what is enabled")
	print("  |cffffff80/elo doctor|r               diagnose why nothing is happening")
	print("  |cffffff80/elo spy|r                  report what the filter decides per message")
	print("  |cffffff80/elo test <text>|r          preview your own dialect")
	print("  |cffffff80/elo test <race> <text>|r   preview a specific dialect")
	print("  |cffffff80/elo <filter> on|off|r      spellbook, decomp, mouthwash, fantasy, dialect")
	print("  |cffffff80/elo <filter> 1|2|3|r       filter strength: light, medium, heavy")
	print("  |cffffff80/elo <filter> incoming on|off|r  apply it to others' chat too")
	print("  |cffffff80/elo race <race> on|off|r   mute or unmute one race's dialect")
	print("  |cffffff80/elo races|r                list every dialect")
	print("  |cffffff80/elo preset [name]|r        apply a bundle of settings, or list them")
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
	if command == "doctor" then Doctor() return end
	if command == "spy" then
		E.Chat.spy = not E.Chat.spy
		E.Print("spy " .. (E.Chat.spy and "|cff40ff40on|r -- every incoming message will report what the filter decided"
			or "off"))
		return
	end
	if command == "config" or command == "options" or command == "panel" then
		E.OpenOptions() return
	end
	if command == "races" then Races() return end
	if command == "class" or command == "classflavor" then
		local want = lower(E.Trim(rest))
		if want == "on" then E.db.dialect.classFlavor = true
		elseif want == "off" then E.db.dialect.classFlavor = false
		else E.db.dialect.classFlavor = not E.db.dialect.classFlavor end
		if E.RefreshOptions then E.RefreshOptions() end
		E.Print("class flavour " .. (E.db.dialect.classFlavor
			and "|cff40ff40on|r -- a Death Knight will not invoke the Light"
			or "off -- everyone speaks purely by race"))
		return
	end
	if command == "preset" or command == "presets" then
		local wanted = lower(E.Trim(rest))
		if wanted ~= "" and E.Presets.Apply(wanted) then
			local preset = E.Presets.list[wanted]
			if E.RefreshOptions then E.RefreshOptions() end
			E.Print(format("preset |cffffff80%s|r applied -- %s", preset.name, preset.desc))
			E.Print("|cff808080outgoing rewriting and muted races were left as they were.|r")
			return
		end
		if wanted ~= "" then
			E.Print("no such preset: " .. wanted)
		end
		E.Print("presets:")
		for _, key in ipairs(E.Presets.order) do
			local preset = E.Presets.list[key]
			print(format("  |cffffff80%-10s|r %s", key, preset.desc))
		end
		return
	end
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

		-- "<filter> incoming on|off" controls whether it touches other people's
		-- chat, separately from whether the filter is on at all.
		local incomingWord = word:match("^incoming%s+(%S+)$")
		if incomingWord then
			local value = Boolean(incomingWord)
			if value == nil then
				E.Print(format("usage: /elo %s incoming on|off", command))
				return
			end
			settings.incoming = value
			if E.RefreshOptions then E.RefreshOptions() end
			E.Print(format("%s on other people's chat: %s",
				E.MODULES[moduleKey].name, value and "on" or "off"))
		-- A self-only filter rewrites what you send. With outgoing off it has
		-- nowhere to go, and silently doing nothing is how people conclude an
		-- addon is broken.
		if value and E.MODULES[moduleKey].selfOnly and not E.db.outgoing.enabled then
			E.Print("|cffffcc00but outgoing rewriting is off, so nothing you type will change.|r "
				.. "Turn it on with |cffffff80/elo out on|r.")
		end
			return
		end
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
