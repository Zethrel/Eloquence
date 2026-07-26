-- Cultural variants.
--
-- Four races are the same language spoken by a different people rather than a
-- different language: Dark Iron are dwarves who served Ragnaros, Mag'har are orcs
-- who never drank Mannoroth's blood, Lightforged are draenei remade into a
-- crusade, Mechagnomes are gnomes with rather more machine in them, Highmountain
-- are tauren of the peaks. Each is its parent's dialect with a layer on top,
-- built through Engine.Derive so the shared vocabulary stays in one place.
--
-- This file loads after every base dialect, because it reads them.
local ADDON, E = ...

local Derive = E.Engine.Derive

--------------------------------------------------------------------------------
-- Dark Iron dwarves: the same Scots, soured by three hundred years under a
-- Firelord. Coal, grudges and the Molten Core.
--------------------------------------------------------------------------------

E.RegisterDialect("DarkIronDwarf", Derive(E.DIALECTS["Dwarf"], {
	name = "Dark Iron",
	desc = "Dwarven Scots gone sour. Coal, grudges and the Molten Core.",

	words = {
		["hello"] = "whit d'ye want", ["hi"] = "whit", ["hey"] = "oi",
		["greetings"] = "aye, whit is it", ["sorry"] = "Ah'll no' apologise",
		["fire"] = "the Flame", ["flame"] = "the Flame", ["flames"] = "the Flame",
		["hot"] = "bilin'", ["burn"] = "burn", ["burning"] = "burnin'",
		["god"] = "the Flame", ["hell"] = "the Molten Core",
		["forge"] = "the forge", ["coal"] = "coal", ["iron"] = "iron",
		["dark"] = "black", ["deep"] = "deep as the Core",
		["home"] = "Shadowforge City", ["city"] = "Shadowforge",
		["king"] = "the Emperor", ["queen"] = "the Empress",
		["ale"] = "firewater", ["beer"] = "firewater", ["drink"] = "firewater",
		["angry"] = "bilin'", ["hate"] = "hae nae love for",
		["enemy"] = "foe", ["enemies"] = "foes",
		["revenge"] = "a reckonin'", ["grudge"] = "a reckonin'",
		["slave"] = "never again", ["free"] = "free, an' hard won",
		["magic"] = "the Flame's work", ["happy"] = "less scunnered than usual",
		["good"] = "no' bad", ["nice"] = "tolerable",
	},

	phrases = {
		{ "%f[%a]for the alliance%f[%A]", "fer the Alliance, an' fer the Flame" },
		{ "%f[%a]good luck%f[%A]", "dinnae get yersel burnt" },
	},

	flavor = {
		chance = 0.18,
		prefix = { "Bah.", "Aye, weel.", "By the Flame,", "Hmph.", "Och, whit noo." },
		suffix = { "an' that's flat", "laddie", "by the Flame", "mind the Core", "so it is" },
	},
}))

--------------------------------------------------------------------------------
-- Mag'har orcs: uncorrupted, and quietly proud of it. Clan and the old ways.
--------------------------------------------------------------------------------

E.RegisterDialect("MagharOrc", Derive(E.DIALECTS["Orc"], {
	name = "Mag'har",
	desc = "Orcish, uncorrupted. Speaks of the clan and the old ways.",

	words = {
		["blood"] = "blood -- never again the blood",
		["fel"] = "that green poison", ["demon"] = "the Legion's filth",
		["demons"] = "the Legion's filth", ["corruption"] = "the old shame",
		["clan"] = "the clan", ["clans"] = "the clans", ["family"] = "the clan",
		["group"] = "the clan", ["tradition"] = "the old ways",
		["ancestor"] = "ancestor", ["ancestors"] = "those who came before",
		["home"] = "Draenor, as it was", ["shaman"] = "spirit-speaker",
		["spirit"] = "the spirits", ["spirits"] = "the spirits",
		["young"] = "untested", ["old"] = "of the old blood",
		["orc"] = "Mag'har", ["orcs"] = "the Mag'har",
	},

	phrases = {
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and for the old ways" },
		{ "%f[%a]good luck%f[%A]", "may the ancestors watch you" },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Lok'tar.", "Hrmph.", "Listen, then.", "The ancestors saw this." },
		suffix = {
			"the old ways endure", "as our ancestors did", "uncorrupted",
			"nothing more", "this is the way",
		},
	},
}))

--------------------------------------------------------------------------------
-- Lightforged draenei: draenei courtesy welded to a crusade.
--------------------------------------------------------------------------------

