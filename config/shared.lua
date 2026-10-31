-- Shared crafting locations in Los Santos; recipes are in recipes.lua.
Config = {
    DefaultLang = 'ro',
    Debug = false,
    HasCraftBooks = false, -- Offer free reference books at the benches.
    AllowPortableBooks = true, -- Holding a book authorizes its recipes away from a bench.
    Locations = {
        {
            Id = 'food',
            Label = 'Bucătărie',
            Coords = vector3(-1195.2, -893.8, 14.0),
            Heading = 305.0,
            Sprite = 52,
            Color = 3,
            Model = 's_m_y_chef_01',
            Book = 'food_craftbook',
        },
        {
            Id = 'refinery',
            Label = 'Atelier',
            Coords = vector3(472.6, -1310.4, 29.2),
            Heading = 110.0,
            Sprite = 566,
            Color = 3,
            Model = 's_m_y_construct_01',
            Book = 'refinery_craftbook',
        },
        {
            Id = 'tobacco',
            Label = 'Prelucrare tutun',
            Coords = vector3(1128.7, -989.6, 45.97),
            Heading = 275.0,
            Sprite = 496,
            Color = 3,
            Model = 'a_m_m_farmer_01',
            Book = 'tobacco_craftbook',
        },
        {
            Id = 'weapons',
            Label = 'Atelier arme',
            Coords = vector3(809.1, -2159.0, 29.62),
            Heading = 355.0,
            Sprite = 110,
            Color = 3,
            Model = 's_m_y_ammucity_01',
            Book = 'weapons_craftbook',
        },
        {
            Id = 'ammunitions',
            Label = 'Atelier muniție',
            Coords = vector3(845.5, -1030.1, 28.2),
            Heading = 180.0,
            Sprite = 110,
            Color = 3,
            Model = 's_m_y_ammucity_01',
            Book = 'ammo_craftbook',
        },
    },
}
