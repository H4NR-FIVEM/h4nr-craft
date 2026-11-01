local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
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
dofile('shared/utils.lua')
local report = print
local output, command = {}, nil
function print(value)
    output[#output + 1] = value
end
function RegisterCommand(name, handler)
    check(name == 'craftcheck', 'Operator command has a stable name')
    command = handler
end
function GetPlayers()
    return { '1', '2' }
end
function GetPlayerPed(source)
    return source == 1 and 101 or 0
end
function GetEntityCoords()
    return Config.Locations[1].Coords
end
function GetPlayerRoutingBucket()
    return 7
end
function GetEntityHealth()
    return 200
end
dofile('server/diagnostics.lua')
command(1, {})
check(#output == 0, 'Players cannot inspect server diagnostics')
command(0, { '1' })
check(#output == 1 and output[1]:find('station=food', 1, true), 'Console resolves nearest actual station')
check(output[1]:find('distance=0.00m', 1, true), 'Reports server distance beside the NPC')
check(output[1]:find('bucket=7 requiredBucket=0', 1, true), 'Explains a different instance without weakening admission')
check(
    output[1]:find('health=200', 1, true) and output[1]:find('stationPos=', 1, true),
    'Reports readiness and configured coordinates'
)
command(0, { 'not-an-id' })
check(output[#output]:find('Usage:', 1, true), 'Invalid source input is refused')
command(0, {})
check(
    output[#output]:find('player=2: no server ped', 1, true),
    'Handles an unavailable server ped without native coordinate reads'
)
report(('Diagnostics: %d assertions passed (console-only server position and instance report)'):format(checks))
