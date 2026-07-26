# Eloquence

A revival of the classic World of Warcraft roleplaying chat addon, rebuilt for
modern retail.

Eloquence gives every speaker an accent or dialect based on their race, and
layers a set of linguistic filters over the chat you read — correcting spelling,
expanding acronyms, censoring profanity, and dragging modern turns of phrase into
something that sounds like it belongs in Azeroth.

---

## What this is, and what it is not

The original Eloquence was written for patch 1.12 and has been inactive for many
years. Its source is not obtainable any more — CurseForge no longer serves the
old files in a way that can be retrieved — so **this is a faithful
reimplementation from the original's documented feature set, not a port of the
original code.** The filter names, the dialect line-up and the behaviour they
describe are all taken from the original addon's own documentation:

| Original feature | Status here |
| --- | --- |
| Dialectician — accent per speaker race | Implemented, 26 dialects |
| The Spell Book — spelling, grammar, repetition, ALL-CAPS | Implemented |
| Decompression Engine — expand MMO/Warcraft acronyms | Implemented |
| Mouthwash — profanity to euphemism | Implemented |
| Fantasy Writer — modern phrasing to fantasy phrasing | Implemented |
| Per-filter strength levels | Implemented (light / medium / heavy) |
| Filter your own outgoing chat, or keep it private | Implemented, opt-in |
| Trim long URLs into clickable links | Implemented |
| Abbreviated channel headers | Implemented |
| Class-coloured player names | Implemented |

One thing is meaningfully **better** than the original. Eloquence's known
weakness was race detection: in 1.12 there was no reliable way to learn a
stranger's race from a chat message, so it guessed. Modern retail includes the
speaker's GUID in every chat event, and `GetPlayerInfoByGUID` turns that directly
into a race — so the dialect system is now accurate for essentially anyone who
speaks, not just people in your group.

---

## Installing

1. Copy the `Eloquence` folder into `World of Warcraft/_retail_/Interface/AddOns/`.
2. Restart the game, or `/reload`.

The folder you copy must be the inner `Eloquence` directory — the one containing
`Eloquence.toc` — not the repository root.

### If the addon shows as out of date

`## Interface: 120007` in `Eloquence.toc` is the only thing that needs changing.
Run `/dump select(4, GetBuildInfo())` in game and put that number in the TOC.
Nothing else is version-sensitive.

---

## Using it

`/elo` opens the options panel. `/elo help` lists everything:

```
/elo                      open the options panel
/elo on|off               master switch
/elo status               show what is enabled
/elo test <text>          preview your own dialect
/elo test <race> <text>   preview a specific dialect
/elo <filter> on|off      spellbook, decomp, mouthwash, fantasy, dialect
/elo <filter> 1|2|3       filter strength: light, medium, heavy
/elo race <race> on|off   mute or unmute one race's dialect
/elo races                list every dialect
/elo out on|off           rewrite your outgoing chat
/elo reset                restore defaults
```

`/elo test` is the quickest way to audition a dialect:

```
/elo test Dwarf I'm not sure if that will work, friend.
  I'm not sure if that will work, friend.
  Ah'm no' shuir if that wull wirk, laddie.
```

### Defaults

Enabled out of the box: **The Spell Book**, **Decompression Engine**,
**Dialectician**, and clickable trimmed URLs.

Off by default: **Mouthwash** and **Fantasy Writer** (both change a lot of text
and are a matter of taste), outgoing rewriting, short channel names, and
class-coloured names.

---

## Reading vs. speaking

Eloquence works in two directions, and they are very different in kind.

**Incoming (on by default).** Purely a display filter, built on
`ChatFrame_AddMessageEventFilter` — the sanctioned API for rewriting a chat line
before it is drawn. Nothing is sent to the server, nothing anyone said is
changed, and no protected code is touched, so there is no taint risk. Only you
see the difference.

**Outgoing (off by default).** `/elo out on` wraps `SendChatMessage` so that
other players see your dialect. This genuinely changes what you send, so it is
opt-in, per channel, and the wrapper is only installed once you enable it — a
player who never turns it on carries none of the extra surface. Two things worth
knowing:

- Messages that grow past WoW's 255-byte limit are **split across several
  lines**, not truncated. A dialect can easily lengthen a sentence.
- Wrapping a global function is a very well-precedented addon technique, but it
  is not completely free of taint risk in the way the incoming path is. If you
  ever see "Interface action failed because of an AddOn" while chatting, turn
  this off first.

If you want your own messages in dialect but only for yourself, leave outgoing
off and turn on "Also apply a dialect to my own messages" instead.

---

## Dialects

Every playable race has its own dialect — 26 in all, covering the full modern
roster rather than just the classic thirteen.

