-- Simulated domain receipts exercise retries, identity fencing and authoritative recipe validation.
local assertions = 0
local function check(value, message)
    assert(value, message)
    assertions = assertions + 1
end
function vector3(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, {
        __sub = function(a, b)
            return vector3(a.x - b.x, a.y - b.y, a.z - b.z)
        end,
        __len = function(a)
            return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
        end,
    })
end
dofile('config/shared.lua')
dofile('config/server.lua')
dofile('languages/ro.lua')
dofile('languages/en_us.lua')
dofile('locale.lua')
dofile('shared/utils.lua')
for _, name in ipairs({ 'food', 'refinery', 'tobacco', 'weapons', 'ammunitions', 'workshop' }) do
    dofile('config/recipes_' .. name .. '.lua')
end
for key in pairs(Locales.ro) do
    check(Locales.en_us[key], 'English key: ' .. key)
end
for key in pairs(Locales.en_us) do
    check(Locales.ro[key], 'Romanian key: ' .. key)
end
local ids = {}
for _, recipe in ipairs(Craft.Recipes) do
    check(not ids[recipe.Id], 'Recipe IDs unique')
    ids[recipe.Id] = true
    check(Craft.Location(recipe.Location), 'Recipe location exists')
    for _, material in ipairs(recipe.Materials) do
        check(material.Item:match('^[a-z0-9_]+$'), 'Materials use valid Inventory receipt names')
    end
end
local clock, distance, bucket, alive = 1000, 0, 0, true
os.time = function()
    return clock
end
function GetPlayerPed()
    return 1
end
function GetEntityHealth()
    return alive and 200 or 0
end
function GetPlayerRoutingBucket()
    return bucket
end
function GetEntityCoords()
    return Config.Locations[1].Coords + vector3(distance, 0, 0)
end
-- Add without changing vector implementation used above.
local mt = getmetatable(Config.Locations[1].Coords)
mt.__add = function(a, b)
    return vector3(a.x + b.x, a.y + b.y, a.z + b.z)
end
local who = { characterId = '00000000-0000-4000-8000-000000000001', sessionId = 'session1' }
local active, job, stock = true, true, { meat = 20, egg = 20, pan = 1, food_craftbook = 0 }
local definitions = {}
for index, name in ipairs({ 'consumable_breakfast', 'meat', 'egg', 'pan', 'food_craftbook' }) do
    definitions[name] = { id = index, instance_mode = 'stack' }
end
local orders, takes, grants, takeCount, grantCount, xp = {}, {}, {}, 0, 0, 0
local failMaterial, failGrant, failCollect, inFlight
local serial = 0
local function copy(t)
    if type(t) ~= 'table' then
        return t
    end
    local out = {}
    for k, v in pairs(t) do
        out[k] = copy(v)
    end
    return out
