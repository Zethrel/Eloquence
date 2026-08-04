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
section("Dialect: Void elf whispers")
--------------------------------------------------------------------------------

do
	-- The whispers should surface far more often when the speaker is agitated.
	local function whisperCount(text, runs)
		local hits = 0
		for i = 1, runs do
			-- Vary the seed by appending an invisible-ish differentiator.
			local sample = text .. string.rep(" ", i)
			if dialectOnly("VoidElf", sample, 3):find("cff9a70c8", 1, true) then
				hits = hits + 1
			end
		end
		return hits
	end
	local calm = whisperCount("it is quiet today and all is well here", 40)
	local frantic = whisperCount("THEY ARE COMING! RUN! GET OUT NOW!", 40)
	check("an agitated void elf whispers more than a calm one", frantic > calm,
		string.format("calm=%d frantic=%d", calm, frantic))
	check("a calm void elf sometimes stays silent", calm < 40, tostring(calm))
end

--------------------------------------------------------------------------------
section("Dialect: register bugs stay fixed")
--------------------------------------------------------------------------------

do
	-- Negation must not break a verb mapping. Mid-clause the idiom correctly
	-- stays literal, so what matters is that it stays *grammatical*.
	local earthen = dialectOnly("EarthenDwarf", "I do not know if that will work")
	excludes("Earthen negation stays grammatical", earthen, "do not have recorded")
	contains("and reads as plain English", earthen, "I do not know if")
	-- Standing alone, it does resolve to the Earthen idiom.
	contains("the clause-final form still fires",
		dialectOnly("EarthenDwarf", "I do not know."), "no record of that")

	-- Verb vs noun, the same trap Goblin fell into.
	contains("Kul Tiran leaves the verb 'work' alone",
		dialectOnly("KulTiran", "I reckon that will work"), "will work")

	-- A flavour suffix must not echo the word already ending the sentence.
	for i = 1, 30 do
		local result = dialectOnly("Vulpera", "that will work, friend" .. string.rep(" ", i))
		excludes("Vulpera does not append a duplicate 'friend'", result, "friend, friend")
	end
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

	-- A strength-gated phrase must beat the base rule it overlaps with.
	contains("the glossary overrides the plain idiom at strength 3",
		dialectOnly("NightElf", "thank you for the help", 3), "Shaha lor'ma")
	contains("while strength 2 keeps the English idiom",
		dialectOnly("NightElf", "thank you for the help", 2), "you have my gratitude")

	-- Longer glossary phrases must win over the shorter ones they contain.
	contains("good fortune to your family resolves whole",
		dialectOnly("NightElf", "good fortune to your family", 3), "Ishnu-dal-dieb")
	contains("and the shorter greeting still works",
		dialectOnly("NightElf", "good fortune to you", 3), "Ishnu-alah")

	contains("Xaxas for chaos", dialectOnly("NightElf", "this is chaos", 3), "xaxas")
	contains("Xaxas names Deathwing", dialectOnly("NightElf", "Deathwing is coming", 3), "Xaxas")
	contains("an'da for father", dialectOnly("NightElf", "my father waits", 3), "an'da")
	contains("Fandu-dath-belore for who goes there",
		dialectOnly("NightElf", "who goes there", 3), "Fandu-dath-belore")

	-- Reported: a farewell was being used as a greeting. "Asha'falah" is a
	-- goodbye and was serving as both the strength-3 "hello" and a flavour prefix.
	do
		local FAREWELLS = { "Ande'thoras%-ethil", "Asha'falah", "En'shu falah%-nah" }
		local GREETINGS = { "Ishnu%-alah", "Ishnu%-dal%-dieb", "Elune%-adore", "Sael'ah" }

		-- dialectOnly strips the flavour and pins the seed, which is exactly what
		-- must vary here: the fault was a flavour prefix, and the fix is a list of
		-- alternatives chosen from the seed.
		local function darn(text, strength, seed)
			local ctx = E.Pipeline.NewContext(text, seed, "NightElf")
			ctx.strength = strength
			return E.Engine.Apply(E.DIALECTS["NightElf"], text, ctx)
		end

		local function saysAny(text, list)
			for _, word in ipairs(list) do
				if text:find(word) then return true end
			end
			return false
		end

		for _, strength in ipairs({ 1, 2, 3 }) do
			local greetBad, partBad = 0, 0
			for i = 1, 40 do
				local hi = darn("Hello there.", strength, "P-g-" .. i)
				local bye = darn("Goodbye.", strength, "P-b-" .. i)
				if saysAny(hi, FAREWELLS) then greetBad = greetBad + 1 end
				-- A greeting prefixed to a farewell is the same fault inverted:
				-- "Ishnu-alah. Ande'thoras-ethil." reads as "hello, goodbye".
				if saysAny(bye, GREETINGS) then partBad = partBad + 1 end
			end
			eq("a greeting never renders as a farewell at strength " .. strength, greetBad, 0)
			eq("nor a farewell as a greeting at strength " .. strength, partBad, 0)
		end
	end

	-- Also reported: every Night Elf greeted identically. Darnassian has three
	-- attested greetings and only one was used.
	do
		local function darn(text, seed)
			local ctx = E.Pipeline.NewContext(text, seed, "NightElf")
			ctx.strength = 3
			return E.Engine.Apply(E.DIALECTS["NightElf"], text, ctx)
		end
		local greetings, farewells = {}, {}
		for i = 1, 60 do
			greetings[darn("Hello.", "P-v-" .. i)] = true
			farewells[darn("Goodbye.", "P-w-" .. i)] = true
		end
		local function count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
		check("greetings vary between messages", count(greetings) > 2, count(greetings) .. " forms")
		check("and so do farewells", count(farewells) > 2, count(farewells) .. " forms")
	end

	-- The same message from the same speaker must always render identically, or
	-- two players with the addon would disagree about what was said.
	do
		local function darn()
			local ctx = E.Pipeline.NewContext("Hello there.", "P-stable", "NightElf")
			ctx.strength = 3
			return E.Engine.Apply(E.DIALECTS["NightElf"], "Hello there.", ctx)
		end
		local first = darn()
		local stable = true
		for _ = 1, 10 do
			if darn() ~= first then stable = false end
		end
		check("a varied greeting is still deterministic", stable, first)
	end

	-- Reported: "Farewell friend" became "En'shu falah-nah shan'do", and shan'do
	-- means teacher. The glossary three lines away glosses it correctly, so the
	-- dialect was contradicting itself and addressing strangers as their master.
	do
		local function darn(text, strength, seed)
			local ctx = E.Pipeline.NewContext(text, seed, "NightElf")
			ctx.strength = strength
			return E.Engine.Apply(E.DIALECTS["NightElf"], text, ctx)
		end

		for _, strength in ipairs({ 1, 2, 3 }) do
			local wrong = 0
			for i = 1, 40 do
				for _, line in ipairs({ "Farewell friend", "Hello friend", "Thank you my friend" }) do
					if darn(line, strength, "P-sd-" .. i):find("shan'do") then wrong = wrong + 1 end
				end
			end
			eq("shan'do is never used for friend at strength " .. strength, wrong, 0)
		end

		-- It remains correct where it belongs.
		contains("but still means teacher", darn("my teacher", 3, "P-t"), "shan'do")
		contains("and mentor", darn("my mentor", 3, "P-t"), "shan'do")

		-- Reported: kaldorei measure their lives in millennia, so addressing
		-- another elf as "young one" is nonsense. A suffix is appended regardless
		-- of who is listening, so it cannot assume the listener is younger.
		for _, strength in ipairs({ 1, 2, 3 }) do
			local young = 0
			for i = 1, 40 do
				if darn("I do not know", strength, "P-y-" .. i):find("young one") then
					young = young + 1
				end
			end
			eq("no one is called young one at random at strength " .. strength, young, 0)
		end

		-- The condescension survives where the listener is known to be younger.
		contains("a human is still a young one", darn("the human waits", 2, "P-h"), "young one")

		-- Reported: "kin" was the fix for shan'do and is wrong for its own reason.
		-- It claims shared blood, and Night Elves talk to Dwarves, Draenei and the
		-- Forsaken. Which term of address fits depends on who is listening, so the
		-- dialect no longer chooses one -- neither by rewriting the word nor by
		-- appending a vocative to an arbitrary sentence.
		for _, strength in ipairs({ 1, 2, 3 }) do
			local claimed = 0
			for i = 1, 40 do
				for _, line in ipairs({ "Farewell friend", "Hello friend", "greetings my ally",
				                        "I do not know", "the road is long" }) do
					local out = darn(line, strength, "P-k-" .. i)
					if out:find("%f[%a]kin%f[%A]") or out:find("%f[%a]kindred%f[%A]") then
						claimed = claimed + 1
					end
				end
			end
			eq("no one is called kin at strength " .. strength, claimed, 0)
		end

		-- And the player's own choice of word survives untouched, whichever they
		-- picked. These are all things a Night Elf might say; the addon does not
		-- get a vote.
		for _, term in ipairs({ "friend", "brother", "sister", "kin", "kindred" }) do
			contains(term .. " is left as the player typed it",
				darn("well met " .. term, 3, "P-kt"), term)
		end
	end

	-- A replacement must not carry its own sentence punctuation. "Fandu-dath-belore?"
	-- read correctly alone but produced "Fandu-dath-belore?, stranger?" the moment
	-- anything followed it, because the source text supplies the punctuation.
	excludes("a glossary phrase does not bring its own question mark",
		dialectOnly("NightElf", "who goes there, stranger?", 3), "?,")
end

--------------------------------------------------------------------------------
section("Void Elf: the whispers")
--------------------------------------------------------------------------------

do
	-- The whispers are inserted rather than substituted, and they arrive wrapped
	-- in a colour code. Two separate faults came of that.
	--
	-- First, they were on `post`, which runs once per plain chunk. Every
	-- protected span starts a new chunk, so naming another character -- the most
	-- ordinary thing anyone does in roleplay -- fired the insertion twice, one of
	-- them wedged mid-sentence and glued to the name with no space:
	--
	--   I will meet  |cff9a70c8*we are always here*|rBrightmoore at the gate ...
	local function agitated(text, seed)
		local dialect = E.DIALECTS["VoidElf"]
		local saved = dialect.flavor
		dialect.flavor = nil
		local ctx = E.Pipeline.NewContext(text, seed, "VoidElf")
		ctx.strength = 3
		ctx.excitement = 1
		local out = E.Engine.Apply(dialect, text, ctx)
		dialect.flavor = saved
		return out
	end

	local worst, sample = 0, nil
	local glued = nil
	for i = 1, 120 do
		for _, line in ipairs({
			"I will meet Brightmoore at the gate",
			"we go now (brb one moment) and then east",
			"tell Brightmoore and Aelric to wait",
		}) do
			local out = agitated(line, "P-ve-" .. i)
			local n = select(2, out:gsub("|cff9a70c8", ""))
			if n > worst then worst, sample = n, out end
			-- The colour close must never butt straight against a word.
			if out:find("|r%a") then glued = out end
		end
	end
	check("at most one whisper per message", worst <= 1, sample)
	check("and none is glued to the text after it", glued == nil, glued)

	-- Second, and worse: the escape guard added with the item-link fix demanded
	-- the escapes be identical before and after, and a whisper adds some. So the
	-- guard threw away the whole transform -- the entire dialect, not just the
	-- whisper -- and a fifth of what a Void Elf said went out as plain English
	-- with no error anywhere. The guard is for corruption of existing escapes,
	-- not for forbidding new ones.
	do
		E.db.modules.dialect.strength = 3
		local survived = 0
		for i = 1, 200 do
			local out = E.Pipeline.Run("I hear the shadow and the silence around us.",
				"Player-1-VEG" .. i, "VoidElf", nil, "incoming", "say")
			if out:find("|cff9a70c8") then survived = survived + 1 end
		end
		check("whispers survive the pipeline at all", survived > 0,
			survived .. " of 200 got through")
		E.db.modules.dialect.strength = 2
	end

	-- The guard still has to catch what it was built for: an escape that was
	-- there and came back mangled, dropped, or reordered.
	check("a mangled escape is still caught",
		not E.EscapesPreserved("|cnIQ3:[Blade]|r", "|gnIG3:[Blade]|r"))
	check("a dropped escape is still caught",
		not E.EscapesPreserved("|cffffffff|Hitem:1|h[A]|h|r", "|cffffffff[A]|r"))
	check("an added escape is allowed",
		E.EscapesPreserved("hello", "hello |cff9a70c8*listen*|r"))
	check("an untouched link passes",
		E.EscapesPreserved("|cnIQ3:[Blade]|r", "|cnIQ3:[Blade]|r"))
	check("text with no escapes at all passes",
		E.EscapesPreserved("hello", "goodbye"))
