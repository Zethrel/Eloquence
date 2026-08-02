-- Lisp: a speech impediment for characters who want one.
--
-- Requested by Sleat of Argent Dawn (EU), alongside the muffle filter.
--
-- SELF ONLY. Unlike every other filter, this describes how YOUR character
-- speaks, not how you would like to read other people. Lisping a stranger's
-- chat would be putting words in their mouth, so module.selfOnly stops the
-- pipeline applying it to anyone else whatever the settings say.
--
-- It runs after the Dialectician, because a lisp is a property of the mouth
-- rather than the language: whatever words come out, they come out lisped.
local ADDON, E = ...

local gsub = string.gsub

local module = E.RegisterModule("lisp", {
	name = "Lisp",
	desc = "Your own speech is lisped. Needs outgoing rewriting on.",
	selfOnly = true,
})

-- Order matters. The digraphs go first: handling "sh" after "s" would already
-- have turned it into "thh".
local function Lisp(chunk, strength)
	if strength >= 2 then
		-- A full lisp takes the postalveolars with it.
		chunk = gsub(chunk, "[Ss][Hh]", function(m)
			return m:sub(1, 1) == "S" and "Th" or "th"
		end)
		chunk = gsub(chunk, "[Cc][Hh]", function(m)
			return m:sub(1, 1) == "C" and "Th" or "th"
		end)
	end

	-- Soft c: only before e, i or y, or "cat" would become "that".
	if strength >= 2 then
		chunk = gsub(chunk, "([Cc])([eiyEIY])", function(c, following)
			return (c == "C" and "Th" or "th") .. following
		end)
	end

	-- The core of it.
	chunk = gsub(chunk, "[SsZz]", function(c)
		if c == "S" or c == "Z" then return "Th" end
		return "th"
	end)

	-- At heavy, the tongue gets in the way of the sibilant in "x" too.
	if strength >= 3 then
		chunk = gsub(chunk, "[Xx]", function(c)
			return c == "X" and "Kth" or "kth"
		end)
	end

	return chunk
end

function module.Filter(text, ctx)
	local strength = ctx.strength or 2
	return E.MapPlain(text, function(chunk)
		return Lisp(chunk, strength)
	end)
end

module.Lisp = Lisp