end
Craft.Db = {
    Uuid = function()
        serial = serial + 1
        return string.format('00000000-0000-4000-8000-%012d', serial)
    end,
    Xp = function()
        return xp
    end,
    List = function(cid)
        local rows = {}
        for _, row in pairs(orders) do
            if row.character_id == cid and row.state ~= 'collected' then
                rows[#rows + 1] = row
            end
        end
        return rows
    end,
    Request = function(cid, request)
        for _, row in pairs(orders) do
            if row.character_id == cid and row.request_id == request then
                return row
            end
        end
    end,
    Order = function(cid, id)
        local row = orders[id]
        return row and row.character_id == cid and row or nil
    end,
    Insert = function(id, cid, request, location, snapshot)
        orders[id] = {
            id = id,
            character_id = cid,
            request_id = request,
            location_id = location,
            snapshot = copy(snapshot),
            state = 'preparing',
            ready_at = 0,
        }
        return orders[id]
    end,
    Queue = function(order)
        order.state = 'queued'
        order.ready_at = clock + order.snapshot.Seconds
        return order
    end,
    Collected = function(order)
        if failCollect then
            failCollect = false
            error('lost DB acknowledgment')
        end
        order.state = 'collected'
        xp = xp + order.snapshot.Xp
    end,
}
Craft.Feather = {
    Session = function()
        return active and who or nil
    end,
    Current = function()
        return active
    end,
    Image = function(name)
        return 'https://cfx-nui-h4nr-craft/web/workbench.svg'
    end,
    Stock = function()
        local inventory = {}
        for name, count in pairs(stock) do
            inventory[name] = { count = count, plain = count, condition = 100 }
        end
        return Craft.Ok({ inventory = inventory, weapons = 0 })
    end,
    Definitions = function()
        return definitions
    end,
    Count = function(_, name)
        return stock[name] or 0
    end,
    Job = function()
        return job
    end,
    WeaponCount = function()
        return 0
    end,
    Tool = function(_, name)
        if (stock[name] or 0) > 0 then
            return { id = 10, revision = 0, definition = { id = 4, type = 'item_item' }, metadata = { condition = 100 } }
        end
    end,
    Take = function(_, _, order, index, material)
        local key = order.id .. ':' .. index
        if takes[key] then
            return Craft.Ok(true)
        end
        if inFlight then
            local fn = inFlight
            inFlight = nil
            fn()
        end
        if failMaterial == material.Item or (stock[material.Item] or 0) < material.Count then
            return Craft.Err('failure')
        end
        stock[material.Item] = stock[material.Item] - material.Count
        takes[key] = true
        takeCount = takeCount + 1
        return Craft.Ok(true)
    end,
    WearContract = function()
        return { ready = true, durableWear = 1, conditionKey = 'condition', conditionMaximum = 100 }
    end,
    Wear = function()
        return Craft.Ok({ state = 'used' })
    end,
    Grant = function(order)
        if failGrant then
            return Craft.Err('capacity')
        end
        if not grants[order.id] then
            grants[order.id] = true
            grantCount = grantCount + 1
        end
        return Craft.Ok(true)
    end,
}
local printed = print
print = function() end
Craft.Ready = true
dofile('server/services/crafting.lua')
dofile('server/rpc.lua')
local recipe = Craft.Recipes[1]
local params = {
    location = 'food',
    recipe = recipe.Id,
    amount = 2,
    requestId = 'test-request-1',
    characterId = who.characterId,
    sessionId = who.sessionId,
}
local function route(action, input)
    if input == nil then
        input = params
    end
    return Craft.Routes[action](input, 1)
end
check(route('start', false).code == 'bad_request', 'Non-table refused')
distance = 100
check(route('start').code == 'too_far', 'Cannot forge distance')
distance = 0
bucket = 3
check(route('start').code == 'wrong_instance', 'Wrong world has a distinct refusal even when beside the NPC')
bucket = 0
alive = false
check(route('start').code == 'player_unavailable', 'Unavailable player is not reported as a distance failure')
alive = true
local bad = copy(params)
bad.amount = 1.5
check(route('start', bad).code == 'bad_request', 'Fractional amount refused')
bad.amount = 999999
check(route('start', bad).code == 'bad_request', 'Oversized amount refused')
bad.amount = 0 / 0
check(route('start', bad).code == 'bad_request', 'NaN refused')
bad = copy(params)
bad.recipe = 'injected-output'
check(route('start', bad).code == 'bad_request', 'Unknown recipe refused')
job = false
check(route('start').code == 'wrong_job', 'Authoritative job refusal')
job = true
local level = recipe.Level
recipe.Level = 3
check(route('start').code == 'low_level', 'Authoritative XP requirement')
recipe.Level = level
local old = stock.meat
stock.meat = 0
check(route('start').code == 'missing_materials' and takeCount == 0, 'Preflight fails without consuming')
stock.meat = old
params.portable = true
check(route('start').code == 'book_required', 'Portable needs actual book')
stock.food_craftbook = 1
distance = 100
check(route('catalog').ok, 'Book explicitly authorizes portable catalog')
distance = 0
params.portable = false
-- Sorted materials debit egg first. The second fails; retry uses the same durable receipts.
failMaterial = 'meat'
check(route('start').code == 'pending', 'Partial preparation retained')
check(takeCount == 1 and stock.egg == 18, 'Only first material consumed')
local retained = Craft.Db.Request(who.characterId, params.requestId)
check(retained.state == 'preparing', 'Durable pending order is visible')
failMaterial = nil
inFlight = function()
    check(route('start').code == 'busy', 'Concurrent same-character request refused')
end
local started = route('start')
check(started.ok and takeCount == 2 and stock.egg == 18 and stock.meat == 18, 'Retry does not consume egg again')
check(started.value.ready_at == 1020, 'Duration is computed on server from batch count')
check(route('start').ok and takeCount == 2, 'Repeated start is idempotent')
bad = copy(params)
bad.amount = 1
check(route('start', bad).code == 'bad_request', 'Request identity binds original batch')
local collect = { location = 'food', id = started.value.id, characterId = who.characterId, sessionId = who.sessionId }
check(route('collect', collect).code == 'not_ready' and grantCount == 0, 'Early collection refused')
clock = 1020
local oldCid = who.characterId
who.characterId = 'other-character'
check(route('collect', collect).code == 'session_expired', 'Other character cannot collect')
who.characterId = oldCid
failGrant = true
check(route('collect', collect).code == 'no_space' and xp == 0, 'Capacity failure preserves output and XP')
failGrant = false
failCollect = true
check(
    route('collect', collect).code == 'pending' and grantCount == 1 and xp == 0,
    'Grant survives lost collection acknowledgment'
)
-- Simulate a resource restart: handlers/locks reset, durable queue and domain receipts survive.
dofile('server/services/crafting.lua')
dofile('server/rpc.lua')
check(
    route('collect', collect).ok and grantCount == 1 and xp == recipe.Xp * 2,
    'Restart retry grants once and awards XP once'
)
check(route('collect', collect).ok and grantCount == 1 and xp == recipe.Xp * 2, 'Collected order never pays twice')
-- Tool wear must use its original per-instance receipt even after a lost acknowledgment.
local originalTools = recipe.Tools
recipe.Tools = { { Item = 'pan', Wear = 10, Maximum = 100 } }
local wearReceipts, wearCount, loseWearReply = {}, 0, true
Craft.Feather.Wear = function(request)
    if not wearReceipts[request.operationId] then
        wearReceipts[request.operationId] = true
        wearCount = wearCount + 1
    end
    if loseWearReply then
        loseWearReply = false
        return Craft.Err('pending')
    end
    return Craft.Ok({ state = 'used', replayed = true })
end
params.requestId = 'test-tool-wear'
params.amount = 2
check(route('start').code == 'pending' and wearCount == 1, 'Wear acknowledgment loss retains preparing order')
local wornOrder = Craft.Db.Request(who.characterId, params.requestId)
check(wornOrder.snapshot.Wear[1].wear == 20, 'Tool wear scales with batch count')
check(route('start').ok and wearCount == 1, 'Wear retry replays the same operation exactly once')
recipe.Tools = originalTools
params.requestId = 'test-queue-limit'
local maxQueue = Config.MaxQueue
Config.MaxQueue = 0
check(route('start').code == 'queue_full', 'Queue limit is authoritative')
Config.MaxQueue = maxQueue
local badScope = copy(params)
badScope.sessionId = 'previous-session'
check(route('catalog', badScope).code == 'session_expired', 'Stale same-character session refused')
badScope = copy(params)
badScope.portable = 'yes'
check(route('catalog', badScope).code == 'bad_request', 'Portable scope must be boolean')
local outputDefinition = definitions[recipe.Item]
outputDefinition.max_quantity = 1
check(
    Craft.Service.Prepare(1, who, recipe, 2, Craft.Db.Uuid()).code == 'output_limit',
    'Impossible-to-collect batches are refused against the Inventory item limit'
)
outputDefinition.max_quantity = nil
-- Fixed workshops and knowledge books are enforced before any debit, even for forged portable requests.
local advanced = copy(recipe)
advanced.Id, advanced.Book, advanced.Portable = 'food.advanced-test', 'food_craftbook', false
Craft.Recipes[#Craft.Recipes + 1] = advanced
local gated = copy(params)
gated.recipe, gated.requestId, gated.amount, gated.portable = advanced.Id, 'advanced-gated', 1, true
local beforeTake = takeCount
check(
    route('start', gated).code == 'workshop_required' and takeCount == beforeTake,
    'Advanced recipes cannot be made portable by a client flag'
)
gated.portable = false
stock.food_craftbook = 0
check(
    route('start', gated).code == 'recipe_book_required' and takeCount == beforeTake,
    'Knowledge book required before materials are consumed'
)
stock.food_craftbook = 1
check(
    Craft.Service.Prepare(1, who, advanced, 1, Craft.Db.Uuid()).ok,
    'Holding book satisfies knowledge requirement at workshop'
)
check(
    Craft.Service.Access(1, Craft.Location('weapons'), true).code == 'workshop_required',
    'Weapons book cannot bypass workshop requirement'
)
check(
    Craft.Service.Access(1, Craft.Location('ammunitions'), true).code == 'workshop_required',
    'Ammunition needs workshop'
)
local preview = route('catalog')
check(
    preview.ok and preview.value.inventory.meat.count == stock.meat and preview.value.maxQueue == Config.MaxQueue,
    'Catalog carries owned stock and queue limits'
)
check(
    preview.value.recipes[1].JobAllowed == true and preview.value.recipes[1].Image ~= nil,
    'Catalog carries authoritative job eligibility and item image'
)
active = false
check(route('catalog').code == 'session_expired', 'Missing active session refused')
active = true
Craft.Ready = false
check(route('catalog').code == 'unavailable', 'Readiness fails closed')
Craft.Ready = true
check(Craft.Level(999) == 1 and Craft.Level(1000) == 2 and Craft.Level(999999999) == Config.MaxLevel, 'Level bounds')
print = printed
print(('Service: %d assertions passed'):format(assertions))
