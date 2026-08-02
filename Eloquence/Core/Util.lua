-- Eloquence: string plumbing.
--
-- The single most important job in this file is making sure we never chew up a
-- chat message's escape sequences. A WoW chat line can contain item links,
-- textures, colour codes, raid target icons and URLs; mangling any of those
-- produces broken or unclickable output. Rather than substituting placeholder
-- sentinels into the string (which the filters could then match against and
-- destroy), we slice the message into alternating "protected" and "plain"
-- segments and only ever transform the plain ones.
local ADDON, E = ...

local find, sub, gsub, lower, upper, byte = string.find, string.sub, string.gsub, string.lower, string.upper, string.byte
local floor = math.floor

--------------------------------------------------------------------------------
-- Protected spans
--------------------------------------------------------------------------------

-- Patterns matched against the raw message. Anything matched is passed through
-- untouched. Order within the table only matters for ties at the same offset,
-- where the longest match wins.
local PROTECTED = {
	"|H.-|h.-|h",                 -- hyperlinks (item/spell/player/achievement...)
	"|T.-|t",                     -- inline textures
	"|A.-|a",                     -- inline atlases
	"|K.-|k",                     -- Battle.net presence names
	"|c%x%x%x%x%x%x%x%x",         -- colour open
	"|r",                         -- colour close
	"|n",                         -- newline escape
	"||",                         -- literal pipe
	"%b{}",                       -- {rt3}, {star}, {square}...
	"%a[%w%+%-%.]*://[^%s]+",     -- scheme URLs
	"www%.[^%s]+",                -- bare www URLs

	-- Roleplaying conventions. These are not speech and must never be dialected.
	--
	-- Parentheses mark an out-of-character aside inside an in-character channel.
	-- Rendering "(brb, the dog needs out)" as "(brb, the dog needs oot)" is
	-- precisely wrong: the player has explicitly stepped outside their character
	-- to say it.
	--
	-- Both single and double count. Double is the older convention, but Total RP
	-- 3 -- which most of the roleplaying population runs -- treats a single pair
	-- as out of character, so a single pair is what people actually type.
	--
	-- The cost is that an in-character parenthetical stops being dialected, and
	-- that is the right way round to fail: protecting too much passes the
	-- player's own words through untouched, while protecting too little rewrites
	-- something they explicitly stepped out of character to say. Live chat also
	-- barely uses prose parentheticals -- an opening bracket in /say is nearly
	-- always meta commentary.
	--
	-- The double-parenthesis pattern is kept even though the single one covers
	-- the same text, because "%(.-%)" is non-greedy and stops at the first ")":
	-- on "((...))" it protects all but the final character. That makes no
	-- difference to any filter, since a stranded ")" has no letters to rewrite,
	-- but it does leave the span structurally wrong -- E.SplitMessage treats
	-- protected spans as atomic units, and an orphaned bracket could be split
	-- away from its pair at a message boundary. Ties at the same offset are
	-- broken by taking the longest match, so the double rule wins where both
	-- apply and the span stays whole.
	"%(%(.-%)%)",
	"%(.-%)",
	-- Square-bracketed tags mark the register or language of what follows --
	-- "[low]" for quiet speech that passers-by may overhear, "[Thalassian]" for
	-- the language being spoken. The tag is metadata about the line, not part of
	-- it, so it passes through while the speech after it is still dialected.
	"%[.-%]",
}

--------------------------------------------------------------------------------
-- Proper nouns
--------------------------------------------------------------------------------

-- Words that are capitalised without starting a sentence are almost always
-- names, and on a roleplaying realm a name is the last thing that should be
-- rewritten. Someone writing "Zethrrel" with rolled Rs, or another character
-- deliberately mangling it as "Zettle", has made a choice; sanding that off is
-- worse than doing nothing. Protecting them here means every filter leaves them
-- alone, not just the dialects.
--
-- "I" and its contractions are exempt, or the Dwarven "i" -> "Ah" would never
-- fire anywhere except at the start of a sentence.
local PRONOUN_I = {
	["I"] = true, ["I'm"] = true, ["I'll"] = true, ["I've"] = true, ["I'd"] = true,
}

-- A word starts a sentence if only whitespace and opening punctuation separate
-- it from the start of the text or from a preceding . ! or ?
local function StartsSentence(text, wordStart)
	local i = wordStart - 1
	while i >= 1 do
		local c = sub(text, i, i)
		if c:match("%s") or c == "(" or c == "[" or c == '"' or c == "*" or c == "<" then
			i = i - 1
		elseif c == "." or c == "!" or c == "?" or c == ":" or c == ";" then
			return true
		else
			return false
		end
	end
	return true
