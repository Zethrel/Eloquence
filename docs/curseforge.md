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

26 dialects, covering the full modern roster rather than just the classic thirteen.

---

## Only you see it

By default Eloquence changes **only what you read**. Nothing you type is altered, and nobody else is affected.

Want your own speech to go out in dialect so others see it too? One opt-in setting.

---

## Five filters

Three run out of the box:

- **Dialectician** -- the accents themselves, one per race
- **The Spell Book** -- spelling, repetition, ALL-CAPS
- **Decompression Engine** -- expands MMO and Warcraft acronyms

Two are off until you want them, because they rewrite a lot and are a matter of taste:

- **Mouthwash** -- profanity to euphemism
- **Fantasy Writer** -- modern turns of phrase into something that belongs in Azeroth

Each has light, medium and heavy settings, and each can be switched on or off independently.

---

## It respects what other people wrote

On a roleplaying realm, how somebody spells things is a choice. Eloquence never touches:

- **Names** -- `Zethrrel` and `Zettle` both survive exactly as written
- **Deliberate accents** -- `no'` never becomes `nae'`
- **OOC asides** -- anything in parentheses, `(single)` or `(( double ))`
- **Register tags** -- `[low]`, `[Thalassian]`, `[to the crowd]`
- **Links, colour codes and URLs** -- passed through intact

The Spell Book stays off other people's chat unless you ask for it, because correcting a stranger's spelling means sanding off authored voice rather than tidying a typo.

---

## What you get out of the box

- Dialects apply to **say, yell and emote**. Party, raid, instance and guild stay plain -- *"interrupt now, bloodlust on pull"* is not roleplay, and dialecting it just makes the useful chat harder to read.
- **Whispers are left alone too.** In-character whispering is conventionally done in `/say` opened with a `[low]` tag, so nearby characters get the chance to overhear. That leaves the whisper channel itself carrying out-of-character talk.
- **Chat bubbles** above characters' heads are rewritten as well, not just the chat frame.
- **NPCs are not dialected** unless you ask -- the Immersive preset turns that on.
- **Nothing you type is changed.** Sending in dialect is a separate opt-in.

Four presets to start from: **Roleplay** (the default), **Immersive**, **Clean chat** and **Off**.

---

## Getting started

Install and log in. The defaults are already the Roleplay preset.

- `/elo` -- open the options
- `/elo preset rp` -- apply a preset
- `/elo doctor` -- diagnose anything that looks wrong

---

## A note on Darnassian

The Night Elf dialect carries a glossary of canon Darnassian -- *Ishnu-alah*, *Shaha lor'ma*, *Fandu-dath-belore?* -- drawn from [Darnassian (Canon) Translation](https://docs.google.com/document/d/1bD2qSEdWweR7xfIqUx_Iewv_4F40gboM-6ViSgfn1O8), a community-maintained document collecting every attested word and phrase and keeping the confirmed translations separate from the speculative ones. Only the confirmed entries are used here; nothing was invented. Thanks to everyone who put that list together.

---

Free and open source (MIT): **[github.com/Zethrel/Eloquence](https://github.com/Zethrel/Eloquence)**

A revival of the classic Vanilla-era RP chat addon, by **Zethrel -- Argent Dawn EU**.
If you'd like to support further work: **[ko-fi.com/zethrel](https://ko-fi.com/zethrel)**