E.RegisterDialect("LightforgedDraenei", Derive(E.DIALECTS["Draenei"], {
	name = "Lightforged",
	desc = "Draenei courtesy welded onto a crusade. The Light is not a comfort but a weapon.",

	words = {
		["hello"] = "the Light guide you", ["hi"] = "the Light guide you",
		["enemy"] = "the Legion's remnant", ["enemies"] = "the Legion's remnant",
		["fight"] = "wage the crusade", ["fighting"] = "waging the crusade",
		["war"] = "the Crusade", ["battle"] = "the Crusade",
		["kill"] = "purge", ["killed"] = "purged", ["killing"] = "purging",
		["burn"] = "cleanse", ["clean"] = "cleansed",
		["doubt"] = "a thing I have burned away", ["fear"] = "a thing the Light does not permit",
		["afraid"] = "unshaken", ["scared"] = "unshaken",
		["tired"] = "ever ready", ["rest"] = "there is no rest",
		["ready"] = "ever ready", ["hope"] = "certainty",
		["home"] = "the Vindicaar", ["ship"] = "the Vindicaar",
		["god"] = "the Light", ["gods"] = "the Light", ["luck"] = "the Light's will",
	},

	phrases = {
		{ "%f[%a]for the alliance%f[%A]", "for the Alliance, and for the Army of the Light" },
		{ "%f[%a]good luck%f[%A]", "let the Light burn away all doubt" },
		{ "%f[%a]be careful%f[%A]", "be resolute" },
	},

	flavor = {
		chance = 0.18,
		prefix = { "The Light demands it.", "By the Light's fire,", "Stand ready.", "Hear me." },
		suffix = {
			"the Light burns", "no corner shall be spared", "for the Army of the Light",
			"there can be no compromise", "so it must be",
		},
	},
}))

--------------------------------------------------------------------------------
-- Mechagnomes: gnomish jargon, now describing itself.
--------------------------------------------------------------------------------

E.RegisterDialect("Mechagnome", Derive(E.DIALECTS["Gnome"], {
	name = "Mechagnome",
	desc = "Gnomish jargon turned inward. Refers to its own body in specifications.",

	words = {
		["body"] = "chassis", ["arm"] = "manipulator", ["arms"] = "manipulators",
		["hand"] = "manipulator", ["hands"] = "manipulators",
		["leg"] = "strut", ["legs"] = "struts", ["foot"] = "footplate",
		["heart"] = "power core", ["head"] = "processing unit",
		["eye"] = "optic", ["eyes"] = "optics", ["brain"] = "processing unit",
		["skin"] = "plating", ["blood"] = "coolant", ["bone"] = "framework",
		["tired"] = "low on charge", ["sleep"] = "a recharge cycle",
		["hungry"] = "low on fuel", ["sick"] = "malfunctioning",
		["hurt"] = "damaged", ["pain"] = "a damage report",
		["feel"] = "register", ["feelings"] = "registered states",
		["flesh"] = "the meat components", ["mortal"] = "the wholly organic",
		["home"] = "Mechagon", ["city"] = "Mechagon City",
		["king"] = "the Mechagon King", ["upgrade"] = "an upgrade",
	},

	phrases = {
		{ "%f[%a]how are you%f[%A]", "all systems nominal" },
		{ "%f[%a]are you ok%f[%A]", "diagnostics are clear" },
		{ "%f[%a]are you okay%f[%A]", "diagnostics are clear" },
	},

	flavor = {
		chance = 0.2,
		prefix = { "Diagnostics complete.", "Right then,", "By my calculations,", "Recalibrating." },
		suffix = {
			"per specification", "within tolerance", "my chassis concurs",
			"as designed", "give or take a decimal",
		},
	},
}))

--------------------------------------------------------------------------------
-- Highmountain tauren: the same reverence, aimed at the peaks.
--------------------------------------------------------------------------------

E.RegisterDialect("HighmountainTauren", Derive(E.DIALECTS["Tauren"], {
	name = "Highmountain",
	desc = "Tauren reverence, aimed at the peaks. Huln's people.",

	words = {
		["home"] = "Highmountain", ["mountain"] = "Highmountain",
		["mountains"] = "the peaks", ["hill"] = "the slopes",
		["sky"] = "the high air", ["stone"] = "the ancient stone",
		["cave"] = "the deep halls", ["eagle"] = "the eagles",
		["hunt"] = "the hunt", ["hunter"] = "hunter of the peaks",
		["horn"] = "our horns", ["horns"] = "our horns",
		["cold"] = "the honest cold", ["snow"] = "the snows",
		["climb"] = "climb", ["high"] = "high as Highmountain",
		["ancestor"] = "Huln's kin", ["hero"] = "one worthy of Huln",
	},

	phrases = {
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and for Highmountain" },
		{ "%f[%a]good luck%f[%A]", "may the peaks shelter you" },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Hmm.", "Be at peace.", "Listen, young one,", "The peaks remember." },
		suffix = {
			"as the mountain endures", "by Huln's example", "young one",
			"the peaks have taught us this", "in its own season",
		},
	},
}))
