# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

LuckyOdds is a single-file WoW addon (`LuckyOdds.lua`) for **Azeroth Survivors**, a fan game on the WoW 1.12.1 client (benilla). It shows rarity odds for cards/amulets from the player's luck, and minimap pins for Battleground Caches and guardian lairs. Slash command `/lucky` (`chests`, `lairs`). SavedVariables `LuckyOddsDB`.

## No build, no tests

No build step, linter, test suite or Lua interpreter. Verify only in game (`/reload`). Say when a change is untested in game.

## Platform constraints

Lua 5.0 / WoW 1.12 API: no `#`, no `string.match`, no `select`, no `_G`, `this`/`arg1` in handlers, max 32 upvalues per function. No world-to-screen projection exists.

## How it works

- Odds: weights Common 60, Uncommon 25k, Rare 10k², Epic 4k³, Legendary k⁴, with k = 1 + luck + level bonus (+1%/level, max 30%) + source bonus (+0.5 for amulets). Luck comes from `AZS_STATS`. It is a rough guide, not the game's exact roll; the formula is documented in the file header.
- Minimap pins: the game publishes the hero position (`AZS_RUN.px/py`), caches (`AZS_CHESTS`) and lairs (`AZS_LAIRS`, timed with `AZS_LAIRS_UPDATED`) in yards (world x = north, world y = west). Pins are placed relative to the hero, with an edge arrow for the nearest off-map cache; round and square minimaps are both handled. Everything is gated on `AZS_GetPhase()` (only during a run).

## Releasing

`.github/workflows/release.yml` runs on a push to `main` that changes `*.toc`: if tag `v<## Version>` is new, it zips the repo as `LuckyOdds-vX.Y.Z.zip` (excluding `.git`, `.github`, `RELEASE_NOTES.md`) and releases it with `RELEASE_NOTES.md` as notes. Release = bump `.toc` version + `RELEASE_NOTES.md` + push to `main`, only when the owner explicitly asks. Keep `README.md` in sync with features.
