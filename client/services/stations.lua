-- Streamed NPC targets and optional NPC-free station zones. Each option is removed before its entity.
Craft.Stations = {}
local S, U = Craft.Stations, Craft.Ui
local peds, zones = {}, {}
local function optionName(location)
    return 'h4nr-craft:open:' .. location.Id
end
local function available(location)
    return not Craft.Board.Active()
        and not IsEntityDead(PlayerPedId())
        and #(GetEntityCoords(PlayerPedId()) - location.Coords) <= Config.InteractDistance + 0.5
end
local function option(location, valid)
    local function canInteract()
        return valid() and available(location)
    end
    return {
        name = optionName(location),
        label = _U('open'),
        icon = 'wrench',
        distance = Config.InteractDistance,
        canInteract = canInteract,
        onSelect = function()
            if canInteract() then
                Craft.Menu.Open(location.Id, false)
            end
        end,
    }
end
local function attachPed(location, record)
    if record.targeted or GetResourceState('feather-target') ~= 'started' then
        return
    end
    local result = U.TargetEntity(
        record.entity,
        optionName(location),
        option(location, function()
            return peds[location.Id] == record and DoesEntityExist(record.entity)
        end)
    )
    record.targeted = result and result.ok == true
    if not record.targeted then
        print('[h4nr-craft] target registration failed for ' .. location.Id)
    end
end
local function removePed(location)
    local record = peds[location.Id]
    if not record then
        return
    end
    peds[location.Id] = nil -- invalidate callbacks before yielding to the owning resources
    U.RemoveTargetEntity(record.entity, optionName(location))
    U.Toolkit('RemoveEntity', record.id)
end
local function addZone(location)
    if zones[location.Id] or GetResourceState('feather-target') ~= 'started' then
        return
    end
    local result = U.TargetZone(
        optionName(location),
        location.Coords,
        option(location, function()
            return zones[location.Id] == true
        end)
    )
    zones[location.Id] = result and result.ok == true or nil
end
local function removeZone(location)
    if not zones[location.Id] then
        return
    end
    zones[location.Id] = nil
    U.RemoveTargetZone(optionName(location))
end
function S.Update()
    local coords = GetEntityCoords(PlayerPedId())
    for _, location in ipairs(Config.Locations) do
        local near = #(coords - location.Coords) < Config.SpawnDistance
        if not Config.ShowNpcs then
            removePed(location)
            if near then
                addZone(location)
            else
                removeZone(location)
            end
        else
            removeZone(location)
            local record = peds[location.Id]
            if record and (not near or not DoesEntityExist(record.entity)) then
                removePed(location)
                record = nil
            end
            if near and not record then
                local result = U.Toolkit('CreatePed', {
                    model = location.Model,
                    x = location.Coords.x,
                    y = location.Coords.y,
                    z = location.Coords.z - 1.0,
                    heading = location.Heading,
                    networked = false,
                    timeoutMs = 3000,
                })
                if result and result.ok then
                    record = { id = result.value.id, entity = result.value.entity }
                    peds[location.Id] = record
                    SetEntityInvincible(record.entity, true)
                    FreezeEntityPosition(record.entity, true)
                    SetBlockingOfNonTemporaryEvents(record.entity, true)
                    TaskStartScenarioInPlace(record.entity, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                end
            end
            if record then
                attachPed(location, record)
            end
        end
    end
end
function S.TargetStopped()
    for _, record in pairs(peds) do
        record.targeted = false
    end
    zones = {}
end
function S.Cleanup()
    for _, location in ipairs(Config.Locations) do
        removePed(location)
        removeZone(location)
    end
end