| Race | Dialect | Flavour |
| --- | --- | --- |
| Human | Common | Deliberately the lightest touch. *"King's honor, friend."* |
| Dwarf | Dwarven | Broad Scots. *"Ah'm no' shuir if that wull wirk, laddie."* |
| Night Elf | Darnassian | Formal, unhurried, canon Darnassian. *"Ishnu-alah."* |
| Gnome | Gnomish | Over-precise technical vocabulary meeting folksy cliches. |
| Draenei | Draenei | Ancient and courteous, blessings of the Light. *"Aka'Magosh."* |
| Worgen | Gilnean | Clipped aristocratic English, with a growl when riled. |
| Void Elf | Ren'dorei | Elven composure, with Void whispers leaking through. |
| Lightforged Draenei | Lightforged | Draenei courtesy welded onto a crusade. |
| Dark Iron Dwarf | Dark Iron | Dwarven Scots gone sour. Coal, grudges, the Molten Core. |
| Kul Tiran | Kul Tiran | A seafaring West Country burr. *"Fair winds to ye."* |
| Mechagnome | Mechagnome | Gnomish jargon turned inward, describing its own chassis. |
| Orc | Orcish | Blunt and martial. *"Lok'tar! Zug zug."* |
| Forsaken | Forsaken | A dry hiss that thickens when they are agitated. |
| Tauren | Taurahe | Unhurried and reverent. *"Winds be at your back."* |
| Troll (Darkspear) | Trollish | Thick Jamaican patois. *"Tas'dingo, mon!"* |
| Blood Elf | Thalassian | Elegant, clipped, condescending. *"Anar'alah."* |
| Goblin | Goblin | Fast-talking and transactional. Everything is a deal. |
| Nightborne | Shal'dorei | Aloof and exacting. Ten thousand years of Suramar. |
| Highmountain Tauren | Highmountain | Taurahe reverence, aimed at the peaks. |
| Mag'har Orc | Mag'har | Orcish, uncorrupted. The clan and the old ways. |
| Zandalari Troll | Zandali | Formal, proud, imperial. **Not** the Darkspear patois. |
| Vulpera | Vulpera | Warm and quick, forever thinking of the caravan. |
| Pandaren | Pandaren | Calm and patient, fond of proverbs. |
| Dracthyr | Dracthyr | Precise and refined. Flights, wings and Aspects. |
| Earthen | Earthen | Titan-forged precision. Literal, measured. **No Scots.** |
| Harronir | Harronir | Soft and melodic. Roots, dreams, and what is kept. |

### Where the accents come from

The dialects follow how Blizzard actually voices each race, and two of those
details are easy to get wrong:

- **Zandalari are not Darkspear.** Before Battle for Azeroth they reused the
  jungle troll voice set and sounded Jamaican; since BfA they are voiced with
  Xhosa-accented English. **Harronir share that voice work** — a soft, melodic
  delivery on the same South African base.
- **Earthen deliberately lack the dwarven Scots.** Dwarves are earthen who
  succumbed to the Curse of Flesh; those who did not still sound titan-forged.

For Zandali and Harronir the addon **does not respell speech phonetically.** That
accent lives in the vocal delivery — on the page these characters speak formal,
dignified English — so the dialects render their *register* and vocabulary
instead. Respelling a real-world accent as broken English would be both wrong
about how they talk and a caricature. Regional British respelling is kept for
Dwarven, Dark Iron and Kul Tiran, since that is the convention the original addon
established with its Scots.

Only genuine token spelling variants are aliased now — `Earthen` →
`EarthenDwarf`, and `Haranir` → `Harronir`; see `Eloquence/Core/Race.lua`.

A note on that second one: the client reports the Midnight race as **`Harronir`**
with two Rs (race ID 86, confirmed in game with
`/dump select(2, UnitRace("player"))`), while a good deal of community writing
spells it "Haranir". The dialect is registered under the token the client
actually returns, and the other spelling is aliased onto it so `/elo race
haranir` works either way.

Five races are cultural variants rather than separate languages — Dark Iron,
Mag'har, Lightforged, Mechagnome and Highmountain — and are built with
`Engine.Derive` as their parent's dialect plus a layer, so shared vocabulary
lives in one place.

Three dialects do more than substitute words, and all three scale with how
agitated the message looks (exclamation marks and shouting): the **Forsaken**
hiss, the **Worgen** growl, and the **Void Elf** whispers, which surface between
sentences in a dim violet so they read as intrusions rather than speech.

### Darnassian

The Night Elf dialect carries a glossary of canon Darnassian, applied at
strength 3 only — a message peppered with untranslated Darnassian becomes
unreadable fast. `Shaha lor'ma` for "thank you", `Fandu-dath-belore?` for "who
goes there", `an'da` and `min'da` for father and mother, `Xaxas` for chaos or
Deathwing, `Ishnu-alah`, `Bandu thoribas`, `Tor ilisar'thera'nal`, the World
Trees by their meanings, and so on.

