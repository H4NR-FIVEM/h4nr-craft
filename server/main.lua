-- Startup fails closed; pending orders remain durable across resource restarts.
Craft.Ready = false
CreateThread(function()
    local called, problem = xpcall(function()
        Craft.Db.Migrate()
        local result = Craft.Feather.Ready()
        assert(result.ok, 'Inventory is unavailable')
        Craft.RegisterRoutes()
        Craft.Feather.RegisterBooks()
        Craft.Ready = true
    end, debug.traceback)
    if not called then
        print('[h4nr-craft] startup failed: ' .. tostring(problem))
    end
end)
AddEventHandler('onResourceStart', function(resource)
    if resource ~= 'feather-inventory' then
        return
    end
    Craft.Ready = false
    CreateThread(function()
        local result = Craft.Feather.Ready()
        if result.ok then
            Craft.Feather.RegisterBooks()
            Craft.Ready = true
        end
    end)
end)
RegisterCommand('CraftReleaseSmokeTest', function(src)
    if src ~= 0 then
        return
    end
    local definitions = Craft.Feather.Definitions()
    local missing = {}
    for _, recipe in ipairs(Craft.Recipes) do
        if not definitions[recipe.Item] then
            missing[recipe.Item] = true
        end
        for _, material in ipairs(recipe.Materials) do
            if not definitions[material.Item] then
                missing[material.Item] = true
            end
        end
        for _, tool in ipairs(recipe.Tools) do
            if not definitions[tool.Item] then
                missing[tool.Item] = true
            end
        end
    end
    for _, location in ipairs(Config.Locations) do
        if location.Book and not definitions[location.Book] then
            missing[location.Book] = true
        end
    end
    local count = 0
    for name in pairs(missing) do
        count = count + 1
        print('[h4nr-craft] missing definition: ' .. name)
    end
    print(
        ('[h4nr-craft] ready=%s recipes=%d missing=%d; no items granted'):format(
            tostring(Craft.Ready),
            #Craft.Recipes,
            count
        )
    )
end, true)
