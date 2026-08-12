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
| Class-coloured player names | Removed — the client does this natively |

One thing is meaningfully **better** than the original. Eloquence's known
weakness was race detection: in 1.12 there was no reliable way to learn a
stranger's race from a chat message, so it guessed. Modern retail includes the
speaker's GUID in every chat event, and `GetPlayerInfoByGUID` turns that directly
into a race — so the dialect system is now accurate for essentially anyone who
speaks, not just people in your group.

---

## Installing

**From CurseForge**, which is the easiest route and what most people will want:
[Eloquence on CurseForge](https://www.curseforge.com/wow/addons/eloquence-revived).
Install it through the CurseForge app or any addon manager that can reach it, and
updates take care of themselves.

**By hand**, from a
[GitHub release](https://github.com/Zethrel/Eloquence/releases):

1. Copy the `Eloquence` folder into `World of Warcraft/_retail_/Interface/AddOns/`.
2. Restart the game, or `/reload`.

The folder you copy must be the inner `Eloquence` directory — the one containing
`Eloquence.toc` — not the repository root.

### If the addon shows as out of date

`## Interface: 120100` in `Eloquence.toc` is the only thing that needs changing.
Run `/dump select(4, GetBuildInfo())` in game and put that number in the TOC.
Nothing else is version-sensitive.

A weekly workflow watches for this and opens an issue when a patch moves past the
TOC — see [Keeping up with patches](#keeping-up-with-patches).

---

## Using it

`/elo` opens the options panel. `/elo help` lists everything:

```
/elo                      open the options panel
/elo on|off               master switch
/elo status               show what is enabled
/elo doctor               diagnose why nothing is happening
/elo spy                  report what the filter decides for each message
/elo config               open the options panel (same as bare /elo)
/elo test <text>          preview your own dialect
/elo test <race> <text>   preview a specific dialect
/elo <filter> on|off      spellbook, decomp, mouthwash, fantasy, dialect, lisp, muffle
/elo <filter> 1|2|3       filter strength: light, medium, heavy
/elo race <race> on|off   mute or unmute one race's dialect
/elo races                list every dialect
/elo class on|off         class flavour (a death knight will not invoke the Light)
/elo lisp on|off          your own speech is lisped
/elo muffle on|off        your own speech is muffled, as through a helm
/elo preset [name]        apply a bundle of settings, or list them
/elo speak <race>         speak as another race ("list" or "reset")
/elo speakclass <class>   speak as another class layer
/elo out on|me|off        show your chat in dialect to everyone / only you / nobody
/elo reset                restore defaults
```

`/elo test` is the quickest way to audition a dialect:

```
/elo test Dwarf I'm not sure if that will work, friend.
  I'm not sure if that will work, friend.
  Ah'm no' shuir if that wull wirk, laddie.
```

### If nothing seems to be happening

```
/elo doctor
```

It reports whether every module started, whether the chat filters and the
outgoing hook actually attached, whether your race resolves to a dialect, and
then runs a sample line through the pipeline so you can see the before and after.
Anything marked `FAIL` is the answer. It also reports how much incoming chat has
reached the filter and what it decided about the last message, which separates
"the filter never ran" from "the filter ran and changed nothing".

For a running commentary, `/elo spy` prints the sender, resolved race, dialect,
language and verdict for every incoming message until you turn it off.

Worth knowing: **retail hides Lua errors by default**, so a broken command looks
identical to one that did nothing. `/console scriptErrors 1` turns them on, which
is worth doing before reporting a problem.

One trap worth recording for anyone else writing an addon panel: nearly every
Dragonflight-era guide tells you to do `category.ID = addonName` after
`Settings.RegisterCanvasLayoutCategory`. **That is wrong on 12.0.**
`Settings.OpenToCategory` now forwards the ID to
`C_SettingsUtil.OpenSettingsPanel`, which requires an integer, so passing the
addon name throws `bad argument #1 to 'OpenSettingsPanel' (outside of expected
range …)` and the panel silently never opens. Leave the numeric ID the Settings
system assigns alone.

### Class flavour

Race decides how a character sounds. Class decides what they would never say.

The Human dialect offers *"By the Light,"* as an interjection, which is right for a
farmer from Elwynn and absurd for a knight of the Ebon Blade. So a class layer
sits on top of the race dialect, defined in `Classes/*.lua` and applied by
`Core/Class.lua`.

It **removes** racial flavour rather than replacing it. A layer that swapped out
the whole table would flatten every death knight into one voice regardless of who
they were before they died; instead the clashing lines are dropped by pattern and
the class adds its own. A Dwarf death knight stops invoking the Light and keeps
speaking broad Scots.

Nine layers. **Death Knight**, **Warlock** and **Demon Hunter** all have reason
to avoid the Light; **Paladin** leans into it; **Priest**, **Shaman**, **Druid**,
**Monk** and **Mage** each have an idiom of their own — vows and the care of
souls, asking the elements rather than commanding them, seasons and the balance,
breath and form, and precision with a licence.

**Priest** is the awkward one and shapes how it is written. The client reports
the class token, not the specialisation, so `PRIEST` covers a holy priest of the
Light and a shadow priest who hears the Void with no way to tell them apart. The
layer is therefore built on the vocation — faith, vows, tending suffering — and
names neither the Light nor the Void.

Four classes still have none. **Warrior** and **Rogue** say nothing a race would
not, which is the criterion. **Hunter** comes close, but its idiom overlaps
almost entirely with the Troll, Tauren and Night Elf dialects that already carry
it. **Evoker** is Dracthyr-only, and the Dracthyr dialect already speaks of
Aspects, flights and scales — a layer would repeat it.

**Adjust speech for the speaker's class** in the options disables the whole
layer, as does `/elo class off`.

The class token comes back from `GetPlayerInfoByGUID` alongside the race, so
incoming costs no extra call.

### Speaking as somebody else

A character's accent is not their biology. A Night Elf raised in Ironforge sounds
like Ironforge; a Forsaken who was Gilnean in life kept the vowels. `selfRace`
and `selfClass` override the dialect and class layer used for **your own** speech
and nobody else's.

```
/elo speak dwarf          your own lines come out in broad Scots
/elo speak Dark Iron      display names work too, punctuation and all
/elo speak list           every option
/elo speak reset          back to your own
/elo speakclass warlock   the class layer, separately
```

Both settings existed and worked from the first release, and neither could be
reached without editing saved variables — the third to ship that way, after the
class layer and `applyToSelf`. The engine half needed nothing; what was missing
was a command and a control.

Three times is a pattern, so a test now measures it. It drives every control on
the panel, applies every preset, and diffs the saved variables to see what
actually changed — a control wired to nothing counts as unreachable however
convincing it looks. Anything left over must appear in a short exemption list
with a reason, and that list is itself checked against the current settings so a
stale entry cannot hide a deleted one.

Running it found two more. `cleanup.classColors` was read by nothing at all —
Eloquence used to colour sender names, got it wrong, and the setting outlived the
feature. `incoming.enabled` was a second master switch, checked beside
`db.enabled` on the same line, defaulted true, set true by every preset and set
false by nothing. Both are gone.

One real bug came with it. The override was honoured on the outgoing path only,
so in **Only me** mode — which reads your own copy back through the *incoming*
filter — your race was resolved from your GUID and the choice was silently
ignored. `Race.Resolve` now answers `Race.Player()` for your own GUID, so both
paths agree.

### Personal speech effects

Two filters describe your own character's mouth rather than anyone else's:
**Lisp** and **Muffle**, the latter for a closed helm, a diving suit, or anything
else that gets between you and the air.

Both are **self only**, and that is enforced by the pipeline rather than left to a
setting. Lisping a stranger's chat would be putting words in their mouth, and you
cannot see what anyone else is wearing, so guessing would garble their words on a
hunch. `module.selfOnly` stops `Pipeline.Run` applying them to incoming text even
if the `incoming` flag is set explicitly.

They run **after** the Dialectician, because they belong to the mouth rather than
the language: whatever words come out, and in whatever accent, these are what
sits over them on the way.

Both **need outgoing rewriting on** (`/elo out on`) to reach anyone, since they
change what you send. Turning one on without it prints a warning, and `/elo
doctor` reports it as a failure — an effect that silently does nothing is how
people conclude an addon is broken.

Muffling keeps the shape and length of each word. Collapsing everything to *mmmph*
would be more realistic and impossible to roleplay against; this way the rhythm of
the sentence survives and a patient listener can still follow.

### Presets

Rather than argue about defaults, `/elo preset` bundles the sensible
combinations — also as buttons at the top of the options panel:

| Preset | What it does |
| --- | --- |
| `rp` | Dialects on the in-character channels only. Coordination chat left alone. This is the default shape. |
| `immersive` | As `rp`, but heavier, and NPCs get dialects too. |
| `clean` | No dialects. Just tidier chat everywhere: spelling, acronyms, profanity. |
| `off` | Every filter disabled, addon still loaded. |

A preset never turns **outgoing sending** on and never clears **muted races** —
the first changes what other people receive, and the second you set deliberately.

### Defaults

Enabled out of the box: **The Spell Book**, **Decompression Engine**,
**Dialectician**, and clickable trimmed URLs.

**Only the in-character channels are filtered** — say, yell and emote, incoming
and outgoing alike. Party, raid, instance, guild, officer and public channels are
coordination by convention, and dialecting *"interrupt now, bloodlust on pull"*
makes the useful chat harder to read rather than more immersive.

Say, yell, emotes, guild, NPCs and whispers each get their own checkbox. Party,
raid, instance, officer and public channels share one, because five boxes to
express "the coordination channels are off" was a wall of boxes making a single
point. They are kept rather than dropped because the settings are not only about
dialects: the **Clean chat** preset switches them on so spelling and acronym
expansion reach group chat, which is where *"lfm 2dps hc +10"* needs it most.

Whispers are off on both sides, which surprises people until you look at how
in-character whispering is actually done: in `/say`, opened with a `[low]` tag,
so that nearby characters get the chance to overhear. That convention leaves the
whisper channel itself carrying out-of-character traffic, the same as party and
guild.

Off by default: **Mouthwash** and **Fantasy Writer** (both change a lot of text
and are a matter of taste), outgoing rewriting, and short channel names.

**The Spell Book does not touch other people's chat unless you opt in**
(`/elo spellbook incoming on`). It still fixes your own typos on the way out.
See below for why.

Class-coloured names are **not** an Eloquence feature. The game does it natively
(Options → Social → "Chat Class Colors"). Eloquence tried to do it by colouring
the sender argument, which corrupted the player hyperlink, because the chat
system builds the link *around* that argument rather than treating it as display
text. It has been removed rather than reimplemented.

---

## Reading vs. speaking

Eloquence works in two directions, and they are very different in kind.

**Incoming (on by default).** Purely a display filter, built on
`ChatFrame_AddMessageEventFilter` — the sanctioned API for rewriting a chat line
before it is drawn. Nothing is sent to the server, nothing anyone said is
changed, and no protected code is touched, so there is no taint risk. Only you
see the difference.

**Chat bubbles are a second, separate render path.** The bubble above someone's
head is drawn by the client straight from the chat event and never passes through
a chat filter, so a correctly dialected chat frame will sit above an untouched
bubble. There is no hook for bubble text, so the only approach available is to
remember each rewrite, wait for the client to create the bubble, then find the one
whose text still matches the original and replace it — see `Core/Bubbles.lua`.
Consequences: it only applies to say and yell (nothing else makes a bubble),
bubbles the client marks forbidden are skipped, and matching is by text, so two
people saying the same thing both get the same correct replacement.

**Outgoing (off by default).** `/elo out on` makes other players see your
dialect. This genuinely changes what you send, so it is opt-in, per channel, and
nothing is hooked until you enable it.

**Show my chat in dialect to** is one three-way control — *Off*, *Only me*,
*Everyone* — rather than the two checkboxes it used to be. Those were
`outgoing.enabled` and `dialect.applyToSelf`, and they looked like duplicates
because they nearly were: `Chat.ShouldFilterSelf` refuses to dialect your own
incoming copy while outgoing rewriting is on, since that copy was already
rewritten on the way out. Four tick combinations, three behaviours, and a fourth
that silently ignored a box the player had ticked. Both settings survive
unchanged in the saved variables; `E.GetSelfMode` and `E.SetSelfMode` in
`Core/Init.lua` map between them and the three states, and a test asserts the
mapping round-trips.

Patch 12.0.0 rearchitected the chat send path. Overriding the global
`SendChatMessage` — the technique addons used for twenty years — **no longer sees
anything typed into the chat box**, and `ChatEdit_SendText` is now only a
deprecated alias behind a CVar. Eloquence uses the hook point Blizzard added for
this instead:

```lua
EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", ...)
```

It fires after the edit box parses the text but before the text is read for
sending, so rewriting the box changes what goes out. The old `SendChatMessage`
wrapper is kept as a fallback for macros, other addons, and pre-12.0 clients.
`/elo doctor` reports which path is actually carrying your messages.

Three consequences worth knowing:

- **Nothing is rewritten during combat lockdown.** Rewriting the edit box there
  taints the protected send that follows, and the client blocks the message
  outright. A dialect is not worth a swallowed message.
- **An over-long result is left alone.** This path sends exactly one message and
  cannot split, so rather than let a line be truncated, it goes out untransformed.
- Typed chat is handled entirely by the edit box path, including when that path
  deliberately declines — otherwise the fallback would transform the very
  messages it just decided to leave alone.

If you want your own messages in dialect but only for yourself, set **Show my
chat in dialect to** to *Only me* (`/elo out me`). Nothing you send changes.

---

## Not mangling what other people wrote

On a roleplaying realm, how somebody spells things is a choice. A character
rolling their Rs as *Zethrrel*, or another mangling the same name as *Zettle*,
has written that deliberately — and a filter that "corrects" it is destroying
authored voice, not tidying a typo. Four rules keep that intact:

**Names are protected.** A capitalised word that does not start a sentence is
treated as a proper noun and passed through untouched by *every* filter, not just
the dialects. `Zethrrel`, `Zettle` and `Zethrrrrel` all survive verbatim.

The rule deliberately excludes ALL-CAPS words, because `ZETHRREL` is
indistinguishable from a shouted ordinary word, and protecting every word in a
shouted message would make de-shouting impossible. `I` and its contractions are
also exempt, or the Dwarven `i` → `Ah` would only ever fire at the start of a
sentence.

**A capitalised pair at the start of a sentence is a name too.** Leading a
sentence, capitalisation carries no information, so the rule above stands down —
which meant any mapped word that is also a title or a name was eaten precisely
when it led. `Lady Jaina is here` became `Lassie Jaina is here`, `Master Aelric`
became `Shan'do Aelric`, and anyone actually named *Hope* or *Storm* was
rewritten whenever their name began a line. Mid-sentence they were all fine,
which is why it went unnoticed.

The signal is the word *after* it. `Lady Jaina` is capitalised twice and the
second capital does mean something, because it is mid-sentence. A capitalised
word standing in front of a protected one is a title or a first name, so it is
protected as well. A sentence ending in between breaks the pair — `We go. Hope
is all we have` still translates *hope*.

The cost is that a sentence opening with a capitalised pair nobody meant as a
name — `The Horde is coming` — keeps its first word, so a Troll says *The Horde*
rather than *De Horde*. That is the right way round to be wrong: leaving a word
alone is recoverable, eating somebody's name is not.

**Deliberate elision is respected.** A word with an apostrophe at either end —
`no'`, `tha'`, `'tis` — is left exactly as written. This used to produce
`no'` → `nae'`: the letters were substituted and the apostrophe glued back on,
which is nonsense and exactly the kind of authored voice that must survive.
Internal apostrophes are unaffected, so `don't` → `dinnae` still works.

The upshot is that text somebody has already written in accent passes through
untouched rather than being re-accented on top:

```
Ah'm no' shuir aboot tha', laddie.   ->   Ah'm no' shuir aboot tha', laddie.
```

**Roleplaying conventions are not speech.** Two of them get carried inside
in-character channels and must never be dialected:

```
(brb, the dog needs out)       ->   (brb, the dog needs out)
(( brb, the dog needs out ))   ->   (( brb, the dog needs out ))
[low] I don't know, friend.    ->   [low] Ah dinnae ken, laddie.
[to the crowd] Hello           ->   [to the crowd] Hail
```

Parentheses mark an out-of-character aside. The player has explicitly stepped
outside their character to say it, so rendering it as *"(brb, the dog needs oot)"*
is precisely wrong.

**Single and double both count.** Double is the older convention, but Total RP 3 —
which most of the roleplaying population runs — treats a single pair as out of
character, so a single pair is what people actually type. The cost is that an
in-character parenthetical is not dialected either, and that is the right way
round to fail: protecting too much passes the player's own words through
untouched, while protecting too little rewrites something they deliberately
stepped out of character to say. Live chat barely uses prose parentheticals in any
case — an opening bracket in `/say` is nearly always meta commentary.

Square brackets tag the register or language of the line: `[low]` for quiet
speech that passers-by may overhear, `[Thalassian]` for the language being
spoken, `[to the crowd]` for a stage direction. The tag is metadata about the
line rather than part of it, so it passes through while the speech after it is
still dialected.

**The Spell Book is opt-in for incoming.** It is the only filter that *removes*
character rather than adding it — squashing `Hmmmm`, de-shouting, correcting
spelling. Useful on your own outgoing text, hostile on someone else's. It
defaults to outgoing only; `/elo spellbook incoming on` if you want it applied to
what you read.

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
| Draenei | Draenei | Ancient and courteous, blessings of the Light. *"The Light be with you."* |
| Worgen | Gilnean | Clipped aristocratic English, with a growl when riled. |
| Void Elf | Ren'dorei | Restrained elven formality, circling silence and the dark. |
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

Two dialects do more than substitute words, and both scale with how agitated
the message looks (exclamation marks and shouting): the **Forsaken** hiss and
the **Worgen** stretched consonants. Both respell what the speaker wrote rather
than adding to it, which is the line that matters.

**A dialect never writes anyone's roleplay for them.** The Void Elf dialect used
to insert Void whispers — *"let go"*, *"it is already too late"* — and Worgen
flavour included *"\*grrr\*"* and *"\*low growl\*"*. Every other filter here
*translates* what somebody typed; those invented text nobody wrote and attributed
it to them, in asterisks, which on a roleplaying realm means an emote. So a
character appeared to perform an action they never performed:

```
[Vynlor Dawnfall] says: *it is already too late* Gold! Come here, girl!
```

With outgoing rewriting on it was broadcast, too. `Lisp` and `Muffle` are
self-only precisely so the addon never puts words in someone's mouth; this put
whole actions there. All of it is gone, and a test sweeps every dialect at every
strength asserting that no asterisk appears in the output that was not in the
input.

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

The source is
[Darnassian (Canon) Translation](https://docs.google.com/document/d/1bD2qSEdWweR7xfIqUx_Iewv_4F40gboM-6ViSgfn1O8),
a community document that separates confirmed translations from speculative
ones. Only the confirmed side is used. If you extend the glossary from it, keep
that split.

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

## Packaging and distribution

A zip and a CurseForge listing are not alternatives — CurseForge distributes a
zip, so the zip is the deliverable either way and CurseForge is one channel for
it.

Build one:

```
tools/package.sh          # writes dist/Eloquence-<version>.zip
```

The result contains a single top-level `Eloquence/` folder, which is what both a
manual install and every addon manager expect. Development files — the test
suite, `tools/`, CI config — are excluded, and `README.md` and `LICENSE` are
copied inside the addon folder.

**Do not hand people the GitHub "Download ZIP" button.** That produces
`Eloquence-<branch>/Eloquence/…`, one level too deep, so the game will not see
the addon; it also ships the test suite. Use a built zip or a Release.

### Why the script validates before it builds

The game loads exactly what `Eloquence.toc` lists. The test harness keeps its own
load order in `Tests/wow_stub.lua`. If those two drift, **every test still passes
while the addon fails to load a file in game** — the worst kind of failure,
because nothing complains. So both the packager and the suite assert that the TOC,
the harness list, and the files on disk all agree, and that `Variants.lua` still
comes after the dialects it derives from. `tools/package.sh` refuses to build if
they disagree.

### Publishing

`.github/workflows/ci.yml` runs the suite and a packaging check on every push.

`.github/workflows/release.yml` cuts a release when you push a tag:

```
git tag v2.0.0 && git push origin v2.0.0
```

It runs the tests, builds the zip, and attaches it to a GitHub Release. That part
needs no setup at all.

The project is live at
[curseforge.com/wow/addons/eloquence-revived](https://www.curseforge.com/wow/addons/eloquence-revived).

**Publishing there is a manual step.** The CurseForge account is connected to this
repository, but that connection imported one file around the time the project was
approved and has not picked up a release since: `v2.4.1` produced no file on
CurseForge, not even a pending one, and replacing the `v2.4.0` asset did not sync
either. So do not assume a GitHub release reaches CurseForge by itself — it does
not, on the evidence so far.

That is one observation rather than a settled conclusion. If the integration turns
out to have an auto-publish setting that was simply switched off, this section is
wrong and the fix is a checkbox rather than anything in this repository.

To upload by hand, which takes under a minute:

1. Download the zip from the
   [GitHub release](https://github.com/Zethrel/Eloquence/releases), or build it
   locally with `tools/package.sh`.
2. Drag it into the project's **Upload File** form and pick the game version
   matching the TOC's `## Interface` line (`120100` → `12.1.0`).
3. Mark it the **main file**, so the project page's Install button serves it.
4. Write a **changelog**. Eloquence changes what chat looks like, so "single
   parentheses are now treated as out-of-character" is exactly what a returning
   user needs to read.

The workflow can do the upload from CI instead. Two settings enable it:

1. Add a repository **secret** `CF_API_KEY` from CurseForge account settings →
   API Tokens.
2. Add a repository **variable** `CF_PROJECT_ID` — the numeric Project ID shown
   on the project page.

Both must be present or the step skips, which is what the "Upload to CurseForge
skipped" notice in every release run so far means. Do not enable this while the
CurseForge-side integration is also publishing, or each release lands twice.

`tools/curseforge-upload.sh` does the upload, and handles the one fiddly part —
CurseForge wants its own numeric game-version ID rather than an interface number,
so `120007` is converted to `12.0.7` and looked up. Two ways to exercise it
without uploading anything:

```
CF_SELFTEST=1 tools/curseforge-upload.sh                      # tests the conversion

tools/package.sh                                              # build one to point at
CF_DRY_RUN=1 CF_API_KEY=x CF_PROJECT_ID=1 \
  tools/curseforge-upload.sh dist/Eloquence-*.zip             # offline, sends nothing
```

Note that the actual CurseForge API calls are the one part of this repository that
has never run for real — everything up to the network request is verified, but the
upload itself will need a live key the first time.

Wago.io and WoWInterface are other options; both take the same zip.

### Keeping up with patches

`.github/workflows/interface-check.yml` runs every Wednesday, compares the TOC's
interface number against the live retail client, and opens an issue when a patch
has moved past it. `tools/check-interface.sh` does the work and can be run by
hand.

**It deliberately does not bump the TOC**, and should not be changed to. The
interface number is a compatibility claim — `## Interface: 120100` asserts that a
human tested this addon against 12.1.0. A script setting it asserts only that a
number changed on a website.

A major patch is exactly when this addon is most likely to break. Patch 12.0
rearchitected the chat send path: overriding `SendChatMessage` stopped seeing
typed chat, and outgoing dialects silently did nothing, with no Lua error to
notice. An automatic bump would have shipped a release claiming 12.0 support
while the headline feature was dead. Being flagged out of date is the safe
failure — the addon still loads if the player opts in, and the label honestly
says nobody has checked yet.

The parser is covered by fixtures and runs in CI:

```
CHECK_SELFTEST=1 tools/check-interface.sh
```

That matters more than it looks. The failure this guards against is not a crash
but a silent degradation to "never reports drift", which is indistinguishable
from "no patch has landed". The live fetch is the one part that has never run
here — Blizzard's build endpoint is not reachable from every environment — so the
first real run is the first proof it works end to end.

The project page's summary and description live in
[`docs/curseforge.md`](docs/curseforge.md), so the store copy and this README can
be kept in step. Edit that file rather than the web form, then paste it across.

That description is also where the [Ko-fi](https://ko-fi.com/zethrel) link belongs
if you want it seen at all — most addon users install through the CurseForge app
and never open the GitHub page, so the repository's Sponsor button reaches almost
none of them. The description field is the storefront; the repository is for
people who came looking for the source.

## Tests

The text handling — which is nearly all of the interesting behaviour — is tested
headlessly against a stubbed client. No game required:

```
lua Tests/run.lua
```

Currently 1608 assertions covering case preservation, escape-sequence integrity,
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

**This revival is by Zethrel — Argent Dawn EU.**

The original Eloquence was a community roleplaying addon of the Vanilla era,
written for patch 1.12 by an author the surviving listings do not name. This
project owes its filter design, its dialect line-up and several of its example
lines — including the Dwarven *"Ah'm no' shuir if that wull wirk, laddie"* — to
that addon's own documentation. It is a reimplementation rather than a fork: none
of the original code was available (see
[What this is, and what it is not](#what-this-is-and-what-it-is-not)).

Race accents follow how Blizzard voices each race in the modern game. The
Darnassian glossary comes from
[Darnassian (Canon) Translation](https://docs.google.com/document/d/1bD2qSEdWweR7xfIqUx_Iewv_4F40gboM-6ViSgfn1O8),
a community-maintained document collecting every attested Darnassian word and
phrase from quest text, unit voice lines and Warcraft III, with the confirmed
translations kept separate from the speculative ones. Only the confirmed entries
were used here. Thanks to everyone who put that list together.

**Sleat — Argent Dawn (EU)** asked for the muffle and lisp filters, for
characters in closed helms and characters who want the impediment.

**Trustbough — Argent Dawn (EU)** reported that the Darnassian dialect greeted
people with a farewell, that every Night Elf greeted identically when three
greetings are attested, and that `shan'do` — *teacher* — was being used for
"friend". Most of what is right about `Dialects/NightElf.lua` is his doing. He
also asked whether a character could speak in a race's dialect other than their
own — a Night Elf raised in Ironforge — which is what surfaced **Speak as**
below.

**Môrgrith — Argent Dawn (EU)** reported that his Human death knight had no
business saying "By the Light", which is what prompted the class flavour layer in
`Core/Class.lua`. Race decides how a character sounds; class decides what they
would never say, and nothing had modelled the second until he said so.

**Anadelonbrin — Argent Dawn (EU)**, creeped out by the voices in her head, and **Vynlor — Argent Dawn (EU)**, saying
creepy stuff — both due to a void elf bug. Their descriptions, and better than
any summary of the fault: the Void Elf dialect was inserting whispers into
people's chat in emote asterisks, so characters appeared to perform actions they
had never typed. It is the report that produced the rule now enforced across
every dialect — Eloquence changes *how* a line is worded, never *what* was said.

MIT licensed — see [LICENSE](LICENSE).

### Supporting it

Eloquence is free and always will be — Blizzard's addon policy requires it, and
it is the right shape for an addon anyway. If you would like to put something in
the tip jar towards keeping this and other revived RP addons maintained, there is
one at [ko-fi.com/zethrel](https://ko-fi.com/zethrel). Entirely optional, and it
buys no features: everything the addon does is in the box for everyone.

You will not find that link anywhere inside the addon, and it should stay that
way. Blizzard's UI Add-On Development Policy prohibits addons from soliciting
donations or displaying advertisements, so the link lives here, on the repository
page, and in the CurseForge description — never in the Lua, the options panel, or
the TOC, whose fields show up in the in-game addon list.
