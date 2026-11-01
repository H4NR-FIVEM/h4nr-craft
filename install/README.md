# Installation and startup

1. Install this directory as `resources/[h4nr]/h4nr-craft`.
2. Apply the companion Feather commits: Inventory's additive bootstrap definitions
   and caller trust, Jobs' reader trust, Weapons' FiveM issuer trust. Existing
   Inventory item definitions must stay unchanged.
3. With players disconnected, restart the server/dependencies in the order below.
   Inventory's owner bootstrap installs missing crafting definitions automatically.
   `items.sql` is the same additive installer for deployments applying item changes
   manually through the Inventory owner. Do not run SQL against domain tables from
   the Craft runtime.
4. Run `CraftReleaseSmokeTest` in the server console. Fix missing/incompatible
   definitions before enabling recipes on a server with existing customized items.
5. Complete the in-game checks listed in the resource README.

```cfg
ensure feather-mysql
ensure feather-core
ensure feather-character
ensure feather-notify
ensure feather-toolkit
ensure feather-target
ensure feather-inventory
ensure feather-weapons
ensure feather-organizations
ensure feather-jobs
ensure h4nr-craft
```

OneSync is required for server position validation. If not already present,
set `onesync on` in the server's startup configuration.

Permissions in Inventory:

```lua
Config.TrustedIdempotentGrantCallers['h4nr-craft'] = true
Config.TrustedIdempotentTakeCallers['h4nr-craft'] = true
Config.TrustedConsumptionCallers['h4nr-craft'] = {
    ['craft.tool.v1'] = { hammer = true },
}
```

Jobs: `Config.Access.trustedReaders['h4nr-craft'] = true`.
Weapons: `Config.FiveMTrustedIssuers['h4nr-craft'] = true` in `fivem/config.lua`.
No Economy or BCC dependency is required for this version's free reference books.

Default bench coordinates are in `config/shared.lua`. Verify placement against
custom maps/interiors. Edit recipe data in `config/recipes_*.lua`, retaining IDs
for in-flight orders. New tools/materials/outputs must be installed through their
owning Feather domain; do not turn missing-definition errors into free output.

Never commit the live `server.cfg`: it contains secrets. Only the sanitized
server repository example is versioned.

## Dedicated NUI update (1.1.0)

The resource ships plain HTML/CSS/JS. Deploy web/ with the Lua files and restart
only h4nr-craft. Menu v2 is no longer a dependency; keep it running for its other
consumers. No Inventory restart is needed when updating an installed 1.0.x Craft.

Books are offered free at each bench by default. Advanced recipes require their
configured book, and weapons/ammunition/refining require a fixed workshop. Only
explicitly portable recipes can be made in the field. Existing orders without
the new Portable snapshot flag remain collectible at a bench.

Version 1.1.1 adds feather-target as a dependency. Hold ALT, aim at the station
NPC, left-click and select Deschide atelierul. No E prompt is used. Restart only
h4nr-craft after deploying; Feather Core and Inventory do not need restarting.
