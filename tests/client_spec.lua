-- Exercise the actual menu callbacks and local timeout journal without Cfx or NUI.
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
function vector3(x, y, z)
    return { x = x, y = y, z = z }
end
dofile('config/shared.lua')
dofile('config/server.lua')
dofile('languages/ro.lua')
dofile('languages/en_us.lua')
dofile('locale.lua')
dofile('shared/utils.lua')
dofile('config/recipes_food.lua')
local who = { characterId = 'char1', sessionId = 'session1' }
local kvp, menus, pages, callbacks = {}, {}, {}, {}
local nextId, activeMenu, destroyed, lastStart, startResponse, lastLifecycle = 0, nil, 0, nil, Craft.Ok(true)
local queue = {}
function CreateThread(fn)
    fn()
end
function GetResourceState()
    return 'started'
end
function GetResourceKvpString(key)
    return kvp[key]
end
function SetResourceKvp(key, value)
    kvp[key] = value
end
function DeleteResourceKvp(key)
    kvp[key] = nil
end
function GetCloudTimeAsInt()
    return 100
end
function GetGameTimer()
    return nextId
end
json = {
    encode = function(value)
        return value
    end,
    decode = function(value)
        return value
    end,
}
local lastNotify
Craft.Ui = {
    Session = function()
        return who
    end,
    Notify = function(key)
        lastNotify = key
    end,
    Rpc = function(action, params)
        if action == 'catalog' then
            return Craft.Ok({
                characterId = who.characterId,
                sessionId = who.sessionId,
                recipes = { Craft.Recipes[1] },
                queue = queue,
                level = 1,
                xp = 0,
                maxBatch = 10,
            })
        elseif action == 'start' then
            lastStart = params
            return startResponse
        end
        return Craft.Ok(true)
    end,
    Menu = function(operation, ...)
        local args = { ... }
        if operation == 'AwaitReady' then
            return Craft.Ok(true)
        end
        if operation == 'CreateMenu' then
            check(args[1].theme.preset == 'modern', 'Neon Vice modern preset')
            nextId = nextId + 1
            activeMenu = nextId
            menus[activeMenu] = args[1]
            callbacks[activeMenu] = {}
            pages[activeMenu] = {}
            return Craft.Ok({ menuId = activeMenu })
        end
        local id = args[1]
        if operation == 'CreatePage' then
            pages[id][args[2].key] = args[2].key
            return Craft.Ok({ pageId = args[2].key })
        elseif operation == 'AddElement' then
            check(menus[id] and pages[id][args[2]], 'Elements target an existing owned menu/page')
            local key = args[2] .. ':' .. args[4].key
            callbacks[id][key] = args[5]
            return Craft.Ok({ elementId = key })
        elseif operation == 'RegisterMenuLifecycle' then
            lastLifecycle = args[2]
            return Craft.Ok(true)
        elseif operation == 'DestroyMenu' then
            check(menus[id], 'Destroy only a live menu')
            menus[id] = nil
            destroyed = destroyed + 1
            if lastLifecycle then
                lastLifecycle({ event = 'closed' })
            end
            return Craft.Ok(true)
        elseif operation == 'OpenMenu' or operation == 'NavigateToPage' then
            check(menus[id] and pages[id][args[2].pageId or args[2]], 'Navigation targets a live page')
            return Craft.Ok(true)
        end
        error('Unhandled Menu operation ' .. operation)
    end,
}
dofile('client/menus/crafting.lua')
Craft.Menu.Open('food', false)
check(menus[activeMenu] and not lastNotify, 'Menu opens')
local firstMenu = activeMenu
startResponse = Craft.Err('pending')
callbacks[activeMenu]['recipe-1:craft']()
check(
    lastStart and lastStart.recipe == Craft.Recipes[1].Id and lastStart.amount == 1,
    'Only server recipe ID and batch requested'
)
check(kvp['h4nr-craft:pending:char1'] and lastNotify == 'pending', 'Timeout retains stable pending request')
local requestId = lastStart.requestId
check(callbacks[activeMenu]['main:retry'], 'Pending request is reviewable/retryable')
startResponse = Craft.Ok(true)
callbacks[activeMenu]['main:retry']()
check(
    lastStart.requestId == requestId and not kvp['h4nr-craft:pending:char1'],
    'Retry retains original identity and clears only on success'
)
check(activeMenu ~= firstMenu and destroyed >= 2, 'Refresh destroys the previous menu without lifecycle recursion')
startResponse = Craft.Err('missing_materials')
callbacks[activeMenu]['recipe-1:craft']()
check(not kvp['h4nr-craft:pending:char1'], 'Definitive pre-admission refusal does not trap the UI')
local oldCallback = callbacks[activeMenu]['recipe-1:craft']
who = { characterId = 'char2', sessionId = 'session2' }
lastStart = nil
oldCallback()
check(not lastStart, 'Retained callback cannot submit for a different session')
Craft.Menu.Close()
check(not menus[activeMenu], 'Close releases the menu')
Craft.Menu.Open('food', false)
lastLifecycle({ event = 'closed' })
check(not menus[activeMenu], 'Escape lifecycle releases menu state')
print(('Client: %d assertions passed'):format(checks))
