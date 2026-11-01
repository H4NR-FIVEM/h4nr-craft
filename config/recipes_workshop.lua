-- Workshop families researched in ox_inventory and qb-crafting; see docs/recipe_sources.md.
-- Material substitutions use this server's existing catalog. These costs are our adapted balance.
local recipes = {
    {
        Key = 'lockpick',
        Label = 'Șperaclu',
        Amount = 2,
        Xp = 5,
        Level = 1,
        Seconds = 10,
        Materials = { { Item = 'ironbar', Count = 5 } },
        Tools = { { Item = 'hammer', Wear = 5, Maximum = 100 } },
    },
    {
        Key = 'screwdriverset',
        Label = 'Set de șurubelnițe',
        Amount = 1,
        Xp = 8,
        Level = 1,
        Seconds = 20,
        Materials = {
            { Item = 'ironbar', Count = 2 },
            { Item = 'copperbar', Count = 1 },
            { Item = 'nails', Count = 2 },
        },
        Tools = { { Item = 'hammer', Wear = 0, Maximum = 100 } },
    },
    {
        Key = 'repairkit',
        Label = 'Trusă de reparații',
        Amount = 1,
        Xp = 12,
        Level = 2,
        Seconds = 30,
        Materials = {
            { Item = 'ironbar', Count = 3 },
            { Item = 'copperbar', Count = 2 },
            { Item = 'nails', Count = 4 },
        },
        Tools = { { Item = 'hammer', Wear = 0, Maximum = 100 }, { Item = 'screwdriverset', Wear = 0, Maximum = 100 } },
    },
}
for _, location in ipairs({ 'workshop_industrial', 'workshop_central' }) do
    for _, entry in ipairs(recipes) do
        Craft.Recipes[#Craft.Recipes + 1] = {
            Id = location .. '.' .. entry.Key,
            Location = location,
            Category = 'Unelte și reparații',
            Item = entry.Key,
            Label = entry.Label,
            Amount = entry.Amount,
            Xp = entry.Xp,
            Level = entry.Level,
            Seconds = entry.Seconds,
            Materials = entry.Materials,
            Tools = entry.Tools,
            Jobs = {},
            Portable = false,
        }
    end
end
