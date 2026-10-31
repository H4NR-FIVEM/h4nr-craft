# h4nr-craft

FiveM crafting for the local Feather Framework: 26 recipes at five Los Santos
stations, batches, persistent crafting queues, collectible output, tools and wear,
recipe job/grade/duty restrictions, levels, and optional portable inventory books.
Romanian is the default; all interface messages have an English fallback. Menus
use feather-menu-v2's blue `modern` preset.

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
Open **Comenzi în lucru / colectare** to inspect or collect orders. Refresh the
queue when a timer expires. A full inventory leaves the order available to retry.

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

With `HasCraftBooks = true`, each station offers one free reference copy per
character/station. With `AllowPortableBooks = true`, using a book opens its
station's recipes away from a bench. The server checks book possession for
portable requests. Books are actual Inventory items and are not consumed.

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

Lua 5.4 syntax and simulated service/client contracts: **26 files (including three companion configs), 203 service
assertions and 111 client assertions** at the initial verification checkpoint.
The isolated MariaDB installer/queue suite passes **99 checks**, preserves
existing definitions, rejects duplicate request identities, and tests retained
server deadlines and collected XP. It starts and stops its own temporary database;
it never connects to the game database. Requires local MariaDB binaries.

`CraftReleaseSmokeTest` is a read-only server-console command reporting readiness
and missing recipe/tool/book definitions. It does not grant test items.

Automated checks do not replace in-game acceptance. Still verify station
placement/E prompts, menu Escape/controller focus, NPC streaming, portable books,
material and output rendering, broken tools, job/duty restrictions, GTA weapon
equip/ammo refill, reconnect/restart recovery and competing players. No live
Inventory restart or gameplay acceptance was performed during this port.
