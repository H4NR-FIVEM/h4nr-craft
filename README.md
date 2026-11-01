# h4nr-craft

FiveM crafting for the local Feather Framework: 32 station recipes at seven Los Santos
stations, batches, persistent crafting queues, collectible output, tools and wear,
recipe job/grade/duty restrictions, levels, and optional portable inventory books.
Romanian is the default; all interface messages have an English fallback.
The dedicated NUI uses the blue Neon Vice palette and does not require Menu v2.
[Workbench preview](docs/workbench-preview.png).

Ported from [BCC-FeatherFramework/bcc-craft](https://github.com/BCC-FeatherFramework/bcc-craft)
at `f1d5dc1`. Original author: BCC Team / iseeyoucopy. GPL-3.0; see LICENSE.
This is a GTA V implementation using the BCC food, refining and tobacco recipe
values and matching the installed Feather FiveM weapon/ammunition catalogue.

## Install

See [install/README.md](install/README.md). The companion changes are required:
Inventory's additive item bootstrap and narrow caller permissions, Jobs reader
trust, and Weapons' FiveM issuer permission. This resource never creates or
queries another resource's tables.

Walk to a station and press **E**. Select a recipe and number of batches, then
start crafting. The server begins the timer after material preparation succeeds.
The right panel shows queued orders with live countdowns and Collect/Resume
actions. Quantity controls update output, materials, duration and XP immediately.
Search and expandable categories filter the left recipe list. A full inventory leaves the order available to retry.

## Configuration

- `config/shared.lua`: language, locations, books and portable access.
- `config/client.lua`: GTA control index, blips, NPC streaming distance.
- `config/recipes_*.lua`: stable recipe IDs, outputs, XP, materials, tools and jobs.
- `config/server.lua`: distance, batch/queue limits, duty, collection and levels.

`Jobs = { 'gunsmith', { 'police', 2 } }` accepts either named job (the second
requires minimum grade ordinal 2). Define jobs through their owning gameplay
resource; Craft does not create jobs or assignments. Set `RequireOnDuty = true`
to require an on-duty assignment.

`Materials` are consumed plain Inventory stack units. `Tools` are retained;
`Wear = 0` means presence only, otherwise wear is normalized from `Maximum` to
Inventory's 0–100 condition scale and multiplied by the batch count. Add each
new worn tool to Inventory's `TrustedConsumptionCallers['h4nr-craft']['craft.tool.v1']`
allowlist. Worn tools must use Inventory's `item_item` condition contract.
A tool can break when its remaining condition reaches zero.

Ammunition recipes produce inventory boxes; Feather Weapons determines rounds
per box (currently 24). Weapons are issued through `feather-weapons:IssueWeapon`
with durable request IDs, serial metadata and zero initial rounds. Craft never
calls `GiveWeaponToPed` or writes weapon/ammunition state.

With `HasCraftBooks = true` (the default), each station offers one free reference
copy per character/station. A recipe with `Book` requires that inventory item.
Only recipes explicitly marked `Portable = true` can be made in the field, and
the location must permit portable access. Weapons, ammunition and refining
require a fixed workshop. The server enforces both book and station requirements. Books are actual Inventory items and are not consumed.

## Queue and recovery

`h4nr_craft_orders` owns the admission snapshot, output, material definitions,
wear requests, deadline, state and XP reward. A start request is bound to a
character and original batch. A local client journal preserves its request ID
through timeouts; every RPC is fenced to the current character/session.

States are `preparing` → `queued` → `collected`. Preparation persists before any
material debit. Each material uses `TakeCharacterItemOnce`, each worn tool uses
`WearCharacterItemOnce`, and output uses `GrantCharacterItemOnce` or Weapons'
idempotent issuance. Retrying reuses those original receipt identities. A lost
collection acknowledgment cannot grant output twice. XP is calculated from
collected orders, so it is awarded once per order, including across reconnects.

The sequence is not an atomic transaction spanning all resources. If a later
material/tool operation fails after earlier debits, the order stays visible as
**preparing**, with the already consumed materials bound to it. Restore the
missing material/dependency and resume the same order. A changed or transferred
tool revision or incompatible item definition may require operator investigation.
Do not delete pending orders, edit their snapshots, or replace their operation IDs
to recover them. Historical collected rows must remain for XP and replay checks.
Only one Craft handler per character runs at once; other resources can still
mutate inventory through Inventory's own locks and guards.

## Differences from RedM

GTA stations, controls, NPCs, weapon definitions and ammunition replace their
RedM counterparts. Invalid RedM weapon/ammo variants are not shipped as GTA items.
The `Mutton` material is normalized to lowercase `mutton` for Inventory receipts.
Old RedM queues/progression are not automatically migrated into this new resource.

Books are free reference copies. Upstream gold/dollar book sales, category-only
books, paid unlocks, portable campfire props, Discord webhooks and BCC playtime
hooks are outside this release. Craft uses its own fixed XP step per level;
it does not claim to award character-wide Feather progression XP.

## Verification

```sh
python3 tests/run.py
python3 tests/mysql_integration.py
```

Lua 5.4 verification: **30 files parse, 335 service assertions, 40 NUI/controller
assertions and 44 actual Core RPC assertions pass**. The browser suite passes
**31 checks** using a synthetic payload emitted by the actual Lua controller.
It covers layout, search, selection, quantity/material/time totals, scoped actions,
selection preservation, countdowns, blocking reasons, images, 720p/narrow layouts
and Escape close.

```sh
CRAFT_PREVIEW_OUT=/tmp/h4nr-craft-workbench-view.json python3 tests/run.py
node tests/browser_spec.mjs /tmp/h4nr-craft-workbench-view.json
```

The browser suite needs Playwright and Chromium. Set `CRAFT_PLAYWRIGHT_MODULE`
to an installed module path and `CRAFT_BROWSER_EXECUTABLE` to a browser executable
when they are not in standard locations. `CRAFT_SCREENSHOT_OUT` sets the screenshot
path. The test serves only the four NUI files locally, uses synthetic data and
stops its server after the run. No game database or production player is involved.

The earlier isolated MariaDB installer/queue checkpoint passed **99 checks**.
No SQL/schema change is needed for this NUI release.

`CraftReleaseSmokeTest` is a read-only server-console command reporting readiness
and missing recipe/tool/book definitions. It does not grant test items.

Automated checks do not replace in-game acceptance. Still verify station
placement/E prompts, menu Escape/controller focus, NPC streaming, portable books,
material and output rendering, broken tools, job/duty restrictions, GTA weapon
equip/ammo refill, reconnect/restart recovery and competing players. No live
Inventory restart or gameplay acceptance was performed during this port.

## 1.0.1 — RPC startup correction

Contract RPC names now use a shared `.v1` suffix on both client and server.
Craft error responses include the localized `message` required by Core's result
contract. Registration failures report Core's error code and message. Deploy
both sides together with `restart h4nr-craft`; no Inventory restart is needed.

## 1.1.0 — dedicated workbench NUI

The owner selected a dedicated interface following the supplied three-column
reference, overriding the earlier Menu v2 presentation rule for this resource.
The left panel groups/searches recipes, the center shows item art, materials,
tools, knowledge and quantity totals, and the right shows owned materials and
the persistent queue. Green marks collectible/available output; amber marks unmet
requirements. Presentation refreshes every ten seconds without resetting selection
or quantity; countdowns update locally each second. Server admission revalidates.

Inventory remains the owner: catalogs use one inventory snapshot rather than a
count query for every recipe/material. No new Inventory contract or permission is
required. NUI actions are bound to the current UI nonce and Core session. Close,
death, distance, Core stop and resource stop release focus; gameplay controls are
suppressed while the NUI holds focus. ItemImages/ItemLabels in config/server.lua
can alias existing Inventory assets/labels without changing item definitions.

Deploy all files and run `restart h4nr-craft`. Do not restart Inventory for this
update. Confirm layout, focus and controller handling in FiveM; browser tests do
not replace in-game acceptance. No UI package install or build step is needed.

## Sourced workshops and recipe research

Two additional fixed workshops use the default points from ox_inventory. Each
offers adapted lockpick, screwdriver-set and repair-kit recipes using items that
already exist in Feather Inventory. This adds six station entries (three recipe
types); item definitions and third-party resources are unchanged. Costs and XP
are our adaptation, not the original upstream balance.

[Locations, recipes, sources and additional candidates](docs/recipe_sources.md)
records the ox/QB/Jim references, exact installed coordinates, and candidate foundry,
gem-cutting and jewelry locations. Mining/smelting is retained with h4nr-mining.
New item/weapon mechanics are not enabled just because a third-party recipe names them.
