-- BCC recipe port for tobacco; keep identifiers stable for pending orders.
local recipes = {
    {
        Amount = 3,
        Category = 'Tutun',
        Id = 'tobacco.loose_tobacco.1',
        Item = 'tobaccopipe',
        Jobs = {},
        Label = 'Tutun uscat',
        Level = 5,
        Location = 'tobacco',
        Materials = {
            {
                Count = 1,
                Item = 'tobacco_leafs',
            },
        },
        Seconds = 30,
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
        Category = 'Tutun',
        Id = 'tobacco.loose_tobacco.2',
        Item = 'cigar',
        Jobs = {},
        Label = 'Trabuc',
        Level = 10,
        Location = 'tobacco',
        Materials = {
            {
                Count = 3,
                Item = 'tobaccopipe',
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
        Amount = 5,
        Category = 'Tutun',
        Id = 'tobacco.loose_tobacco.3',
        Item = 'cigarette',
        Jobs = {},
        Label = 'Țigară',
        Level = 3,
        Location = 'tobacco',
        Materials = {
            {
                Count = 5,
                Item = 'tobaccopipe',
            },
            {
                Count = 5,
                Item = 'rollingpaper',
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
        Category = 'Tutun',
        Id = 'tobacco.loose_tobacco.4',
        Item = 'cigaret',
        Jobs = {},
        Label = 'Pachet de țigări',
        Level = 3,
        Location = 'tobacco',
        Materials = {
            {
                Count = 10,
                Item = 'cigarette',
            },
            {
                Count = 1,
                Item = 'paper',
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
