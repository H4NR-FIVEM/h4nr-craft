-- Actual NUI/controller callbacks, simulated transport, focus and storage; no production inventory or data.
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local function copy(value)
    if type(value) ~= 'table' then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy(v)
    end
    return out
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
dofile('config/server.lua')
dofile('config/client.lua')
dofile('languages/ro.lua')
dofile('languages/en_us.lua')
dofile('locale.lua')
dofile('shared/utils.lua')
dofile('shared/workbench.lua')
dofile('config/recipes_food.lua')
local who = { characterId = 'char1', sessionId = 'session1' }
local clock, lastStart, response = 1000, nil, Craft.Ok(true)
local kvp, nui, messages = {}, {}, {}
local queue = {}
local recipes = copy(Craft.Recipes)
for _, recipe in ipairs(recipes) do
    recipe.JobAllowed, recipe.DefinitionReady = true, true
    recipe.Image = 'https://cfx-nui-feather-inventory/ui/images/items/'
        .. ((Config.ItemImages or {})[recipe.Item] or recipe.Item)
        .. '.png'
    recipe.Description = 'Preparat proaspăt la atelier.'
end
local held = {}
local labels = {
    meat = 'Carne',
    egg = 'Ou',
    pan = 'Tigaie',
    salt = 'Sare',
    biggame = 'Vânat mare',
    game = 'Vânat',
    mutton = 'Carne de oaie',
}
for _, recipe in ipairs(recipes) do
    for _, material in ipairs(recipe.Materials) do
        held[material.Item] = {
            count = 30,
            plain = 30,
            label = labels[material.Item] or material.Item,
            image = 'https://cfx-nui-feather-inventory/ui/images/items/'
                .. ((Config.ItemImages or {})[material.Item] or material.Item)
                .. '.png',
        }
    end
    for _, tool in ipairs(recipe.Tools) do
        held[tool.Item] = { count = 1, plain = 0, condition = 80, label = labels[tool.Item] or tool.Item }
    end
    if recipe.Book then
        held[recipe.Book] = { count = 1, label = 'Carte de rețete' }
    end
end
function CreateThread(fn)
    fn()
end
function RegisterNUICallback(name, fn)
    nui[name] = fn
end
function GetResourceState()
    return 'started'
end
function GetResourceKvpString(key)
    return kvp[key]
end
function SetResourceKvp(key, value)
    kvp[key] = copy(value)
end
function DeleteResourceKvp(key)
    kvp[key] = nil
end
function GetCloudTimeAsInt()
    return 100
end
function GetGameTimer()
    return clock
end
function IsEntityDead()
    return false
end
function PlayerPedId()
    return 1
end
function GetEntityCoords()
    return Config.Locations[1].Coords
end
json = { encode = copy, decode = copy }
local function catalog()
    return {
        characterId = who.characterId,
        sessionId = who.sessionId,
        recipes = copy(recipes),
        queue = copy(queue),
        level = 1,
        xp = 350,
        xpStep = 1000,
        maxLevel = 300,
        maxBatch = 10,
        maxMaterialUnits = 100,
        inventory = copy(held),
        queueCount = #queue,
        maxQueue = 12,
        weaponCount = 0,
        maxWeapons = 5,
    }
