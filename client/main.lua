-- Station startup, UI monitoring and frame-local input ownership. NPC interaction belongs to Feather Target.
local blips = {}
CreateThread(function()
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
        Craft.Stations.Update()
        Wait(1500)
    end
end)
CreateThread(function()
    while true do
        Craft.Menu.Monitor()
        Wait(250)
    end
end)
CreateThread(function()
    while true do
        local sleep = 250
        if Craft.Board.Active() then
            sleep = 0 -- UI input suppression cannot wait on a session RPC or NPC model loading.
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            DisablePlayerFiring(PlayerId(), true)
        end
        Wait(sleep)
    end
end)
RegisterNetEvent('h4nr-craft:client:book', function(id)
    if Craft.Location(id) then
        Craft.Menu.Open(id, true)
    end
end)
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'feather-target' then
        Craft.Stations.TargetStopped()
    end
end)
local function stopped(resource)
    if resource == 'feather-core' or resource == 'feather-target' then
        Craft.Menu.Close()
    end
    if resource == 'feather-target' then
        Craft.Stations.TargetStopped()
    end
    if resource ~= GetCurrentResourceName() then
        return
    end
    Craft.Menu.Close()
    Craft.Stations.Cleanup()
    for _, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
end
AddEventHandler('onResourceStop', stopped)
AddEventHandler('onClientResourceStop', stopped)
