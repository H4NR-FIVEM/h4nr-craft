-- Limits are server-only. Duration is always measured from server admission.
Config.MaximumDistance = 3.5 -- metres, OneSync server coordinates
Config.MaxBatch = 10
Config.MaxQueue = 12
Config.MaxMaterialUnits = 100 -- maximum per material per operation, Inventory contract bound
Config.RequireOnDuty = false
Config.AllowGlobalCollection = false
Config.MaxWeapons = 5
Config.XpPerLevel = 1000
Config.MaxLevel = 300

-- Presentation aliases reuse existing Inventory assets; no item ownership/data changes.
Config.ItemImages = {
    consumable_breakfast = 'consumable_meat_prime_beef_cooked',
    cooked_biggame = 'consumable_big_game_meat_wild_mint_cooked',
    cooked_game = 'consumable_game_meat_oregano_cooked',
    cooked_venison = 'consumable_mature_venison_thyme_cooked',
    cooked_mutton = 'consumable_meat_gristly_mutton_cooked',
    cooked_pork = 'consumable_meat_tender_pork_cooked',
    cooked_bird = 'consumable_meat_plump_bird_cooked',
    consumable_bluegil = 'cooked_fish',
    meat = 'provision_meat_prime_beef',
    egg = 'provision_duck_egg',
    mutton = 'provision_meat_gristly_mutton',
    bird = 'provision_meat_plump_bird',
    fish = 'provision_fish_meat',
    ironbar = 'ls_iron_ingot',
    copperbar = 'ls_copper_ingot',
    tobacco_leafs = 'consumable_herb_indian_tobacco',
    tobaccopipe = 'kit_tobacco_pipe',
    cigar = 'consumable_cigar',
    cigarette = 'emote_action_smoke_cigarette',
    cigaret = 'consumable_cigarette_box_cheap',
    rollingpaper = 'rolling_paper',
}
Config.ItemLabels = {
    meat = 'Carne',
    egg = 'Ou',
    pan = 'Tigaie',
    salt = 'Sare',
    biggame = 'Vânat mare',
    game = 'Vânat',
    venison = 'Carne de cerb',
    mutton = 'Carne de oaie',
    pork = 'Carne de porc',
    bird = 'Carne de pasăre',
    fish = 'Pește',
    hammer = 'Ciocan',
    ironbar = 'Lingou de fier',
    copperbar = 'Lingou de cupru',
    nails = 'Cuie',
    gunpowder = 'Praf de pușcă',
    petroleum = 'Petrol brut',
    tobacco_leafs = 'Frunze de tutun',
    tobaccopipe = 'Tutun uscat',
    rollingpaper = 'Foițe',
    paper = 'Hârtie',
}