Deliberately excluded: proper nouns that are already the English word (weapon
names like *Ellemayne* "Reaver" — nobody types "reaver" meaning the sword), bare
grammatical fragments that cannot be substituted safely mid-sentence (*Aria* "we
face", *Bessae* "from the"), and *Belore*, whose "sun" reading is Thalassian
rather than Darnassian. `Dialects/NightElf.lua` documents that split at the top;
keep it if you extend the glossary.

---

## How it fits together

```
Eloquence/
  Eloquence.toc
  Core/
    Init.lua        namespace, saved variables, module registry
    Util.lua        escape-sequence protection, case matching, RNG, splitting
    Engine.lua      the declarative rule engine every filter is built on
    Race.lua        GUID -> race resolution, allied-race aliasing
    Pipeline.lua    one entry point shared by the incoming and outgoing paths
    Chat.lua        chat event filters and the opt-in outgoing wrapper
    Cleanup.lua     URLs, channel abbreviations, class colours
    Options.lua     options panel
    Commands.lua    /elo
  Dialects/         one file per race
  Modules/          one file per filter
Tests/              headless test suite
```

Filters run in a fixed order — normalise first, then add flavour:

```
Spell Book -> Decompression -> Mouthwash -> Fantasy Writer -> Dialectician
```

### Two design decisions worth knowing about

**Escape sequences are never touched.** A chat line can contain item links,
textures, colour codes, raid target icons and URLs, and mangling any of them
produces broken output. Rather than substituting placeholders into the string
(which the filters could then match and destroy), `Util.lua` slices a message
into alternating protected and plain segments and only ever transforms the plain
ones. Adjacent protected segments are kept together, so a coloured item link —
which is really three spans, `|cff...` + `|Hitem:...|h` + `|r` — never gets split
across two messages.

**Randomness is deterministic.** Dialects make probabilistic choices (whether to
add an interjection, whether to hiss a given S). If those used `math.random` the
same line could read differently every time a chat frame redrew it, and two
players running Eloquence would disagree about what someone said. Instead every
random decision comes from a small generator seeded from the speaker's GUID plus
the message text, so a given message always renders identically.

Eloquence also skips messages in languages your character does not understand.
WoW has already replaced those with gibberish, and there is nothing to translate.

### Writing a dialect

A dialect is a declarative table. The engine handles case preservation, word
boundaries, escape protection and strength gating:

```lua
E.RegisterDialect("Dwarf", {
    name = "Dwarven",
    desc = "Broad Scots.",
    words   = { ["you"] = "ye", ["not"] = "no'" },      -- always
    wordsAt = { [3] = { ["horse"] = "cuddy" } },        -- heavy only
    phrases = { { "%f[%a]going to%f[%A]", "gaun tae" } },
    post    = function(chunk, ctx) return chunk end,    -- accent transforms
    flavor  = { prefix = { "Och," }, suffix = { "laddie" }, chance = 0.18 },
})
```

Phrases run before words, so multi-word idioms beat their parts. `ctx` carries
`rng`, `strength` and `excitement`.

---

## Tests

The text handling — which is nearly all of the interesting behaviour — is tested
headlessly against a stubbed client. No game required:

```
lua Tests/run.lua
```

Currently 1350 assertions covering case preservation, escape-sequence integrity,
determinism, message splitting, each dialect at every strength, each filter,
race resolution and aliasing, the chat filter round trip, outgoing splitting, the
slash commands, and a hostile-input pass that throws malformed escape sequences
and Lua pattern metacharacters at every module.

Several of these exist because the suite caught real bugs. Three worth knowing
about if you extend the addon:

- **Lua patterns cannot quantify a back-reference.** `"(%a)%1%1+"` looks like
  "three or more of the same letter" and silently never matches, which had
  quietly disabled all of the repeat-squashing. `Util.CollapseRuns` does it
  explicitly instead.
- **`v and nil or false` can never evaluate to `nil`.** It had made unmuting a
  race impossible.
- **Phrase patterns are matched case-insensitively**, because chat is full of
  capitalised sentence openings and a lower-case rule would miss all of them.
  `Engine.CaseInsensitive` rewrites the patterns at compile time.

`Tests/wow_stub.lua` stubs only the APIs the addon actually uses. Note that the
addon targets WoW's Lua 5.1; the suite runs under 5.1 or later.

To syntax-check everything:

```
for f in $(find Eloquence -name '*.lua'); do luac -p "$f" || echo "FAIL $f"; done
```

---

## Credits

The original Eloquence was a community roleplaying addon of the Vanilla era; this
project owes its filter design, its dialect line-up and several of its example
lines to that documentation. Modern addons in the same tradition worth knowing
about are **AccentChat**, **Tongues** and **Dialect**.

MIT licensed.
