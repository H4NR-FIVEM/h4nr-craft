-- Admission, durable preparation and collection. A failed step retains the same order for retry.
Craft.Service = {}
local S, F, D = Craft.Service, Craft.Feather, Craft.Db
function S.Access(src, location, portable)
    if not location then
        return Craft.Err('bad_request')
    end
    local ped = GetPlayerPed(src)
    if ped == 0 or GetEntityHealth(ped) <= 0 then
        return Craft.Err('too_far')
    end
    if portable then
        if location.Portable == false then
            return Craft.Err('workshop_required')
        end
        if not Config.AllowPortableBooks or F.Count(src, location.Book) < 1 then
            return Craft.Err('book_required')
        end
        return Craft.Ok(true)
    end
    if GetPlayerRoutingBucket(src) ~= 0 or #(GetEntityCoords(ped) - location.Coords) > Config.MaximumDistance then
        return Craft.Err('too_far')
    end
    return Craft.Ok(true)
end
function S.Resume(src, who, order)
    if order.state ~= 'preparing' then
        return Craft.Ok(order)
    end
    for index, material in ipairs(order.snapshot.Materials) do
        if not F.Current(src, who) then
            return Craft.Err('session_expired')
        end
        local result = F.Take(src, who, order, index, material)
        if not result.ok then
            return Craft.Err('pending')
        end
    end
    for _, request in ipairs(order.snapshot.Wear) do
        if not F.Current(src, who) then
            return Craft.Err('session_expired')
        end
        local result = F.Wear(request)
        if not result.ok or result.value.state ~= 'used' then
            return Craft.Err('pending')
        end
    end
    return Craft.Ok(D.Queue(order))
end
function S.Prepare(src, who, recipe, amount, orderId)
    local definitions = F.Definitions()
    local definition = definitions[recipe.Item]
    if not definition then
        return Craft.Err('missing_definition')
    end
    if not recipe.Weapon and definition.instance_mode ~= 'stack' then
        return Craft.Err('missing_definition')
    end
    if recipe.Book and F.Count(src, recipe.Book) < 1 then
        return Craft.Err('recipe_book_required')
    end
    if not F.Job(who.characterId, recipe.Jobs) then
        return Craft.Err('wrong_job')
    end
    if Craft.Level(D.Xp(who.characterId)) < recipe.Level then
        return Craft.Err('low_level')
    end
    if recipe.Weapon and (amount ~= 1 or F.WeaponCount(who.characterId) >= Config.MaxWeapons) then
        return Craft.Err('no_space')
    end
    local snapshot = {
        Portable = recipe.Portable == true,
        Batches = amount,
        Recipe = recipe.Id,
        Item = recipe.Item,
        Label = recipe.Label,
        Weapon = recipe.Weapon,
        Definition = tonumber(definition.id),
        Amount = recipe.Amount * amount,
        Seconds = recipe.Seconds * amount,
        Xp = recipe.Xp * amount,
        Materials = {},
        Wear = {},
    }
    if
        tonumber(definition.max_quantity)
        and tonumber(definition.max_quantity) > 0
        and snapshot.Amount > tonumber(definition.max_quantity)
    then
        return Craft.Err('output_limit')
    end
    if not Craft.Integer(snapshot.Amount, 1, 100) then
        return Craft.Err('bad_request')
    end
    local totals = {}
    for _, material in ipairs(recipe.Materials) do
        totals[material.Item] = (totals[material.Item] or 0) + material.Count * amount
    end
    local names = {}
    for name in pairs(totals) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local count, materialDefinition = totals[name], definitions[name]
        if not materialDefinition or materialDefinition.instance_mode ~= 'stack' then
            return Craft.Err('missing_definition')
        end
        if not Craft.Integer(count, 1, Config.MaxMaterialUnits) then
            return Craft.Err('bad_request')
        end
        if F.Count(src, name) < count then
            return Craft.Err('missing_materials')
        end
        snapshot.Materials[#snapshot.Materials + 1] = {
            Item = name,
            Definition = tonumber(materialDefinition.id),
            Count = count,
        }
    end
    for _, tool in ipairs(recipe.Tools) do
        local item = F.Tool(who.characterId, tool.Item)
        if not item then
            return Craft.Err('missing_materials')
        end
        if tool.Wear > 0 then
            local contract = F.WearContract()
            if
                contract.ready ~= true
                or contract.durableWear ~= 1
                or contract.conditionKey ~= 'condition'
                or contract.conditionMaximum ~= 100
                or item.definition.type ~= 'item_item'
            then
                return Craft.Err('missing_definition')
            end
            local wear = Craft.ToolWear(tool, amount)
            if (tonumber(item.metadata and item.metadata.condition) or 100) < wear or wear > 100 then
                return Craft.Err('missing_materials')
            end
            snapshot.Wear[#snapshot.Wear + 1] = {
                operationId = D.Uuid(),
                characterId = who.characterId,
                instanceId = tonumber(item.id),
                definitionId = tonumber(item.definition.id),
                expectedRevision = item.revision,
                itemName = tool.Item,
                purpose = 'craft.tool.v1',
                effectReference = orderId,
                wear = wear,
                maximumDurability = 100,
            }
        end
    end
    return Craft.Ok(snapshot)
