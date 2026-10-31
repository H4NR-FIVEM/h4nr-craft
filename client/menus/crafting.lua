-- Menu v2 pages; a persisted start request is retried with its original identity after timeouts.
Craft.Menu = {}
local U, M = Craft.Ui, Craft.Menu
local menuId, locationId, portable, characterId, sessionId
local busy = false
local function requireValue(result)
    if not result or not result.ok then
        error('Menu operation failed')
    end
    return result.value
end
function M.Close()
    local previous = menuId
    menuId, locationId, characterId, sessionId = nil, nil, nil, nil
    if previous and GetResourceState('feather-menu-v2') == 'started' then
        U.Menu('DestroyMenu', previous)
    end
end

local function current()
    local who = U.Session()
    return who and who.characterId == characterId and who.sessionId == sessionId
end
local function pendingKey(id)
    return 'h4nr-craft:pending:' .. id
end
local function savedRequest(id)
    local saved = GetResourceKvpString(pendingKey(id))
    if not saved then
        return nil
    end
    local decoded, request = pcall(json.decode, saved)
    if not decoded or type(request) ~= 'table' then
        error('Invalid pending crafting request')
    end
    return request
end
local function work(fn)
    if busy then
        return
    end
    busy = true
    CreateThread(function()
        local called, problem = xpcall(fn, debug.traceback)
        busy = false
        if not called then
            print('[h4nr-craft] ' .. tostring(problem))
            M.Close()
            U.Notify('unavailable')
        end
    end)
end
local function request(action, extra)
    if not current() then
        M.Close()
        return Craft.Err('session_expired')
    end
    local params = { location = locationId, portable = portable, characterId = characterId, sessionId = sessionId }
    for key, value in pairs(extra or {}) do
        params[key] = value
    end
    local result = U.Rpc(action, params)
    if not current() then
        M.Close()
        return Craft.Err('session_expired')
    end
    return result
end
local render
local function refresh()
    local result = request('catalog')
    if result.ok then
        render(result.value)
    else
        U.Notify(result.code)
    end
end
local function start(params)
    if not current() then
        M.Close()
        return
    end
    local cid = characterId
    params.characterId, params.sessionId = cid, sessionId
    SetResourceKvp(pendingKey(cid), json.encode(params))
    local result = U.Rpc('start', params)
    local refused = {
        bad_request = true,
        missing_materials = true,
        wrong_job = true,
        low_level = true,
        queue_full = true,
        too_far = true,
        book_required = true,
        missing_definition = true,
        no_space = true,
    }
    if result.ok or refused[result.code] then
        DeleteResourceKvp(pendingKey(cid))
    end
    if not current() then
        M.Close()
        return
    end
    U.Notify(result.ok and 'started' or result.code)
    refresh()
