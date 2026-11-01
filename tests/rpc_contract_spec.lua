-- Run the Craft boundaries through Core's real RPC registration, Contract 1 wrapper and transport dispatch.
local core = '../../[feather]/feather-core/'
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local events, emitted, coreExports = {}, {}, {}
local invoking
local who = { characterId = 'owned-character', sessionId = 'session', accountId = 'account' }
local ticks = 1000
GetCurrentResourceName = function()
    return 'feather-core'
end
GetInvokingResource = function()
    return invoking
end
GetGameTimer = function()
    return ticks
end
IsOnServer = function()
    return true
end
IsCallable = function(value)
    return type(value) == 'function'
end
CoreLogging = {
    Create = function()
        return {}
    end,
}
Config = { DevMode = false, DefaultLang = 'ro', RPCRateLimit = { windowMs = 1000, maxCalls = 100 } }
json = {
    encode = function()
        return '{}'
    end,
}
RegisterNetEvent = function() end
RegisterCommand = function() end
AddEventHandler = function(name, fn)
    events[name] = fn
end
TriggerClientEvent = function(name, target, ...)
    emitted[#emitted + 1] = { name = name, target = target, values = { ... } }
end
CoreSessions = {
    Get = function()
        return CoreResults.Ok(who)
    end,
    IsCurrent = function(src, sid, cid)
        return src == 42 and sid == who.sessionId and cid == who.characterId
    end,
}
exports = setmetatable({}, {
    __call = function(_, name, callback)
        coreExports[name] = callback
    end,
})
dofile(core .. 'shared/services/results.lua')
dofile(core .. 'shared/services/arpc.lua')
dofile(core .. 'server/services/rpc_contract.lua')
-- Actual Cfx exports carry an implicit receiver for colon calls.
exports['feather-core'] = setmetatable({
    GetSessionContext = function()
        return CoreResults.Ok(who)
    end,
    IsSessionCurrent = function(_, ...)
        return CoreSessions.IsCurrent(...)
    end,
}, {
    __index = function(_, name)
        return function(_, ...)
            return assert(coreExports[name], name)(...)
        end
    end,
})
dofile('languages/ro.lua')
dofile('languages/en_us.lua')
dofile('locale.lua')
dofile('shared/utils.lua')
dofile('server/feather.lua')
local access = true
local calls = {}
Craft.Location = function(id)
    return id == 'food' and { Id = id } or nil
end
Craft.Service = {
    Access = function()
        return access and Craft.Ok(true) or Craft.Err('too_far')
    end,
}
for _, action in ipairs({ 'Catalog', 'Start', 'Collect', 'Book' }) do
    Craft.Service[action] = function(src, context)
        check(src == 42 and context.characterId == who.characterId, 'Core dispatch passes the real caller')
        calls[action] = (calls[action] or 0) + 1
        return Craft.Ok({ action = action })
    end
end
Craft.Ready = true
invoking = 'h4nr-craft'
dofile('server/rpc.lua')
check(not RPCAPI.RegisterContract('h4nr-craft:catalog', function() end).ok, 'Core rejects original unversioned name')
Craft.RegisterRoutes()
local registered = {}
for _, row in ipairs(RPCAPI.GetRoutes()) do
    registered[row.route] = row
end
for _, action in ipairs({ 'catalog', 'start', 'collect', 'book' }) do
    local route = registered[Craft.Route(action)]
    check(route and route.contract == 1 and route.owner == 'h4nr-craft', 'Craft route registered as owned Contract 1')
    check(
        route.direction == 'client_to_server' and route.requireCharacter,
        'Route retains identity requirement and direction'
    )
end
local requestId = 0
local function dispatch(name, payload)
    ticks = ticks + 1001
    requestId = requestId + 1
    source = 42
    events['Feather:Call'](requestId, name, payload)
    local reply = emitted[#emitted]
    check(reply and reply.target == 42 and reply.values[1] == requestId, 'Reply targets requesting player')
    check(CoreResults.Is(reply.values[2]), 'Actual Core wrapper accepts Craft response envelope')
    return reply.values[2]
end
local payload = { location = 'food', characterId = who.characterId, sessionId = who.sessionId }
for _, action in ipairs({ 'catalog', 'start', 'collect', 'book' }) do
    check(dispatch(Craft.Route(action), payload).ok, 'Route dispatch succeeds: ' .. action)
end
access = false
local refused = dispatch(Craft.Route('catalog'), payload)
check(
    refused.code == 'too_far' and refused.message == _U('too_far'),
    'Localized Craft failure survives Core response validation'
)
check(calls.Catalog == 1, 'Access denial never invokes the service')
access = true
local stale = { location = 'food', characterId = who.characterId, sessionId = 'old-session' }
check(dispatch(Craft.Route('catalog'), stale).code == 'session_expired', 'Stale-session error survives transport')
check(dispatch(Craft.Route('catalog'), {}).code == 'bad_request', 'Bad-request error survives transport')
Craft.Ready = false
check(dispatch(Craft.Route('catalog'), payload).code == 'unavailable', 'Readiness error survives transport')
Craft.Ready = true
-- Load the real client boundary and dispatch its selected name through Core too.
local lastClientRoute
exports['feather-core'].CallRPCAsync = function(_, name, params)
    lastClientRoute = name
    return dispatch(name, params)
end
dofile('client/feather.lua')
check(
    Craft.Ui.Rpc('catalog', payload).ok and lastClientRoute == Craft.Route('catalog'),
    'Client and server use identical versioned route'
)
local registeredAgain, problem = pcall(Craft.RegisterRoutes)
check(
    not registeredAgain and problem:find('conflict', 1, true) and problem:find('already registered', 1, true),
    'Registration diagnostics preserve Core code and message'
)
-- Core removes consumer-owned routes on resource stop, permitting a clean restart.
events.onResourceStop('h4nr-craft')
check(pcall(Craft.RegisterRoutes), 'Consumer can register again after Core owner cleanup')
print(('RPC contract: %d assertions passed (actual Feather Core registration and dispatch)'):format(checks))
