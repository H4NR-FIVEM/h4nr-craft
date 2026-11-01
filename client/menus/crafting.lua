-- Session-scoped workbench controller. The request journal survives timeout, close and reconnect.
Craft.Menu = {}
local M, B, U = Craft.Menu, Craft.Board, Craft.Ui
local locationId, portable, characterId, sessionId
local busy, generation, lastSync, lastTick = false, 0, 0, 0
local function current()
    local who = U.Session()
    return characterId and who and who.characterId == characterId and who.sessionId == sessionId
end
local function pendingKey(cid)
    return 'h4nr-craft:pending:' .. cid
end
local function savedRequest()
    local saved = characterId and GetResourceKvpString(pendingKey(characterId))
    if not saved then
        return nil
    end
    local decoded, request = pcall(json.decode, saved)
    if not decoded or type(request) ~= 'table' then
        error('Invalid pending crafting request')
    end
    return request
end
function M.Close()
    generation = generation + 1
    locationId, characterId, sessionId = nil, nil, nil
    B.Close()
end
local function work(fn)
    if busy then
        return
    end
    busy = true
    U.Send({ action = 'busy', value = true })
    CreateThread(function()
        local called, problem = xpcall(fn, debug.traceback)
        busy = false
        U.Send({ action = 'busy', value = false })
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
    local epoch = generation
    local params = { location = locationId, portable = portable, characterId = characterId, sessionId = sessionId }
    for key, value in pairs(extra or {}) do
        params[key] = value
    end
    local result = U.Rpc(action, params)
    if generation ~= epoch then
        return Craft.Err('session_expired')
    end
    if not current() then
        M.Close()
        return Craft.Err('session_expired')
    end
    return result
end
local function refresh()
    local result = request('catalog')
    if result.ok then
        if result.value.characterId ~= characterId or result.value.sessionId ~= sessionId then
            M.Close()
            return
        end
        lastSync = GetGameTimer()
        B.Update(result.value, savedRequest())
    elseif current() then
        U.Notify(result.code)
    end
end
local function start(params)
    if not current() then
        return
    end
    local cid = characterId
    params.characterId, params.sessionId = cid, sessionId
    SetResourceKvp(pendingKey(cid), json.encode(params))
    local result = request('start', params)
    local refused = {
        bad_request = true,
        output_limit = true,
        missing_materials = true,
        wrong_job = true,
        low_level = true,
        queue_full = true,
        too_far = true,
        wrong_instance = true,
        player_unavailable = true,
        book_required = true,
        recipe_book_required = true,
        workshop_required = true,
        missing_definition = true,
        no_space = true,
    }
    if result.ok or refused[result.code] then
        DeleteResourceKvp(pendingKey(cid))
    end
    if current() then
        U.Notify(result.ok and 'started' or result.code)
        refresh()
    end
end
local function retry(params)
    if not params then
        return
    end
    if params.location ~= locationId then
        U.Notify('resumeElsewhere')
        return
    end
    params.portable = portable
    start(params)
end
local function callbacks()
    return {
        current = current,
        close = M.Close,
        refresh = function()
            work(refresh)
        end,
        retry = function()
            work(function()
                retry(savedRequest())
            end)
        end,
        craft = function(recipe, amount)
            work(function()
                if not current() then
                    return
                end
                local token = ('start:%s:%s:%s'):format(GetCloudTimeAsInt(), GetGameTimer(), math.random(1, 999999999))
                start({
                    location = locationId,
                    portable = portable,
                    recipe = recipe,
                    amount = amount,
                    requestId = token,
                })
            end)
        end,
        collect = function(orderId)
            work(function()
                local result = request('collect', { id = orderId })
                if current() then
                    U.Notify(result.ok and 'collected' or result.code)
                    refresh()
                end
            end)
        end,
        resume = function(order)
            work(function()
                retry({
                    location = locationId,
                    portable = portable,
                    recipe = order.recipe,
                    amount = order.batches,
                    requestId = order.requestId,
                })
            end)
        end,
        book = function()
            work(function()
                local result = request('book')
                if current() then
                    U.Notify(result.ok and 'bookReceived' or result.code)
                    refresh()
                end
            end)
        end,
    }
end
function M.Open(location, useBook)
    work(function()
        M.Close()
        local who = U.Session()
        if not who or not who.characterId then
            return
        end
        locationId, portable, characterId, sessionId = location, useBook == true, who.characterId, who.sessionId
        local result = request('catalog')
        if not result.ok then
            if current() then
                U.Notify(result.code)
            end
            M.Close()
            return
        end
        if result.value.characterId ~= characterId or result.value.sessionId ~= sessionId then
            M.Close()
            return
        end
        if not current() then
            M.Close()
            return
        end
        lastSync, lastTick = GetGameTimer(), GetGameTimer()
        B.Open(result.value, portable, savedRequest(), Craft.Location(locationId), callbacks())
    end)
end
function M.Monitor()
    if not B.Active() then
        return
    end
    local location = Craft.Location(locationId)
    if
        not current()
        or IsEntityDead(PlayerPedId())
        or (not portable and #(GetEntityCoords(PlayerPedId()) - location.Coords) > Config.MenuCloseDistance)
    then
        M.Close()
        return
    end
    local now = GetGameTimer()
    if now - lastTick >= 1000 then
        lastTick = now
        B.Queue()
    end
    if not busy and now - lastSync >= Config.CatalogRefreshMs then
        work(refresh)
    end
end
