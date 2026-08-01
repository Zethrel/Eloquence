-- Eloquence: class flavour.
--
-- Race decides how a character sounds. Class decides what they would never say.
--
-- Reported by a player of a Human Death Knight, and obviously right once stated:
-- the Human dialect offers "By the Light," as an interjection, which is fine in
-- the mouth of a farmer from Elwynn and absurd in the mouth of a risen knight of
-- the Ebon Blade. The race was doing its job; the problem is that racial flavour
-- assumes a piety some classes flatly contradict.
--
-- So a class layer sits on top of the race dialect and can do three things:
--
--   flavorExclude   drop racial flavour lines matching these patterns
--   flavor          add its own prefixes and suffixes
--   words/phrases   override specific vocabulary, via the same Engine.Derive
--                   used for the cultural variants in Dialects/Variants.lua
--
-- Excluding rather than replacing matters. A Dwarf Death Knight should stop
-- invoking the Light but keep speaking broad Scots, and a class that threw away
-- the whole racial flavour table would flatten every Death Knight into the same
-- voice regardless of who they were before they died.
--
-- Most classes need no layer at all. A Warrior or a Rogue says nothing a race
-- would not, so only the classes with a genuine clash or a genuine idiom of
-- their own are defined in Classes\*.lua.
local ADDON, E = ...

local Class = {}
E.Class = Class

E.CLASSES = {}  -- upper-case class token -> overrides

-- `token` is the second return of GetPlayerInfoByGUID and UnitClass: an
-- unlocalised, upper-case identifier such as "DEATHKNIGHT".
function E.RegisterClass(token, overrides)
	overrides.token = token
	E.CLASSES[token] = overrides
	return overrides
end

-- Merged rule sets are cached per dialect and class. Engine.Derive builds a
-- whole new rule set, which is far too much work to repeat for every chat line.
local cache = setmetatable({}, { __mode = "k" })

local function Excluded(line, patterns)
	for i = 1, #patterns do
		if line:find(patterns[i]) then return true end
	end
	return false
end

-- Keep the racial voice, minus anything the class would not say, plus whatever
-- the class adds.
local function MergeFlavor(parent, overrides)
	local classFlavor = overrides.flavor
	local exclude = overrides.flavorExclude

	if not classFlavor and not exclude then return parent end
	if not parent then return classFlavor end

	local merged = {
		chance = (classFlavor and classFlavor.chance) or parent.chance,
		prefix = {},
		suffix = {},
	}

	for _, field in ipairs({ "prefix", "suffix" }) do
		for _, line in ipairs(parent[field] or {}) do
			if not (exclude and Excluded(line, exclude)) then
				merged[field][#merged[field] + 1] = line
			end
		end
		for _, line in ipairs((classFlavor and classFlavor[field]) or {}) do
			merged[field][#merged[field] + 1] = line
		end
	end

	return merged
end

-- Return the rule set for `dialect` as spoken by `token`, or `dialect` itself
-- when the class has no layer or the setting is off.
function Class.Apply(dialect, token)
	if not dialect or not token then return dialect end
	if E.db and E.db.dialect.classFlavor == false then return dialect end

	local overrides = E.CLASSES[token]
	if not overrides then return dialect end

	local byClass = cache[dialect]
	if not byClass then
		byClass = {}
		cache[dialect] = byClass
	end
	local merged = byClass[token]
	if merged then return merged end

	merged = E.Engine.Derive(dialect, overrides)
	merged.name = dialect.name
	merged.desc = dialect.desc
	merged.flavor = MergeFlavor(dialect.flavor, overrides)
	byClass[token] = merged
	return merged
end

-- The player's own class token, for the outgoing path.
function Class.Player()
	if E.db and E.db.dialect.selfClass then
		return E.db.dialect.selfClass
	end
	local _, token = UnitClass("player")
	return token
end