end
function S.Start(src, who, params)
    if
        type(params.requestId) ~= 'string'
        or #params.requestId > 80
        or not params.requestId:match('^[A-Za-z0-9][A-Za-z0-9._:%-]+$')
    then
        return Craft.Err('bad_request')
    end
    local previous = D.Request(who.characterId, params.requestId)
    if previous then
        if params.portable and previous.snapshot.Portable ~= true then
            return Craft.Err('workshop_required')
        end
        if
            previous.location_id ~= params.location
            or previous.snapshot.Recipe ~= params.recipe
            or previous.snapshot.Batches ~= params.amount
        then
            return Craft.Err('bad_request')
        end
        return S.Resume(src, who, previous)
    end
    if not Craft.Integer(params.amount, 1, Config.MaxBatch) then
        return Craft.Err('bad_request')
    end
    if #D.List(who.characterId) >= Config.MaxQueue then
        return Craft.Err('queue_full')
    end
    local recipe
    for _, row in ipairs(Craft.Recipes) do
        if row.Id == params.recipe and row.Location == params.location then
            recipe = row
        end
    end
    if not recipe then
        return Craft.Err('bad_request')
    end
    if params.portable and recipe.Portable ~= true then
        return Craft.Err('workshop_required')
    end
    local id = D.Uuid()
    local prepared = S.Prepare(src, who, recipe, params.amount, id)
    if not prepared.ok then
        return prepared
    end
    if not F.Current(src, who) then
        return Craft.Err('session_expired')
    end
    local access = S.Access(src, Craft.Location(params.location), params.portable)
    if not access.ok then
        return access
    end
    local order = D.Insert(id, who.characterId, params.requestId, recipe.Location, prepared.value)
    return S.Resume(src, who, order)
end
function S.Collect(src, who, params)
    if type(params.id) ~= 'string' or #params.id ~= 36 then
        return Craft.Err('bad_request')
    end
    local order = D.Order(who.characterId, params.id)
    if not order then
        return Craft.Err('bad_request')
    end
    if params.portable and order.snapshot.Portable ~= true then
        return Craft.Err('workshop_required')
    end
    if order.state == 'collected' then
        return Craft.Ok(true)
    end
    if not Config.AllowGlobalCollection and order.location_id ~= params.location then
        return Craft.Err('too_far')
    end
    if order.state ~= 'queued' or os.time() < tonumber(order.ready_at) then
        return Craft.Err('not_ready')
    end
    if not F.Current(src, who) then
        return Craft.Err('session_expired')
    end
    local result = F.Grant(order)
    if not result.ok then
        return Craft.Err('no_space')
    end
    D.Collected(order)
    return Craft.Ok(true)
