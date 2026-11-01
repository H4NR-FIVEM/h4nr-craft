-- Client boundary for RPC, sessions, NUI, notifications and Toolkit-owned entities.
Craft.Ui = {}
local U = Craft.Ui
local toolkit = exports['feather-toolkit']
function U.Session()
    local called, result = pcall(function()
        return exports['feather-core']:GetSessionContext()
    end)
    return called and result and result.ok and result.value or nil
end
function U.Rpc(action, params)
    local result = exports['feather-core']:CallRPCAsync(Craft.Route(action), params, nil, 30000)
    return type(result) == 'table' and result or Craft.Err('pending')
end
function U.Notify(key)
    local message = _U(key)
    if message == key then
        message = _U('unavailable')
    end
    U.Send({
        action = 'notice',
        message = message,
        success = key == 'started' or key == 'collected' or key == 'bookReceived',
    })
    exports['feather-notify']:ShowNotification({ style = 'right', message = message, duration = 5000 })
end
function U.Toolkit(operation, ...)
    return toolkit[operation](toolkit, ...)
end

function U.Focus(enabled)
    SetNuiFocus(enabled, enabled)
end
function U.Send(message)
    SendNUIMessage(message)
end
