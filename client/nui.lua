-- Craft-owned NUI boundary. Each action is scoped to the currently displayed workbench instance.
Craft.Board = {}
local B, U = Craft.Board, Craft.Ui
local active, nonce, sequence, catalog, actions, station, portable, fetchedAt, retainedRequest = false, nil, 0
local function sendView(retained)
    local assessments = {}
    for _, recipe in ipairs(catalog.recipes) do
        assessments[recipe.Id] = {}
        for amount = 1, math.max(1, recipe.Weapon and 1 or (recipe.MaxBatch or catalog.maxBatch)) do
            assessments[recipe.Id][amount] = Craft.Assess(recipe, amount, catalog, portable, retained)
        end
    end
    local messages = {}
    for key, value in pairs(Locales.en_us) do
        messages[key] = value
    end
    for key, value in pairs(Locales[Config.DefaultLang] or {}) do
        messages[key] = value
    end
    U.Send({
        action = 'workbench',
        nonce = nonce,
        station = { id = station.Id, label = station.Label },
        catalog = catalog,
        language = Config.DefaultLang,
        portable = portable,
        pending = retained ~= nil,
        assessments = assessments,
        messages = messages,
        hasBooks = Config.HasCraftBooks and station.Book ~= nil,
    })
end
function B.Active()
    return active
end
function B.Close()
    active, nonce, actions = false, nil, nil
    U.Focus(false)
    U.Send({ action = 'close' })
end
function B.Update(view, retained)
    if not active then
        return
    end
    catalog, fetchedAt, retainedRequest = view, GetGameTimer(), retained
    sendView(retained)
end
function B.Queue()
    if active then
        U.Send({ action = 'queueTick', elapsed = math.max(0, math.floor((GetGameTimer() - fetchedAt) / 1000)) })
    end
end
function B.Open(view, useBook, retained, location, callbacks)
    B.Close()
    sequence = sequence + 1
    nonce = ('workbench:%s:%s'):format(GetGameTimer(), sequence)
    active, catalog, portable, station, actions, fetchedAt, retainedRequest =
        true, view, useBook, location, callbacks, GetGameTimer(), retained
    sendView(retained)
    U.Focus(true)
end
local function findOrder(id)
    for _, order in ipairs(catalog.queue) do
        if order.id == id then
            return order
        end
    end
end
local function handle(name, data)
    if not active or type(data) ~= 'table' or data.nonce ~= nonce or not actions.current() then
        return Craft.Err('session_expired')
    end
    if name == 'close' then
        actions.close()
        return Craft.Ok(true)
    end
    if name == 'craft' then
        if type(data.recipe) ~= 'string' or not Craft.Integer(data.amount, 1, catalog.maxBatch) then
            return Craft.Err('bad_request')
        end
        local recipe
        for _, row in ipairs(catalog.recipes) do
            if row.Id == data.recipe then
                recipe = row
            end
        end
        if not recipe then
            return Craft.Err('bad_request')
        end
        local assessment = Craft.Assess(recipe, data.amount, catalog, portable, retainedRequest)
        if not assessment.canCraft then
            return Craft.Err(assessment.reasons[1])
        end
        actions.craft(data.recipe, data.amount)
    elseif name == 'collect' or name == 'resume' then
        local order = type(data.id) == 'string' and findOrder(data.id)
        if not order then
            return Craft.Err('bad_request')
        end
        if name == 'collect' then
            actions.collect(order.id)
        else
            actions.resume(order)
        end
    elseif name == 'book' then
        actions.book()
    elseif name == 'refresh' then
        actions.refresh()
    elseif name == 'retry' then
        actions.retry()
    else
        return Craft.Err('bad_request')
    end
    return Craft.Ok(true)
end
for _, name in ipairs({ 'close', 'craft', 'collect', 'resume', 'book', 'refresh', 'retry' }) do
    RegisterNUICallback(name, function(data, cb)
        local called, result = xpcall(handle, debug.traceback, name, data)
        if not called then
            print('[h4nr-craft] NUI action ' .. name .. ' failed: ' .. tostring(result))
            cb(Craft.Err('unavailable'))
        else
            cb(result)
        end
    end)
end