end

local function FindProperNouns(text)
	local spans = {}
	local pos = 1
	while true do
		local s, e = find(text, "%a[%w']*", pos)
		if not s then break end
		local word = sub(text, s, e)
		local first = sub(word, 1, 1)
		-- "Zethrrel" is a name; "ZETHRREL" is indistinguishable from a shouted
		-- word, and treating every word in an ALL-CAPS message as a name would
		-- make de-shouting impossible. Only Capitalised words are protected.
		local shouted = #word > 1 and word == word:upper()
		if first == first:upper() and first:match("%a")
			and not shouted
			and not PRONOUN_I[word]
			and not StartsSentence(text, s) then
			spans[#spans + 1] = { s = s, e = e }
		end
		pos = e + 1
	end
	return spans
end

E.FindProperNouns = FindProperNouns

--------------------------------------------------------------------------------

-- An action wrapped in asterisks inside an otherwise spoken line:
--
--   Here, this is for you *pulls out a flower* hope you like it.
--
-- Same principle as an emote -- the starred part is narration, not speech, so it
-- must not be accented. Unlike the entries in PROTECTED this is not applied to
-- every filter: it is passed in by Modules/Dialectician.lua alone, because a typo
-- or a modernism inside an action is still worth fixing. It is the accent
-- specifically that does not belong in prose about the character.
--
-- Requires a matched pair with something between them, so a lone asterisk or a
-- stray "2*3" is left as ordinary text.
E.ACTION_SPAN = "%*[^%*]+%*"

-- Earliest match wins; ties at the same offset go to the longest.
local function BestMatch(text, pos, patterns, bestS, bestE)
	for i = 1, #patterns do
		local s, e = find(text, patterns[i], pos)
		if s and (not bestS or s < bestS or (s == bestS and e > bestE)) then
			bestS, bestE = s, e
		end
	end
	return bestS, bestE
end

-- Split `text` into a list of { text = string, protected = boolean } segments.
-- With `protectNames`, mid-sentence capitalised words are protected too.
-- `extra` is an optional list of additional protected patterns, for callers that
-- need spans protected from themselves but not from every filter.
function E.Tokenize(text, protectNames, extra)
	-- Collect every protected range first, then emit segments around them. Doing
	-- it in two passes keeps the escape-sequence scan and the proper-noun scan
	-- independent of each other.
	local ranges = {}
	local pos, len = 1, #text
	while pos <= len do
		local bestS, bestE = BestMatch(text, pos, PROTECTED)
		if extra then bestS, bestE = BestMatch(text, pos, extra, bestS, bestE) end
		if not bestS then break end
		ranges[#ranges + 1] = { s = bestS, e = bestE }
		pos = bestE + 1
	end

	if protectNames then
		for _, span in ipairs(FindProperNouns(text)) do
			-- Skip anything already inside an escape sequence.
			local inside = false
			for _, range in ipairs(ranges) do
				if span.s >= range.s and span.s <= range.e then inside = true break end
			end
			if not inside then ranges[#ranges + 1] = span end
		end
		table.sort(ranges, function(a, b) return a.s < b.s end)
	end

	local out = {}
	local cursor = 1
	for _, range in ipairs(ranges) do
		if range.s > cursor then
			out[#out + 1] = { text = sub(text, cursor, range.s - 1), protected = false }
		end
		if range.e >= cursor then
			out[#out + 1] = { text = sub(text, math.max(range.s, cursor), range.e), protected = true }
			cursor = range.e + 1
		end
	end
	if cursor <= len then
		out[#out + 1] = { text = sub(text, cursor), protected = false }
	end
	return out
end

-- Run `fn(plainChunk)` over every unprotected segment and reassemble. Proper
-- nouns count as protected, so no filter can rewrite somebody's name.
function E.MapPlain(text, fn, extra)
	local segs = E.Tokenize(text, true, extra)
	local parts = {}
	for i = 1, #segs do
		local seg = segs[i]
		if seg.protected then
			parts[i] = seg.text
		else
			parts[i] = fn(seg.text) or seg.text
		end
	end
	return table.concat(parts)
end

-- Just the prose, with every protected span dropped. Used for decisions that
-- have to be made about the message as a whole -- "is this person shouting?",
-- "is there any actual text here?" -- where the contents of an item link would
-- otherwise skew the answer.
function E.PlainText(text)
	local parts = {}
	for _, seg in ipairs(E.Tokenize(text, true)) do
		if not seg.protected then parts[#parts + 1] = seg.text end
	end
	return table.concat(parts)
end

--------------------------------------------------------------------------------
-- Quoted speech
--------------------------------------------------------------------------------

-- An emote is narration, not speech. The convention is third-person prose for
-- the action and quotation marks around anything the character actually says:
--
--   Zethrel holds out a flower. "Here you go, this is for you."
--
-- Accenting the narration is wrong -- it reads as though the narrator has the
-- accent rather than the character -- so the dialect is confined to the quoted
-- spans. See Modules/Dialectician.lua.
--
-- ONLY DOUBLE QUOTES COUNT. A single quote is an apostrophe far more often than a
-- quotation mark in this domain: the dialects emit "no'", "dinnae", "shan'do",
-- "Al diel shala" and "Lok'tar" constantly, and treating ' as a delimiter would
-- carve speech spans out of the middle of words.
local CURLY_OPEN, CURLY_CLOSE = "\226\128\156", "\226\128\157"

-- Find the next opening quote at or after `pos`. Returns its start, its end, and
-- the closing delimiter to look for.
local function NextQuote(text, pos)
	local sStraight = find(text, '"', pos, true)
	local sCurly = find(text, CURLY_OPEN, pos, true)
	if sStraight and (not sCurly or sStraight < sCurly) then
		return sStraight, sStraight, '"'
	elseif sCurly then
		return sCurly, sCurly + #CURLY_OPEN - 1, CURLY_CLOSE
	end
	return nil
end

-- Run `fn` over the interior of each quoted span and reassemble. Text outside
-- quotes, and the quote marks themselves, pass through untouched.
--
-- An unclosed quote is treated as running to the end of the message, since a
-- player who opened one and got cut off by the 255-byte limit still meant the
-- rest as speech.
function E.MapQuoted(text, fn)
	local out, pos, len = {}, 1, #text
	while pos <= len do
		local openS, openE, closer = NextQuote(text, pos)
		if not openS then break end

		-- Everything before the quote is narration.
		if openS > pos then
			out[#out + 1] = sub(text, pos, openS - 1)
		end
		out[#out + 1] = sub(text, openS, openE)

		local closeS = find(text, closer, openE + 1, true)
		local speech = sub(text, openE + 1, closeS and closeS - 1 or len)
		if speech ~= "" then
			out[#out + 1] = fn(speech) or speech
		end

		if closeS then
			out[#out + 1] = sub(text, closeS, closeS + #closer - 1)
			pos = closeS + #closer
		else
			pos = len + 1
		end
	end
	if pos <= len then
		out[#out + 1] = sub(text, pos)
	end
	return table.concat(out)
end

-- True when `text` contains a quoted span at all.
function E.HasQuotedSpeech(text)
	return NextQuote(text, 1) ~= nil
end

--------------------------------------------------------------------------------
-- Terms of address
--------------------------------------------------------------------------------

-- Reported from a Human Death Knight: "Goodbye, friend." came out as
-- "Suffer well, companion, friend" -- two different words doing the same job.
--
-- It happens because the filters run in sequence and none of them can see what
-- the others did. The Fantasy Writer maps "friend" to "companion", then the
-- dialect either appends its own vocative as flavour or expands an idiom whose
-- replacement already contains one, as Human's "goodbye" does with "King's
-- honor, friend". Neither step is wrong on its own.
E.VOCATIVES = {}
for _, word in ipairs({
	"friend", "friends", "companion", "companions", "comrade", "comrades",
	"laddie", "lassie", "lad", "lass", "lads", "brother", "sister", "kin",
	"mate", "associate", "stranger", "youngling", "child", "mon", "bruddah",
	"kindred",
	"shan'do", "thero'shan", "young one", "old chap", "one",
}) do E.VOCATIVES[word] = true end

-- Drop a term of address that immediately follows another. The first is kept:
-- it is the one the dialect chose deliberately, while the later is the vestige
-- of whatever the earlier filters left behind.
function E.CollapseVocatives(text)
	if not text:find(",") then return text end
	local body, tail = text:match("^(.-)([%p%s]*)$")
	if body == "" then return text end

	local parts = {}
	for part in (body .. ","):gmatch("(.-),") do parts[#parts + 1] = part end
	if #parts < 2 then return text end

	local kept = {}
	for _, part in ipairs(parts) do
		local previous = kept[#kept]
		local isVocative = E.VOCATIVES[lower(E.Trim(part))] == true
		local afterVocative = previous ~= nil
			and E.VOCATIVES[lower(E.Trim(previous))] == true
		if not (isVocative and afterVocative) then
			kept[#kept + 1] = part
		end
	end
	if #kept == #parts then return text end
	return table.concat(kept, ",") .. tail
end

--------------------------------------------------------------------------------
-- Run-length collapsing
--------------------------------------------------------------------------------

-- Lua patterns cannot express "three or more of the same character": a
-- back-reference like %1 may not carry a quantifier, so "(%a)%1%1+" silently
-- never matches. This does the job explicitly instead.
--
-- `maxRunFor(char)` returns the longest run to keep, or nil to leave alone.
function E.CollapseRuns(text, maxRunFor)
	local out, i, len = {}, 1, #text
	while i <= len do
		local c = sub(text, i, i)
		local j = i + 1
		while j <= len and sub(text, j, j) == c do j = j + 1 end
		local run = j - i
		local limit = maxRunFor(c)
		if limit and run > limit then run = limit end
		out[#out + 1] = string.rep(c, run)
		i = j
	end
	return table.concat(out)
end

--------------------------------------------------------------------------------
-- Case handling
--------------------------------------------------------------------------------

-- Re-apply the capitalisation of `src` onto `repl`.
function E.MatchCase(src, repl)
	if src == lower(src) then
		return repl
	end
	if #src > 1 and src == upper(src) then
		return upper(repl)
	end
	local first = sub(src, 1, 1)
	if first == upper(first) then
		return upper(sub(repl, 1, 1)) .. sub(repl, 2)
	end
	return repl
end

--------------------------------------------------------------------------------
-- Deterministic randomness
--------------------------------------------------------------------------------

-- A message must always render the same way. If we used math.random the same
-- line could read differently every time a chat frame redrew it, and two
-- players running Eloquence would disagree about what someone said. So every
-- random decision is driven by a Lehmer generator seeded from the message
-- itself plus the speaker's GUID.
function E.Hash(str)
	local h = 5381
	for i = 1, #str do
		h = (h * 33 + byte(str, i)) % 4294967296
	end
	return h
end

function E.NewRNG(seed)
	local s = seed % 2147483647
	if s <= 0 then s = s + 2147483646 end
	return function()
		s = (s * 16807) % 2147483647
		return (s - 1) / 2147483646
	end
end

--------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------

function E.Trim(s)
	return (gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- How worked up is the speaker? Drives things like the Forsaken hiss.
-- Returns 0..1.
function E.Excitement(text)
	local score = 0
	local _, bangs = gsub(text, "!", "")
	score = score + math.min(bangs, 4) * 0.15

	local letters, caps = 0, 0
	for i = 1, #text do
		local b = byte(text, i)
		if b >= 65 and b <= 90 then caps = caps + 1; letters = letters + 1
		elseif b >= 97 and b <= 122 then letters = letters + 1 end
	end
	if letters >= 4 then
		score = score + (caps / letters) * 0.5
	end
	return math.min(score, 1)
end

-- True when `b` is a UTF-8 continuation byte.
local function IsCont(b)
	return b and b >= 128 and b < 192
end

-- Truncate to at most `limit` bytes without slicing a multi-byte character.
function E.SafeSub(text, limit)
	if #text <= limit then return text end
	local cut = limit
	while cut > 0 and IsCont(byte(text, cut + 1)) do
		cut = cut - 1
	end
	return sub(text, 1, cut)
end

-- Split a message into chunks of at most `limit` bytes, preferring word
-- boundaries and never cutting a protected span (an item link) in half.
function E.SplitMessage(text, limit)
	limit = limit or 255
	if #text <= limit then return { text } end

	-- Break into atomic units: protected spans stay whole, plain text splits on
	-- whitespace but keeps the whitespace attached to the following word.
	--
	-- Adjacent protected spans are merged, because a coloured item link arrives
	-- as three of them ("|cffa335ee", "|Hitem:...|h", "|r") and splitting
	-- between them would strand the colour codes on different lines.
	local units = {}
	local lastWasProtected = false
	for _, seg in ipairs(E.Tokenize(text)) do
		if seg.protected then
			if lastWasProtected then
				units[#units] = units[#units] .. seg.text
			else
				units[#units + 1] = seg.text
			end
			lastWasProtected = true
		else
			lastWasProtected = false
			for chunk in gsub(seg.text, "(%s+)", "\1%1"):gmatch("[^\1]+") do
				units[#units + 1] = chunk
			end
		end
	end

	local out, cur = {}, ""
	local function flush()
		local trimmed = E.Trim(cur)
		if trimmed ~= "" then out[#out + 1] = trimmed end
		cur = ""
	end

	for _, unit in ipairs(units) do
		if #cur + #unit <= limit then
			cur = cur .. unit
		else
			flush()
			-- A single unit longer than the limit has to be hard-split.
			while #unit > limit do
				local piece = E.SafeSub(unit, limit)
				out[#out + 1] = piece
				unit = sub(unit, #piece + 1)
			end
			cur = unit
		end
	end
	flush()
	return out
end