end

--------------------------------------------------------------------------------
section("Dialect: Thalassian glossary")
--------------------------------------------------------------------------------

do
	-- Attested Thalassian, gated behind strength 3 exactly like Darnassian.
	contains("greeting is used at strength 3",
		dialectOnly("BloodElf", "greetings traveler", 3), "Bal'a dash, malanore")
	excludes("but not at strength 2",
		dialectOnly("BloodElf", "greetings traveler", 2), "Bal'a dash")

	contains("Al diel shala for safe travels",
		dialectOnly("BloodElf", "safe travels", 3), "Al diel shala")
	contains("Anar'alah belore for by the light of the sun",
		dialectOnly("BloodElf", "by the light of the sun", 3), "Anar'alah belore")
	contains("Doral ana'diel for how are you",
		dialectOnly("BloodElf", "how are you", 3), "Doral ana'diel")
	contains("Selama ashal'anore for justice for our people",
		dialectOnly("BloodElf", "justice for our people", 3), "Selama ashal'anore")
	contains("sin'dorei for blood elves",
		dialectOnly("BloodElf", "the blood elves are here", 3), "sin'dorei")
	contains("belore for sun", dialectOnly("BloodElf", "the sun is setting", 3), "belore")
	contains("shorel'aran for farewell",
		dialectOnly("BloodElf", "farewell", 3), "shorel'aran")

	-- Same punctuation rule as Darnassian.
	excludes("no doubled punctuation mid-sentence",
		dialectOnly("BloodElf", "how are you, friend?", 3), "?,")

	-- Longer phrases must beat the shorter ones they contain: "by the light of the
	-- sun" must not be eaten by the bare "sun" word rule.
	local full = dialectOnly("BloodElf", "by the light of the sun", 3)
	excludes("the sun phrase is not shredded by the word rule", full, "the belore")

	-- Nightborne speak Shalassian, a separate language. Thalassian must not leak
	-- into their dialect just because both are elven.
	excludes("Thalassian does not leak into Nightborne",
		dialectOnly("Nightborne", "safe travels", 3), "Al diel shala")
end

--------------------------------------------------------------------------------
section("Dialect: Orcish glossary")
--------------------------------------------------------------------------------

do
	contains("Throm-Ka for well met", dialectOnly("Orc", "well met", 3), "Throm-Ka")
	excludes("but not at strength 2", dialectOnly("Orc", "well met", 2), "Throm-Ka")

	contains("Lok'tar ogar for victory or death",
		dialectOnly("Orc", "victory or death", 3), "Lok'tar ogar")
	contains("Gol'Kosh for by my axe", dialectOnly("Orc", "by my axe", 3), "Gol'Kosh")
	contains("Dabu for I obey", dialectOnly("Orc", "i obey", 3), "Dabu")
	contains("Lok-Regar for ready for orders",
		dialectOnly("Orc", "ready for orders", 3), "Lok-Regar")
	contains("Mak'gora for duel of honour",
		dialectOnly("Orc", "a duel of honor", 3), "Mak'gora")
	contains("ur'gora for coward", dialectOnly("Orc", "he is a coward", 3), "ur'gora")
	contains("zug zug for yes", dialectOnly("Orc", "yes", 3), "zug zug")

	-- The longer phrase must beat the bare "victory" word rule.
	local both = dialectOnly("Orc", "victory or death", 3)
	excludes("victory or death is not shredded into lok'tar or death", both, "or death")

	-- Aka'Magosh is attested ORCISH, not Draenei. It sat in the Draenei dialect
	-- for several releases purely because it sounds like it belongs there.
	contains("Aka'Magosh is Orcish",
		dialectOnly("Orc", "a blessing on you and yours", 3), "Aka'Magosh")
	excludes("and is no longer claimed by Draenei",
		dialectOnly("Draenei", "a blessing on you and yours", 3), "Aka'Magosh")

	-- Regression: "victory" mapped to "victory or death", so any line already
	-- containing "or death" got it appended twice.
	excludes("victory does not expand self-referentially",
		dialectOnly("Orc", "victory or death", 2), "or death or death")

	-- Regression: contempt for fleeing belonged on the phrase. As a bare word
	-- rule it produced "flee like a coward away" and "I flee like a coward every
	-- day" for a neutral use of "run".
	local neutral = dialectOnly("Orc", "I run every day", 2)
	excludes("a neutral run is not made contemptuous", neutral, "like a coward")
	local flee = dialectOnly("Orc", "run away", 2)
	excludes("and run away leaves no orphaned word", flee, "coward away")
end

--------------------------------------------------------------------------------
section("Escape sequences survive the filters")
--------------------------------------------------------------------------------

