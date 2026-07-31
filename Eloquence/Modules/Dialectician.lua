-- The Dialectician: gives every speaker an accent based on their race.
--
-- The dialect itself lives in Dialects\*.lua; this module only decides whether
-- one applies and hands it to the engine. The pipeline has already resolved
-- ctx.dialect from the speaker's GUID by the time we get here.
local ADDON, E = ...

local module = E.RegisterModule("dialect", {
	name = "Dialectician",
	desc = "Each speaker talks in an accent or dialect based on their race.",
})

-- An emote is narration with the character's speech quoted inside it:
--
--   Zethrel holds out a flower. "Here you go, this is for you."
--
-- The narration is authorial prose, written about the character rather than by
-- them, so accenting it is wrong -- "Zethrel haulds oot a flooer" reads as though
-- the narrator were the Dwarf. Only the quoted spans are speech, so only those
-- get the dialect. An emote with no quotes is pure action and is left alone.
--
-- This restriction is deliberately limited to the Dialectician. The other filters
-- are still welcome in narration: a typo is a typo wherever it sits, and someone
-- who turned Mouthwash on wants profanity handled in an emote too. It is the
-- accent specifically that does not belong in prose about the character.
function module.Filter(text, ctx)
	local dialect = ctx.dialect
	if not dialect then return text end

	-- An action in asterisks is narration wherever it appears, including inside
	-- a spoken line: "this is for you *pulls out a flower* hope you like it".
	-- Protected from the accent only; see E.ACTION_SPAN.
	local actions = { E.ACTION_SPAN }

	if ctx.channel == "emote" then
		if not E.HasQuotedSpeech(text) then return text end
		return E.MapQuoted(text, function(speech)
			return E.Engine.Apply(dialect, speech, ctx, actions)
		end)
	end

	return E.Engine.Apply(dialect, text, ctx, actions)
end
