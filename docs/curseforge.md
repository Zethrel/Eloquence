# CurseForge page copy

The live project: https://www.curseforge.com/wow/addons/eloquence-revived
(the slug is `eloquence-revived`, since the original addon's listing still holds
`eloquence`).

The text of that project page, kept here so it does not drift from the README.
Edit this file rather than the web form, then paste it across.

Nothing in this directory ships: `tools/package.sh` copies only the addon's Lua
and TOC files plus the README and LICENSE.

---

## Summary field

CurseForge requires a single sentence for this field -- it is the preview line
shown in search results.

> Eloquence rewrites chat in a dialect matched to each speaker's race, with optional filters for spelling, acronyms, profanity and modern phrasing.

---

## Description field

CurseForge's editor accepts pasted Markdown reasonably well, but check the
horizontal rules and the nested blockquote in the example -- those are the two
things most likely to need fixing by hand.

---

# Eloquence

**Every character speaks with their race's accent.**

Eloquence reads the race of whoever is talking and renders their chat to match. A Dwarf sounds like a Dwarf:

> *I don't know if that will work, friend.*
> **-> Och, whit noo. Ah dinnae ken if that wull wirk, laddie.**

26 dialects, covering the full modern roster rather than just the classic thirteen -- and at heavy strength, six of them speak real Warcraft languages.

---

## Only you see it

By default Eloquence changes **only what you read**. Nothing you type is altered, and nobody else is affected.

Your own speech is a single three-way setting -- **Show my chat in dialect to**:

- **Off** -- your own lines appear exactly as you typed them.
- **Only me** -- you see your character's accent in your own chat frame. Nothing you send changes and nobody else is affected.
- **Everyone** -- your messages are rewritten before they are sent, so everyone reads them in dialect.

---

## The filters

Three run out of the box:

- **Dialectician** -- the accents themselves, one per race, plus canon vocabulary at heavy strength
- **The Spell Book** -- spelling, repetition, ALL-CAPS
- **Decompression Engine** -- expands MMO and Warcraft acronyms

Two are off until you want them, because they rewrite a lot and are a matter of taste:

- **Mouthwash** -- profanity to euphemism
- **Fantasy Writer** -- modern turns of phrase into something that belongs in Azeroth

Two more describe your own character rather than anyone else's -- **Lisp** and **Muffle** -- and have a section of their own below.

Each has light, medium and heavy settings, and each can be switched on or off independently.

---

## Canon languages

Turn the Dialectician up to **heavy** and six races start salting their speech with their own language:

| Language | Spoken by | For instance |
| --- | --- | --- |
| **Darnassian** | Night Elf | *Ishnu-alah*, *Shaha lor'ma*, *Fandu-dath-belore* |
| **Thalassian** | Blood Elf | *Bal'a dash, malanore*, *Al diel shala*, *Anar'alah belore* |
| **Orcish** | Orc, Mag'har Orc | *Throm-Ka*, *Lok'tar ogar*, *Gol'Kosh*, *Dabu* |
| **Zandali** | Troll, Zandalari Troll | *ma'da*, *dazdooga*, *juju*, *loa* |

```
Well met, friend.          ->  Throm-Ka, friend.
Safe travels.              ->  Al diel shala.
The spirits are angry.     ->  De loa be angry.
```

These sit behind **heavy** deliberately. A whole message peppered with untranslated words stops being flavour and starts being unreadable, so at light and medium strength you get the accent without the vocabulary. Pick the **Immersive** preset, or set the Dialectician to heavy yourself.

**Every entry is attested.** Each one traces to Blizzard's own material -- quest text, NPC voice lines, Warcraft III -- and nothing has been invented to pad a list out. The Darnassian glossary comes from [Darnassian (Canon) Translation](https://docs.google.com/document/d/1bD2qSEdWweR7xfIqUx_Iewv_4F40gboM-6ViSgfn1O8), a community-maintained document that keeps confirmed translations separate from speculative ones; only the confirmed side is used. Thanks to everyone who compiled it.

That discipline is also why some races have no glossary at all. Dwarves, Gnomes, Draenei and Tauren get none, because Blizzard never wrote enough of those languages to draw on -- Gnomish has no attested vocabulary whatsoever, and the Draenei words that do exist only ever appear inside place names like Shattrath. Inventing some would have been easy and would have made them no more canon than a fan dictionary. Their accents carry them instead.

---

## Your class has opinions too

Race decides how a character sounds. Class decides what they would never say.

A Human farmer saying *"By the Light"* is fine. A Human death knight saying it is not -- they are a corpse that kept its will, and the Light is the thing that burns. So a class layer sits on top of the race:

| | Human | Human Death Knight |
| --- | --- | --- |
| *Goodbye, friend.* | King's honor, friend. | **Suffer well, friend.** |
| *Good luck out there.* | Fortune favor you. | **Die well out there.** |
| *Thank you.* | My thanks to you. | **You have my debt.** |

It removes rather than replaces. A **Dwarf** death knight stops invoking the Light and carries on speaking broad Scots -- the accent still belongs to the race, and only what clashes is gone.

