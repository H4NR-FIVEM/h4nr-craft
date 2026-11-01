-- Pure quantity, requirement and queue presentation calculations; the server still revalidates every mutation.
function Craft.Assess(recipe, batches, catalog, portable, pending)
    local result = {
        reasons = {},
        materials = {},
        tools = {},
        output = recipe.Amount * batches,
        seconds = recipe.Seconds * batches,
        xp = recipe.Xp * batches,
    }
    local found = {}
    local function refuse(code)
        if not found[code] then
            result.reasons[#result.reasons + 1] = code
            found[code] = true
        end
    end
    if
        not Craft.Integer(batches, 1, recipe.Weapon and 1 or (recipe.MaxBatch or catalog.maxBatch))
        or result.output > 100
    then
        refuse('bad_request')
    end
    if recipe.DefinitionReady == false then
        refuse('missing_definition')
    end
    if portable and recipe.Portable ~= true then
        refuse('workshop_required')
    end
    if catalog.level < recipe.Level then
        refuse('low_level')
    end
    if recipe.JobAllowed == false then
        refuse('wrong_job')
    end
    if recipe.Book and ((catalog.inventory[recipe.Book] or {}).count or 0) < 1 then
        refuse('recipe_book_required')
    end
    if recipe.Weapon and catalog.weaponCount >= catalog.maxWeapons then
        refuse('no_space')
    end
    if catalog.queueCount >= catalog.maxQueue then
        refuse('queue_full')
    end
    if pending then
        refuse('pending')
    end
    local totals, ordered = {}, {}
    for _, material in ipairs(recipe.Materials) do
        if not totals[material.Item] then
            ordered[#ordered + 1] = material.Item
            totals[material.Item] = 0
        end
        totals[material.Item] = totals[material.Item] + material.Count * batches
    end
    for _, name in ipairs(ordered) do
        local held = catalog.inventory[name] or {}
        local needed, owned = totals[name], held.plain or held.count or 0
        if needed > catalog.maxMaterialUnits then
            refuse('bad_request')
        end
        if owned < needed then
            refuse('missing_materials')
        end
        result.materials[#result.materials + 1] = {
            item = name,
            label = held.label or name,
            needed = needed,
            owned = owned,
            enough = owned >= needed,
        }
    end
    for _, tool in ipairs(recipe.Tools) do
        local held = catalog.inventory[tool.Item] or {}
        local wear = Craft.ToolWear(tool, batches)
        local condition = held.condition or 0
        local enough = (held.count or 0) > 0 and condition >= wear and wear <= 100
        if not enough then
            refuse('tool_unavailable')
        end
        result.tools[#result.tools + 1] = {
            item = tool.Item,
            label = held.label or tool.Item,
            wear = wear,
            condition = condition,
            enough = enough,
        }
    end
    result.canCraft = #result.reasons == 0
    return result
end
function Craft.Duration(seconds)
    seconds = math.max(0, math.ceil(seconds))
    return ('%02d:%02d:%02d'):format(math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end
function Craft.QueueRemaining(order, elapsed)
    return math.max(0, order.remaining - math.max(0, elapsed))
end
