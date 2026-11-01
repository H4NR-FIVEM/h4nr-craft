-- Read-only operator diagnostics. Never accept a client-provided position or change routing.
RegisterCommand('craftcheck', function(source, args)
    if source ~= 0 then
        return -- server console / txAdmin console only
    end
    local targets
    if args[1] then
        local target = tonumber(args[1])
        if not Craft.Integer(target, 1, 65535) then
            print('[h4nr-craft] Usage: craftcheck [server player ID]')
            return
        end
        targets = { target }
    else
        targets = GetPlayers()
    end
    for _, value in ipairs(targets) do
        local target = tonumber(value)
        local ped = GetPlayerPed(target)
        if ped == 0 then
            print(('[h4nr-craft] player=%d: no server ped (not connected or spawn not ready)'):format(target))
        else
            local coords = GetEntityCoords(ped)
            local closest, distance
            for _, location in ipairs(Config.Locations) do
                local current = #(coords - location.Coords)
                if not distance or current < distance then
                    closest, distance = location, current
                end
            end
            if closest then
                print(
                    ('[h4nr-craft] player=%d station=%s distance=%.2fm max=%.2fm bucket=%d requiredBucket=0 health=%d pos=(%.2f, %.2f, %.2f) stationPos=(%.2f, %.2f, %.2f)'):format(
                        target,
                        closest.Id,
                        distance,
                        Config.MaximumDistance,
                        GetPlayerRoutingBucket(target),
                        GetEntityHealth(ped),
                        coords.x,
                        coords.y,
                        coords.z,
                        closest.Coords.x,
                        closest.Coords.y,
                        closest.Coords.z
                    )
                )
            else
                print('[h4nr-craft] No crafting stations configured.')
            end
        end
    end
end, false)