end
render = function(catalog)
    if catalog.characterId ~= characterId or catalog.sessionId ~= sessionId then
        M.Close()
        return
    end
    if menuId then
        local previous = menuId
        menuId = nil
        U.Menu('DestroyMenu', previous)
    end
    menuId = requireValue(U.Menu('CreateMenu', {
        key = 'crafting',
        closable = true,
        draggable = true,
        size = { width = '34rem', maxHeight = '85vh' },
        theme = { preset = 'modern' },
    })).menuId
    local id = menuId
    local main = requireValue(U.Menu('CreatePage', id, { key = 'main' })).pageId
    local function add(page, kind, spec, callback)
        return requireValue(U.Menu('AddElement', id, page, kind, spec, callback and function(event)
            if menuId == id and current() then
                callback(event)
            end
        end))
    end
    local function page(key, title)
        local pageId = requireValue(U.Menu('CreatePage', id, { key = key })).pageId
        add(pageId, 'header', { key = 'header', value = title, slot = 'header' })
        add(pageId, 'button', { key = 'back', label = _U('back'), slot = 'footer' }, function()
            U.Menu('NavigateToPage', id, main)
        end)
        return pageId
    end
    add(main, 'header', { key = 'header', value = Craft.Location(locationId).Label, slot = 'header' })
    add(main, 'textdisplay', { key = 'level', value = _U('level', catalog.level, catalog.xp) })
    local pending = savedRequest(characterId)
    if pending then
        add(main, 'button', { key = 'retry', label = _U('resume') }, function()
            work(function()
                -- Retry only at the original location and with the original batch; no replacement request ID.
                if pending.location ~= locationId then
                    U.Notify('too_far')
                    return
                end
                pending.portable = portable
                start(pending)
            end)
        end)
    end
    local queuePage = page('queue', _U('queue'))
    add(main, 'button', { key = 'queue', label = _U('queue') }, function()
        U.Menu('NavigateToPage', id, queuePage)
    end)
    add(queuePage, 'button', { key = 'refresh', label = _U('queue') }, function()
        work(refresh)
    end)
    if #catalog.queue == 0 then
        add(queuePage, 'textdisplay', { key = 'empty', value = _U('empty') })
    end
    for index, order in ipairs(catalog.queue) do
        add(
            queuePage,
            'textdisplay',
            { key = 'order-' .. index, value = _U('remaining', order.label, order.amount, order.remaining) }
        )
        if order.state == 'preparing' then
            add(queuePage, 'textdisplay', { key = 'pending-' .. index, value = _U('preparing') })
            add(queuePage, 'button', { key = 'resume-' .. index, label = _U('resume') }, function()
                work(function()
                    start({
                        location = locationId,
                        portable = portable,
                        recipe = order.recipe,
                        requestId = order.requestId,
                        amount = order.batches,
                    })
                end)
            end)
        elseif order.remaining == 0 then
            add(queuePage, 'button', { key = 'collect-' .. index, label = _U('collect') }, function()
                work(function()
                    local result = request('collect', { id = order.id })
                    U.Notify(result.ok and 'collected' or result.code)
                    if current() then
                        refresh()
                    end
                end)
            end)
        end
    end
    if Config.HasCraftBooks and not portable then
        add(main, 'button', { key = 'book', label = _U('book') }, function()
            work(function()
                local result = request('book')
                U.Notify(result.ok and 'bookReceived' or result.code)
            end)
        end)
    end
    for index, recipe in ipairs(catalog.recipes) do
        local recipePage = page('recipe-' .. index, recipe.Label)
        add(main, 'button', { key = 'recipe-' .. index, label = recipe.Category .. ' · ' .. recipe.Label }, function()
            U.Menu('NavigateToPage', id, recipePage)
        end)
        add(
            recipePage,
            'textdisplay',
            { key = 'info', value = _U('recipeInfo', recipe.Label, recipe.Seconds, recipe.Level, recipe.Xp) }
        )
        for number, material in ipairs(recipe.Materials) do
            add(
                recipePage,
                'textdisplay',
                { key = 'material-' .. number, value = _U('material', material.Item, material.Count) }
            )
        end
        for number, tool in ipairs(recipe.Tools) do
            add(recipePage, 'textdisplay', { key = 'tool-' .. number, value = _U('tool', tool.Item) })
        end
        local amount = 1
        add(recipePage, 'number', {
            key = 'amount',
            label = _U('amount'),
            value = 1,
            min = 1,
            max = recipe.Weapon and 1 or catalog.maxBatch,
            step = 1,
        }, function(event)
            amount = tonumber(event.value) or 1
        end)
        add(recipePage, 'button', { key = 'craft', label = _U('craft'), disabled = pending ~= nil }, function()
            work(function()
                if not current() then
                    M.Close()
                    return
                end
                local token = ('start:%s:%s:%s'):format(GetCloudTimeAsInt(), GetGameTimer(), math.random(1, 999999999))
                start({
                    location = locationId,
                    portable = portable,
                    recipe = recipe.Id,
                    amount = amount,
                    requestId = token,
                })
            end)
        end)
    end
    add(main, 'button', { key = 'close', label = _U('close'), slot = 'footer' }, M.Close)
    U.Menu('RegisterMenuLifecycle', id, function(event)
        if (event.event == 'closed' or event.event == 'suspended') and menuId == id then
            M.Close()
        end
    end)
    requireValue(U.Menu('OpenMenu', id, { pageId = main }))
end
function M.Open(location, useBook)
    work(function()
        M.Close()
        local who = U.Session()
        if not who or not who.characterId then
            return
        end
        locationId, portable = location, useBook == true
        characterId, sessionId = who.characterId, who.sessionId
        requireValue(U.Menu('AwaitReady', 5000))
        refresh()
    end)
end
function M.Monitor()
    if not menuId then
        return
    end
    local location = Craft.Location(locationId)
    if
        not current()
        or IsEntityDead(PlayerPedId())
        or (not portable and #(GetEntityCoords(PlayerPedId()) - location.Coords) > Config.PromptDistance + 1.5)
    then
        M.Close()
    end
end
