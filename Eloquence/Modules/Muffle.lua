-- Muffle: speech through a closed helm, a diving suit, or a mouthful of cloth.
--
-- Requested by Sleat of Argent Dawn (EU).
--
-- SELF ONLY, like the lisp. You cannot see what anyone else is wearing, and
-- guessing would garble a stranger's words on a hunch. module.selfOnly keeps the
-- pipeline from applying it to anyone but you.
--
-- Runs last, after the Dialectician and the lisp, because muffling is what
-- happens to the sound on its way out -- whatever was said, and in whatever
-- accent, this is the layer that sits over the mouth.
--
-- HOW IT SOUNDS
-- Through a helm you lose the consonants that need lips and teeth and keep the
-- ones made in the nose and throat, along with most of the vowels. So plosives
-- collapse onto nasals, fricatives go dull, and the word keeps its shape and
-- length -- which is what makes the result read as muffled speech rather than
-- as noise. Losing the shape entirely would just be mmmph, and nobody can
-- roleplay against that.
local ADDON, E = ...

local gsub = string.gsub

-- Applied in order; digraphs first so "th" is not eaten by the "t" rule.
local DIGRAPHS = {
	{ "th", "d" }, { "sh", "hm" }, { "ch", "hm" }, { "ph", "m" }, { "wh", "w" },
}

local LIGHT = { ["b"] = "m", ["p"] = "m", ["v"] = "m", ["f"] = "m" }

local MEDIUM = {
	["b"] = "m", ["p"] = "m", ["v"] = "m", ["f"] = "m",
	["t"] = "n", ["d"] = "n", ["s"] = "h", ["z"] = "h",
}

local HEAVY = {
	["b"] = "m", ["p"] = "m", ["v"] = "m", ["f"] = "m",
	["t"] = "n", ["d"] = "n", ["s"] = "h", ["z"] = "h",
	["k"] = "g", ["c"] = "g", ["q"] = "g", ["j"] = "n",
	["l"] = "w", ["r"] = "w",
}

-- A single left-to-right scan rather than a series of gsubs.
--
-- Two passes would feed the first one's output into the second: "th" became "d"
-- and the letter map then turned that "d" into "n", so "the" muffled to "ne"
-- instead of "de". Emitting each replacement and stepping past it means nothing
-- is ever muffled twice.
local function Muffle(chunk, strength)
	local map = strength >= 3 and HEAVY or (strength >= 2 and MEDIUM or LIGHT)
	local out, i, len = {}, 1, #chunk

	while i <= len do
		local matched = false

		-- Digraphs first: "th" is not a "t" followed by an "h".
		local pair = chunk:sub(i, i + 1)
		if #pair == 2 then
			local lowerPair = pair:lower()
			for _, entry in ipairs(DIGRAPHS) do
				if lowerPair == entry[1] then
					local replacement = entry[2]
					if pair:sub(1, 1):match("%u") then
						replacement = replacement:sub(1, 1):upper() .. replacement:sub(2)
					end
					out[#out + 1] = replacement
					i = i + 2
					matched = true
					break
				end
			end
		end

		if not matched then
			local letter = chunk:sub(i, i)
			local replacement = map[letter:lower()]
			if replacement then
				out[#out + 1] = letter:match("%u") and replacement:upper() or replacement
			else
				out[#out + 1] = letter
			end
			i = i + 1
		end
	end

	return table.concat(out)
end

local module = E.RegisterModule("muffle", {
	name = "Muffle",
	desc = "Your own speech is muffled, as through a helm. Needs outgoing rewriting on.",
	selfOnly = true,
})

function module.Filter(text, ctx)
	local strength = ctx.strength or 2
	return E.MapPlain(text, function(chunk)
		return Muffle(chunk, strength)
	end)
end

module.Muffle = Muffle
