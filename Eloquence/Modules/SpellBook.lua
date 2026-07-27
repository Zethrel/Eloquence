-- The Spell Book: the least glamorous and most useful filter.
--
-- Fixes common misspellings and grammar slips, squashes runaway repetition
-- ("heyyyyyy", "!!!!!!!"), and takes the shouting out of ALL-CAPS messages.
local ADDON, E = ...

local gsub, upper, lower, sub, rep = string.gsub, string.upper, string.lower, string.sub, string.rep

local CORRECTIONS = {
	-- Homophone and apostrophe slips
	["teh"] = "the", ["hte"] = "the", ["adn"] = "and", ["nad"] = "and",
	["taht"] = "that", ["thsi"] = "this", ["waht"] = "what", ["wich"] = "which",
	["yuo"] = "you", ["yor"] = "your", ["youre"] = "you're", ["your'e"] = "you're",
	["thier"] = "their", ["theri"] = "their", ["theyre"] = "they're",
	["dont"] = "don't", ["doesnt"] = "doesn't", ["didnt"] = "didn't",
	["cant"] = "can't", ["wont"] = "won't", ["isnt"] = "isn't", ["arent"] = "aren't",
	["wasnt"] = "wasn't", ["werent"] = "weren't", ["havent"] = "haven't",
	["hasnt"] = "hasn't", ["couldnt"] = "couldn't", ["wouldnt"] = "wouldn't",
	["shouldnt"] = "shouldn't", ["im"] = "I'm", ["ive"] = "I've",
	["ill"] = "I'll", ["id"] = "I'd", ["thats"] = "that's", ["whats"] = "what's",
	["theres"] = "there's", ["hes"] = "he's", ["shes"] = "she's",
	["lets"] = "let's", ["wouldve"] = "would've", ["couldve"] = "could've",
	["shouldve"] = "should've", ["alot"] = "a lot", ["aswell"] = "as well",
	["definately"] = "definitely", ["definatly"] = "definitely",
	["seperate"] = "separate", ["recieve"] = "receive", ["recieved"] = "received",
	["beleive"] = "believe", ["beleived"] = "believed", ["freind"] = "friend",
	["freinds"] = "friends", ["wierd"] = "weird", ["truely"] = "truly",
	["untill"] = "until", ["allready"] = "already", ["allot"] = "a lot",
	["accross"] = "across", ["occured"] = "occurred", ["begining"] = "beginning",
	["comming"] = "coming", ["runing"] = "running", ["geting"] = "getting",
	["puting"] = "putting", ["stoped"] = "stopped", ["droped"] = "dropped",
	["succesful"] = "successful", ["neccessary"] = "necessary",
	["probaly"] = "probably", ["propably"] = "probably", ["probly"] = "probably",
	["basicly"] = "basically", ["completly"] = "completely",
	["immediatly"] = "immediately", ["speach"] = "speech", ["strenght"] = "strength",
	["lenght"] = "length", ["heigth"] = "height", ["wich"] = "which",
	["excpet"] = "except", ["becuase"] = "because", ["becasue"] = "because",
	["bacause"] = "because", ["wanna"] = "want to", ["gonna"] = "going to",
	["gotta"] = "got to", ["kinda"] = "kind of", ["sorta"] = "sort of",
	["outta"] = "out of", ["lemme"] = "let me", ["gimme"] = "give me",
	["dunno"] = "don't know", ["cuz"] = "because", ["coz"] = "because",
	["nite"] = "night", ["lite"] = "light", ["thru"] = "through",
	["tho"] = "though", ["altho"] = "although", ["prolly"] = "probably",
	-- WoW-specific spellings people mangle constantly
	["stormwing"] = "Stormwind", ["ogrimmar"] = "Orgrimmar",
	["orgimmar"] = "Orgrimmar", ["ogrimar"] = "Orgrimmar",
	["darnasus"] = "Darnassus", ["ironforce"] = "Ironforge",
	["undercitiy"] = "Undercity", ["azerorth"] = "Azeroth",
	["deathwign"] = "Deathwing", ["arthas"] = "Arthas", ["sylvanis"] = "Sylvanas",
	["sylvannas"] = "Sylvanas", ["thral"] = "Thrall", ["jaine"] = "Jaina",
}

local module = E.RegisterModule("spellbook", {
	name = "The Spell Book",
	desc = "Corrects common misspellings, tames repeated letters and squashes ALL-CAPS shouting.",
})

-- Words that legitimately repeat a letter three or more times are vanishingly
-- rare, so anything past a double is treated as emphasis and trimmed back.
-- "heyyyyyy" -> "heyy", "stop!!!!!!" -> "stop!!", "well......" -> "well...".
local function RunLimit(c)
	if c:match("%a") then return 2 end
	if c == "!" or c == "?" then return 2 end
	if c == "." then return 3 end
	if c == "," or c == ";" or c == ":" then return 1 end
	return nil
end

local function SquashRepeats(chunk)
	return E.CollapseRuns(chunk, RunLimit)
end

-- "HELP ME PLEASE" -> "Help me please".
--
-- The decision has to be made on the whole message (a short segment between two
-- item links would never look shouty on its own), but the rewrite has to be
-- applied per plain segment so that colour codes and link payloads survive.
-- Hence the split into a test and a transform.
local function IsShouting(text)
	local letters, caps = 0, 0
	for i = 1, #text do
		local b = text:byte(i)
		if b >= 65 and b <= 90 then caps = caps + 1; letters = letters + 1
		elseif b >= 97 and b <= 122 then letters = letters + 1 end
	end
	return letters >= 8 and (caps / letters) >= 0.75
end

local function Unshout(chunk)
	chunk = lower(chunk)
	-- Recapitalise sentence starts and the pronoun I.
	chunk = gsub(chunk, "^(%l)", upper)
	chunk = gsub(chunk, "([.!?]%s+)(%l)", function(pre, c) return pre .. upper(c) end)
	chunk = gsub(chunk, "%f[%a]i%f[%A]", "I")
	return chunk
end

function module.Filter(text, ctx)
	local strength = ctx.strength

	-- Measured on the prose alone: the lowercase words inside an item link's
	-- display text would otherwise hide the fact that someone is shouting.
	local shouty = IsShouting(E.PlainText(text))

	text = E.MapPlain(text, function(chunk)
		if shouty then chunk = Unshout(chunk) end
		if strength >= 1 then chunk = SquashRepeats(chunk) end
		chunk = gsub(chunk, "[%a']+", function(token)
			-- An edge apostrophe is deliberate elision, not a typo. See the note
			-- in Engine.lua's ApplyWords.
			if token:sub(1, 1) == "'" or token:sub(-1) == "'" then return nil end
			local fixed = CORRECTIONS[lower(token)]
			if not fixed then return nil end
			return E.MatchCase(token, fixed)
		end)
		if strength >= 2 then
			-- Tidy spacing around punctuation.
			chunk = gsub(chunk, "%s+([,.!?;:])", "%1")
			chunk = gsub(chunk, "([,;:])(%a)", "%1 %2")
			chunk = gsub(chunk, "  +", " ")
		end
		if strength >= 3 then
			-- Capitalise the start of sentences.
			chunk = gsub(chunk, "^%s*(%l)", upper)
			chunk = gsub(chunk, "([.!?]%s+)(%l)", function(pre, c) return pre .. upper(c) end)
		end
		return chunk
	end)

	return text
end

-- Exposed for the test harness.
module.IsShouting = IsShouting
module.Unshout = Unshout
module.SquashRepeats = SquashRepeats
