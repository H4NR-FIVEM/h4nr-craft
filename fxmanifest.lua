fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'h4nr-craft'
author 'BCC Team, BCC-FeatherFramework, h4nr'
description 'Inventory-backed crafting queues, books and levels for Feather FiveM'
version '1.1.2'
shared_scripts {
    'config/shared.lua',
    'languages/ro.lua',
    'languages/en_us.lua',
    'locale.lua',
    'shared/utils.lua',
    'shared/workbench.lua',
    'config/recipes_food.lua',
    'config/recipes_refinery.lua',
    'config/recipes_tobacco.lua',
    'config/recipes_weapons.lua',
    'config/recipes_ammunitions.lua',
    'config/recipes_workshop.lua',
}
client_scripts {
    '@feather-theme/lib/bridge.lua',
    'config/client.lua',
    'client/feather.lua',
    'client/nui.lua',
    'client/menus/crafting.lua',
    'client/services/stations.lua',
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
    'feather-theme',
    'feather-character',
    'feather-inventory',
    'feather-jobs',
    'feather-weapons',
    'feather-toolkit',
    'feather-target',
    'feather-notify',
}

ui_page 'web/index.html'
files { 'web/index.html', 'web/style.css', 'web/app.js', 'web/workbench.svg' }
