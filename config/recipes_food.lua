-- BCC recipe port for food; keep identifiers stable for pending orders.
local recipes = {
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.1',
        Item = 'consumable_breakfast',
        Portable = true,
        Jobs = {},
        Label = 'Mic dejun',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'meat',
            },
            {
                Count = 1,
                Item = 'egg',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.2',
        Item = 'steak',
        Portable = true,
        Jobs = {},
        Label = 'Carne la grătar',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'meat',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.3',
        Item = 'cooked_biggame',
        Portable = false,
        Book = 'food_craftbook',
        Jobs = {},
        Label = 'Vânat mare cu sare',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'biggame',
            },
            {
                Count = 1,
                Item = 'salt',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.4',
        Item = 'cooked_game',
        Portable = false,
        Book = 'food_craftbook',
        Jobs = {},
        Label = 'Vânat cu sare',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'game',
            },
            {
                Count = 1,
                Item = 'salt',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.5',
        Item = 'cooked_venison',
        Portable = false,
        Book = 'food_craftbook',
        Jobs = {},
        Label = 'Preparat din cerb',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'venison',
            },
            {
                Count = 1,
                Item = 'salt',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.6',
        Item = 'cooked_mutton',
        Portable = false,
        Book = 'food_craftbook',
        Jobs = {},
        Label = 'Preparat din oaie',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'mutton',
            },
            {
                Count = 1,
                Item = 'salt',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.7',
        Item = 'cooked_pork',
        Portable = false,
        Book = 'food_craftbook',
        Jobs = {},
        Label = 'Preparat din porc',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'pork',
            },
            {
                Count = 1,
                Item = 'salt',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.8',
        Item = 'cooked_bird',
        Portable = false,
        Book = 'food_craftbook',
        Jobs = {},
        Label = 'Preparat din pasăre',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'bird',
            },
            {
                Count = 1,
                Item = 'salt',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
    {
        Amount = 1,
        Category = 'Preparate din carne',
        Id = 'food.meat.9',
        Item = 'consumable_bluegil',
        Portable = false,
        Book = 'food_craftbook',
        Jobs = {},
        Label = 'Preparat din pește',
        Level = 1,
        Location = 'food',
        Materials = {
            {
                Count = 1,
                Item = 'fish',
            },
            {
                Count = 1,
                Item = 'salt',
            },
        },
        Seconds = 10,
        Tools = {
            {
                Item = 'pan',
                Maximum = 100,
                Wear = 0,
            },
        },
        Xp = 1,
    },
}
for _, recipe in ipairs(recipes) do
    Craft.Recipes[#Craft.Recipes + 1] = recipe
end
