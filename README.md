# LuckyOdds

A small odds panel and minimap helper addon for **Azeroth Survivors** (WoW 1.12.1 client, benilla).

See what your luck actually buys you, and never miss a Battleground Cache or a guardian lair again.

## Features

- **Odds panel**: your chance of a Rare, Epic or Legendary card for spells, rings, trinkets and amulets, worked out from your luck stat plus the level bonus (+1% per level, 30% at most). Amulets get their extra bonus on top. It updates live during the run.
- **Battleground Caches**: every cache shows up as an icon on the minimap. When the nearest one is off the map, an arrow on the edge points to it. Hover any icon to see how far it is.
- **Guardian lairs**: lairs show up on the minimap too. A skull means the guardian is asleep, a red skull means you're fighting it, an orange timer counts down until an empty lair comes back, and yellow "due" means it's about to spawn.
- **Minimap button**: click it to show or hide the odds panel, drag it to move it around the minimap.
- Drag the panel wherever you like; it remembers its spot. It only shows up during a run.
- Works with round and square minimaps.

The odds are a rough guide, not the game's exact roll.

## Install

1. Download `LuckyOdds-vX.Y.Z.zip` from [Releases](../../releases).
2. Put the `LuckyOdds` folder into `benilla-config/AddOns/`.
3. Restart the game.

If you use Chestlight, turn it off, or you'll see the chests twice.

## Commands

- `/lucky`: show or hide the odds panel
- `/lucky chests`: turn the cache icons on the minimap on or off
- `/lucky lairs`: turn the guardian lairs on the minimap on or off

## Author

Cadoky

Azeroth Survivors is a fan game by Aethus. This addon is not affiliated with Blizzard Entertainment.
