fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'h4nr-craft'
author 'BCC Team, BCC-FeatherFramework, h4nr'
description 'Inventory-backed crafting queues, books and levels for Feather FiveM'
version '1.0.0'
shared_scripts {
    'config/shared.lua',
    'languages/ro.lua',
    'languages/en_us.lua',
    'locale.lua',
    'shared/utils.lua',
    'config/recipes_food.lua',
    'config/recipes_refinery.lua',
    'config/recipes_tobacco.lua',
    'config/recipes_weapons.lua',
    'config/recipes_ammunitions.lua',
}
client_scripts {
    'config/client.lua',
    'client/feather.lua',
    'client/menus/crafting.lua',
    'client/main.lua',
}
server_scripts {
    '@feather-mysql/lib/DB.lua',
    'config/server.lua',
    'server/feather.lua',
    'server/database.lua',
    'server/services/crafting.lua',
    'server/rpc.lua',
    'server/main.lua',
}
dependencies {
    '/onesync',
    'feather-mysql',
    'feather-core',
    'feather-character',
    'feather-inventory',
    'feather-jobs',
    'feather-weapons',
    'feather-toolkit',
    'feather-notify',
    'feather-menu-v2',
}