end
local lastNotify, collectCount, catalogCalls, focused = nil, 0, 0, false
Craft.Ui = {
    Session = function()
        return who
    end,
    Notify = function(key)
        lastNotify = key
    end,
    Send = function(message)
        messages[#messages + 1] = copy(message)
    end,
    Focus = function(value)
        focused = value
    end,
    Rpc = function(action, params)
        if action == 'catalog' then
            catalogCalls = catalogCalls + 1
            return Craft.Ok(catalog())
        end
        if action == 'start' then
            lastStart = copy(params)
            return response
        end
        if action == 'collect' then
            collectCount = collectCount + 1
        end
        return Craft.Ok(true)
    end,
}
local function view()
    for i = #messages, 1, -1 do
        if messages[i].action == 'workbench' then
            return messages[i]
        end
    end
end
local function invoke(name, extra)
    local payload = { nonce = view().nonce }
    for key, value in pairs(extra or {}) do
        payload[key] = value
    end
    local replies, result = 0, nil
    nui[name](payload, function(reply)
        replies = replies + 1
        result = reply
    end)
    check(replies == 1, 'NUI callback always answers once: ' .. name)
    return result
end
dofile('client/nui.lua')
dofile('client/menus/crafting.lua')
Craft.Menu.Open('food', false)
check(focused and Craft.Board.Active(), 'Workbench opens with NUI keyboard/mouse focus')
check(view().station.label == Config.Locations[1].Label and view().language == 'ro', 'Romanian station presentation')
local data = view().assessments[recipes[1].Id][3]
check(
    data.output == 3 and data.seconds == 30 and data.xp == 3,
    'Quantity assessments include output, time and XP totals'
)
check(data.materials[1].owned == 30 and data.materials[1].needed == 3, 'Owned versus required totals included')
check(data.tools[1].condition == 80 and data.canCraft, 'Tool condition and eligibility included')
local previewPath = os.getenv('CRAFT_PREVIEW_OUT')
if previewPath then
    local function encode(v)
        if type(v) == 'string' then
            return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
        end
        if type(v) ~= 'table' then
            return tostring(v)
        end
        local array = #v > 0
        local parts = {}
        if array then
            for _, child in ipairs(v) do
                parts[#parts + 1] = encode(child)
            end
        else
            for key, child in pairs(v) do
                parts[#parts + 1] = encode(tostring(key)) .. ':' .. encode(child)
            end
        end
        return (array and '[' or '{') .. table.concat(parts, ',') .. (array and ']' or '}')
    end
    local snapshot = copy(view())
    snapshot.catalog.queue = {
        {
            id = 'preview-ready',
            state = 'queued',
            label = 'Mic dejun',
            amount = 2,
            duration = 20,
            remaining = 0,
            portable = true,
        },
        {
            id = 'preview-working',
            state = 'queued',
            label = 'Carne la grătar',
            amount = 3,
            duration = 30,
            remaining = 18,
            portable = true,
        },
    }
    snapshot.catalog.queueCount = 2
    local f = assert(io.open(previewPath, 'w'))
    f:write(encode(snapshot))
    f:close()
end
local nonce = view().nonce
check(
    invoke('craft', { recipe = 'unknown', amount = 1 }).code == 'bad_request',
    'Unknown recipe rejected at NUI boundary'
)
check(invoke('craft', { recipe = recipes[1].Id, amount = 1.5 }).code == 'bad_request', 'Fractional batch rejected')
response = Craft.Err('pending')
check(invoke('craft', { recipe = recipes[1].Id, amount = 3 }).ok, 'Eligible request forwarded')
check(lastStart.amount == 3 and lastStart.recipe == recipes[1].Id, 'Only recipe identity and amount forwarded')
local requestId = lastStart.requestId
check(kvp['h4nr-craft:pending:char1'] and view().pending, 'Timeout retains original request journal')
check(
    invoke('craft', { recipe = recipes[1].Id, amount = 1 }).code == 'pending',
    'Pending request cannot be overwritten through NUI'
)
response = Craft.Ok(true)
check(invoke('retry').ok, 'Retry action succeeds')
check(
    lastStart.requestId == requestId and not kvp['h4nr-craft:pending:char1'],
    'Retry reuses identity and clears on success'
)
check(view().nonce == nonce, 'Refresh preserves the interface instance')
response = Craft.Err('missing_materials')
invoke('craft', { recipe = recipes[1].Id, amount = 3 })
check(not kvp['h4nr-craft:pending:char1'], 'Definitive refusal clears client journal')
held.meat.plain = 1
invoke('refresh')
check(not view().assessments[recipes[1].Id][3].canCraft, 'Inventory refresh updates per-quantity eligibility')
held.meat.plain = 30
queue = {
    { id = 'order1', state = 'queued', label = 'Mic dejun', amount = 3, duration = 30, remaining = 2, portable = true },
}
invoke('refresh')
local syncs = catalogCalls
clock = clock + 2000
Craft.Menu.Monitor()
local tick = messages[#messages]
check(tick.action == 'queueTick' and tick.elapsed == 2, 'Countdown receives local elapsed time')
check(catalogCalls == syncs, 'Countdown does not poll server every second')
check(invoke('collect', { id = 'unknown' }).code == 'bad_request', 'Unknown queue ID rejected')
invoke('collect', { id = 'order1' })
check(collectCount == 1, 'Collection routed to server controller')
who = { characterId = 'char2', sessionId = 'session2' }
lastStart = nil
check(
    invoke('craft', { recipe = recipes[1].Id, amount = 1 }).code == 'session_expired' and not lastStart,
    'Old NUI cannot act across session switch'
)
Craft.Menu.Close()
check(not focused and not Craft.Board.Active(), 'Close releases focus')
Craft.Menu.Open('food', false)
check(view().nonce ~= nonce, 'Each opening receives a new UI instance nonce')
check(
    invoke('close', { nonce = nonce }).code == 'session_expired' and focused,
    'Delayed close from old interface cannot close a new one'
)
invoke('close')
check(not focused, 'Close callback releases focus')
local replies = 0
nui.craft(false, function(result)
    replies = replies + 1
    check(not result.ok, 'Malformed closed callback refused')
end)
check(replies == 1, 'Malformed callback still answers once')
print(('Client: %d assertions passed (actual NUI/controller callbacks)'):format(checks))
