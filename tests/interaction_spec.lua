-- Real client boundary, controller and Target registry: session RPC budget and streamed NPC lifecycle.
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
function vector3(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, {
        __sub = function(a, b)
            return vector3(a.x - b.x, a.y - b.y, a.z - b.z)
        end,
        __len = function(v)
            return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
        end,
    })
end
dofile('config/shared.lua')
dofile('config/client.lua')
dofile('languages/ro.lua')
dofile('languages/en_us.lua')
dofile('locale.lua')
dofile('shared/utils.lua')
dofile('../../[feather]/feather-target/client/registry.lua')
local ticks, reads, mode = 0, 0, 'ok'
local who = { characterId = 'character1', sessionId = 'session1', state = 'ready' }
local states = { ['feather-core'] = 'started', ['feather-target'] = 'started' }
local coords = Config.Locations[1].Coords
local exists, nextEntity, pedCreates, pedRemoves = {}, 100, 0, 0
local order = {}
function GetGameTimer()
    return ticks
end
function GetResourceState(name)
    return states[name] or 'started'
end
function GetCurrentResourceName()
    return 'h4nr-craft'
end
function PlayerPedId()
    return 1
end
function GetEntityCoords()
    return coords
end
function IsEntityDead()
    return false
end
function DoesEntityExist(entity)
    return exists[entity] == true
end
function SetEntityInvincible() end
function FreezeEntityPosition() end
function SetBlockingOfNonTemporaryEvents() end
function TaskStartScenarioInPlace() end
function CreateThread(fn)
    fn()
end
function GetResourceKvpString()
    return nil
