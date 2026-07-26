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
| Dialectician — accent per speaker race | Implemented, 13 dialects |
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

`## Interface: 120005` in `Eloquence.toc` is the only thing that needs changing.
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

| Race | Dialect | Flavour |
| --- | --- | --- |
| Dwarf | Dwarven | Broad Scots. *"Ah'm no' shuir if that wull wirk, laddie."* |
| Troll | Trollish | Jamaican patois with Zandali. *"Tas'dingo, mon!"* |
| Orc | Orcish | Blunt and martial. *"Lok'tar! Zug zug."* |
| Night Elf | Darnassian | Formal, unhurried, some Darnassian. *"Ishnu'alah."* |
| Gnome | Gnomish | Over-precise technical vocabulary meeting folksy cliches. |
| Draenei | Draenei | Ancient and courteous, blessings of the Light. *"Aka'Magosh."* |
| Tauren | Taurahe | Unhurried and reverent. *"Winds be at your back."* |
| Forsaken | Forsaken | A dry hiss that thickens when they are agitated. |
| Blood Elf | Thalassian | Elegant, clipped, condescending. *"Anar'alah."* |
| Goblin | Goblin | Fast-talking and transactional. Everything is a deal. |
| Worgen | Gilnean | Clipped aristocratic English, with a growl when riled. |
| Pandaren | Pandaren | Calm and patient, fond of proverbs. |
| Human | Common | Deliberately the lightest touch. *"King's honor, friend."* |

Allied races inherit their parent culture's speech — Void Elves speak Thalassian,
Earthen speak Dwarven, Zandalari speak Trollish, Kul Tirans speak Common, and so
on. `Eloquence/Core/Race.lua` holds that mapping.

Two dialects do something more than word substitution. The **Forsaken** hiss and
the **Worgen** growl both scale with how agitated the message looks — exclamation
marks and shouting — so a calm Forsaken barely sibilates while an angry one is
hard to miss.

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

Currently 936 assertions covering case preservation, escape-sequence integrity,
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
