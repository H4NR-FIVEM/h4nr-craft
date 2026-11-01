-- Client boundary for RPC, sessions, NUI, notifications and Toolkit-owned entities.
Craft.Ui = {}
local U = Craft.Ui
local toolkit = exports['feather-toolkit']
-- Presentation-only snapshot: Core's client session export is a network RPC.
-- Never call it every frame. Server handlers still validate the live session on every action.
local sessionSnapshot, lastReadAt, lastGoodAt
local readingSession = false
local function elapsed(now, previous)
    return previous and (now - previous) % 4294967296 or math.huge
end
function U.Session()
    local now = GetGameTimer()
    if GetResourceState('feather-core') ~= 'started' then
        sessionSnapshot = nil
        return nil
    end
    if readingSession or elapsed(now, lastReadAt) < 1000 then
        return elapsed(now, lastGoodAt) < 3000 and sessionSnapshot or nil
    end
    readingSession, lastReadAt = true, now
    local called, result = pcall(function()
        return exports['feather-core']:GetSessionContext()
    end)
    readingSession = false
    now = GetGameTimer()
    if called and result and result.ok and type(result.value) == 'table' then
        if result.value.state == 'leaving' then
            sessionSnapshot = nil
            return nil
        end
        sessionSnapshot, lastGoodAt = result.value, now
    else
        local code = type(result) == 'table' and result.code
        if code == 'character_required' or code == 'unauthenticated' or elapsed(now, lastGoodAt) >= 3000 then
            sessionSnapshot = nil
        end
    end
    return sessionSnapshot
end

function U.Rpc(action, params)
    local result = exports['feather-core']:CallRPCAsync(Craft.Route(action), params, nil, 30000)
    return type(result) == 'table' and result or Craft.Err('pending')
end
function U.Notify(key)
    local message = _U(key)
    if message == key then
        message = _U('unavailable')
    end
    U.Send({
        action = 'notice',
        message = message,
        success = key == 'started' or key == 'collected' or key == 'bookReceived',
    })
    exports['feather-notify']:ShowNotification({ style = 'right', message = message, duration = 5000 })
end
function U.Toolkit(operation, ...)
    return toolkit[operation](toolkit, ...)
end

function U.Focus(enabled)
    SetNuiFocusKeepInput(false)
    SetNuiFocus(enabled, enabled)
end
function U.Send(message)
    SendNUIMessage(message)
end

function U.TargetEntity(entity, name, option)
    return exports['feather-target']:AddEntity(entity, { option })
end
function U.RemoveTargetEntity(entity, name)
    if GetResourceState('feather-target') == 'started' then
        return exports['feather-target']:RemoveEntity(entity, name)
    end
end
function U.TargetZone(name, coords, option)
    return exports['feather-target']:AddSphereZone(name, { coords = coords, radius = 0.7, options = { option } })
end
function U.RemoveTargetZone(name)
    if GetResourceState('feather-target') == 'started' then
        return exports['feather-target']:RemoveZone(name)
    end
end
