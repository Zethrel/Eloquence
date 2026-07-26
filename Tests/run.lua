-- Eloquence test suite. Run from the repository root:
--   lua Tests/run.lua
--
-- These tests exercise the parts of the addon that are pure text handling --
-- which is nearly all of the interesting behaviour -- against a stubbed client.

package.path = "Tests/?.lua;" .. package.path
local stub = require("wow_stub")
stub.install(_G)

local E = stub.loadAddon("Eloquence")
stub.login(E)

--------------------------------------------------------------------------------
-- Tiny test framework
--------------------------------------------------------------------------------

local passed, failed = 0, 0
local failures = {}

local function check(name, ok, detail)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		failures[#failures + 1] = name .. (detail and ("\n      " .. detail) or "")
		io.write("  FAIL  ", name, "\n")
		if detail then io.write("        ", detail, "\n") end
	end
end

local function eq(name, actual, expected)
	check(name, actual == expected,
		string.format("expected %q\n      got      %q", tostring(expected), tostring(actual)))
end

local function contains(name, haystack, needle)
	check(name, type(haystack) == "string" and haystack:find(needle, 1, true) ~= nil,
		string.format("%q\n      should contain %q", tostring(haystack), tostring(needle)))
end

local function excludes(name, haystack, needle)
	check(name, type(haystack) == "string" and haystack:find(needle, 1, true) == nil,
		string.format("%q\n      should NOT contain %q", tostring(haystack), tostring(needle)))
end

local function section(title)
	io.write("\n", title, "\n")
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Run a single module in isolation.
local function runModule(key, text, strength, race)
	local dialect = race and E.DIALECTS[race] or nil
	local ctx = E.Pipeline.NewContext(text, "Player-1-TEST", race)
	ctx.strength = strength or 2
	ctx.dialect = dialect
	return E.MODULES[key].Filter(text, ctx)
end

-- Run only the dialect, with interjections suppressed so assertions are about
-- the substitutions rather than the random flavour text.
local function dialectOnly(race, text, strength)
	local dialect = E.DIALECTS[race]
	assert(dialect, "no dialect for " .. tostring(race))
	local saved = dialect.flavor
	dialect.flavor = nil
	local ctx = E.Pipeline.NewContext(text, "Player-1-TEST", race)
	ctx.strength = strength or 2
	local ok, result = pcall(E.Engine.Apply, dialect, text, ctx)
	dialect.flavor = saved
	if not ok then return "ERROR: " .. tostring(result) end
	return result
end

local function onlyModules(...)
	for key in pairs(E.db.modules) do
		E.db.modules[key].enabled = false
	end
	for _, key in ipairs({ ... }) do
		E.db.modules[key].enabled = true
		E.db.modules[key].strength = 2
	end
end

--------------------------------------------------------------------------------
section("Util: case matching")
--------------------------------------------------------------------------------

eq("lower stays lower", E.MatchCase("friend", "laddie"), "laddie")
eq("Capitalised stays capitalised", E.MatchCase("Friend", "laddie"), "Laddie")
eq("ALL CAPS stays ALL CAPS", E.MatchCase("FRIEND", "laddie"), "LADDIE")
eq("single upper letter is not shouting", E.MatchCase("I", "ah"), "Ah")
eq("multi-word replacement capitalises first word only",
	E.MatchCase("Lol", "laugh out loud"), "Laugh out loud")

--------------------------------------------------------------------------------
section("Util: protected spans")
--------------------------------------------------------------------------------

local LINK = "|cffa335ee|Hitem:19019::::::::60:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"

do
	local segments = E.Tokenize("look at " .. LINK .. " friend")
	local protectedCount = 0
	for _, seg in ipairs(segments) do
		if seg.protected then protectedCount = protectedCount + 1 end
	end
	check("an item link tokenises into protected spans", protectedCount >= 2,
		"got " .. protectedCount .. " protected segments")
end

do
	-- The engine must never touch the inside of a link, even though the display
	-- text is full of words the dialects would happily rewrite.
	local text = "I will give you " .. LINK .. " for gold"
	local result = dialectOnly("Dwarf", text)
	contains("item link survives the dialect verbatim", result, LINK)
	contains("text around the link is still translated", result, "gowd")
end

do
	local text = "see |cff00ff00this|r and {rt3} and |TInterface\\Icons\\INV_Misc_Bag_08:16|t now"
	local result = dialectOnly("Dwarf", text)
	contains("colour open code preserved", result, "|cff00ff00")
	contains("colour reset preserved", result, "|r")
	contains("raid target icon preserved", result, "{rt3}")
	contains("texture escape preserved", result, "|TInterface\\Icons\\INV_Misc_Bag_08:16|t")
	contains("plain text outside escapes is translated", result, "noo")
end

do
	local text = "guide is at https://www.wowhead.com/guide/some-very-long-name here"
	local result = dialectOnly("Troll", text)
	contains("URL survives untouched", result, "https://www.wowhead.com/guide/some-very-long-name")
end

--------------------------------------------------------------------------------
section("Util: deterministic randomness")
--------------------------------------------------------------------------------

do
	local rng = E.NewRNG(E.Hash("some message"))
	local first = {}
	for i = 1, 8 do first[i] = rng() end
	local rng2 = E.NewRNG(E.Hash("some message"))
	local same = true
	for i = 1, 8 do
		if rng2() ~= first[i] then same = false end
	end
	check("same seed gives the same sequence", same)

	local inRange = true
	for i = 1, 8 do
		if first[i] < 0 or first[i] >= 1 then inRange = false end
	end
	check("values stay in [0,1)", inRange)

	local other = E.NewRNG(E.Hash("a different message"))
	check("different seeds diverge", other() ~= first[1])
end

do
	local text = "Hello there friend, are you going to help me or not?"
	local a = dialectOnly("Dwarf", text)
	local b = dialectOnly("Dwarf", text)
	eq("the same message always renders identically", a, b)
end

--------------------------------------------------------------------------------
section("Util: excitement")
--------------------------------------------------------------------------------

do
	local calm = E.Excitement("i am walking to the inn")
	local shouty = E.Excitement("HELP ME RIGHT NOW!!!")
	check("shouting scores higher than calm speech", shouty > calm,
		string.format("calm=%.2f shouty=%.2f", calm, shouty))
	check("excitement is bounded at 1", shouty <= 1, tostring(shouty))
	check("calm speech scores near zero", calm < 0.2, tostring(calm))
end

--------------------------------------------------------------------------------
section("Util: message splitting")
--------------------------------------------------------------------------------

do
	local long = string.rep("the quick brown fox jumps over the lazy dog ", 12)
	local chunks = E.SplitMessage(long, 255)
	check("a long message is split", #chunks > 1, "#chunks = " .. #chunks)

	local oversize = false
	for _, chunk in ipairs(chunks) do
		if #chunk > 255 then oversize = true end
	end
	check("no chunk exceeds the byte limit", not oversize)

	local rejoined = table.concat(chunks, " "):gsub("%s+", " ")
	local original = long:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
	eq("splitting loses no words", rejoined:gsub("^%s*(.-)%s*$", "%1"), original)
end

do
	-- A link must never be cut in half, because half a link is broken output.
	local text = string.rep("word ", 40) .. LINK .. string.rep(" word", 40)
	local chunks = E.SplitMessage(text, 255)
	local intact = false
	for _, chunk in ipairs(chunks) do
		if chunk:find(LINK, 1, true) then intact = true end
	end
	check("an item link stays inside one chunk", intact)
end

do
	local short = "just a short line"
	local chunks = E.SplitMessage(short, 255)
	eq("a short message is returned as one chunk", #chunks, 1)
	eq("and is unchanged", chunks[1], short)
end

--------------------------------------------------------------------------------
section("Dialect: Dwarven (the canonical line)")
--------------------------------------------------------------------------------

do
	-- Straight from the original addon's own documentation.
	local result = dialectOnly("Dwarf", "I'm not sure if that will work, friend.")
	eq("reproduces the documented Dwarven example",
		result, "Ah'm no' shuir if that wull wirk, laddie.")
end

do
	local result = dialectOnly("Dwarf", "I don't know where the small child went")
	contains("dinnae", result, "dinnae")
	contains("ken", result, "ken")
	contains("wee", result, "wee")
	contains("bairn", result, "bairn")
end

do
	local result = dialectOnly("Dwarf", "I am working on it")
	contains("working is translated and loses its g", result, "wirkin'")
	local kept = dialectOnly("Dwarf", "the king had a thing")
	contains("short -ing words are left alone (king)", kept, "king")
	contains("short -ing words are left alone (thing)", kept, "thing")
end

--------------------------------------------------------------------------------
section("Dialect: Trollish")
--------------------------------------------------------------------------------

do
	local result = dialectOnly("Troll", "I think that the other one is nothing")
	contains("th becomes d (that)", result, "dat")
	contains("th becomes d (the)", result, "de")
	contains("think becomes tink", result, "tink")
	contains("nothing becomes nuttin", result, "nuttin")
end

do
	local result = dialectOnly("Troll", "Hello friend, are you going to help?")
	contains("friend becomes mon", result, "mon")
	contains("'going to' is caught by the phrase rule first", result, "gonna")
	-- An -ing word with no dictionary entry of its own still loses its g.
	contains("-ing loses its g", dialectOnly("Troll", "we are walking home"), "walkin")
end

--------------------------------------------------------------------------------
section("Dialect: Forsaken hiss scales with agitation")
--------------------------------------------------------------------------------

do
	local function countS(s) local _, n = s:gsub("[sS]", ""); return n end
	local calm = dialectOnly("Scourge", "yes, i suppose so, this is fine")
	local angry = dialectOnly("Scourge", "YES I SUPPOSE SO THIS IS FINE!!!")
	check("an agitated Forsaken hisses more than a calm one",
		countS(angry) > countS(calm),
		string.format("calm=%d (%s) angry=%d (%s)", countS(calm), calm, countS(angry), angry))
end

--------------------------------------------------------------------------------
section("Dialect: formal races expand contractions")
--------------------------------------------------------------------------------

for _, race in ipairs({ "NightElf", "Draenei", "Tauren" }) do
	local result = dialectOnly(race, "I don't think it's ready")
	excludes(race .. " removes don't", result, "don't")
	excludes(race .. " removes it's", result, "it's")
end

--------------------------------------------------------------------------------
section("Engine: phrase rules")
--------------------------------------------------------------------------------

do
	-- Chat is full of capitalised sentence openings; a phrase rule written in
	-- lower case still has to catch them.
	local lower_ = dialectOnly("Gnome", "watch out, there are a lot of them")
	local upper_ = dialectOnly("Gnome", "Watch out, there are a lot of them")
	local shout_ = dialectOnly("Gnome", "WATCH OUT, THERE ARE A LOT OF THEM")
	contains("lower case phrase matches", lower_, "mind the blast radius")
	contains("capitalised phrase matches too", upper_, "Mind the blast radius")
	contains("upper case phrase matches too", shout_, "MIND THE BLAST RADIUS")
	excludes("and 'watch' is not word-substituted instead", upper_, "Monitor out")
end

do
	-- A phrase replacement is final. "a lot of" -> "a great many of" must not
	-- then have "great" rewritten to "wondrous" by the word pass.
	local result = dialectOnly("NightElf", "there are a lot of them coming")
	contains("phrase output is used verbatim", result, "a great many of")
	excludes("and is not re-translated by the word pass", result, "wondrous many")
end

do
	-- The word "sure" is an adjective far more often than an affirmative.
	for _, race in ipairs({ "NightElf", "Draenei", "Tauren", "Orc", "BloodElf", "Worgen", "Pandaren" }) do
		local result = dialectOnly(race, "I'm not sure if that will work")
		excludes(race .. " does not turn 'not sure' into an affirmative", result, "not of course")
		excludes(race .. " does not use 'obviously' for 'sure'", result, "not obviously")
		excludes(race .. " does not use 'zug zug' for 'sure'", result, "not zug zug")
	end
	contains("Dwarven keeps its phonetic 'sure'",
		dialectOnly("Dwarf", "I'm not sure"), "shuir")
end

do
	-- Idioms that stand in for a whole sentence must not fire mid-clause.
	-- "I don't know." is "That knowledge escapes me"; "I don't know where the
	-- child went" has to stay literal.
	local standalone = dialectOnly("NightElf", "I don't know.")
	contains("clause-final idiom fires on its own", standalone, "That knowledge escapes me")

	local midClause = dialectOnly("NightElf", "I don't know where the child went")
	excludes("but not mid-clause", midClause, "knowledge escapes me")
	contains("the word pass handles it instead", midClause, "I do not know where")

	-- Punctuation after the idiom still counts as the end of a clause.
	-- Capitalisation is carried across, so match on the case-stable part.
	contains("a following comma counts as clause-final",
		dialectOnly("Gnome", "I don't know, and it bothers me"), "data are inconclusive")
	excludes("Gnome mid-clause stays literal",
		dialectOnly("Gnome", "I don't know how many there are"), "data are inconclusive")

	-- The same applies to "I think".
	contains("'I think' fires clause-finally",
		dialectOnly("Gnome", "That will work, I think."), "working hypothesis")
	excludes("'I think' stays literal mid-clause",
		dialectOnly("Gnome", "I think that will work"), "working hypothesis")

	-- Non-clause-final phrases are unaffected by the gating.
	contains("ordinary phrases still fire anywhere",
		dialectOnly("NightElf", "thank you for the help"), "you have my gratitude")
end

do
	-- Verb senses must survive: "that will work" is not "that will the job".
	local result = dialectOnly("Goblin", "I'm not sure if that will work")
	contains("Goblin leaves the verb 'work' alone", result, "will work")
end

--------------------------------------------------------------------------------
section("Dialect: Darnassian glossary")
--------------------------------------------------------------------------------

do
	-- Attested Darnassian, gated behind strength 3.
	local heavy = dialectOnly("NightElf", "prepare to fight", 3)
	contains("attested phrase is used at strength 3", heavy, "Bandu thoribas")
	local medium = dialectOnly("NightElf", "prepare to fight", 2)
	excludes("but not at strength 2", medium, "Bandu thoribas")

	contains("shan'do for teacher", dialectOnly("NightElf", "my teacher taught me", 3), "shan'do")
	contains("thero'shan for student", dialectOnly("NightElf", "I am your student", 3), "thero'shan")
	contains("kaldorei for night elves", dialectOnly("NightElf", "the night elves are here", 3), "kaldorei")
end

--------------------------------------------------------------------------------
section("Dialect: every registered dialect runs clean")
--------------------------------------------------------------------------------

do
	local samples = {
		"Hello there, friend! I don't know if this will work.",
		"WATCH OUT!!! there are a lot of them coming, we should go now",
		"i think the small one is going to help us with that thing",
		"see " .. LINK .. " -- worth 500 gold at https://www.wowhead.com/item=19019",
		"ok",
		"...",
	}
	for _, race in ipairs(E.Race.KnownDialects()) do
		for _, sample in ipairs(samples) do
			for strength = 1, 3 do
				local result = dialectOnly(race, sample, strength)
				check(race .. " strength " .. strength .. " produces a string",
					type(result) == "string" and not result:find("^ERROR:"), tostring(result))
				if sample:find(LINK, 1, true) then
					contains(race .. " strength " .. strength .. " keeps the link intact", result, LINK)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
section("Module: The Spell Book")
--------------------------------------------------------------------------------

do
	eq("fixes missing apostrophes", runModule("spellbook", "i dont think thats right"),
		"i don't think that's right")
	eq("fixes transpositions", runModule("spellbook", "teh cake is adn lie"),
		"the cake is and lie")
	eq("squashes stretched letters", runModule("spellbook", "heyyyyyyy waaaaait"), "heyy waait")
	eq("squashes runaway punctuation", runModule("spellbook", "stop!!!!!!!"), "stop!!")
	eq("trims long ellipses", runModule("spellbook", "well........ maybe"), "well... maybe")
end

do
	local result = runModule("spellbook", "HELP ME I AM UNDER ATTACK")
	eq("de-shouts a fully upper-case message", result, "Help me I am under attack")
	local acronym = runModule("spellbook", "LFG UBRS")
	eq("leaves short acronyms alone", acronym, "LFG UBRS")
end

do
	-- Mixed case with an item link: the link must not be lower-cased.
	local text = "LOOK AT THIS AMAZING WEAPON " .. LINK
	local result = runModule("spellbook", text)
	contains("de-shouting does not destroy a link", result, LINK)
	contains("de-shouting still lowercases the prose", result, "amazing weapon")
end

--------------------------------------------------------------------------------
section("Module: Decompression Engine")
--------------------------------------------------------------------------------

do
	eq("expands common acronyms", runModule("decompression", "brb ty"), "be right back thank you")
	eq("expands wow acronyms", runModule("decompression", "wtb port pls"),
		"want to buy port please")
	eq("expands letter-digit shorthand", runModule("decompression", "b4 you go"), "before you go")
	eq("leaves bare numbers alone", runModule("decompression", "meet me at level 2 in 4 min"),
		"meet me at level 2 in 4 min")
	eq("expands single letters at strength 2", runModule("decompression", "r u coming", 2),
		"are you coming")
	eq("but not at strength 1", runModule("decompression", "r u coming", 1), "r u coming")
	contains("preserves case", runModule("decompression", "Brb"), "Be right back")
end

--------------------------------------------------------------------------------
section("Module: Mouthwash")
--------------------------------------------------------------------------------

do
	local result = runModule("mouthwash", "what the hell is this crap", 2)
	contains("replaces hell", result, "the Nether")
	contains("replaces crap", result, "rubbish")
	excludes("original word is gone", result, "crap")
end

do
	eq("catches trailing punctuation", runModule("mouthwash", "hell!", 2), "the Nether!")
	eq("catches symbol substitution", runModule("mouthwash", "a$$", 2), "backside")
	eq("catches stretched letters", runModule("mouthwash", "daaaamn", 2), "curse it")
	eq("leaves ordinary words alone", runModule("mouthwash", "a perfectly normal sentence", 2),
		"a perfectly normal sentence")
	eq("leaves numbers alone", runModule("mouthwash", "i have 1000 gold and 45 silver", 2),
		"i have 1000 gold and 45 silver")
end

--------------------------------------------------------------------------------
section("Module: Fantasy Writer")
--------------------------------------------------------------------------------

do
	local result = runModule("fantasy", "hey guys that was really awesome, ok?")
	contains("modernism replaced (hey)", result, "ho there")
	contains("modernism replaced (guys)", result, "friends")
	contains("modernism replaced (awesome)", result, "wondrous")
	contains("modernism replaced (ok)", result, "very well")
end

do
	local result = runModule("fantasy", "i will call you on the phone about my car", 3)
	contains("anachronism replaced (phone)", result, "sending stone")
	contains("anachronism replaced (car)", result, "wagon")
	contains("archaic second person at strength 3", result, "thou")
end

--------------------------------------------------------------------------------
section("Pipeline: end to end")
--------------------------------------------------------------------------------

do
	_G._guidRaces["Player-1-DWARF"] = { race = "Dwarf", class = "Warrior", name = "Bromm" }
	onlyModules("spellbook", "decompression", "dialect")

	local result = E.Pipeline.Run("brb, i dont know if thats going to work friend",
		"Player-1-DWARF", "Dwarf", "Common")
	check("pipeline produced a string", type(result) == "string", tostring(result))
	contains("spellbook ran (apostrophe fixed then dialected)", result, "dinnae")
	contains("decompression ran", result, "be richt back")
	contains("dialect ran", result, "laddie")
end

do
	-- A language the character does not know is already gibberish; leave it.
	local before = "zug zug lok'tar ogar throm ka"
	local result = E.Pipeline.Run(before, "Player-1-DWARF", "Dwarf", "Thalassian")
	eq("unknown languages pass through untouched", result, before)
	local known = E.Pipeline.Run(before, "Player-1-DWARF", "Dwarf", "Common")
	check("known languages are processed", known ~= before)
end

do
	eq("slash commands are skipped", E.Pipeline.Run("/dance", "Player-1-DWARF", "Dwarf", "Common"), "/dance")
	local link = LINK
	eq("a bare link is left alone", E.Pipeline.Run(link, "Player-1-DWARF", "Dwarf", "Common"), link)
end

do
	E.db.enabled = false
	eq("the master switch stops everything",
		E.Pipeline.Run("i dont know friend", "Player-1-DWARF", "Dwarf", "Common"),
		"i dont know friend")
	E.db.enabled = true
end

do
	-- No race resolved means no dialect, but the cleanup filters still run.
	onlyModules("spellbook")
	eq("filters work with no race at all",
		E.Pipeline.Run("i dont know", nil, nil, "Common"), "i don't know")
end

--------------------------------------------------------------------------------
section("Race resolution")
--------------------------------------------------------------------------------

do
	_G._guidRaces["Player-1-VOID"] = { race = "VoidElf", class = "Mage", name = "Sylwen" }
	eq("resolves race from a GUID", E.Race.Resolve("Player-1-VOID", "Sylwen"), "VoidElf")
	eq("allied races alias onto their parent", E.Race.Canonical("VoidElf"), "BloodElf")
	eq("Earthen speak Dwarven", E.Race.Canonical("EarthenDwarf"), "Dwarf")
	check("a void elf gets the Thalassian dialect",
		E.Race.DialectFor("VoidElf") == E.DIALECTS["BloodElf"])
	eq("creature GUIDs resolve to nothing", E.Race.Resolve("Creature-0-1-2-3-4-5", "Kobold"), nil)
	eq("an unknown GUID resolves to nothing", E.Race.Resolve("Player-1-NOBODY", "Nobody"), nil)
end

do
	E.db.dialect.races["Dwarf"] = false
	eq("a muted race gets no dialect", E.Race.DialectFor("Dwarf"), nil)
	E.db.dialect.races["Dwarf"] = nil
	check("unmuting restores it", E.Race.DialectFor("Dwarf") == E.DIALECTS["Dwarf"])
end

--------------------------------------------------------------------------------
section("Cleanup: URLs and channels")
--------------------------------------------------------------------------------

do
	local linked = E.Cleanup.Linkify("see https://www.wowhead.com/item=19019 for details")
	contains("URL becomes a clickable link", linked, "|Heloquence:url:https://www.wowhead.com/item=19019|h")
	contains("display text is trimmed of the scheme", linked, "[wowhead.com/item=19019]")
	contains("surrounding text is preserved", linked, "for details")

	local long = "https://example.com/" .. string.rep("a", 200)
	local display = E.Cleanup.DisplayText(long)
	check("long URLs are trimmed for display", #display <= 45, "#display = " .. #display)
	contains("but keep their host", display, "example.com")

	local untouched = E.Cleanup.Linkify("no links here at all")
	eq("text without URLs is returned unchanged", untouched, "no links here at all")

	-- An existing hyperlink must not be double-wrapped.
	local withLink = E.Cleanup.Linkify("look " .. LINK)
	excludes("item links are not turned into url links", withLink, "eloquence:url")
end

do
	eq("known channels get short names", E.Cleanup.Abbreviate("General"), "G")
	eq("trade too", E.Cleanup.Abbreviate("Trade"), "T")
	eq("LookingForGroup too", E.Cleanup.Abbreviate("LookingForGroup"), "LFG")
	eq("unknown multi-word channels use initials", E.Cleanup.Abbreviate("My Custom Channel"), "MCC")
end

--------------------------------------------------------------------------------
section("Chat filters are registered")
--------------------------------------------------------------------------------

do
	local registered = 0
	for event in pairs(E.CHANNELS) do
		if _G._filters[event] and #_G._filters[event] >= 2 then
			registered = registered + 1
		end
	end
	local total = 0
	for _ in pairs(E.CHANNELS) do total = total + 1 end
	eq("every chat event has a linguistic and a presentation filter", registered, total)
end

do
	-- Drive a real filter the way the chat system would, checking that the
	-- trailing arguments survive the round trip. arg12 is the GUID.
	onlyModules("dialect")
	E.db.incoming.say = true
	local filter = _G._filters["CHAT_MSG_SAY"][1]
	local args = { "i dont know friend", "Bromm", "Common", "", "", "", 0, 0, "", "", 42,
		"Player-1-DWARF", nil, false, false, false, false }
	local suppressed, text, sender, language = filter(nil, "CHAT_MSG_SAY", unpack(args, 1, 17))
	eq("the filter does not suppress the message", suppressed, false)
	eq("the sender is passed through", sender, "Bromm")
	eq("the language is passed through", language, "Common")
	contains("the text was dialected via the GUID", text, "laddie")
end

--------------------------------------------------------------------------------
section("Outgoing rewriting")
--------------------------------------------------------------------------------

do
	_G._playerRace = "Dwarf"
	E.db.outgoing.enabled = true
	E.db.outgoing.say = true
	onlyModules("dialect")
	E.Chat.EnsureOutgoingHook()

	_G._sent = {}
	SendChatMessage("i dont know friend", "SAY")
	eq("one message went out", #_G._sent, 1)
	contains("and it was dialected", _G._sent[1][1], "laddie")

	-- Something long enough that the dialect pushes it past the byte cap.
	_G._sent = {}
	SendChatMessage(string.rep("i do not know friend, ", 20), "SAY")
	check("an over-long message is split, not truncated", #_G._sent > 1, "#sent = " .. #_G._sent)
	local oversize = false
	for _, call in ipairs(_G._sent) do
		if #call[1] > 255 then oversize = true end
	end
	check("no outgoing chunk exceeds 255 bytes", not oversize)

	-- A channel we have not opted into must go out verbatim.
	_G._sent = {}
	E.db.outgoing.guild = false
	SendChatMessage("i dont know friend", "GUILD")
	eq("un-opted channels are untouched", _G._sent[1][1], "i dont know friend")

	_G._sent = {}
	SendChatMessage("/dance", "SAY")
	eq("slash commands are never rewritten", _G._sent[1][1], "/dance")

	E.db.outgoing.enabled = false
	_G._sent = {}
	SendChatMessage("i dont know friend", "SAY")
	eq("disabling outgoing restores verbatim sending", _G._sent[1][1], "i dont know friend")
end

--------------------------------------------------------------------------------
section("Slash commands")
--------------------------------------------------------------------------------

do
	local handler = SlashCmdList["ELOQUENCE"]
	check("the slash command is registered", type(handler) == "function")

	local ok = pcall(handler, "status")
	check("/elo status runs", ok)
	ok = pcall(handler, "races")
	check("/elo races runs", ok)
	ok = pcall(handler, "test Dwarf i dont know friend")
	check("/elo test <race> <text> runs", ok)
	ok = pcall(handler, "help")
	check("/elo help runs", ok)

	handler("dialect off")
	eq("/elo dialect off disables the module", E.db.modules.dialect.enabled, false)
	handler("dialect 3")
	eq("/elo dialect 3 sets strength", E.db.modules.dialect.strength, 3)
	eq("and re-enables it", E.db.modules.dialect.enabled, true)

	handler("race Troll off")
	eq("/elo race Troll off mutes trolls", E.db.dialect.races["Troll"], false)
	handler("race Troll on")
	eq("/elo race Troll on unmutes them", E.db.dialect.races["Troll"], nil)
	handler("race zandalaritroll off")
	eq("allied race names work too", E.db.dialect.races["Troll"], false)

	handler("off")
	eq("/elo off disables the addon", E.db.enabled, false)
	handler("on")
	eq("/elo on re-enables it", E.db.enabled, true)

	handler("reset")
	eq("/elo reset restores defaults", E.db.modules.dialect.strength, 2)
	eq("and clears muted races", E.db.dialect.races["Troll"], nil)
end

--------------------------------------------------------------------------------
section("Every module survives hostile input")
--------------------------------------------------------------------------------

do
	local nasty = {
		"", " ", "|", "||", "|c", "|cff", "|Hitem", "|h|h", "{}", "{rt",
		"%", "%1", "%s", "%%", "()", "[]", "^$.*+-?", "\\", "'", "''", "'''",
		LINK, "|cffff0000|r", "https://", "www.", "a", "I", "!!!", "...",
		string.rep("x", 300), string.rep("a$$ ", 50), "\226\150\136 unicode \195\169\195\168",
	}
	for key in pairs(E.MODULES) do
		for _, sample in ipairs(nasty) do
			for strength = 1, 3 do
				local ok, result = pcall(runModule, key, sample, strength, "Dwarf")
				check(string.format("%s survives %q at strength %d", key, sample:sub(1, 24), strength),
					ok and type(result) == "string", tostring(result))
			end
		end
	end
end

do
	for _, sample in ipairs({ "", "|", "%1", string.rep("word ", 200), LINK }) do
		local ok, result = pcall(E.SplitMessage, sample, 255)
		check(string.format("SplitMessage survives %q", sample:sub(1, 20)),
			ok and type(result) == "table", tostring(result))
	end
end

--------------------------------------------------------------------------------

io.write(string.format("\n%d passed, %d failed\n", passed, failed))
if failed > 0 then
	io.write("\nFailures:\n")
	for _, name in ipairs(failures) do
		io.write("  - ", name, "\n")
	end
	os.exit(1)
end
os.exit(0)
