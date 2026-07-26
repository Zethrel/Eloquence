-- Vulpera: warm, quick, and always thinking about the caravan.
--
-- Not goblins. Goblins are cynics who price everything; vulpera are survivors who
-- value everyone, having spent generations being hunted across Vol'dun. Their
-- voice work is notably warmer and less gimmicky than the goblin or gnome sets.
-- The doubled words ("yes yes", "come, come") are a real tic of their in-game
-- speech and do most of the characterisation here.
local ADDON, E = ...

E.RegisterDialect("Vulpera", {
	name = "Vulpera",
	desc = "Warm and quick, forever thinking of the caravan. Survivor's optimism.",

	words = {
		["hello"] = "ah, a friend", ["hi"] = "hello there", ["hey"] = "psst, friend",
		["greetings"] = "well met, friend", ["goodbye"] = "safe travels",
		["bye"] = "safe travels", ["farewell"] = "may your road be soft",
		["thanks"] = "you are kind", ["please"] = "please, friend",
		["sorry"] = "forgive me, forgive me",
		["yes"] = "yes yes", ["yeah"] = "yes yes", ["yep"] = "yes yes",
		["ok"] = "good, good", ["okay"] = "good, good", ["sure"] = "certain",
		["no"] = "no no", ["nope"] = "no no", ["maybe"] = "who can say",
		["friend"] = "friend", ["friends"] = "the caravan", ["family"] = "the caravan",
		["group"] = "the caravan", ["team"] = "the caravan", ["people"] = "the pack",
		["home"] = "the caravan", ["guy"] = "friend", ["guys"] = "friends",
		["stranger"] = "one we do not know yet",
		["enemy"] = "one who hunts us", ["enemies"] = "those who hunt us",
		["danger"] = "trouble", ["dangerous"] = "trouble, much trouble",
		["safe"] = "safe, for now", ["run"] = "run, always run",
		["hide"] = "hide, quickly", ["escaped"] = "slipped away",
		["small"] = "small, yes, but clever", ["big"] = "big and slow",
		["strong"] = "strong, but we are quicker", ["weak"] = "soft",
		["clever"] = "clever", ["smart"] = "clever", ["stupid"] = "not clever",
		["food"] = "food, always food", ["hungry"] = "hungry, always hungry",
		["water"] = "water, precious water", ["thirsty"] = "parched",
		["desert"] = "the sands", ["sand"] = "the sands", ["sun"] = "the hard sun",
		["night"] = "the cold night", ["fire"] = "the fire", ["camp"] = "the camp",
		["tent"] = "the tent", ["wagon"] = "the wagon", ["road"] = "the road",
		["money"] = "coin", ["gold"] = "coin", ["trade"] = "trade",
		["buy"] = "trade for", ["sell"] = "trade away", ["cheap"] = "a kind price",
		["help"] = "help, of course", ["helped"] = "helped, gladly",
		["die"] = "be lost", ["died"] = "was lost", ["dead"] = "lost",
		["death"] = "the long sand", ["kill"] = "end", ["fight"] = "fight, if we must",
		["scared"] = "afraid, yes", ["afraid"] = "afraid, yes", ["brave"] = "brave enough",
		["tired"] = "tired, but we go on", ["hurt"] = "hurt, a little",
		["good"] = "good, very good", ["great"] = "wonderful", ["nice"] = "kind",
		["bad"] = "bad, very bad", ["awful"] = "terrible, terrible",
		["think"] = "think", ["want"] = "want", ["need"] = "need badly",
		["hurry"] = "quickly, quickly", ["wait"] = "wait, wait",
		["look"] = "look, look", ["listen"] = "listen, friend",
		["problem"] = "trouble", ["luck"] = "the sands' kindness",
	},

	wordsAt = {
		[3] = {
			["remember"] = "remember, always remember",
			["forget"] = "never forget", ["story"] = "the telling",
			["past"] = "the old days, hard days", ["future"] = "the road ahead",
			["hope"] = "hope, still", ["alone"] = "alone, and that is worst",
			["together"] = "together, as it should be",
			["slave"] = "never again", ["free"] = "free, at last",
		},
	},

	phrases = {
		{ "%f[%a]i don't know%f[%A]", "who can say, friend", nil, true },
		{ "%f[%a]i think%f[%A]", "I think, yes" },
		{ "%f[%a]thank you%f[%A]", "you are kind, friend" },
		{ "%f[%a]good luck%f[%A]", "may the sands be kind to you" },
		{ "%f[%a]be careful%f[%A]", "watch the dunes, friend" },
		{ "%f[%a]no problem%f[%A]", "it is nothing, friend" },
		{ "%f[%a]what's up%f[%A]", "what is it, friend" },
		{ "%f[%a]let's go%f[%A]", "come, the caravan moves" },
		{ "%f[%a]trust me%f[%A]", "I would not lie to a friend" },
		{ "%f[%a]for the horde%f[%A]", "for the Horde, and for the caravan" },
	},

	flavor = {
		chance = 0.2,
		prefix = { "Ah!", "Listen, friend,", "Yes, yes,", "Hmm.", "Come, come," },
		suffix = {
			"friend", "yes?", "so it is", "the caravan endures",
			"this we have learned", "no?",
		},
	},
})
