-- GTA ambient stations, streamed NPCs and Toolkit E prompts; cleanup owns every handle.
local U = Craft.Ui
local blips, peds = {}, {}
local prompt
local GROUP_ID = 48541
CreateThread(function()
    local result =
        U.Toolkit('CreatePrompt', { control = Config.InteractControl, label = _U('open'), groupId = GROUP_ID })
    if result and result.ok then
        prompt = result.value.id
    end
    if Config.ShowBlips then
        for _, location in ipairs(Config.Locations) do
            local blip = AddBlipForCoord(location.Coords.x, location.Coords.y, location.Coords.z)
            SetBlipSprite(blip, location.Sprite)
            SetBlipColour(blip, location.Color)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(location.Label)
            EndTextCommandSetBlipName(blip)
            blips[#blips + 1] = blip
        end
    end
    while true do
        local sleep = 750
        local coords = GetEntityCoords(PlayerPedId())
        if not IsEntityDead(PlayerPedId()) then
            for _, location in ipairs(Config.Locations) do
                if #(coords - location.Coords) < Config.PromptDistance then
                    sleep = 0 -- Toolkit prompt completion is tied to the frame showing this group.
                    if prompt then
                        U.Toolkit('ShowPromptGroup', GROUP_ID, location.Label)
                        local completed = U.Toolkit('IsPromptCompleted', prompt)
                        if completed and completed.ok and completed.value.completed then
                            Craft.Menu.Open(location.Id, false)
                        end
                    end
                    break
                end
            end
        end
        Craft.Menu.Monitor()
        Wait(sleep)
    end
end)
CreateThread(function()
    while true do
        if Config.ShowNpcs then
            local coords = GetEntityCoords(PlayerPedId())
            for _, location in ipairs(Config.Locations) do
                local near = #(coords - location.Coords) < Config.SpawnDistance
                if near and not peds[location.Id] then
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
                        local ped = result.value.entity
                        SetEntityInvincible(ped, true)
                        FreezeEntityPosition(ped, true)
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                        peds[location.Id] = result.value.id
                    end
                elseif not near and peds[location.Id] then
                    U.Toolkit('RemoveEntity', peds[location.Id])
                    peds[location.Id] = nil
                end
            end
        end
        Wait(1500)
    end
end)
RegisterNetEvent('h4nr-craft:client:book', function(id)
    if Craft.Location(id) then
        Craft.Menu.Open(id, true)
    end
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == 'feather-menu-v2' or resource == 'feather-core' then
        Craft.Menu.Close()
    end
    if resource ~= GetCurrentResourceName() then
        return
    end
    Craft.Menu.Close()
    for _, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    for _, id in pairs(peds) do
        U.Toolkit('RemoveEntity', id)
    end
    if prompt then
        U.Toolkit('RemovePrompt', prompt)
    end
end)