end
function SendNUIMessage() end
function SetNuiFocus() end
function SetNuiFocusKeepInput() end
exports = {
    ['feather-core'] = {
        GetSessionContext = function()
            reads = reads + 1
            if mode ~= 'ok' then
                return Craft.Err(mode)
            end
            return Craft.Ok({ characterId = who.characterId, sessionId = who.sessionId, state = who.state })
        end,
    },
    ['feather-toolkit'] = {
        CreatePed = function()
            nextEntity = nextEntity + 1
            exists[nextEntity] = true
            pedCreates = pedCreates + 1
            return Craft.Ok({ id = nextEntity, entity = nextEntity })
        end,
        RemoveEntity = function(_, id)
            order[#order + 1] = 'ped:' .. id
            exists[id] = false
            pedRemoves = pedRemoves + 1
            return Craft.Ok(true)
        end,
    },
    ['feather-target'] = {
        AddEntity = function(_, entity, options)
            return TargetRegistry.AddEntity(entity, options, 'h4nr-craft')
        end,
        RemoveEntity = function(_, entity, name)
            order[#order + 1] = 'target:' .. entity
            return TargetRegistry.RemoveEntity(entity, name)
        end,
        AddSphereZone = function(_, name, spec)
            return TargetRegistry.AddSphereZone(name, spec, 'h4nr-craft')
        end,
        RemoveZone = function(_, name)
            return TargetRegistry.RemoveZone(name)
        end,
    },
}
dofile('client/feather.lua')
local U = Craft.Ui
for _ = 1, 100 do
    check(U.Session().sessionId == 'session1', 'Repeated UI identity checks retain valid context')
end
check(reads == 1, 'One session RPC for a burst of one hundred UI checks')
ticks = 1001
mode = 'rate_limited'
check(U.Session().sessionId == 'session1', 'Brief Core throttle does not masquerade as logout')
check(reads == 2, 'Throttled read is retried at bounded frequency')
ticks = 3001
check(U.Session() == nil, 'An unresolved outage expires the display snapshot')
mode = 'ok'
ticks = 4002
check(U.Session().sessionId == 'session1', 'Session can recover after a transient outage')
ticks = 5003
mode = 'character_required'
check(U.Session() == nil, 'Confirmed logout invalidates the snapshot immediately')
mode = 'ok'
ticks = 6004
local closes, opened, active = 0, 0, false
Craft.Board = {
    Active = function()
        return active
    end,
    Close = function()
        closes = closes + 1
        active = false
    end,
    Open = function()
        opened = opened + 1
        active = true
    end,
    Update = function() end,
    Queue = function() end,
}
U.Rpc = function()
    return Craft.Ok({ characterId = who.characterId, sessionId = who.sessionId })
end
U.Notify = function() end
dofile('client/menus/crafting.lua')
Craft.Menu.Open('food', false)
check(active and opened == 1, 'Actual controller opens with bounded identity reads')
local baselineCloses, baselineReads = closes, reads
for _ = 1, 120 do
    ticks = ticks + 5
    Craft.Menu.Monitor()
end
check(active and closes == baselineCloses, 'Actual monitor keeps workbench open through the first half-second')
check(reads == baselineReads, 'Monitoring does not flood Core with frame-by-frame RPCs')
ticks = ticks + 1001
who = { characterId = 'character2', sessionId = 'session2', state = 'ready' }
Craft.Menu.Monitor()
check(not active, 'A confirmed character switch still closes the workbench')
-- Actual streamed station implementation uses the real Target registry.
local opens = {}
Craft.Menu.Open = function(location, portable)
    opens[#opens + 1] = { location = location, portable = portable }
end
dofile('client/services/stations.lua')
Craft.Stations.Update()
check(pedCreates == 1, 'Only the nearby station NPC is spawned')
local entity = nextEntity
local function collect(hit)
    return TargetRegistry.Collect(
        { rayStart = coords, rayEnd = coords, playerCoords = coords, entity = hit, entityType = 'ped', model = 1 },
        Config.InteractDistance
    )
end
local found = collect(entity)
check(#found == 1 and found[1].option.icon == 'wrench', 'NPC exposes crafting through actual Feather Target collection')
local beforeReads = reads
for _ = 1, 100 do
    collect(entity)
end
check(reads == beforeReads, 'Target visibility never makes session RPCs')
found[1].option.onSelect({ entity = entity })
check(opens[1].location == 'food' and opens[1].portable == false, 'Target opens its configured station')
active = true
check(#collect(entity) == 0, 'Target action is hidden while crafting NUI owns focus')
active = false
local oldOption = found[1].option
coords = vector3(9000, 9000, 1000)
Craft.Stations.Update()
check(
    pedRemoves == 1 and order[1] == 'target:' .. entity and order[2] == 'ped:' .. entity,
    'Despawn removes target before deleting the NPC'
)
oldOption.onSelect({ entity = entity })
check(#opens == 1, 'Retained option cannot open a despawned station')
coords = Config.Locations[1].Coords
Craft.Stations.Update()
entity = nextEntity
check(#collect(entity) == 1 and pedCreates == 2, 'Returning streams a fresh NPC and exactly one option')
TargetRegistry.RemoveResource('h4nr-craft')
Craft.Stations.TargetStopped()
check(#collect(entity) == 0, 'Target resource loss removes the option')
Craft.Stations.Update()
check(#collect(entity) == 1 and pedCreates == 2, 'Target restart reattaches without duplicating the NPC')
Craft.Stations.Cleanup()
check(#collect(entity) == 0 and pedRemoves == 2, 'Resource cleanup removes entity interactions')
Config.ShowNpcs = false
Craft.Stations.Update()
local zone = TargetRegistry.Collect({ rayStart = coords, rayEnd = coords, playerCoords = coords }, 2)
check(
    #zone == 1 and zone[1].zone == 'h4nr-craft:open:food',
    'NPC-free mode provides a target zone instead of an E prompt'
)
Craft.Stations.Cleanup()
check(
    #TargetRegistry.Collect({ rayStart = coords, rayEnd = coords, playerCoords = coords }, 2) == 0,
    'NPC-free target zone is cleaned up'
)
print(('Interaction: %d assertions passed (actual client boundary, monitor and Target registry)'):format(checks))
