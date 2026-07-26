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

function module.Filter(text, ctx)
	local dialect = ctx.dialect
	if not dialect then return text end
	return E.Engine.Apply(dialect, text, ctx)
end
