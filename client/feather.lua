-- Client boundary for RPC, sessions, Menu v2, notifications and Toolkit-owned entities.
Craft.Ui = {}
local U = Craft.Ui
local menu = exports['feather-menu-v2']
local toolkit = exports['feather-toolkit']
function U.Session()
    local result = exports['feather-core']:GetSessionContext()
    return result and result.ok and result.value or nil
end
function U.Rpc(action, params)
    local result = exports['feather-core']:CallRPCAsync('h4nr-craft:' .. action, params, nil, 30000)
    return type(result) == 'table' and result or Craft.Err('pending')
end
function U.Notify(key)
    local message = _U(key)
    if message == key then
        message = _U('unavailable')
    end
    exports['feather-notify']:ShowNotification({ style = 'right', message = message, duration = 5000 })
end
function U.Menu(operation, ...)
    return menu[operation](menu, ...)
end
function U.Toolkit(operation, ...)
    return toolkit[operation](toolkit, ...)
end
