-- BCC recipe port for refinery; keep identifiers stable for pending orders.
local recipes = {
    {
        Amount = 1,
        Category = 'Rafinare',
        Id = 'refinery.refinery.1',
        Item = 'trainoil',
        Jobs = {},
        Label = 'Ulei',
        Level = 3,
        Location = 'refinery',
        Materials = {
            {
                Count = 10,
                Item = 'petroleum',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 10,
    },
    {
        Amount = 1,
        Category = 'Rafinare',
        Id = 'refinery.refinery.2',
        Item = 'petrol',
        Jobs = {},
        Label = 'Benzină',
        Level = 3,
        Location = 'refinery',
        Materials = {
            {
                Count = 10,
                Item = 'petroleum',
            },
        },
        Seconds = 40,
        Tools = {
            {
                Item = 'hammer',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 10,
    },
}
for _, recipe in ipairs(recipes) do
    Craft.Recipes[#Craft.Recipes + 1] = recipe
end
