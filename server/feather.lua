-- All server-side Feather calls. Inventory owns definitions, units, wear and receipts.
Craft.Feather = {}
local F = Craft.Feather
local api
function F.Call(resource, operation, ...)
    local args = table.pack(...)
    local called, result = pcall(function()
        local provider = exports[resource]
        return provider[operation](provider, table.unpack(args, 1, args.n))
    end)
    if not called or type(result) ~= 'table' or type(result.ok) ~= 'boolean' then
        print(('[h4nr-craft] %s:%s unavailable'):format(resource, operation))
        return Craft.Err('pending')
    end
    return result
end
function F.Session(src)
    local result = F.Call('feather-core', 'GetSessionContext', src)
    local who = result.ok and result.value
    if type(who) ~= 'table' or type(who.characterId) ~= 'string' or who.state == 'leaving' then
        return nil
    end
    return who
end
function F.Current(src, who)
    return exports['feather-core']:IsSessionCurrent(src, who.sessionId, who.characterId) == true
end
function F.Ready()
    local result = F.Call('feather-inventory', 'AwaitReady', 30000)
    if not result.ok then
        return result
    end
    api = exports['feather-inventory']:initiate()
    return Craft.Ok(true)
end
function F.Definitions()
    local result = api and api.Items.GetDefinitions()
    local rows = {}
    if not result or not result.ok then
        return rows
    end
    for _, definition in ipairs(result.value or {}) do
        if definition.archived_at == nil then
            rows[definition.name] = definition
        end
    end
    return rows
end
function F.Count(src, name)
    local result = api and api.Items.GetItemCount(name, src)
    return result and result.ok and tonumber(result.value) or 0
end
function F.Tool(characterId, name)
    local inventory = F.Call('feather-inventory', 'GetCharacterInventory', characterId)
    if not inventory.ok then
        return nil
    end
    local result = api.Instances.FindInstances(inventory.value.id, name)
    if not result or not result.ok then
        return nil
    end
    table.sort(result.value, function(a, b)
        return tonumber(a) < tonumber(b)
    end)
    for _, id in ipairs(result.value) do
        local item = api.Instances.GetItemForCharacter(characterId, id)
        if item and item.ok and item.value.inventoryId == inventory.value.id then
            return item.value
        end
    end
end
function F.Job(characterId, jobs)
    if not jobs or #jobs == 0 then
        return true
    end
    for _, entry in ipairs(jobs) do
        local key = type(entry) == 'table' and entry[1] or entry
        local grade = type(entry) == 'table' and entry[2] or 0
        local result = F.Call('feather-jobs', 'CheckAssignment', {
            characterId = characterId,
            jobKey = key,
            minGradeOrdinal = grade,
            dutyState = Config.RequireOnDuty and 'on_duty' or nil,
        })
        if result.ok and result.value.matched then
            return true
        end
    end
    return false
end
function F.WeaponCount(characterId)
    local inventory = F.Call('feather-inventory', 'GetCharacterInventory', characterId)
    if not inventory.ok then
        return Config.MaxWeapons
    end
    local result = api.Inventory.GetInventoryItems(inventory.value.id)
    if not result or not result.ok then
        return Config.MaxWeapons
    end
    local count = 0
    for _, row in ipairs(result.value) do
        if type(row.name) == 'string' and row.name:sub(1, 7) == 'weapon_' then
            count = count + 1
        end
    end
    return count
end
function F.Take(src, who, order, index, material)
    return F.Call('feather-inventory', 'TakeCharacterItemOnce', {
        takeId = 'craft:' .. order.id .. ':material:' .. index,
        characterId = who.characterId,
        definitionId = material.Definition,
        itemName = material.Item,
        quantity = material.Count,
        source = src,
        sessionId = who.sessionId,
    })
end
function F.WearContract()
    local called, contract = pcall(function()
        return exports['feather-inventory']:GetConsumptionContract()
    end)
    return called and type(contract) == 'table' and contract or {}
end
function F.Wear(request)
    return F.Call('feather-inventory', 'WearCharacterItemOnce', request)
end
function F.Grant(order)
    local snapshot = order.snapshot
    if snapshot.Weapon then
        return F.Call('feather-weapons', 'IssueWeapon', {
            requestId = 'craft:' .. order.id,
            characterId = order.character_id,
            definitionId = snapshot.Weapon,
            purpose = 'crafting',
        }, {})
    end
    return F.Call('feather-inventory', 'GrantCharacterItemOnce', {
        grantId = 'craft:' .. order.id,
        characterId = order.character_id,
        definitionId = snapshot.Definition,
        itemName = snapshot.Item,
        quantity = snapshot.Amount,
    })
end
function F.RegisterBooks()
    for _, location in ipairs(Config.Locations) do
        if F.Definitions()[location.Book] then
            local result = api.Items.RegisterUsableItem(location.Book, function(_, src)
                api.Inventory.CloseInventory(src)
                TriggerClientEvent('h4nr-craft:client:book', src, location.Id)
                return Craft.Ok(true)
            end)
            if not result or not result.ok then
                print('[h4nr-craft] could not register book ' .. location.Book)
            end
        end
    end
end
function F.RegisterRpc(name, handler)
    return exports['feather-core']:RegisterRpc(name, handler, {
        requireCharacter = true,
        windowMs = 1000,
        maxCalls = 6,
        maxPayloadBytes = 1024,
        maxDepth = 2,
        maxNodes = 20,
    })
end
