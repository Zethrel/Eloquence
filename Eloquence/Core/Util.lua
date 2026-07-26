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
}

-- Split `text` into a list of { text = string, protected = boolean } segments.
function E.Tokenize(text)
	local out, pos, len = {}, 1, #text
	while pos <= len do
		local bestS, bestE
		for i = 1, #PROTECTED do
			local s, e = find(text, PROTECTED[i], pos)
			if s and (not bestS or s < bestS or (s == bestS and e > bestE)) then
				bestS, bestE = s, e
			end
		end
		if not bestS then
			out[#out + 1] = { text = sub(text, pos), protected = false }
			break
		end
		if bestS > pos then
			out[#out + 1] = { text = sub(text, pos, bestS - 1), protected = false }
		end
		out[#out + 1] = { text = sub(text, bestS, bestE), protected = true }
		pos = bestE + 1
	end
	return out
end

-- Run `fn(plainChunk)` over every unprotected segment and reassemble.
function E.MapPlain(text, fn)
	-- Fast path: nothing worth protecting.
	if not find(text, "[|{]") and not find(text, "://") and not find(text, "www%.") then
		return fn(text) or text
	end
	local segs = E.Tokenize(text)
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
	for _, seg in ipairs(E.Tokenize(text)) do
		if not seg.protected then parts[#parts + 1] = seg.text end
	end
	return table.concat(parts)
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
