-- Eloquence: the substitution engine.
--
-- Every filter (and every dialect) is expressed as a declarative rule set that
-- this file knows how to apply. A rule set may define:
--
--   words       = { ["you"] = "ye" }         single-word swaps, case preserving
--   wordsAt     = { [2] = {...}, [3] = {...} }  extra words gated by strength
--   phrases     = { { "%f[%a]going to%f[%A]", "gaun tae" } }   ordered patterns
--   phrasesAt   = { [3] = { ... } }             extra phrases gated by strength
--   post        = function(chunk, ctx) return chunk end   accent transforms
--   flavor      = { prefix = {...}, suffix = {...}, chance = 0.12 }
--
-- Phrases run before words so that multi-word idioms win over their parts.
--
-- A phrase entry is { pattern, replacement, raw, clauseFinal }:
--   raw          hand the replacement straight to gsub; it may use %1 captures.
--                Otherwise the whole match is replaced and the original
--                capitalisation is carried across.
--   clauseFinal  only match when the phrase ends a clause -- that is, when it is
--                followed by punctuation or the end of the message. Idioms that
--                stand in for a whole sentence need this: "I don't know" should
--                become "That knowledge escapes me" on its own, but must stay
--                literal in "I don't know where the child went".
local ADDON, E = ...

local gsub, lower, find, sub = string.gsub, string.lower, string.find, string.sub
local floor = math.floor

local function Concat(pieces)
	local parts = {}
	for i = 1, #pieces do parts[i] = pieces[i].text end
	return table.concat(parts)
end

local Engine = {}
E.Engine = Engine

--------------------------------------------------------------------------------
-- Compilation
--------------------------------------------------------------------------------

