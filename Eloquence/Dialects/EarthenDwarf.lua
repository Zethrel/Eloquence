-- Earthen: titan-forged, literal, precise.
--
-- Deliberately NOT the Dwarven dialect, and players noticed this immediately when
-- The War Within shipped: the earthen pointedly do not have the Scottish accent.
-- Dwarves are earthen who succumbed to the Curse of Flesh; the earthen who did
-- not still sound like what the titans built -- measured, literal, unhurried,
-- speaking of purpose and directives and records.
--
-- So the register here is machine-precise rather than regional: contractions are
-- expanded, feelings are described as processes, and nothing is exaggerated.
local ADDON, E = ...

E.RegisterDialect("EarthenDwarf", {
	name = "Earthen",
	desc = "Titan-forged precision. Literal, measured, speaks of purpose. No Scots.",

	words = E.Engine.Extend(E.Engine.EXPAND_CONTRACTIONS, {
		["hello"] = "greetings", ["hi"] = "greetings", ["hey"] = "attention",
		["greetings"] = "greetings", ["goodbye"] = "our purpose continues",
		["bye"] = "our purpose continues", ["farewell"] = "may your purpose hold",
		["thanks"] = "your assistance is noted", ["sorry"] = "an error was made",
		["yes"] = "affirmed", ["yeah"] = "affirmed", ["yep"] = "affirmed",
		["ok"] = "acknowledged", ["okay"] = "acknowledged", ["sure"] = "certain",
		["no"] = "negative", ["nope"] = "negative", ["maybe"] = "uncertain",
		["friend"] = "ally", ["friends"] = "allies", ["guy"] = "one",
		["guys"] = "allies", ["people"] = "beings",
		-- Feelings described from the outside, as processes.
		["feel"] = "register", ["feeling"] = "registering", ["feelings"] = "internal states",
		["happy"] = "functioning as intended", ["sad"] = "registering a deficit",
		["angry"] = "registering conflict", ["afraid"] = "registering risk",
		["scared"] = "registering risk", ["love"] = "hold in high regard",
		["hate"] = "reject", ["like"] = "find acceptable", ["tired"] = "in need of maintenance",
		["hungry"] = "in need of resources", ["sleep"] = "dormancy",
		["dream"] = "an unexplained process",
		["body"] = "this form", ["heart"] = "core", ["stone"] = "stone",
		["flesh"] = "flesh, a curious material", ["skin"] = "outer surface",
		["hurt"] = "damaged", ["hurts"] = "registers damage", ["pain"] = "damage",
		["sick"] = "malfunctioning", ["heal"] = "repair", ["healed"] = "repaired",
		["broken"] = "damaged", ["fix"] = "repair", ["fixed"] = "repaired",
		["die"] = "cease", ["died"] = "ceased", ["dead"] = "ceased",
		["death"] = "cessation", ["kill"] = "terminate", ["killed"] = "terminated",
		["think"] = "calculate", ["thinking"] = "calculating", ["thought"] = "calculation",
		["guess"] = "estimate",
		-- "know" and "remember" are handled as phrases, not words: "do not know"
		-- would otherwise become "do not have recorded".
		["want"] = "require", ["wants"] = "requires", ["need"] = "require",
		["help"] = "assist", ["helped"] = "assisted", ["helping"] = "assisting",
		["work"] = "function", ["works"] = "functions", ["worked"] = "functioned",
		["job"] = "purpose", ["task"] = "directive", ["plan"] = "directive",
		["order"] = "directive", ["orders"] = "directives", ["boss"] = "the directive",
		["god"] = "the Titans", ["gods"] = "the Titans", ["creator"] = "the Titans",
		["magic"] = "an unrecorded force", ["strange"] = "unrecorded",
		["weird"] = "unrecorded", ["crazy"] = "operating outside parameters",
		["stupid"] = "poorly reasoned", ["dumb"] = "poorly reasoned",
		["big"] = "of great mass", ["huge"] = "of considerable mass",
		["small"] = "of little mass", ["fast"] = "at speed", ["slow"] = "at reduced speed",
		["very"] = "highly", ["really"] = "verifiably",
		["hurry"] = "increase pace", ["wait"] = "hold position", ["stop"] = "halt",
		["go"] = "proceed", ["come"] = "approach", ["look"] = "observe",
		["see"] = "observe", ["understand"] = "comprehend",
		["problem"] = "fault", ["problems"] = "faults", ["mistake"] = "error",
		["luck"] = "an unmeasured variable", ["good"] = "acceptable",
		["great"] = "well within tolerance", ["bad"] = "unacceptable",
		["home"] = "Khaz Algar", ["food"] = "resources", ["drink"] = "intake",
	}),

	wordsAt = {
		[3] = {
			["always"] = "in all recorded instances", ["never"] = "in no recorded instance",
			["probably"] = "with high probability", ["definitely"] = "without measurable doubt",
			["soon"] = "within an acceptable interval", ["later"] = "at a subsequent interval",
			["now"] = "at this interval", ["time"] = "the interval",
			["year"] = "cycle", ["years"] = "cycles", ["old"] = "of long service",
			["new"] = "recently instantiated", ["change"] = "deviate",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "I have no record of that", nil, true },
		{ "%f[%a]i do not know%f[%A]", "I have no record of that", nil, true },
		{ "%f[%a]i don't remember%f[%A]", "that record is lost", nil, true },
		{ "%f[%a]i remember%f[%A]", "I have a record of that", nil, true },
		{ "%f[%a]i know%f[%A]", "that is recorded", nil, true },
		{ "%f[%a]i forget%f[%A]", "that record is lost", nil, true },
		{ "%f[%a]i think%f[%A]", "my calculation is", nil, true },
		{ "%f[%a]how are you%f[%A]", "I am functioning" },
		{ "%f[%a]thank you%f[%A]", "your assistance is noted" },
		{ "%f[%a]good luck%f[%A]", "may your variables align" },
		{ "%f[%a]be careful%f[%A]", "minimise risk" },
		{ "%f[%a]what's up%f[%A]", "state your purpose" },
		{ "%f[%a]let's go%f[%A]", "we proceed" },
		{ "%f[%a]hold on%f[%A]", "hold position" },
		{ "%f[%a]i have no idea%f[%A]", "no record exists", nil, true },
	},

	flavor = {
		chance = 0.16,
		prefix = { "Acknowledged.", "Understood.", "Query:", "A record exists.", "Processing." },
		suffix = {
			"as the Titans designed", "this is recorded", "purpose endures",
			"it is so ordered", "within tolerance",
		},
	},
})
