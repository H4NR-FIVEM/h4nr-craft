-- BCC recipe port for weapons; keep identifiers stable for pending orders.
local recipes = {
    {
        Amount = 1,
        Category = 'Arme',
        Id = 'weapons.knife',
        Item = 'weapon_knife',
        Jobs = {},
        Label = 'Cuțit',
        Level = 1,
        Location = 'weapons',
        Materials = {
            {
                Count = 2,
                Item = 'ironbar',
            },
            {
                Count = 2,
                Item = 'nails',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 1,
            },
        },
        Weapon = 'knife',
        Xp = 10,
    },
    {
        Amount = 1,
        Category = 'Arme',
        Id = 'weapons.bat',
        Item = 'weapon_bat',
        Jobs = {},
        Label = 'Bâtă',
        Level = 1,
        Location = 'weapons',
        Materials = {
            {
                Count = 2,
                Item = 'ironbar',
            },
            {
                Count = 2,
                Item = 'nails',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 1,
            },
        },
        Weapon = 'bat',
        Xp = 10,
    },
    {
        Amount = 1,
        Category = 'Arme',
        Id = 'weapons.flashlight',
        Item = 'weapon_flashlight',
        Jobs = {},
        Label = 'Lanternă',
        Level = 1,
        Location = 'weapons',
        Materials = {
            {
                Count = 2,
                Item = 'ironbar',
            },
            {
                Count = 2,
                Item = 'nails',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 1,
            },
        },
        Weapon = 'flashlight',
        Xp = 10,
    },
    {
        Amount = 1,
        Category = 'Arme',
        Id = 'weapons.revolver',
        Item = 'weapon_revolver',
        Jobs = {},
        Label = 'Revolver',
        Level = 3,
        Location = 'weapons',
        Materials = {
            {
                Count = 2,
                Item = 'ironbar',
            },
            {
                Count = 2,
                Item = 'nails',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 1,
            },
        },
        Weapon = 'revolver',
        Xp = 10,
    },
    {
        Amount = 1,
        Category = 'Arme',
        Id = 'weapons.pistol',
        Item = 'weapon_pistol',
        Jobs = {},
        Label = 'Pistol',
        Level = 3,
        Location = 'weapons',
        Materials = {
            {
                Count = 2,
                Item = 'ironbar',
            },
            {
                Count = 2,
                Item = 'nails',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 1,
            },
        },
        Weapon = 'pistol',
        Xp = 10,
    },
    {
        Amount = 1,
        Category = 'Arme',
        Id = 'weapons.combatpistol',
        Item = 'weapon_combatpistol',
        Jobs = {},
        Label = 'Pistol de luptă',
        Level = 5,
        Location = 'weapons',
        Materials = {
            {
                Count = 2,
                Item = 'ironbar',
            },
            {
                Count = 2,
                Item = 'nails',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 1,
            },
        },
        Weapon = 'combatpistol',
        Xp = 10,
    },
}
for _, recipe in ipairs(recipes) do
    Craft.Recipes[#Craft.Recipes + 1] = recipe
end