end
function S.Catalog(src, who, params)
    local recipes, inventory = {}, {}
    local definitions = F.Definitions()
    local stock = F.Stock(who.characterId)
    if not stock.ok then
        return stock
    end
    local wearContract = F.WearContract()
    local function inventoryRow(name)
        if inventory[name] then
            return inventory[name]
        end
        local definition = definitions[name]
        local held = stock.value.inventory[name] or {}
        local row = {
            count = held.count or 0,
            plain = held.plain or 0,
            condition = held.condition or 0,
            label = Config.DefaultLang == 'ro' and (Config.ItemLabels or {})[name]
                or (definition and definition.display_name or name),
            image = F.Image(name),
        }
        inventory[name] = row
        return row
    end
    for _, recipe in ipairs(Craft.Recipes) do
        if recipe.Location == params.location then
            local copy = {}
            for key, value in pairs(recipe) do
                copy[key] = value
            end
            local definition = definitions[recipe.Item]
            copy.Description = definition and definition.description or ''
            copy.Image = F.Image(recipe.Item)
            local limit = tonumber(definition and definition.max_quantity)
            copy.MaxBatch = math.min(
                Config.MaxBatch,
                math.floor(100 / recipe.Amount),
                limit and limit > 0 and math.floor(limit / recipe.Amount) or Config.MaxBatch
            )
            copy.DefinitionReady = definition ~= nil and (recipe.Weapon ~= nil or definition.instance_mode == 'stack')
            copy.JobAllowed = F.Job(who.characterId, recipe.Jobs)
            if recipe.Book then
                inventoryRow(recipe.Book)
            end
            for _, material in ipairs(recipe.Materials) do
                local materialDefinition = definitions[material.Item]
                if not materialDefinition or materialDefinition.instance_mode ~= 'stack' then
                    copy.DefinitionReady = false
                end
                inventoryRow(material.Item)
            end
            for _, tool in ipairs(recipe.Tools) do
                inventoryRow(tool.Item)
                local toolDefinition = definitions[tool.Item]
                if not toolDefinition then
                    copy.DefinitionReady = false
                end
                if tool.Wear > 0 then
                    if
                        not toolDefinition
                        or toolDefinition.type ~= 'item_item'
                        or wearContract.ready ~= true
                        or wearContract.durableWear ~= 1
                        or wearContract.conditionKey ~= 'condition'
                        or wearContract.conditionMaximum ~= 100
                    then
                        copy.DefinitionReady = false
                    end
                end
            end
            recipes[#recipes + 1] = copy
        end
    end
    local orders = D.List(who.characterId)
    local queue = {}
    for _, order in ipairs(orders) do
        if Config.AllowGlobalCollection or order.location_id == params.location then
            queue[#queue + 1] = {
                id = order.id,
                state = order.state,
                requestId = order.request_id,
                recipe = order.snapshot.Recipe,
                batches = order.snapshot.Batches,
                label = order.snapshot.Label,
                amount = order.snapshot.Amount,
                duration = order.snapshot.Seconds,
                portable = order.snapshot.Portable == true,
                image = F.Image(order.snapshot.Item),
                remaining = math.max(0, tonumber(order.ready_at) - os.time()),
            }
        end
    end
    local xp = D.Xp(who.characterId)
    return Craft.Ok({
        characterId = who.characterId,
        sessionId = who.sessionId,
        recipes = recipes,
        queue = queue,
        queueCount = #orders,
        maxQueue = Config.MaxQueue,
        inventory = inventory,
        weaponCount = stock.value.weapons,
        maxWeapons = Config.MaxWeapons,
        xp = xp,
        level = Craft.Level(xp),
        xpStep = Config.XpPerLevel,
        maxLevel = Config.MaxLevel,
        maxBatch = Config.MaxBatch,
        maxMaterialUnits = Config.MaxMaterialUnits,
    })
end

function S.Book(src, who, params)
    if not Config.HasCraftBooks or params.portable then
        return Craft.Err('bad_request')
    end
    local location = Craft.Location(params.location)
    if not location.Book then
        return Craft.Err('bad_request')
    end
    if F.Count(src, location.Book) > 0 then
        return Craft.Ok(true)
    end
    local definitions = F.Definitions()
    local definition = definitions[location.Book]
    if not definition or definition.instance_mode ~= 'stack' then
        return Craft.Err('missing_definition')
    end
    -- One free reference copy per character/station. This is an inventory object, not an unlock balance.
    local order = {
        id = 'book:' .. who.characterId .. ':' .. location.Id,
        character_id = who.characterId,
        snapshot = { Item = location.Book, Definition = tonumber(definition.id), Amount = 1 },
    }
    return F.Grant(order)
end