do
	-- Reported from live: shift-clicking an item into /say produced
	--   SendChatMessage(): Invalid escape code in chat message
	-- with the text "|gnIG3:[Spellbreaker's Phoenixblade]". Modern item links
	-- carry a named colour escape, "|cnIQ3:", which PROTECTED did not know about,
	-- so the Muffle filter rewrote c to g and Q to G inside it and the client
	-- refused the whole message.
	local MODERN = "|cnIQ3:|Hitem:44731::::::::70:::::|h[Spellbreaker's Phoenixblade]|h|r"
	local LEGACY = "|cff0070dd|Hitem:44731::::::::70:::::|h[Spellbreaker's Phoenixblade]|h|r"

	for _, link in ipairs({ MODERN, LEGACY }) do
		local plain = {}
		for _, seg in ipairs(E.Tokenize(link, true)) do
			if not seg.protected then plain[#plain + 1] = seg.text end
		end
		eq("the whole link is protected: " .. link:sub(1, 12), table.concat(plain), "")
	end

	-- End to end, with the filter that actually broke it.
	do
		onlyModules("muffle")
		E.db.modules.muffle.enabled = true
		E.db.modules.muffle.strength = 3
		for _, link in ipairs({ MODERN, LEGACY }) do
			local out = E.Pipeline.Run("look at this " .. link, nil, "Human", nil, "outgoing", "say")
			contains("the escape survives muffling", out, link)
		end
		-- And the surrounding words are still muffled, or the protection would be
		-- indistinguishable from the filter not running.
		local out = E.Pipeline.Run("look at this " .. MODERN, nil, "Human", nil, "outgoing", "say")
		excludes("while the prose around it is not", out, "look at this ")
	end

	-- The guard itself. A filter that mangles an escape must have its work
	-- discarded rather than shipped, whatever the cause.
	do
		eq("an unchanged signature compares equal",
			E.EscapeSignature(MODERN), E.EscapeSignature(MODERN))
		check("a mangled colour escape is detected",
			E.EscapeSignature("|cnIQ3:x") ~= E.EscapeSignature("|gnIG3:x"))
		check("and a dropped escape too",
			E.EscapeSignature(MODERN) ~= E.EscapeSignature("[Spellbreaker's Phoenixblade]"))
		eq("a literal pipe is one marker, not two",
			E.EscapeSignature("a || b"), "||")
	end

	onlyModules("dialect")
end

--------------------------------------------------------------------------------
section("Personal speech effects: lisp and muffle")
--------------------------------------------------------------------------------

do
	-- Requested by Sleat of Argent Dawn (EU). Unlike every other filter these
	-- describe the speaker's own mouth, so they apply to what you send and never
	-- to what you receive.
	check("the lisp is registered", E.MODULES.lisp ~= nil)
	check("and the muffle", E.MODULES.muffle ~= nil)
	check("both are off by default",
		E.DEFAULTS.modules.lisp.enabled == false and E.DEFAULTS.modules.muffle.enabled == false)
	check("and both are self only",
		E.MODULES.lisp.selfOnly == true and E.MODULES.muffle.selfOnly == true)

	local lisp, muffle = E.MODULES.lisp.Lisp, E.MODULES.muffle.Muffle

	eq("s becomes th", lisp("Yes sir", 1), "Yeth thir")
	eq("capitals are kept", lisp("Sir", 1), "Thir")
	eq("z too", lisp("zeal", 1), "theal")
	-- "sh" must be handled before "s", or it becomes "thh".
	excludes("sh does not double up", lisp("shield", 2), "thh")
	-- Soft c only: "cat" must not become "that".
	eq("a hard c is untouched", lisp("cat", 2), "cat")
	contains("but a soft c lisps", lisp("city", 2), "th")

	-- Muffling keeps the shape of the word, which is what makes it read as
	-- speech rather than noise.
	local muffled = muffle("stand aside friend", 2)
	check("muffled text is still word-shaped",
		select(2, muffled:gsub("%s+", "")) == select(2, ("stand aside friend"):gsub("%s+", "")),
		muffled)
	check("and is actually changed", muffled ~= "stand aside friend", muffled)
	-- "th" is a digraph and must not be eaten by the "t" rule.
	eq("th is handled before t", muffle("the", 2), "de")
	check("light is gentler than heavy",
		muffle("stand aside", 1) ~= muffle("stand aside", 3))

	-- Both must respect the protections every other filter honours.
	local protected = E.Pipeline.Run
	do
		local saved = E.db.modules
		onlyModules("lisp")
		E.db.modules.lisp.enabled = true
		local out = protected("say (( sorry, brb )) so", nil, "Human", nil, "outgoing", "say")
		contains("an OOC aside is not lisped", out, "(( sorry, brb ))")
		E.db.modules = saved
	end

	-- Self only, enforced by the pipeline rather than by a setting: lisping a
	-- stranger's chat would be putting words in their mouth.
	do
		onlyModules("lisp")
		E.db.modules.lisp.enabled = true
		E.db.modules.lisp.incoming = true  -- even asked for explicitly
		local incoming = E.Pipeline.Run("Yes sir", "Player-1-TEST", "Human", "Common", nil, "say")
		eq("incoming chat is never lisped", incoming, "Yes sir")
		local outgoing = E.Pipeline.Run("Yes sir", nil, "Human", nil, "outgoing", "say")
		check("but your own outgoing text is", outgoing ~= "Yes sir", outgoing)
		E.db.modules.lisp.incoming = nil
	end

	onlyModules("dialect")
end

--------------------------------------------------------------------------------
section("Emotes are narration with speech quoted inside")
--------------------------------------------------------------------------------

do
	-- E.MapQuoted first, on its own.
	local function up(s) return s:upper() end
	eq("narration outside quotes is untouched",
		E.MapQuoted('holds out a flower. "here you go."', up),
		'holds out a flower. "HERE YOU GO."')
	eq("several quoted spans are each transformed",
		E.MapQuoted('"one." he nods. "two."', up), '"ONE." he nods. "TWO."')
	eq("no quotes means no transformation",
		E.MapQuoted("laughs heartily", up), "laughs heartily")
	eq("an unclosed quote runs to the end",
		E.MapQuoted('says "and then', up), 'says "AND THEN')

	-- Apostrophes must never be read as delimiters. The dialects emit no',
	-- dinnae, shan'do and Lok'tar constantly; treating ' as a quote would carve
	-- speech spans out of the middle of words.
	eq("apostrophes are not quote marks",
		E.MapQuoted("no' dinnae shan'do Lok'tar", up), "no' dinnae shan'do Lok'tar")

	-- Curly quotes, which some clients and copy-paste produce.
	local curly = "nods. \226\128\156like this\226\128\157 and after"
	eq("curly quotes are recognised",
		E.MapQuoted(curly, up), "nods. \226\128\156LIKE THIS\226\128\157 and after")

	check("HasQuotedSpeech finds a straight quote", E.HasQuotedSpeech('a "b"'))
	check("and a curly one", E.HasQuotedSpeech("a \226\128\156b\226\128\157"))
	check("and reports none when there is none", not E.HasQuotedSpeech("no quotes here"))
	check("an apostrophe is not quoted speech", not E.HasQuotedSpeech("dinnae ken"))
end

do
	-- Now through the pipeline, where only the Dialectician is restricted.
	onlyModules("dialect")
	E.db.modules.dialect.incoming = true
	E.db.modules.dialect.strength = 2

	local emote = 'holds out a flower. "I don\'t know if you will like it, friend."'

	local out = E.Pipeline.Run(emote, "P-emote", "Dwarf", "Common", nil, "emote")
	contains("the quoted speech is dialected", out, "dinnae ken")
	contains("the narration keeps its plain English", out, "holds out a flower")
	excludes("and is not accented", out, "haulds")
	excludes("nor respelled", out, "oot a flooer")

	-- The same text on /say is speech end to end, so quotes restrict nothing.
	local said = E.Pipeline.Run(emote, "P-emote", "Dwarf", "Common", nil, "say")
	contains("on /say the whole line is dialected", said, "dinnae ken")
	check("including the part outside the quotes",
		said:find("holds out a flower", 1, true) == nil, said)

	-- A pure action emote has no speech in it at all.
	local action = "laughs and holds out a flower"
	eq("an emote with no quotes is left alone",
		E.Pipeline.Run(action, "P-emote", "Dwarf", "Common", nil, "emote"), action)

	-- A missing channel must not accidentally trigger the emote rule; the
	-- doctor's pipeline test and the outgoing fallback both pass none.
	check("no channel behaves like ordinary speech",
		E.Pipeline.Run(emote, "P-emote", "Dwarf", "Common"):find("holds out a flower", 1, true) == nil)
end

do
	-- Asterisks mark an action inside an otherwise spoken line. Same principle as
	-- an emote: the starred part is narration and must not be accented.
	onlyModules("dialect")
	E.db.modules.dialect.incoming = true
	E.db.modules.dialect.strength = 2

	local function say(text)
		return E.Pipeline.Run(text, "P-star", "Dwarf", "Common", nil, "say")
	end

	local mixed = say("Here this is for you *pulls out a flower* hope you like it.")
	contains("the action survives verbatim", mixed, "*pulls out a flower*")
	check("while the speech around it is dialected", mixed:find("fer ye", 1, true) ~= nil, mixed)

	contains("several actions in one line all survive",
		say("*one* and *two* and you know"), "*one* and *two*")

	-- An unmatched asterisk is ordinary text, not an unterminated action.
	check("an unmatched asterisk does not swallow the rest",
		say("unmatched *asterisk here and you know"):find("ye ken", 1, true) ~= nil)

	-- A lone asterisk between digits is arithmetic, not an action, and needs no
	-- special handling as long as a span requires a matched pair.
	contains("arithmetic is left intact", say("you know 2*3 is six"), "2*3")

	-- Flavour must be added once to the finished line. Splitting the text around
	-- the action and dialecting each fragment separately would let a prefix land
	-- in the middle of a sentence.
	for i = 1, 30 do
		local out = E.Pipeline.Run("this is for you *pulls out a flower* hope you like it",
			"P-flavour-" .. i, "Dwarf", "Common", nil, "say")
		local n = select(2, out:gsub("Och,", "")) + select(2, out:gsub("Aye,", ""))
			+ select(2, out:gsub("Weel noo,", "")) + select(2, out:gsub("Hoots!", ""))
		if n > 1 then
			check("flavour is not applied per fragment", false, out)
			break
		end
	end
	check("flavour is not applied per fragment", true)

	-- The two rules compose: an action inside quoted speech inside an emote.
	local both = E.Pipeline.Run('nods. "I do not know *shrugs* friend."',
		"P-star", "Dwarf", "Common", nil, "emote")
	contains("narration outside the quotes is untouched", both, "nods.")
	contains("the action inside the quotes is untouched", both, "*shrugs*")
	check("and the speech around it is still dialected", both:find("ken", 1, true) ~= nil, both)
end

--------------------------------------------------------------------------------
section("Class decides what a speaker would never say")
--------------------------------------------------------------------------------

do
	-- Reported by a player of a Human Death Knight: the Human dialect offers
	-- "By the Light," as an interjection, which is fine from a farmer in Elwynn
	-- and absurd from a risen knight of the Ebon Blade.
	onlyModules("dialect")
	E.db.modules.dialect.incoming = true

	local function speak(text, class, race, strength)
		local ctx = E.Pipeline.NewContext(text, "P-class", race or "Human", nil, class)
		ctx.strength = strength or 2
		return E.MODULES.dialect.Filter(text, ctx)
	end

	-- The reported line.
	local human = E.DIALECTS["Human"]
	local dk = E.Class.Apply(human, "DEATHKNIGHT")
	local function has(list, needle)
		for _, line in ipairs(list or {}) do
			if line:find(needle, 1, true) then return true end
		end
		return false
	end

	check("the Human dialect does offer the Light", has(human.flavor.prefix, "By the Light"))
	check("a Death Knight never does", not has(dk.flavor.prefix, "Light"))
	check("nor in the suffixes", not has(dk.flavor.suffix, "Light"))

	-- The racial voice must survive. Stripping the whole flavour table would
	-- flatten every Death Knight into the same person regardless of their race.
	check("but keeps the racial flavour that does not clash",
		has(dk.flavor.prefix, "Well met.") and has(dk.flavor.prefix, "Ho there,"))
	check("and adds its own", has(dk.flavor.prefix, "Suffer well."))

	-- The Ebon Blade's own farewell.
	contains("goodbye becomes suffer well", speak("Goodbye, friend.", "DEATHKNIGHT"), "Suffer well")
	contains("good luck becomes die well", speak("Good luck out there.", "DEATHKNIGHT"), "Die well")

	-- The same mechanism runs the other way: a paladin leans in.
	local pal = E.Class.Apply(human, "PALADIN")
	check("a Paladin keeps the Light", has(pal.flavor.prefix, "By the Light,"))
	contains("and invokes it where a plain Human would not",
		speak("Good luck out there.", "PALADIN"), "the Light watch over you")

	-- A class with no layer changes nothing.
	eq("an unlayered class is left to the race",
		speak("Goodbye, friend.", "WARRIOR"), speak("Goodbye, friend.", nil))

	-- The accent still belongs to the race. A Dwarf Death Knight stops invoking
	-- the Light but keeps speaking Scots.
	local dwarfDK = speak("I don't know, friend.", "DEATHKNIGHT", "Dwarf")
	contains("a Dwarf Death Knight still speaks Scots", dwarfDK, "dinnae")

	-- Off by setting.
	E.db.dialect.classFlavor = false
	eq("the layer can be switched off",
		speak("Goodbye, friend.", "DEATHKNIGHT"), speak("Goodbye, friend.", nil))
	E.db.dialect.classFlavor = true
	check("and back on", speak("Goodbye, friend.", "DEATHKNIGHT"):find("Suffer well") ~= nil)

	-- Reported from a Human Death Knight: "Goodbye, friend." came out as
	-- "Suffer well, companion, friend". Two different words doing the same job.
	--
	-- The cause is a module interaction rather than the class layer. The Fantasy
	-- Writer maps "friend" to "companion" and runs before the Dialectician, so
	-- the exact-match guard in ApplyFlavor saw "companion" and appended its own
	-- "friend" on top.
	do
		local saved = E.db.modules.fantasy.enabled
		E.db.modules.fantasy.enabled = true
		E.db.modules.fantasy.incoming = true

		local doubled = 0
		for i = 1, 60 do
			local out = E.Pipeline.Run("Goodbye, friend.", "P-voc-" .. i, "Human", "Common")
			-- Any two terms of address in one line is one too many.
			local n = 0
			for _, word in ipairs({ "friend", "companion", "laddie", "lassie", "comrade" }) do
				for _ in out:lower():gmatch("%f[%a]" .. word .. "%f[%A]") do n = n + 1 end
			end
			if n > 1 then doubled = doubled + 1 end
		end
		eq("a line never carries two terms of address", doubled, 0)

		E.db.modules.fantasy.enabled = saved
	end

	-- Two mechanisms guard this, and they are not redundant.
	--
	-- E.CollapseVocatives works on comma-separated parts, so it cannot see a
	-- vocative that is simply the last word of a clause. The guard inside
	-- ApplyFlavor covers that case by declining to add the suffix at all. If
	-- either is deleted as dead code, one of these fails.
	eq("the collapse handles comma-separated pairs",
		E.CollapseVocatives("King's honor, friend, companion."), "King's honor, friend.")
	eq("but cannot see a vocative that ends a clause without one",
		E.CollapseVocatives("Hello friend, laddie."), "Hello friend, laddie.")
	eq("and leaves an ordinary trailing tag alone",
		E.CollapseVocatives("Suffer well, companion, aye."), "Suffer well, companion, aye.")
	-- "thank you" became "my thanks to you" in the Fantasy Writer, then the Human
	-- dialect's ["thanks"] = "my thanks" fired on that, giving "My my thanks to
	-- you". Same shape as the doubled articles, so the same collapse handles it.
	eq("a repeated possessive collapses",
		dialectOnly("Human", "thank you", 2):find("My my") == nil and "ok" or "doubled", "ok")

	eq("a single vocative is untouched",
		E.CollapseVocatives("Goodbye, friend."), "Goodbye, friend.")
	eq("text without commas is returned as is",
		E.CollapseVocatives("Goodbye friend"), "Goodbye friend")

	-- The flavour suffix is still added when there is no vocative to clash with.
	do
		local added = false
		for i = 1, 60 do
			local out = E.Pipeline.Run("I do not know", "P-suf-" .. i, "Human", "Common")
			if out:find(",") then added = true break end
		end
		check("but a suffix is still added when nothing clashes", added)
	end

	-- A class only gets to speak if its idiom survives long enough to reach the
	-- Dialectician, and the Fantasy Writer runs first. It was rewriting
	-- "good luck" into "fortune favour you", so a Death Knight wished people well
	-- like anyone else -- the same failure as "By the Light", by another route.
	do
		local saved = E.db.modules.fantasy.enabled
		E.db.modules.fantasy.enabled = true
		E.db.modules.fantasy.incoming = true
		onlyModules("fantasy", "dialect")

		local function full(text, class)
			local ctx = E.Pipeline.NewContext(text, "P-prec", "Human", nil, class)
			local out = text
			for _, key in ipairs(E.MODULE_ORDER) do
				local m, st = E.MODULES[key], E.db.modules[key]
				if m and st.enabled then ctx.strength = st.strength; out = m.Filter(out, ctx) or out end
			end
			return out
		end

		contains("a Death Knight's idiom beats the Fantasy Writer",
			full("Good luck out there.", "DEATHKNIGHT"), "Die well")
		excludes("and the generic version does not survive",
			full("Good luck out there.", "DEATHKNIGHT"), "Fortune favour")
		contains("while a speaker with no layer still gets the fantasy version",
			full("Good luck out there.", nil), "Fortune favour")

		-- The claim patterns are authored in lower case; the text is not.
		contains("a claim matches regardless of capitalisation",
			full("GOOD LUCK out there.", "DEATHKNIGHT"), "well")

		-- Switching the layer off returns the idiom to the Fantasy Writer.
		E.db.dialect.classFlavor = false
		contains("with class flavour off the Fantasy Writer keeps it",
			full("Good luck out there.", "DEATHKNIGHT"), "Fortune favour")
		E.db.dialect.classFlavor = true

		E.db.modules.fantasy.enabled = saved
		onlyModules("dialect")
	end

	-- Every registered layer must produce a usable rule set for every race,
	-- which is where a typo in one of the Classes files would surface.
	for token in pairs(E.CLASSES) do
		for race in pairs(E.DIALECTS) do
			local out = speak("Hello there, I don't know if that will work, friend.", token, race, 3)
			check(token .. " on " .. race .. " produces text",
				type(out) == "string" and out ~= "", tostring(out))
		end
	end
end

--------------------------------------------------------------------------------
section("Dialect: Zandali glossary")
--------------------------------------------------------------------------------

do
	-- Shared by both troll dialects, since they speak the same language.
	for _, race in ipairs({ "Troll", "ZandalariTroll" }) do
		contains(race .. ": loa for spirits",
			dialectOnly(race, "the spirits are angry", 3), "loa")
		contains(race .. ": ma'da for mother",
			dialectOnly(race, "my mother waits", 3), "ma'da")
		contains(race .. ": dazdooga for fire",
			dialectOnly(race, "light the fire", 3), "dazdooga")
		contains(race .. ": juju for charm",
			dialectOnly(race, "she made a charm", 3), "juju")
		excludes(race .. ": ma'da is gated to strength 3",
			dialectOnly(race, "my mother waits", 2), "ma'da")

		-- Regression: several entries embedded the article, so "the spirits"
		-- became "the the loa" and "the gods" became "de da loa". The source
		-- sentence supplies the article; a replacement must not bring its own.
		for _, line in ipairs({ "the spirits are angry", "the gods watch us",
		                        "the magic is strong", "the death of kings" }) do
			local out = dialectOnly(race, line, 3)
			excludes(race .. ": no doubled article in \"" .. line .. "\"", out, "the the")
			excludes(race .. ": no de/da doubling in \"" .. line .. "\"", out, "de da")
		end
	end
end

--------------------------------------------------------------------------------
section("Dialect: races with no attested vocabulary get no glossary")
--------------------------------------------------------------------------------

do
	-- Four languages Blizzard never developed enough to draw on. The rule is
	-- attested-only, so these carry register rather than lexicon, and nothing was
	-- invented to fill the gap. Asserting it here keeps a well-meaning future
	-- edit from quietly adding fan coinages.
	--
	-- The specific traps: "sha" is glossed as Draenei for "light" but only ever
	-- appears inside compounds like Shattrath, and "modan" is Dwarven for
	-- "mountain" on the same compound-only basis.
	excludes("Draenei does not use the compound-only sha for light",
		dialectOnly("Draenei", "the light guides us", 3), "sha ")
	excludes("Dwarven does not use the compound-only modan for mountain",
		dialectOnly("Dwarf", "over the mountain", 3), "modan")

	-- Each still has to be a working dialect, not an empty one.
	for _, race in ipairs({ "Draenei", "Dwarf", "Gnome", "Tauren" }) do
		local out = dialectOnly(race, "I don't know if that will work, friend", 3)
		check(race .. " still transforms text without a glossary",
			type(out) == "string" and out ~= "I don't know if that will work, friend", out)
	end
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
	contains("decompression ran", result, "be richt back")
	contains("dialect ran", result, "laddie")
	-- The Spell Book is gated off for incoming: correcting someone else's
	-- spelling means erasing deliberate speech quirks.
	contains("spellbook did NOT correct someone else's typo", result, "dont")
	-- ...but it still runs on the way out, where the typo is your own.
	local mine = E.Pipeline.Run("i dont know", nil, "Dwarf", nil, "outgoing")
	contains("spellbook still fixes your own outgoing typos", mine, "dinnae")
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
	-- The language gate must FAIL OPEN. It sits in front of every incoming
	-- message, and if the language API returns nothing -- too early in login, or
	-- because the call moved -- treating that as "understands nothing" silently
	-- kills the entire incoming half while outgoing (which passes no language)
	-- carries on working perfectly. That asymmetry is very hard to diagnose.
	local savedLanguages = _G._languages
	_G._languages = {}
	E.Pipeline.RefreshLanguages()

	local languages, failed = E.Pipeline.LanguageInfo()
	check("an empty language list is reported as a failed lookup", failed,
		"languages: " .. table.concat(languages, ", "))
	check("and everything is understood rather than nothing",
		E.Pipeline.Understood("Common") and E.Pipeline.Understood("Thalassian"))

	onlyModules("dialect")
	local result = E.Pipeline.Run("I don't know friend", "Player-1-DWARF", "Dwarf", "Common")
	check("so incoming chat is still filtered", result ~= "I don't know friend", tostring(result))

	_G._languages = savedLanguages
	E.Pipeline.RefreshLanguages()
	check("a populated list stops being treated as a failure",
		not select(2, E.Pipeline.LanguageInfo()))
	eq("and unknown languages are skipped again",
		E.Pipeline.Run("zug zug lok'tar", "Player-1-DWARF", "Dwarf", "Thalassian"),
		"zug zug lok'tar")
end

do
	-- The filter must record what it decided, so "incoming does not work" can be
	-- distinguished from "the filter was never called".
	onlyModules("dialect")
	E.Chat.stats.calls = 0
	E.Chat.stats.changed = 0
	local filter = _G._filters["CHAT_MSG_SAY"][1]
	local args = { "i dont know friend", "Bromm", "Common", "", "", "", 0, 0, "", "", 42,
		"Player-1-DWARF", nil, false, false, false, false }
	filter(nil, "CHAT_MSG_SAY", unpack(args, 1, 17))
	eq("the filter counted the message", E.Chat.stats.calls, 1)
	eq("and counted the rewrite", E.Chat.stats.changed, 1)
	check("and recorded what it saw", E.Chat.lastSeen ~= nil)
	if E.Chat.lastSeen then
		eq("including the sender", E.Chat.lastSeen.sender, "Bromm")
		eq("and the resolved dialect", E.Chat.lastSeen.dialect, "Dwarven")
		eq("and a verdict", E.Chat.lastSeen.verdict, "rewritten")
	end

	-- Your own message with outgoing on is skipped, and says so.
	E.db.outgoing.enabled = true
	local mine = { "i dont know friend", "Me", "Common", "", "", "", 0, 0, "", "", 43,
		_G._playerGUID, nil, false, false, false, false }
	filter(nil, "CHAT_MSG_SAY", unpack(mine, 1, 17))
	eq("own messages are skipped", E.Chat.stats.skippedSelf, 1)
	contains("with a reason a player can act on", E.Chat.lastSeen.verdict, "already rewritten")

	check("/elo spy toggles", pcall(SlashCmdList["ELOQUENCE"], "spy"))
	check("/elo spy toggles back", pcall(SlashCmdList["ELOQUENCE"], "spy"))
	check("/elo doctor reports incoming stats", pcall(SlashCmdList["ELOQUENCE"], "doctor"))
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
	-- No race resolved means no dialect, but the other filters still run.
	onlyModules("spellbook")
	eq("filters work with no race at all",
		E.Pipeline.Run("i dont know", nil, nil, nil, "outgoing"), "i don't know")
end

--------------------------------------------------------------------------------
section("Race resolution")
--------------------------------------------------------------------------------

do
	_G._guidRaces["Player-1-VOID"] = { race = "VoidElf", class = "Mage", name = "Sylwen" }
	eq("resolves race from a GUID", E.Race.Resolve("Player-1-VOID", "Sylwen"), "VoidElf")
	eq("creature GUIDs resolve to nothing", E.Race.Resolve("Creature-0-1-2-3-4-5", "Kobold"), nil)
	eq("an unknown GUID resolves to nothing", E.Race.Resolve("Player-1-NOBODY", "Nobody"), nil)

	-- SECRET VALUES
	-- Modern clients hand addons values that may be held but not inspected. Using
	-- one as a table key raises "attempted to perform indexed assignment on a
	-- table that cannot be indexed with secret keys", which is what a raid roster
	-- scan hit on a boss kill. Race.Resolve runs for every chat message, so if it
	-- raises, the message disappears instead of merely going undialected.
	--
	-- Real secret values cannot be constructed here, so this stands in for one:
	-- a value that throws the moment anything inspects it, which is the property
	-- that matters.
	local secret = setmetatable({}, {
		__index = function() error("attempt to inspect a secret value", 2) end,
		__concat = function() error("attempt to concatenate a secret value", 2) end,
		__tostring = function() error("attempt to inspect a secret value", 2) end,
	})

	local before = E.Race.secretsSkipped
	local ok, result = pcall(E.Race.Resolve, "Player-1-VOID", secret)
	check("a secret name does not take Race.Resolve down with it", ok, tostring(result))
	eq("and the GUID still resolves the race", result, "VoidElf")

	ok = pcall(E.Race.Resolve, nil, secret)
	check("nor when there is no GUID to fall back on", ok)
	check("and the occurrence is counted for /elo doctor",
		E.Race.secretsSkipped > before,
		"before=" .. tostring(before) .. " after=" .. tostring(E.Race.secretsSkipped))

	-- A message from a secret-named speaker must still come out the other side.
	local out = E.Pipeline.Run("I don't know, friend", "Player-1-VOID", nil, "Common")
	check("chat from such a speaker still gets through", type(out) == "string" and out ~= "")

	-- Every playable race speaks for itself now; only token spelling variants
	-- are aliased.
	eq("void elves have their own dialect", E.Race.Canonical("VoidElf"), "VoidElf")
	eq("the Earthen spelling variant is aliased", E.Race.Canonical("Earthen"), "EarthenDwarf")

	-- The client reports "Harronir" (race ID 86), verified in game. Community
	-- writing often spells it "Haranir", so both must resolve.
	eq("the client's Harronir token resolves", E.Race.Canonical("Harronir"), "Harronir")
	eq("the Haranir spelling is aliased onto it", E.Race.Canonical("Haranir"), "Harronir")
	check("both spellings reach the same dialect",
		E.Race.DialectFor("Haranir") == E.DIALECTS["Harronir"])
	-- End to end, the way a real chat event arrives.
	onlyModules("dialect")
	_G._guidRaces["Player-1-HARR"] = { race = "Harronir", class = "Druid", name = "Root" }
	contains("a Harronir speaker gets the dialect",
		E.Pipeline.Run("I don't know, friend", "Player-1-HARR",
			E.Race.Resolve("Player-1-HARR", "Root"), "Common"),
		"traveler")
	check("a void elf gets Ren'dorei, not Thalassian",
		E.Race.DialectFor("VoidElf") == E.DIALECTS["VoidElf"])
end

do
	-- Regression guards for two mistakes that were in the first cut.
	check("Zandalari do NOT get the Darkspear patois",
		E.Race.DialectFor("ZandalariTroll") ~= E.DIALECTS["Troll"])
	eq("Zandalari get Zandali", E.DIALECTS["ZandalariTroll"].name, "Zandali")
	excludes("and Zandali does not respell 'the' as 'de'",
		dialectOnly("ZandalariTroll", "the other one is nothing"), "de other")
	contains("Darkspear still do get the patois",
		dialectOnly("Troll", "the other one is nothing"), "de udda")

	check("Earthen do NOT get the dwarven Scots",
		E.Race.DialectFor("EarthenDwarf") ~= E.DIALECTS["Dwarf"])
	excludes("and Earthen speech has no Scots in it",
		dialectOnly("EarthenDwarf", "I do not know if that will work, friend"), "wirk")
	contains("Dwarves still do get the Scots",
		dialectOnly("Dwarf", "I do not know if that will work, friend"), "wirk")

	-- Trollish is non-rhotic: "-er" and "-or" become "-a", as in wata and dokta.
	-- The rule used to delete the r and keep the vowel, which truncated words
	-- rather than respelling them. Every word that read correctly was an explicit
	-- entry in the tables; the rule itself only produced what looked like typos.
	do
		for _, case in ipairs({
			{ "the elder speaks", "elda" },   { "another matter", "matta" },
			{ "for honor", "hona" },          { "he is a warrior", "warria" },
			{ "my mentor taught me", "menta" },
		}) do
			contains("Trollish \"" .. case[1] .. "\"", dialectOnly("Troll", case[1], 3), case[2])
		end
		-- The explicit mappings still win, and must not be re-processed into
		-- something else on the way past.
		contains("water is still wata", dialectOnly("Troll", "the water is cold", 3), "wata")
		contains("over is still ova", dialectOnly("Troll", "over there", 3), "ova")
		-- "-ar" has no respelling that is not simply a misspelling.
		contains("star keeps its r", dialectOnly("Troll", "the star is bright", 3), "star")
		-- A letter is required in front of the vowel, or the conjunction is eaten.
		contains("the conjunction \"or\" survives",
			dialectOnly("Troll", "for honor or glory", 3), " or ")
	end

	-- Reported: a Dwarf should say "lassie" for a woman and "laddie" for a man,
	-- and the plurals were missing -- "the man" became "the laddie" while "the
	-- men" stayed as written.
	do
		for _, case in ipairs({
			{ "the man is here", "laddie" },   { "the men are here", "lads" },
			{ "the boy is here", "laddie" },   { "the boys are here", "lads" },
			{ "the woman is here", "lassie" }, { "the women are here", "lasses" },
			{ "the girl is here", "lassie" },  { "the girls are here", "lasses" },
		}) do
			contains("Dwarven \"" .. case[1] .. "\"", dialectOnly("Dwarf", case[1]), case[2])
		end

		-- "Lady" and "Lord" are titles as often as descriptions, and a Dwarf may
		-- well be respectful enough to use one. Worse, the mapping ate the title
		-- exactly when it led a sentence: mid-sentence the proper-noun rule
		-- protects it, but a capitalised word at the start of a sentence is
		-- indistinguishable from ordinary capitalisation, so "Lady Jaina is here"
		-- became "Lassie Jaina is here".
		--
		-- Checked on the three dialects that had a mapping for it. Leading the
		-- sentence is the case that regressed; the others are here so a future fix
		-- cannot pass by protecting only the position that was reported.
		for _, race in ipairs({ "Dwarf", "KulTiran", "Worgen" }) do
			for _, line in ipairs({
				"Lady Jaina is here", "I spoke to Lady Jaina",
				"Lord Fordragon sent me", "I spoke to Lord Fordragon",
			}) do
				local title = line:find("Lady") and "Lady" or "Lord"
				contains(race .. " keeps the title in \"" .. line .. "\"",
					dialectOnly(race, line), title)
			end
		end
	end

	-- The general form of that fault. Taking "lady" out of three dialects fixed
	-- three words; the shape of the bug was any mapped word that is also a title
	-- or a name, eaten when it leads a sentence -- where capitalisation carries
	-- no information and the proper-noun rule deliberately stands down.
	--
	-- The signal is the word after it. "Lady Jaina" is capitalised twice, and the
	-- second capital does mean something, because it is mid-sentence. A
	-- capitalised word in front of a protected one is a title or a first name.
	do
		for _, case in ipairs({
			{ "NightElf", "Master Aelric waits",     "Master" },
			{ "NightElf", "Teacher Aelric waits",    "Teacher" },
			{ "Troll",    "Sir Aelric waits",        "Sir" },
			{ "Human",    "King Anduin waits",       "King Anduin" },
			{ "Scourge",  "Queen Talanji waits",     "Queen" },
			{ "Draenei",  "Hope Brightmoore waits",  "Hope" },
			{ "KulTiran", "Storm Brightmoore waits", "Storm" },
			{ "VoidElf",  "Silence Brightmoore waits", "Silence" },
			{ "NightElf", "Fury Brightmoore waits",  "Fury" },
			{ "Orc",      "Human Brightmoore waits", "Human" },
		}) do
			contains(case[1] .. " keeps \"" .. case[3] .. "\" in front of a name",
				dialectOnly(case[1], case[2], 3), case[3])
		end

		-- The other half, and the one that makes this a heuristic rather than a
		-- blanket exemption: the same words must still be translated when they are
		-- not standing in front of a name. Protecting them everywhere would be a
		-- much worse bug than the one being fixed, and it would look like this
		-- test passing.
		for _, case in ipairs({
			{ "Draenei",  "Hope is what we have",  "Light's promise" },
			{ "Draenei",  "I still have hope",     "the Light's promise" },
			{ "NightElf", "my master taught me",   "shan'do" },
			{ "Human",    "the king rules",        "the King" },
			{ "Dwarf",    "the water is cold",     "watter" },
			{ "Troll",    "the horde is coming",   "de horde" },
		}) do
			contains(case[1] .. " still translates \"" .. case[2] .. "\"",
				dialectOnly(case[1], case[2], 3), case[3])
		end

		-- A full stop between them is two sentences, not a pair.
		contains("a sentence boundary does not make a pair",
			dialectOnly("Draenei", "We go. Hope is all we have", 3), "Light's promise")

		-- Shouting is not evidence of a name; the whole line may be capitals.
		excludes("a shouted line is not read as names",
			dialectOnly("Troll", "THE HORDE IS COMING", 3), "THE HORDE IS COMING")
	end
end

do
	-- Every race the client can report should have something to say. If Blizzard
	-- adds one, this is the test that will notice.
	--
	-- The allied-race and later tokens here were confirmed against a live client
	-- (see the table at the top of Core/Race.lua); the classic thirteen use their
	-- long-stable tokens.
	local PLAYABLE = {
		"Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Worgen", "Pandaren",
		"Orc", "Scourge", "Tauren", "Troll", "BloodElf", "Goblin",
		"VoidElf", "LightforgedDraenei", "DarkIronDwarf", "KulTiran", "Mechagnome",
		"Nightborne", "HighmountainTauren", "MagharOrc", "ZandalariTroll", "Vulpera",
		"Dracthyr", "EarthenDwarf", "Harronir",
	}
	for _, race in ipairs(PLAYABLE) do
		local dialect = E.Race.DialectFor(race)
		check(race .. " has a dialect", dialect ~= nil)
		if dialect then
			check(race .. " dialect is named", type(dialect.name) == "string" and dialect.name ~= "")
			check(race .. " dialect is described", type(dialect.desc) == "string" and dialect.desc ~= "")
		end
	end

	-- ...and the reverse: nothing should be registered that the roster above does
	-- not account for, so a new dialect cannot quietly skip the checks here.
	local expected = {}
	for _, race in ipairs(PLAYABLE) do expected[race] = true end
	local unaccounted, total = {}, 0
	for race in pairs(E.DIALECTS) do
		total = total + 1
		if not expected[race] then unaccounted[#unaccounted + 1] = race end
	end
	table.sort(unaccounted)
	check("no dialect is missing from the roster list", #unaccounted == 0,
		"unaccounted for: " .. table.concat(unaccounted, ", "))
	eq("one dialect per playable race", total, #PLAYABLE)

	-- No dialect may decide something about the listener that it cannot see.
	--
	-- Reported for Darnassian ("friend" -> "kin") and then for Orcish ("friend"
	-- -> "brother"), but the fault is structural rather than per-dialect, so it
	-- is checked across the whole roster: a term of address is aimed at whoever
	-- is being spoken to, and a flavour suffix is bolted onto any message at all.
	-- Neither knows who is reading. Asserting a stranger's gender, their age, or
	-- that they are the speaker's own blood is a guess the addon has no business
	-- making, and it will be wrong for a large share of the realm.
	--
	-- The player may of course still type any of these themselves -- that is the
	-- point. None of the inputs below contain one.
	do
		local CLAIMS = {
			-- Gender.
			"brother", "brothers", "bruddah", "bruddahs", "sister", "sisters",
			"sistah", "gentlemen", "chap", "fellow", "fellows", "madam", "sir",
			-- Kinship or nation: the speaker's own people, which a stranger is not.
			"kin", "kindred", "flight", "caravan", "child of Zandalar",
			-- Age.
			"young one", "youngling",
		}

		-- Dwarves are exempt by decision rather than by oversight: "laddie" and
		-- "lassie" are theirs, and a people who address an archmage as "laddie"
		-- are not being careless about forms of address -- that IS the form of
		-- address. Kul Tiran "lad"/"lass" is only reached by writing "man" or
		-- "woman", so the player has already said which. Troll "mon" is kept for
		-- the reason recorded in that file.
		-- Vulpera keep "the caravan endures", which describes the speaker's own
		-- people rather than the listener's -- the distinction the whole check
		-- turns on. "my family is safe" -> "the caravan is safe" is a Vulpera
		-- saying something true about themselves.
		local EXEMPT = {
			Dwarf = { "lad", "lads", "laddie", "lass", "lassie" },
			DarkIronDwarf = { "lad", "lads", "laddie", "lass", "lassie" },
			Vulpera = { "caravan" },
		}

		local NEUTRAL = {
			"Farewell friend", "Hello friend", "Thank you my friend",
			"greetings my ally", "well met", "I do not know",
			"the road is long", "hello everyone", "good luck out there",
			"hey guys", "what is the plan", "we should go now",
		}

		for _, race in ipairs(PLAYABLE) do
			local exempt = {}
			for _, word in ipairs(EXEMPT[race] or {}) do exempt[word] = true end

			local found = {}
			for _, strength in ipairs({ 1, 2, 3 }) do
				for i = 1, 25 do
					for _, line in ipairs(NEUTRAL) do
						local ctx = E.Pipeline.NewContext(line, "P-cl-" .. race .. i, race)
						ctx.strength = strength
						local out = E.Engine.Apply(E.DIALECTS[race], line, ctx):lower()
						for _, claim in ipairs(CLAIMS) do
							if not exempt[claim] and out:find("%f[%a]" .. claim .. "%f[%A]") then
								found[claim] = line .. " -> " .. out
							end
						end
					end
				end
			end

			local names = {}
			for claim in pairs(found) do names[#names + 1] = claim end
			table.sort(names)
			check(race .. " claims nothing about the listener", #names == 0,
				#names > 0 and (names[1] .. ": " .. found[names[1]]) or nil)
		end

		-- The other half: whatever the player did type survives. These are all
		-- things a character might genuinely say, and which one fits is theirs
		-- to decide -- so no dialect may swap one for another.
		-- Dwarves are left out on purpose: "friend" -> "laddie" is theirs to keep,
		-- so they are the one dialect that may still choose for the player.
		for _, race in ipairs({ "Orc", "NightElf", "Tauren", "Troll", "Worgen" }) do
			for _, term in ipairs({ "brother", "sister", "friend" }) do
				local line = "well met " .. term
				local ctx = E.Pipeline.NewContext(line, "P-keep", race)
				ctx.strength = 3
				local out = E.Engine.Apply(E.DIALECTS[race], line, ctx):lower()
				-- Dwarven and Troll accents respell rather than replace, so the
				-- test accepts their spelling of the same word.
				local ok = out:find(term, 1, true)
					or (race == "Troll" and out:find(term:sub(1, 4), 1, true))
					or (race == "Dwarf" and out:find(term:sub(1, 4), 1, true))
				check(race .. " keeps the player's \"" .. term .. "\"", ok ~= nil, out)
			end
		end
	end

	-- No dialect greets a message that is already a greeting.
	--
	-- Reported for Darnassian first ("Ishnu-alah. Ande'thoras-ethil." -- hello,
	-- goodbye) and fixed there by emptying that one prefix pool of salutations.
	-- Orcish then turned out to do it too: "Well met, sister" -> "Throm-Ka,
	-- Throm-Ka, sister". A flavour prefix lands on any message at all and has no
	-- idea the message already opens with a greeting, so this is structural and
	-- is checked across the roster, classes included.
	do
		local GREETINGS = {
			"Well met, friend", "Hello there", "Hi there", "Greetings",
			"Farewell friend", "Goodbye", "Bye for now", "Take care",
			"Good day to you", "Safe travels",
		}
		-- The seeds have to survive translation to be worth testing. If a dialect
		-- renders "hello" as something the salutation set does not know about,
		-- the guard cannot fire and this test would pass for the wrong reason --
		-- so that is checked first, on the raw word rather than a whole sentence.
		for _, race in ipairs(PLAYABLE) do
			for _, word in ipairs({ "hello", "goodbye" }) do
				-- dialectOnly suppresses the flavour, which would otherwise put a
				-- prefix in front of the very thing being measured.
				local said = dialectOnly(race, word, 3)
				check(race .. "'s \"" .. word .. "\" is a known salutation",
					E.OpensWithSalutation(said), said)
			end
		end

		for _, race in ipairs(PLAYABLE) do
			local worst, sample = 0, nil
			for _, strength in ipairs({ 1, 2, 3 }) do
				for i = 1, 30 do
					for _, line in ipairs(GREETINGS) do
						local ctx = E.Pipeline.NewContext(line, "P-s-" .. race .. i, race)
						ctx.strength = strength
						local out = E.Engine.Apply(E.DIALECTS[race], line, ctx)
						local n = E.CountLeadingSalutations(out)
						if n > worst then worst, sample = n, line .. " -> " .. out end
					end
				end
			end
			check(race .. " never greets twice", worst <= 1, sample)
		end

		-- The class layer has its own prefix pools, and the Death Knight's opens
		-- with "Suffer well." -- a farewell, which in front of a greeting is the
		-- same fault wearing different clothes.
		for token in pairs(E.CLASSES) do
			local worst, sample = 0, nil
			for _, race in ipairs({ "Human", "Orc", "NightElf", "Dwarf" }) do
				local dialect = E.Class.Apply(E.DIALECTS[race], token)
				for i = 1, 30 do
					for _, line in ipairs(GREETINGS) do
						local ctx = E.Pipeline.NewContext(line, "P-sc-" .. token .. i, race)
						ctx.strength = 3
						local out = E.Engine.Apply(dialect, line, ctx)
						local n = E.CountLeadingSalutations(out)
						if n > worst then worst, sample = n, race .. ": " .. line .. " -> " .. out end
					end
				end
			end
			check(token .. " never greets twice", worst <= 1, sample)
		end

		-- And the guard must not have simply switched the prefixes off. A message
		-- that is not a greeting still gets them, greetings included.
		do
			local seen = {}
			for i = 1, 200 do
				local ctx = E.Pipeline.NewContext("the road is long", "P-sp-" .. i, "Orc")
				ctx.strength = 3
				seen[E.Engine.Apply(E.DIALECTS["Orc"], "the road is long", ctx)] = true
			end
			local greeted = false
			for line in pairs(seen) do
				if line:find("Throm%-Ka") or line:find("Lok'tar") then greeted = true end
			end
			check("an ordinary message can still be greeted", greeted)
		end
	end

	-- Derived variants must not share their parent's table, or they would share
	-- its compilation cache too.
	check("derived variants are distinct tables",
		E.DIALECTS["DarkIronDwarf"] ~= E.DIALECTS["Dwarf"]
		and E.DIALECTS["MagharOrc"] ~= E.DIALECTS["Orc"]
		and E.DIALECTS["Mechagnome"] ~= E.DIALECTS["Gnome"]
		and E.DIALECTS["HighmountainTauren"] ~= E.DIALECTS["Tauren"]
		and E.DIALECTS["LightforgedDraenei"] ~= E.DIALECTS["Draenei"])

	-- ...but they must inherit the parent's vocabulary.
	contains("Dark Iron inherit the dwarven Scots",
		dialectOnly("DarkIronDwarf", "I do not know if that will work"), "wirk")
	contains("and add their own layer",
		dialectOnly("DarkIronDwarf", "the fire is hot"), "the Flame")
	contains("Highmountain inherit Taurahe formality",
		dialectOnly("HighmountainTauren", "I don't think so"), "do not")
	contains("and add their own layer",
		dialectOnly("HighmountainTauren", "my home is the mountain"), "Highmountain")
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
section("Channel defaults and presets")
--------------------------------------------------------------------------------

do
	-- The in-character channels are filtered; coordination channels are not.
	-- Dialecting "interrupt now, bloodlust on pull" makes useful chat harder to
	-- read rather than more immersive.
	local D = E.DEFAULTS
	for _, key in ipairs({ "say", "yell", "emote" }) do
		eq("incoming " .. key .. " is on by default", D.incoming[key], true)
		eq("outgoing " .. key .. " is on by default", D.outgoing[key], true)
	end
	for _, key in ipairs({ "party", "raid", "instance", "guild", "officer", "channel" }) do
		eq("incoming " .. key .. " is off by default", D.incoming[key], false)
		eq("outgoing " .. key .. " is off by default", D.outgoing[key], false)
	end

	-- Whispers are off on both sides. In-character whispering is conventionally
	-- done in /say with a "[low]" tag, so nearby characters get the chance to
	-- overhear -- which leaves the whisper channel itself as out-of-character
	-- traffic, like party and guild.
	eq("incoming whispers are not filtered", D.incoming.whisper, false)
	eq("outgoing whispers are not filtered", D.outgoing.whisper, false)

	-- Outgoing stays off entirely until asked for.
	eq("outgoing rewriting is off by default", D.outgoing.enabled, false)
end

do
	local handler = SlashCmdList["ELOQUENCE"]
	check("/elo preset lists the presets", pcall(handler, "preset"))
	check("an unknown preset is survivable", pcall(handler, "preset nonsense"))

	for _, key in ipairs(E.Presets.order) do
		check("/elo preset " .. key .. " applies", pcall(handler, "preset " .. key))
		local preset = E.Presets.list[key]
		check(key .. " has a name and description",
			type(preset.name) == "string" and type(preset.desc) == "string")
	end

	-- Roleplay: in-character channels only, dialects on, Spell Book kept off
	-- other people's chat.
	E.Presets.Apply("rp")
	eq("rp filters say", E.db.incoming.say, true)
	eq("rp leaves raid alone", E.db.incoming.raid, false)
	eq("rp enables dialects", E.db.modules.dialect.enabled, true)
	eq("rp keeps the Spell Book off incoming", E.db.modules.spellbook.incoming, false)

	-- Clean: no dialects, tidy everything.
	E.Presets.Apply("clean")
	eq("clean disables dialects", E.db.modules.dialect.enabled, false)
	eq("clean filters raid too", E.db.incoming.raid, true)
	eq("clean applies the Spell Book to incoming", E.db.modules.spellbook.incoming, true)

	-- Immersive: NPCs included, heavier.
	E.Presets.Apply("immersive")
	eq("immersive includes NPCs", E.db.incoming.monster, true)
	eq("immersive turns up the dialect", E.db.modules.dialect.strength, 3)
	eq("immersive enables the Fantasy Writer", E.db.modules.fantasy.enabled, true)

	-- Off: everything down, addon still loaded.
	E.Presets.Apply("off")
	for key in pairs(E.db.modules) do
		eq("off disables " .. key, E.db.modules[key].enabled, false)
	end

	-- A preset must never flip outgoing sending on, nor clear muted races.
	E.db.outgoing.enabled = false
	E.db.dialect.races["Troll"] = false
	for _, key in ipairs(E.Presets.order) do
		E.Presets.Apply(key)
		eq(key .. " never enables outgoing sending", E.db.outgoing.enabled, false)
		eq(key .. " never clears a muted race", E.db.dialect.races["Troll"], false)
	end
	E.db.dialect.races["Troll"] = nil

	eq("an unknown preset reports failure", E.Presets.Apply("nope"), false)
	eq("a nil preset reports failure", E.Presets.Apply(nil), false)

	handler("reset")
end

--------------------------------------------------------------------------------
section("Authored voice must survive the filters")
--------------------------------------------------------------------------------

do
	-- On a roleplaying realm, other people's spelling is a deliberate choice.
	-- Names in particular are sacred: "Zethrrel" with rolled Rs, or another
	-- character mangling it as "Zettle", must come out exactly as written.
	onlyModules("spellbook", "decompression", "dialect")
	for key in pairs(E.db.modules) do E.db.modules[key].incoming = true end

	local cases = {
		"Well met, Zethrrel.",
		"Greetings, Zettle!",
		"Ahh, Zethrrrrel, ye came.",
		"Yer name be Zethrrel, aye?",
		"I greet Zethrrel and Zettle both.",
	}
	for _, text in ipairs(cases) do
		local out = E.Pipeline.Run(text, "Player-1-DWARF", "Dwarf", "Common")
		if text:find("Zethrrel", 1, true) then
			contains("Zethrrel survives: " .. text, out, "Zethrrel")
		end
		if text:find("Zethrrrrel", 1, true) then
			contains("stretched rolled Rs survive: " .. text, out, "Zethrrrrel")
		end
		if text:find("Zettle", 1, true) then
			contains("Zettle survives: " .. text, out, "Zettle")
		end
	end

	-- The pronoun I must stay translatable, or Dwarven "i" -> "Ah" would only
	-- ever fire at the start of a sentence.
	contains("the pronoun I is still dialected mid-sentence",
		dialectOnly("Dwarf", "Well, I know that"), "Ah")

	-- Sentence-initial capitals are ordinary words, not names.
	contains("a capitalised sentence opening is still dialected",
		dialectOnly("Dwarf", "Know this well."), "Ken")
end

do
	-- Edge apostrophes are deliberate elision. Substituting the letters and
	-- gluing the apostrophe back on turned "no'" into "nae'".
	local accented = "Ah'm no' shuir aboot tha', laddie."
	local out = dialectOnly("Dwarf", accented)
	excludes("an author's elision is not re-accented", out, "nae'")
	eq("text already written in accent is left alone", out, accented)

	contains("internal apostrophes still work",
		dialectOnly("Dwarf", "I don't know"), "dinnae")
	eq("a leading apostrophe is respected",
		dialectOnly("Dwarf", "'tis so"), "'tis so")
end

do
	-- Roleplaying conventions carried inside an in-character channel.
	onlyModules("spellbook", "decompression", "mouthwash", "fantasy", "dialect")
	for key in pairs(E.db.modules) do E.db.modules[key].incoming = true end

	-- Parentheses mark an out-of-character aside. The player has stepped outside
	-- their character to say it, so dialecting it is exactly backwards.
	--
	-- Single and double both count: double is the older convention, but Total RP
	-- 3 treats a single pair as OOC, so that is what most people type.
	for _, ooc in ipairs({
		"(( brb, the dog needs out ))",
		"(brb, the dog needs out)",
		"((brb, the dog needs out))",
	}) do
		eq("an OOC aside is left alone: " .. ooc,
			E.Pipeline.Run(ooc, "Player-1-DWARF", "Dwarf", "Common"), ooc)
	end

	for _, aside in ipairs({ "(( brb, the dog needs out ))", "(brb, the dog needs out)" }) do
		local mixed = "Aye, that I know. " .. aside
		local out = E.Pipeline.Run(mixed, "Player-1-DWARF", "Dwarf", "Common")
		contains("the OOC half survives inside a mixed line", out, aside)
		check("the in-character half is still dialected", out ~= mixed, out)
	end

	-- The accepted cost of covering single parentheses: an in-character
	-- parenthetical is not dialected either. Passing the player's own words
	-- through unchanged is the safe direction to fail in.
	eq("an in-character parenthetical is passed through, not dialected",
		dialectOnly("Dwarf", "(I don't know)"), "(I don't know)")

	-- A double pair must tokenize as ONE protected span, not a span plus an
	-- orphaned bracket. This has to be asserted against the tokenizer rather than
	-- the pipeline: "%(.-%)" alone stops at the first ")" and leaves the last
	-- character loose, which no filter would alter anyway -- so a pipeline test
	-- passes with or without the double-parenthesis rule and proves nothing. The
	-- span boundary is the observable difference, and it matters because
	-- E.SplitMessage treats protected spans as atomic and could otherwise split a
	-- bracket away from its pair.
	local segs = E.Tokenize("((brb, the dog needs out))")
	eq("a double pair is one protected span", #segs, 1)
	eq("that span covers the whole aside", segs[1] and segs[1].text, "((brb, the dog needs out))")
	check("and it is marked protected", segs[1] and segs[1].protected == true)

	-- Square brackets tag the register or language of the line. The tag is
	-- metadata; the speech after it is not.
	local low = E.Pipeline.Run("[low] I don't know, friend.", "Player-1-DWARF", "Dwarf", "Common")
	contains("a [low] tag passes through untouched", low, "[low]")
	check("the speech after the tag is still dialected", low ~= "[low] I don't know, friend.", low)

	local lang = E.Pipeline.Run("[Thalassian] I don't know.", "Player-1-DWARF", "Dwarf", "Common")
	contains("a language tag is not dialected", lang, "[Thalassian]")

	-- A tag whose contents the dialect would otherwise happily chew on: without
	-- protection this comes back as "[tae the crowd]".
	contains("a stage direction in brackets is not dialected",
		E.Pipeline.Run("[to the crowd] Hello", "Player-1-DWARF", "Dwarf", "Common"),
		"[to the crowd]")

	onlyModules("dialect")
end

do
	-- The Spell Book must not touch incoming chat unless opted in.
	eq("the Spell Book defaults to off for incoming",
		E.DEFAULTS.modules.spellbook.incoming, false)

	for key in pairs(E.db.modules) do E.db.modules[key].enabled = false end
	E.db.modules.spellbook.enabled = true
	E.db.modules.spellbook.incoming = false

	local quirky = "Hmmmm... heyyyy there"
	eq("someone else's stretched vowels survive",
		E.Pipeline.Run(quirky, "Player-1-DWARF", "Dwarf", "Common"), quirky)
	check("but your own are tidied on the way out",
		E.Pipeline.Run(quirky, nil, "Dwarf", nil, "outgoing") ~= quirky)

	-- Opting in restores the old behaviour.
	E.db.modules.spellbook.incoming = true
	check("opting in applies it to incoming again",
		E.Pipeline.Run(quirky, "Player-1-DWARF", "Dwarf", "Common") ~= quirky)
	E.db.modules.spellbook.incoming = false
end

--------------------------------------------------------------------------------
section("Chat bubbles are a separate render path")
--------------------------------------------------------------------------------

do
	-- The bubble above someone's head is drawn by the client from the raw chat
	-- event and never passes through ChatFrame_AddMessageEventFilter, so a
	-- correct chat frame proves nothing about the bubble. It has to be found and
	-- rewritten afterwards.
	onlyModules("dialect")
	E.db.enabled = true
	E.db.incoming.enabled = true
	E.db.incoming.say = true
	E.db.incoming.bubbles = true
	E.db.outgoing.enabled = false
	_G._guidRaces["Player-1-BUBBLE"] = { race = "Dwarf", class = "Warrior", name = "Bromm" }

	local original = "I don't know friend"
	local expected = E.Pipeline.Run(original, "Player-1-BUBBLE", "Dwarf", "Common")
	check("the sample is actually transformed", expected ~= original, tostring(expected))

	-- The bubble does not exist yet when the message arrives, which is the whole
	-- reason this needs polling rather than a single pass.
	_G._bubbles = {}
	E.Bubbles.Queue("CHAT_MSG_SAY", original, expected)

	local bubble = _G.NewChatBubble(original)
	E.Bubbles.Scan()
	eq("a bubble appearing later still gets rewritten", bubble._fontString:GetText(), expected)

	-- Bubbles the client forbids must be left strictly alone.
	_G._bubbles = {}
	local forbidden = _G.NewChatBubble(original, true)
	E.Bubbles.Queue("CHAT_MSG_SAY", original, expected)
	E.Bubbles.Scan()
	eq("forbidden bubbles are untouched", forbidden._fontString:GetText(), original)

	-- Unrelated bubbles are not touched.
	_G._bubbles = {}
	local other = _G.NewChatBubble("something else entirely")
	E.Bubbles.Queue("CHAT_MSG_SAY", original, expected)
	E.Bubbles.Scan()
	eq("unrelated bubbles are untouched", other._fontString:GetText(), "something else entirely")

	-- Only events that actually produce a bubble are queued. Advance the clock so
	-- the earlier entries have expired and cannot satisfy these cases.
	_G._time = _G._time + 60
	_G._bubbles = {}
	local whisper = _G.NewChatBubble(original)
	E.Bubbles.Queue("CHAT_MSG_WHISPER", original, expected)
	E.Bubbles.Scan()
	eq("whispers never make bubbles, so nothing is queued",
		whisper._fontString:GetText(), original)

	-- The setting is respected.
	_G._time = _G._time + 60
	E.db.incoming.bubbles = false
	_G._bubbles = {}
	local off = _G.NewChatBubble(original)
	E.Bubbles.Queue("CHAT_MSG_SAY", original, expected)
	E.Bubbles.Scan()
	eq("bubbles are left alone when the setting is off", off._fontString:GetText(), original)
	E.db.incoming.bubbles = true
end

do
	-- End to end: driving the real chat filter should rewrite the bubble too.
	onlyModules("dialect")
	_G._bubbles = {}
	local original = "i dont know friend"
	local filter = _G._filters["CHAT_MSG_SAY"][1]
	local args = { original, "Bromm", "Common", "", "", "", 0, 0, "", "", 44,
		"Player-1-BUBBLE", nil, false, false, false, false }
	local _, rewritten = filter(nil, "CHAT_MSG_SAY", unpack(args, 1, 17))
	check("the chat frame copy was rewritten", rewritten ~= original, tostring(rewritten))

	local bubble = _G.NewChatBubble(original)
	E.Bubbles.Scan()
	eq("and the bubble now matches the chat frame", bubble._fontString:GetText(), rewritten)
end

--------------------------------------------------------------------------------
section("Outgoing via the 12.0 edit box path")
--------------------------------------------------------------------------------

do
	-- Patch 12.0 rearchitected chat sending: overriding the global
	-- SendChatMessage no longer sees anything typed into the chat box. Messages
	-- must be transformed through ChatFrame.OnEditBoxPreSendText instead. This
	-- drives the real sequence -- fire the callback, then send whatever the edit
	-- box holds -- so a hook on the wrong path fails here.
	_G._playerRace = "DarkIronDwarf"
	E.db.enabled = true
	E.db.outgoing.enabled = true
	E.db.outgoing.say = true
	onlyModules("dialect")

	eq("the edit box hook is the active method", E.Chat.outgoingMethod, "editbox")

	local sent = stub.typeIntoChat(_G, "Hey friend", "SAY")
	check("a typed message is transformed", sent ~= "Hey friend", tostring(sent))
	contains("with the Dark Iron dialect", sent, "laddie")

	-- Exactly once: the fallback wrapper must not re-transform what the edit box
	-- hook already handled.
	local twice = stub.typeIntoChat(_G, "I don't know friend", "SAY")
	local once = E.Pipeline.Run("I don't know friend", UnitGUID("player"), "DarkIronDwarf", nil)
	eq("transformed exactly once, not twice", twice, once)

	-- Channels not opted into stay verbatim.
	E.db.outgoing.guild = false
	eq("un-opted channels are untouched",
		stub.typeIntoChat(_G, "Hey friend", "GUILD"), "Hey friend")

	eq("slash commands are never rewritten",
		stub.typeIntoChat(_G, "/dance", "SAY"), "/dance")

	-- Combat lockdown: rewriting the edit box there taints the protected send
	-- and the client blocks the message outright.
	_G._inCombat = true
	eq("no rewriting during combat lockdown",
		stub.typeIntoChat(_G, "Hey friend", "SAY"), "Hey friend")
	_G._inCombat = false
	check("and it resumes afterwards",
		stub.typeIntoChat(_G, "Hey friend", "SAY") ~= "Hey friend")

	-- The edit box path sends one message and cannot split, so an over-long
	-- result must be left alone rather than truncated.
	local long = string.rep("I do not know friend, ", 20)
	eq("an over-long transform is skipped rather than truncated",
		stub.typeIntoChat(_G, long, "SAY"), long)

	E.db.outgoing.enabled = false
	eq("disabling outgoing restores verbatim sending",
		stub.typeIntoChat(_G, "Hey friend", "SAY"), "Hey friend")
	E.db.outgoing.enabled = true
end

do
	-- The sender argument must never be modified: the chat system builds the
	-- player hyperlink around it, so colour codes injected there corrupt the
	-- link and spill raw markup into the frame.
	E.db.cleanup.classColors = true
	local filter
	for _, fn in ipairs(_G._filters["CHAT_MSG_SAY"]) do filter = fn end
	local args = { "Hello there", "Becche-Ravencrest", "Common", "", "", "", 0, 0, "", "", 236,
		"Player-1-DWARF", nil, false, false, false, false }
	local _, _, sender = filter(nil, "CHAT_MSG_SAY", unpack(args, 1, 17))
	if sender ~= nil then
		excludes("the sender carries no colour codes", sender, "|c")
		eq("the sender is passed through untouched", sender, "Becche-Ravencrest")
	else
		check("the presentation filter left the sender alone", true)
	end
	E.db.cleanup.classColors = false
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
	eq("allied races are muted in their own right", E.db.dialect.races["ZandalariTroll"], false)
	eq("and muting them leaves the Darkspear alone", E.db.dialect.races["Troll"], nil)
	handler("race zandalaritroll on")

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
section("Startup: every module must actually initialise")
--------------------------------------------------------------------------------

do
	-- The regression that made the addon do nothing at all. Core/Race.lua and
	-- Core/Pipeline.lua registered event names, one of which no longer exists in
	-- retail. RegisterEvent on an unknown event raises, and the raise aborted the
	-- login loop, so Chat never installed its filters or the outgoing hook. Every
	-- test passed; the addon was inert in game.
	check("no module failed to start", #E.initErrors == 0,
		#E.initErrors > 0 and (E.initErrors[1].name .. ": " .. E.initErrors[1].err) or "")

	-- Retired events must be skipped, not fatal.
	check("the retired event was skipped rather than thrown", (function()
		for _, event in ipairs(E.skippedEvents) do
			if event == "LEARNED_SPELL_IN_TAB" then return true end
		end
		return false
	end)(), "skipped: " .. table.concat(E.skippedEvents, ", "))

	-- And the things that depend on startup completing actually happened.
	check("incoming chat filters were installed", (E.Chat.installedFilters or 0) > 0,
		"installed " .. tostring(E.Chat.installedFilters))
	local channelCount = 0
	for _ in pairs(E.CHANNELS) do channelCount = channelCount + 1 end
	eq("one filter per chat event", E.Chat.installedFilters, channelCount)
end

do
	-- Isolation: a module that blows up must not take the rest with it.
	local order = {}
	local fake = {
		onLogin = {}, initErrors = {},
		OnLogin = E.OnLogin,
	}
	-- Re-create the dispatcher's contract in miniature.
	local entries = {
		{ name = "First", fn = function() order[#order + 1] = "first" end },
		{ name = "Broken", fn = function() error("deliberate") end },
		{ name = "Third", fn = function() order[#order + 1] = "third" end },
	}
	local errors = {}
	for _, entry in ipairs(entries) do
		local ok, err = pcall(entry.fn)
		if not ok then errors[#errors + 1] = { name = entry.name, err = err } end
	end
	eq("modules after a failure still run", #order, 2)
	eq("and the failure is recorded", #errors, 1)
	eq("with the module named", errors[1].name, "Broken")
end

do
	-- /elo doctor must survive being run, including when things are broken.
	local handler = SlashCmdList["ELOQUENCE"]
	check("/elo doctor runs", pcall(handler, "doctor"))

	-- Simulate a broken startup and make sure the report still prints.
	local saved = E.initErrors
	E.initErrors = { { name = "Chat", err = "simulated failure" } }
	check("/elo doctor reports a failed module without erroring", pcall(handler, "doctor"))
	E.initErrors = saved
end

--------------------------------------------------------------------------------
section("Options panel: /elo must never silently do nothing")
--------------------------------------------------------------------------------

do
	-- Lua errors are hidden by default in retail, so any failure in here looks
	-- to the player exactly like the command being ignored. Every path must
	-- therefore either open the panel or print something.
	local handler = SlashCmdList["ELOQUENCE"]
	check("bare /elo runs without erroring", pcall(handler, ""))
	check("/elo config runs", pcall(handler, "config"))
	check("/elo options runs", pcall(handler, "options"))

	-- The regression that made /elo throw and appear to do nothing. Every
	-- Dragonflight-era guide says to set `category.ID = addonName`, but 12.0's
	-- OpenToCategory forwards the ID to C_SettingsUtil.OpenSettingsPanel, which
	-- demands an integer. The ID assigned at registration must survive untouched.
	eq("the options panel registered via the Settings API", E.optionsMethod, "settings")
	check("the category kept its assigned numeric ID",
		type(E.settingsCategory and E.settingsCategory.ID) == "number",
		"ID is " .. type(E.settingsCategory and E.settingsCategory.ID)
			.. " (" .. tostring(E.settingsCategory and E.settingsCategory.ID) .. ")")

	_G._openedCategories = {}
	handler("")
	check("bare /elo actually opened the panel", #_G._openedCategories > 0,
		"OpenToCategory was never reached")
	if #_G._openedCategories > 0 then
		check("and passed a numeric category ID, not the addon name",
			type(_G._openedCategories[1]) == "number",
			"got " .. tostring(_G._openedCategories[1]))
		eq("matching the registered category",
			_G._openedCategories[1], E.settingsCategory.ID)
	end

	-- Combat lockdown: ShowUIPanel is blocked, so opening cannot work.
	_G._inCombat = true
	check("it copes during combat lockdown", pcall(handler, ""))
	_G._inCombat = false

	-- A panel that failed to build must be reported, not hidden.
	local saved = E.optionsBuildError
	E.optionsBuildError = "simulated build failure"
	check("a build failure is survivable", pcall(handler, ""))
	check("and doctor reports it", pcall(handler, "doctor"))
	E.optionsBuildError = saved

	-- Registration happens before the widgets are built, so a build failure
	-- still leaves something to open.
	check("the options method was recorded", E.optionsMethod ~= nil, tostring(E.optionsMethod))

	-- A setting only a slash command can reach is invisible to anyone who does
	-- not already know it is there. The class layer shipped that way: it changed
	-- what people said, it was on by default, and the only way to turn it off was
	-- "/elo class off" -- which you had to be told about.
	--
	-- Each entry pairs a checkbox with the setting it writes, so the test fails
	-- both when the control goes missing and when it is wired to nothing.
	do
		local WIRED = {
			{ "Adjust speech for the speaker's class",
				function() return E.db.dialect.classFlavor end,
				function(v) E.db.dialect.classFlavor = v end },
			{ "Also rewrite chat bubbles",
				function() return E.db.incoming.bubbles end,
				function(v) E.db.incoming.bubbles = v end },
		}

		local byLabel = {}
		for _, cb in ipairs(E.optionsChecks or {}) do byLabel[cb.label] = cb end

		for _, entry in ipairs(WIRED) do
			local label, get, set = entry[1], entry[2], entry[3]
			local cb = byLabel[label]
			check("the panel offers \"" .. label .. "\"", cb ~= nil)
			if cb then
				-- Refresh reads the setting; the OnClick writes it. Drive both,
				-- which is what a player does, and put the setting back after.
				local saved = get()

				set(false)
				cb:Refresh()
				eq(label .. " reflects a false setting", cb:GetChecked() and true or false, false)
				set(true)
				cb:Refresh()
				eq(label .. " reflects a true setting", cb:GetChecked() and true or false, true)

				cb:SetChecked(false)
				cb:GetScript("OnClick")(cb)
				eq(label .. " writes the setting when clicked", get() and true or false, false)

				set(saved)
			end
		end
	end

	-- Who sees your own dialect used to be two checkboxes: "Rewrite my outgoing
	-- chat" and, four sections away, "Also apply a dialect to my own messages".
	-- They read as two ways of saying one thing. They were not the same, but they
	-- were not independent either -- Chat.ShouldFilterSelf refuses to dialect your
	-- own incoming copy while outgoing rewriting is on, because that copy was
	-- already rewritten on the way out. Four tick combinations, three behaviours,
	-- and one combination that silently ignored a box the player had ticked.
	--
	-- Now one three-way control. The invariant that makes that safe is that the
	-- mode round-trips through the two settings it is standing in for.
	do
		local saved = { E.db.outgoing.enabled, E.db.dialect.applyToSelf }

		for mode = 1, #E.SELF_MODES do
			E.SetSelfMode(mode)
			eq("mode " .. E.SELF_MODES[mode] .. " round-trips", E.GetSelfMode(), mode)
		end

		-- And each mode means what it says, in the terms the rest of the addon
		-- reads rather than the ones the panel writes.
		E.SetSelfMode(1)
		check("Off sends nothing rewritten", not E.db.outgoing.enabled)
		check("and does not dialect your own copy either", not E.db.dialect.applyToSelf)

		E.SetSelfMode(2)
		check("Only me leaves what you send alone", not E.db.outgoing.enabled)
		check("but dialects your own copy", E.db.dialect.applyToSelf == true)

		E.SetSelfMode(3)
		check("Everyone rewrites what you send", E.db.outgoing.enabled == true)
		-- The self path must stand down here or the message would be dialected
		-- twice: once on the way out, once on the copy that comes back.
		check("the self path is exposed to be checked at all",
			type(E.Chat.ShouldFilterSelf) == "function")
		E.db.dialect.applyToSelf = true  -- even asked for explicitly
		check("and it stands down to avoid a double pass",
			E.Chat.ShouldFilterSelf("Player-1-TEST") == false)
		-- ...and does its job once outgoing is off again.
		E.SetSelfMode(2)
		check("but does dialect your own copy in Only me",
			E.Chat.ShouldFilterSelf("Player-1-TEST") == true)
		E.SetSelfMode(3)

		-- Reachable from the panel, and cycling lands on every mode.
		local byLabel = {}
		for _, cb in ipairs(E.optionsChecks or {}) do byLabel[cb.label] = cb end
		local cycle = byLabel["Show my chat in dialect to"]
		check("the panel offers the control", cycle ~= nil)
		if cycle then
			local seen = {}
			E.SetSelfMode(1)
			for _ = 1, #E.SELF_MODES do
				cycle:GetScript("OnClick")(cycle)
				seen[E.GetSelfMode()] = true
			end
			local count = 0
			for _ in pairs(seen) do count = count + 1 end
			eq("cycling reaches every mode", count, #E.SELF_MODES)
		end

		-- The command has to reach all three too, or the middle setting is once
		-- again panel-only -- which is exactly what it was before this change.
		-- "on" and "off" keep their old meanings so existing macros still work.
		for _, case in ipairs({ { "off", 1 }, { "me", 2 }, { "on", 3 },
		                        { "self", 2 }, { "1", 3 }, { "0", 1 } }) do
			handler("out " .. case[1])
			eq("/elo out " .. case[1] .. " selects " .. E.SELF_MODES[case[2]],
				E.GetSelfMode(), case[2])
		end

		E.db.outgoing.enabled, E.db.dialect.applyToSelf = saved[1], saved[2]
	end

	-- The channel grid offers the roleplaying channels one at a time and the
	-- coordination channels as a single switch. Eleven checkboxes to say "the
	-- usual five are off" was a wall of boxes making one point.
	do
		-- Labels repeat here: the incoming and outgoing sections each carry their
		-- own copy of the channel grid, told apart by the heading above them. So
		-- collect every match in build order rather than keeping the last.
		local byLabel = {}
		for _, cb in ipairs(E.optionsChecks or {}) do
			local list = byLabel[cb.label]
			if not list then list = {} byLabel[cb.label] = list end
			list[#list + 1] = cb
		end

		for _, entry in ipairs(E.IC_CHANNELS) do
			check("the panel still offers " .. entry[2] .. " on its own", byLabel[entry[2]] ~= nil)
		end
		for _, label in ipairs({ "Party", "Raid", "Instance", "Officer", "Channels" }) do
			check("and no longer offers " .. label .. " separately", byLabel[label] == nil)
		end
		-- The two lists have to partition the settings between them, or a channel
		-- reachable in neither is a setting nobody can change.
		do
			local covered = {}
			for _, entry in ipairs(E.IC_CHANNELS) do covered[entry[1]] = true end
			for _, key in ipairs(E.OOC_CHANNELS) do
				check(key .. " is not in both lists", not covered[key])
				covered[key] = true
			end
			for event, key in pairs(E.CHANNELS) do
				check(key .. " (" .. event .. ") is reachable from the panel", covered[key] == true)
			end
		end

		local groups = byLabel["Group and coordination chat"] or {}
		eq("both sections carry a grouped switch", #groups, 2)
		local group = groups[1]  -- incoming is built first
		check("the grouped switch exists", group ~= nil)
		if group then
			local saved = {}
			for _, key in ipairs(E.OOC_CHANNELS) do saved[key] = E.db.incoming[key] end

			for _, key in ipairs(E.OOC_CHANNELS) do E.db.incoming[key] = false end
			group:Refresh()
			eq("it reads empty when they are all off", group:GetChecked() and true or false, false)

			-- Any one of them being on has to show, or a channel would go on being
			-- filtered behind a box that looks switched off.
			E.db.incoming[E.OOC_CHANNELS[#E.OOC_CHANNELS]] = true
			group:Refresh()
			eq("and ticked when any one of them is on", group:GetChecked() and true or false, true)

			group:SetChecked(false)
			group:GetScript("OnClick")(group)
			local anyLeft = false
			for _, key in ipairs(E.OOC_CHANNELS) do
				if E.db.incoming[key] then anyLeft = true end
			end
			check("unticking it clears every one of them", not anyLeft)

			group:SetChecked(true)
			group:GetScript("OnClick")(group)
			local allOn = true
			for _, key in ipairs(E.OOC_CHANNELS) do
				if not E.db.incoming[key] then allOn = false end
			end
			check("and ticking it sets every one of them", allOn)

			for _, key in ipairs(E.OOC_CHANNELS) do E.db.incoming[key] = saved[key] end
		end
	end
end

--------------------------------------------------------------------------------
section("Packaging: the TOC is the single source of truth")
--------------------------------------------------------------------------------

do
	-- The game loads exactly what the TOC lists, in that order, and so does this
	-- harness -- stub.ReadTOC parses the same file. The two therefore cannot
	-- drift, which is the point: they used to be separate lists, and adding
	-- Core/Class.lua to the TOC left the suite silently loading the old set.
	--
	-- What is still worth asserting is that the TOC parses to something sane,
	-- that everything it names exists, and that the order satisfies the
	-- dependencies files have on each other.
	local tocPath = "Eloquence/Eloquence.toc"
	local handle = io.open(tocPath, "r")
	check("the TOC is readable", handle ~= nil, tocPath)

	if handle then
		local tocFiles, seen = {}, {}
		for line in handle:lines() do
			line = line:gsub("\r", "")
			-- Directives start with '#'; everything else that ends .lua is a file.
			if not line:match("^%s*#") and line:match("%.lua%s*$") then
				local normalised = line:gsub("\\", "/"):gsub("^%s+", ""):gsub("%s+$", "")
				tocFiles[#tocFiles + 1] = normalised
				seen[normalised] = true
			end
		end
		handle:close()

		-- The harness reads the same file; this proves the parser agrees with the
		-- one written independently above.
		local harnessFiles = stub.ReadTOC("Eloquence")
		eq("the harness loads exactly what the TOC lists", #harnessFiles, #tocFiles)
		local harnessSeen = {}
		for _, file in ipairs(harnessFiles) do harnessSeen[file] = true end

		for _, file in ipairs(tocFiles) do
			check("TOC entry is loaded by the harness: " .. file, harnessSeen[file] == true)
			local f = io.open("Eloquence/" .. file, "r")
			check("TOC entry exists on disk: " .. file, f ~= nil)
			if f then f:close() end
		end

		-- Load order matters: Variants.lua derives from the base dialects, so it
		-- has to come after them in both lists.
		local function indexOf(list, needle)
			for i, v in ipairs(list) do if v == needle then return i end end
		end
		local variants = indexOf(tocFiles, "Dialects/Variants.lua")
		check("Variants.lua is in the TOC", variants ~= nil)
		if variants then
			local latestParent = 0
			for _, parent in ipairs({ "Dwarf", "Orc", "Draenei", "Gnome", "Tauren" }) do
				local at = indexOf(tocFiles, "Dialects/" .. parent .. ".lua")
				check(parent .. ".lua is in the TOC", at ~= nil)
				if at and at > latestParent then latestParent = at end
			end
			check("Variants.lua loads after every dialect it derives from",
				variants > latestParent,
				string.format("Variants at %d, last parent at %d", variants, latestParent))
		end

		-- Every class layer calls E.RegisterClass, defined in Core/Class.lua.
		local classCore = indexOf(tocFiles, "Core/Class.lua")
		check("Core/Class.lua is in the TOC", classCore ~= nil)
		if classCore then
			for _, file in ipairs(tocFiles) do
				if file:match("^Classes/") then
					check(file .. " loads after Core/Class.lua",
						indexOf(tocFiles, file) > classCore)
				end
			end
		end

		-- Core/Init.lua defines the namespace everything else uses.
		eq("Core/Init.lua is loaded first", tocFiles[1], "Core/Init.lua")
	end
end

do
	-- Attribution lives in Init.lua and is echoed by the TOC, /elo status and the
	-- options panel. Tie the TOC copy to the Lua copy so they cannot drift.
	eq("the author is set", E.AUTHOR, "Zethrel")
	eq("the realm is set", E.REALM, "Argent Dawn EU")
	contains("the combined credit reads correctly", E.CREDIT, "Zethrel - Argent Dawn EU")

	local handle = io.open("Eloquence/Eloquence.toc", "r")
	if handle then
		local author, version
		for line in handle:lines() do
			author = author or line:match("^## Author:%s*(.-)%s*\r?$")
			version = version or line:match("^## Version:%s*(.-)%s*\r?$")
		end
		handle:close()
		eq("the TOC author matches Init.lua", author, E.CREDIT)
		eq("the TOC version matches Init.lua", version, E.VERSION)
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
