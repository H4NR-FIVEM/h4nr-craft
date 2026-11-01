# FiveM crafting locations and recipes

Researched 1 November 2026. References supply gameplay/configuration ideas; h4nr-craft
continues to call Feather owners. No third-party resource is modified or uploaded.
Coordinates need in-game checks against this server's maps and interiors.

## Installed starter workshops

The two default bench points are from
[ox_inventory crafting.lua](https://github.com/overextended/ox_inventory/blob/main/data/crafting.lua):

| Our station | Coordinates | Heading from source target zone |
| --- | --- | --- |
| Atelier industrial | `-1147.083008, -2002.662109, 13.180260` | 315 |
| Atelier central | `-345.374969, -130.687088, 39.009613` | 70 |

The ox example makes two lockpicks from five scrap metal units with a hammer losing
5% durability. Our adaptation uses the existing `ironbar` item in place of scrap,
retains two outputs and hammer wear, and uses ten seconds per batch.

[QB crafting configuration](https://github.com/qbcore-fivem/qb-crafting/blob/main/config.lua)
provides the screwdriver-set and repair-kit recipe families, as well as electronics,
scanners, drills and armor. Its raw costs use scrap/plastic/steel/aluminum. Those
are not silently introduced into this server's item catalog.

The installed adaptations use existing Feather definitions and our own balance:

| Output | Materials per batch | Tool | Seconds | Level |
| --- | --- | --- | --- | --- |
| 2 lockpicks | 5 ironbar | hammer, 5% wear | 10 | 1 |
| 1 screwdriver set | 2 ironbar + 1 copperbar + 2 nails | hammer, retained | 20 | 1 |
| 1 repair kit | 3 ironbar + 2 copperbar + 4 nails | hammer + screwdriver set, retained | 30 | 2 |

Both benches offer these three types. Costs, XP, levels and the latter two material
lists are adaptations, not claims that these are the original upstream values.
No new item definitions or permissions are required. The repair-kit definition and
its use behavior remain owned by the existing Feather/gameplay consumers.
Batch limits also respect Inventory's configured maximum item quantity.

## Other sourced location candidates

[Jim Mining locations](https://github.com/jimathy/jim-mining/blob/main/shared/locations.lua),
confirmed against the local `[notused]/jim-mining-main/shared/locations.lua`:

| Candidate | Coordinates | Use |
| --- | --- | --- |
| Foundry | `1112.29, -2009.9, 31.46` | Metal processing |
| Foundry tool/drill point | `1109.19, -1992.8, 30.98` | Heavy workbench |
| Foundry gem bench | `1077.11, -1984.22, 31.02` | Jewelry/gem cutting |
| Vangelico buyer | `-630.46, -240.13, 38.14` | Jewelry trade, not a confirmed crafting bench |

These are documented candidates rather than additional active Craft stations.

## Additional recipe ideas, not enabled

The local Jim Mining `shared/crafting.lua` and its
[upstream repository](https://github.com/jimathy/jim-mining) provide:

- Smelting: iron ore → iron; iron ore + carbon → steel; copper ore → copper.
- Recycling: two cans → three aluminum; two bottles → two glass.
- Cutting: one uncut emerald/diamond/ruby/sapphire → its cut gem.
- Jewelry: one gold ingot → three gold rings; a gold ring + diamond → diamond ring.

Keep ore processing with `h4nr-mining` unless its owner is deliberately migrated.
The existing mining resource already has its own ore/ingot names, recipes, XP and
smelting service. Jewelry, electronics and attachment ideas need compatible
Inventory/Weapons definitions and valid gameplay behavior before enabling them.
Do not add inert item names or bypass owning resource contracts just to populate
more recipe cards.

The existing BCC-derived food, refining, tobacco and GTA weapon/ammo recipes remain.
