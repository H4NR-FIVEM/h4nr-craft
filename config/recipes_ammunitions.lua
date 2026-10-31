-- BCC recipe port for ammunitions; keep identifiers stable for pending orders.
local recipes = {
    {
        Amount = 1,
        Category = 'Muniție (cutii de 24)',
        Id = 'ammo.pistol',
        Item = 'ammo_pistol',
        Jobs = {},
        Label = 'Muniție pistol',
        Level = 1,
        Location = 'ammunitions',
        Materials = {
            {
                Count = 2,
                Item = 'gunpowder',
            },
            {
                Count = 1,
                Item = 'copperbar',
            },
        },
        Seconds = 20,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 5,
    },
    {
        Amount = 1,
        Category = 'Muniție (cutii de 24)',
        Id = 'ammo.smg',
        Item = 'ammo_smg',
        Jobs = {},
        Label = 'Muniție SMG',
        Level = 1,
        Location = 'ammunitions',
        Materials = {
            {
                Count = 2,
                Item = 'gunpowder',
            },
            {
                Count = 1,
                Item = 'copperbar',
            },
        },
        Seconds = 20,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 5,
    },
    {
        Amount = 1,
        Category = 'Muniție (cutii de 24)',
        Id = 'ammo.rifle',
        Item = 'ammo_rifle',
        Jobs = {},
        Label = 'Muniție pușcă',
        Level = 1,
        Location = 'ammunitions',
        Materials = {
            {
                Count = 2,
                Item = 'gunpowder',
            },
            {
                Count = 1,
                Item = 'copperbar',
            },
        },
        Seconds = 20,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 5,
    },
    {
        Amount = 1,
        Category = 'Muniție (cutii de 24)',
        Id = 'ammo.shotgun',
        Item = 'ammo_shotgun',
        Jobs = {},
        Label = 'Cartușe alice',
        Level = 1,
        Location = 'ammunitions',
        Materials = {
            {
                Count = 2,
                Item = 'gunpowder',
            },
            {
                Count = 1,
                Item = 'copperbar',
            },
        },
        Seconds = 20,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 5,
    },
    {
        Amount = 1,
        Category = 'Muniție (cutii de 24)',
        Id = 'ammo.sniper',
        Item = 'ammo_sniper',
        Jobs = {},
        Label = 'Muniție lunetă',
        Level = 1,
        Location = 'ammunitions',
        Materials = {
            {
                Count = 2,
                Item = 'gunpowder',
            },
            {
                Count = 1,
                Item = 'copperbar',
            },
        },
        Seconds = 20,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 5,
    },
}
for _, recipe in ipairs(recipes) do
    Craft.Recipes[#Craft.Recipes + 1] = recipe
end