Four classes so far: **Death Knight**, **Warlock** and **Demon Hunter**, who all have reason to avoid the Light, and **Paladin**, who leans into it. Every other class speaks purely as its race does. If you would rather they all did, untick **Adjust speech for the speaker's class** in the options, or `/elo class off`.

---

## Effects for your own character

Two filters describe *your* character's mouth rather than anyone else's:

- **Lisp** -- for characters who want the impediment.
- **Muffle** -- for a closed helm, a diving suit, or anything else between you and the air.

```
Yes, stand aside friend.   lisp   ->  Yeth, thtand athide friend.
                           muffle ->  Yeh, hnann ahine mrienn.
```

Both are off by default and apply only to what **you** send -- never to what you read. You cannot see what anyone else is wearing, and lisping a stranger's chat would be putting words in their mouth.

Because they change what you send, they need **Show my chat in dialect to** set to **Everyone**. Turning one on without that says so rather than quietly doing nothing.

Muffling keeps each word's shape and length. Collapsing everything to *mmmph* would be more realistic and impossible to roleplay against.

---

## It knows an emote from speech

An emote is narration with your character's speech quoted inside it, and only the quoted part is being said out loud:

```
/e holds out a flower. "I don't know if you will like it, friend."

   holds out a flower. "Ah dinnae ken if ye wull like it, laddie."
```

The narration stays in plain English, because it is prose written *about* your character rather than *by* them -- accenting it reads as though the narrator had the accent. An emote with no quotes is pure action, and is left completely alone.

Only the accent is held back that way. Spelling, acronyms and profanity still apply to narration, since a typo is a typo wherever it sits.

Double quotes mark speech, curly ones included. Apostrophes are far too common in accented text -- *no'*, *dinnae*, *Lok'tar* -- to treat as delimiters.

---

## It respects what other people wrote

On a roleplaying realm, how somebody spells things is a choice. Eloquence never touches:

- **Names** -- `Zethrrel` and `Zettle` both survive exactly as written, and so do titles in front of them: `Lady Jaina`, `Master Aelric`, `King Anduin`. If your character is called Hope or Storm, their name is left alone too.
- **Deliberate accents** -- `no'` never becomes `nae'`
- **How you address people** -- `friend`, `brother`, `sister`, `kin` all stay as you typed them. The addon cannot see who you are talking to, so it does not guess their gender, their age or whether they are your kin. (Dwarves are the exception, and unrepentant about it.)
- **OOC asides** -- anything in parentheses, `(single)` or `(( double ))`
- **Register tags** -- `[low]`, `[Thalassian]`, `[to the crowd]`
- **Links, colour codes and URLs** -- passed through intact

The Spell Book stays off other people's chat unless you ask for it, because correcting a stranger's spelling means sanding off authored voice rather than tidying a typo.

**And it never writes anyone's roleplay for them.** Eloquence changes *how* a line is worded, never *what* was said. It will not add an emote, an action, or a line of dialogue your character did not type -- a dialect renders an accent, and what your character does is yours to write.

---

## What you get out of the box

- Dialects apply to **say, yell and emote**, with emotes handled as described above. Party, raid, instance and guild stay plain: *"interrupt now, bloodlust on pull"* is not roleplay, and dialecting it just makes the useful chat harder to read.
- **Whispers are left alone too.** In-character whispering is conventionally done in `/say` opened with a `[low]` tag, so nearby characters get the chance to overhear. That leaves the whisper channel itself carrying out-of-character talk.
- **Chat bubbles** above characters' heads are rewritten as well, not just the chat frame.
- **NPCs are not dialected** unless you ask -- the Immersive preset turns that on.
- **Nothing you type is changed** unless you ask for it. **Show my chat in dialect to** is one setting with three states: Off, Only me, Everyone.

Four presets to start from: **Roleplay** (the default), **Immersive**, **Clean chat** and **Off**.

---

## Getting started

Install and log in. The defaults are already the Roleplay preset.

- `/elo` -- open the options
- `/elo preset rp` -- apply a preset
- `/elo doctor` -- diagnose anything that looks wrong

---

## Milestones

- **04.08.2026** -- 100 downloads.

---

Free and open source (MIT): **[github.com/Zethrel/Eloquence](https://github.com/Zethrel/Eloquence)**

The muffle and lisp filters exist because **Sleat -- Argent Dawn (EU)** asked for them. 
Class flavour exists because **Môrgrith -- Argent Dawn (EU)** pointed out that his death knight had no business invoking the Light.
The Darnassian dialect owes most of its accuracy to **Trustbough -- Argent Dawn (EU)**.
The Void whispers were reported by **Anadelonbrin**, creeped out by the voices in her head, and **Vynlor**, saying creepy stuff -- both due to a void elf bug. Feedback like that is welcome.

A revival of the classic Vanilla-era RP chat addon, by **Zethrel -- Argent Dawn EU**.
If you'd like to support further work: **[ko-fi.com/zethrel](https://ko-fi.com/zethrel)**