-- Phrase patterns are written in lower case, but chat is full of capitalised
-- sentence openings -- "Watch out!" has to hit the same rule as "watch out".
-- Rather than making every dialect author spell that out, each letter in the
-- pattern is rewritten into a two-character class at compile time. Escapes
-- (%a, %f) and explicit classes ([%p]) are copied through untouched.
local function CaseInsensitive(pattern)
	local out, i, len = {}, 1, #pattern
	while i <= len do
		local c = pattern:sub(i, i)
		if c == "%" then
			out[#out + 1] = pattern:sub(i, i + 1)
			i = i + 2
		elseif c == "[" then
			-- Copy the whole character class verbatim. This also covers the
			-- "[%a]" half of a %f[%a] frontier, whose "%f" was consumed above.
			local j = i + 1
			if pattern:sub(j, j) == "^" then j = j + 1 end
			if pattern:sub(j, j) == "]" then j = j + 1 end
			while j <= len and pattern:sub(j, j) ~= "]" do
				j = (pattern:sub(j, j) == "%") and (j + 2) or (j + 1)
			end
			out[#out + 1] = pattern:sub(i, j)
			i = j + 1
		elseif c:match("%a") then
			out[#out + 1] = "[" .. c:lower() .. c:upper() .. "]"
			i = i + 1
		else
			out[#out + 1] = c
			i = i + 1
		end
	end
	return table.concat(out)
end
Engine.CaseInsensitive = CaseInsensitive

-- Merge the base rules with everything unlocked at or below `strength`, and
-- cache the result on the rule set so we only pay for it once per strength.
local function Compile(rules, strength)
	rules._compiled = rules._compiled or {}
	local cached = rules._compiled[strength]
	if cached then return cached end

	local words = {}
	if rules.words then
		for k, v in pairs(rules.words) do words[lower(k)] = v end
	end
	if rules.wordsAt then
		for level = 1, strength do
			local extra = rules.wordsAt[level]
			if extra then
				for k, v in pairs(extra) do words[lower(k)] = v end
			end
		end
	end

	-- Strength-gated phrases are tried before the base ones, highest level
	-- first, so a heavy setting can override a rule the base set defines. This
	-- matches how wordsAt already behaves (a later assignment wins), and is what
	-- lets the Darnassian glossary replace "thank you" with "Shaha lor'ma" at
	-- strength 3 while leaving the plain English idiom in place below that.
	local raw = {}
	if rules.phrasesAt then
		for level = strength, 1, -1 do
			local extra = rules.phrasesAt[level]
			if extra then
				for _, p in ipairs(extra) do raw[#raw + 1] = p end
			end
		end
	end
	if rules.phrases then
		for _, p in ipairs(rules.phrases) do raw[#raw + 1] = p end
	end

	-- Clause-final rules are ordered first, so they are evaluated while the
	-- chunk is still whole and "is this the end of a clause?" is answerable.
	local phrases = {}
	for pass = 1, 2 do
		for i = 1, #raw do
			local clauseFinal = raw[i][4] and true or false
			if clauseFinal == (pass == 1) then
				phrases[#phrases + 1] = {
					pattern = CaseInsensitive(raw[i][1]),
					replacement = raw[i][2],
					raw = raw[i][3],
					clauseFinal = clauseFinal,
				}
			end
		end
	end

	cached = { words = words, phrases = phrases, hasWords = next(words) ~= nil }
	rules._compiled[strength] = cached
	return cached
end

-- Dialect files are loaded before the options are read, so a rule set that gets
-- edited at runtime (never, currently) would need this.
function Engine.Invalidate(rules)
	rules._compiled = nil
end

--------------------------------------------------------------------------------
-- Application
--------------------------------------------------------------------------------

-- Does the match ending at `e` finish a clause? True at the end of the text, or
-- when the next non-space character is punctuation.
local function ClauseEnds(text, e)
	if e >= #text then return true end
	return find(text, "^%s*%p", e + 1) ~= nil
end

-- Phrase replacements are final: once "a lot of" has become "a great many of",
-- the word pass must not go on to turn "great" into "wondrous". So instead of a
-- plain gsub, the chunk is split into a list of pieces where the ones produced
-- by a phrase rule are flagged, and the word pass skips those.
local function ApplyPhrases(phrases, pieces)
	for i = 1, #phrases do
		local entry = phrases[i]
		local pattern, replacement, isRaw = entry.pattern, entry.replacement, entry.raw
		local clauseFinal = entry.clauseFinal
		local next_ = {}

		for _, piece in ipairs(pieces) do
			if piece.final then
				next_[#next_ + 1] = piece
			else
				-- Two cursors: `pos` is the start of text not yet emitted, while
				-- `searchFrom` advances past matches we decline to replace.
				local text, pos, searchFrom = piece.text, 1, 1
				while searchFrom <= #text do
					local s, e = find(text, pattern, searchFrom)
					if not s then break end

					if e < s then
						-- Zero-width match; step past it rather than spin.
						searchFrom = s + 1
					elseif clauseFinal and not ClauseEnds(text, e) then
						-- The idiom stands in for a whole clause, and this one is
						-- mid-sentence. Leave it for the word pass.
						searchFrom = e + 1
					else
						if s > pos then
							next_[#next_ + 1] = { text = sub(text, pos, s - 1) }
						end
						local matched = sub(text, s, e)
						next_[#next_ + 1] = {
							text = isRaw and (gsub(matched, pattern, replacement))
								or E.MatchCase(matched, replacement),
							final = true,
						}
						pos = e + 1
						searchFrom = e + 1
					end
				end
				if pos <= #text then
					next_[#next_ + 1] = { text = sub(text, pos) }
				end
			end
		end
		pieces = next_
	end
	return pieces
end

local function ApplyWords(words, chunk)
	return (gsub(chunk, "[%a']+", function(token)
		-- An apostrophe on either end is the author eliding something on purpose
		-- -- "no'", "th'", "'tis", "aboot tha'". Substituting the letters and
		-- gluing the apostrophe back on produced nonsense like "no'" -> "nae'",
		-- which is precisely the sort of authored voice that must survive. Leave
		-- any word with an edge apostrophe exactly as written.
		if token:sub(1, 1) == "'" or token:sub(-1) == "'" then return nil end
		local replacement = words[lower(token)]
		if not replacement then return nil end
		return E.MatchCase(token, replacement)
	end))
end

local function Pick(list, rng)
	return list[floor(rng() * #list) + 1]
end

local function ApplyFlavor(flavor, text, ctx)
	local chance = (flavor.chance or 0.12) * (ctx.strength / 2)
	if flavor.prefix and #flavor.prefix > 0 and ctx.rng() < chance then
		text = Pick(flavor.prefix, ctx.rng) .. " " .. text
	end
	if flavor.suffix and #flavor.suffix > 0 and ctx.rng() < chance then
		-- Slide the interjection in ahead of any trailing punctuation so we get
		-- "...that wull wirk, laddie!" rather than "...wirk! laddie".
		local body, tail = text:match("^(.-)([%p%s]*)$")
		if body == "" then body, tail = text, "" end
		local suffix = Pick(flavor.suffix, ctx.rng)
		-- Skip it when the sentence already ends on those words, which otherwise
		-- produces "...work, friend, friend".
		local lowerBody, lowerSuffix = lower(body), lower(suffix)
		if sub(lowerBody, -#lowerSuffix) ~= lowerSuffix then
			text = body .. ", " .. suffix .. tail
		end
	end
	return text
end

-- Run a rule set over `text`. `ctx` must carry `rng` and `strength`.
-- Many dialect entries legitimately expand a noun into an articled phrase --
-- ["moon"] = "the Mother Moon", ["death"] = "da long sleep", ["gods"] = "the loa".
-- That reads correctly until the source sentence supplies its own article, and
-- then you get "the the Mother Moon" or "de da long sleep".
--
-- Auditing every entry across 26 dialects is the fragile fix: the next person to
-- add ["sea"] = "the deep" reintroduces it. So the doubling is collapsed centrally
-- instead, which also covers the Trollish "de"/"da" respellings of "the".
--
-- Only genuine duplicates are touched. "de da" is a doubling because both are
-- Trollish "the"; "the loa" and "a juju" are left alone.
local ARTICLES = { ["the"] = true, ["de"] = true, ["da"] = true }

local function CollapseArticles(chunk)
	return (gsub(chunk, "(%a+)(%s+)(%a+)", function(first, space, second)
		if ARTICLES[lower(first)] and ARTICLES[lower(second)] then
			-- Drop the trailing space too, or "the the Flame" collapses to
			-- "the  Flame": the space before the next word is still there.
			return first
		end
		return first .. space .. second
	end))
end

function Engine.Apply(rules, text, ctx)
	local compiled = Compile(rules, ctx.strength or 2)
	local hasPhrases = #compiled.phrases > 0
	local hasWords = compiled.hasWords
	local post = rules.post

	if hasPhrases or hasWords or post then
		text = E.MapPlain(text, function(chunk)
			local pieces = { { text = chunk } }
			if hasPhrases then
				pieces = ApplyPhrases(compiled.phrases, pieces)
			end
			if hasWords then
				for _, piece in ipairs(pieces) do
					if not piece.final then
						piece.text = ApplyWords(compiled.words, piece.text)
					end
				end
			end
			chunk = #pieces == 1 and pieces[1].text or Concat(pieces)
			-- Accent transforms run over the reassembled chunk: a Dwarf drops
			-- the g from an -ing that a phrase rule produced, too.
			if post then chunk = post(chunk, ctx) end
			return CollapseArticles(chunk)
		end)
	end

	if rules.flavor then
		text = ApplyFlavor(rules.flavor, text, ctx)
	end
	return text
end

--------------------------------------------------------------------------------
-- Shared helpers for dialect authors
--------------------------------------------------------------------------------

-- Contractions are a recurring axis: Night Elves, Draenei and Tauren speak
-- formally (expanded), while Dwarves and Trolls contract heavily.
Engine.EXPAND_CONTRACTIONS = {
	["i'm"] = "I am", ["i've"] = "I have", ["i'd"] = "I would", ["i'll"] = "I shall",
	["you're"] = "you are", ["you've"] = "you have", ["you'd"] = "you would", ["you'll"] = "you will",
	["we're"] = "we are", ["we've"] = "we have", ["we'd"] = "we would", ["we'll"] = "we shall",
	["they're"] = "they are", ["they've"] = "they have", ["they'd"] = "they would", ["they'll"] = "they will",
	["he's"] = "he is", ["she's"] = "she is", ["it's"] = "it is", ["that's"] = "that is",
	["there's"] = "there is", ["here's"] = "here is", ["what's"] = "what is", ["who's"] = "who is",
	["let's"] = "let us", ["can't"] = "cannot", ["won't"] = "will not", ["don't"] = "do not",
	["doesn't"] = "does not", ["didn't"] = "did not", ["isn't"] = "is not", ["aren't"] = "are not",
	["wasn't"] = "was not", ["weren't"] = "were not", ["haven't"] = "have not", ["hasn't"] = "has not",
	["hadn't"] = "had not", ["wouldn't"] = "would not", ["shouldn't"] = "should not",
	["couldn't"] = "could not", ["ain't"] = "is not",
}

-- Turn a copy of a table so dialects can extend shared tables without
-- clobbering them.
function Engine.Extend(base, additions)
	local t = {}
	for k, v in pairs(base) do t[k] = v end
	if additions then
		for k, v in pairs(additions) do t[k] = v end
	end
	return t
end

-- Build a dialect from an existing one. Several races are genuine cultural
-- variants rather than separate languages -- Mag'har are orcs who never drank
-- the blood, Highmountain are tauren of the peaks -- so their dialects are the
-- parent's with a layer on top rather than a wholesale copy.
--
-- The result is a fresh table, so it gets its own compilation cache. The
-- variant's own phrases are placed ahead of the parent's, letting it override an
-- inherited idiom.
function Engine.Derive(parent, overrides)
	local derived = {
		name = overrides.name,
		desc = overrides.desc,
		words = Engine.Extend(parent.words or {}, overrides.words),
		post = overrides.post or parent.post,
		flavor = overrides.flavor or parent.flavor,
		wordsAt = {},
		phrases = {},
		phrasesAt = {},
	}

	for level = 1, 3 do
		local fromParent = parent.wordsAt and parent.wordsAt[level]
		local fromOverride = overrides.wordsAt and overrides.wordsAt[level]
		if fromParent or fromOverride then
			derived.wordsAt[level] = Engine.Extend(fromParent or {}, fromOverride)
		end
	end

	for _, entry in ipairs(overrides.phrases or {}) do
		derived.phrases[#derived.phrases + 1] = entry
	end
	for _, entry in ipairs(parent.phrases or {}) do
		derived.phrases[#derived.phrases + 1] = entry
	end

	for level = 1, 3 do
		local merged = {}
		for _, entry in ipairs((overrides.phrasesAt and overrides.phrasesAt[level]) or {}) do
			merged[#merged + 1] = entry
		end
		for _, entry in ipairs((parent.phrasesAt and parent.phrasesAt[level]) or {}) do
			merged[#merged + 1] = entry
		end
		if #merged > 0 then derived.phrasesAt[level] = merged end
	end

	return derived
end
