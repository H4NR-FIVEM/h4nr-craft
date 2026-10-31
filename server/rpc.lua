-- Serialized per-character RPCs validate location, identity and bounded payloads.
Craft.Routes = {}
local locks = {}
local handlers = {
    catalog = Craft.Service.Catalog,
    start = Craft.Service.Start,
    collect = Craft.Service.Collect,
    book = Craft.Service.Book,
}
for action, handler in pairs(handlers) do
    Craft.Routes[action] = function(params, src)
        if not Craft.Ready then
            return Craft.Err('unavailable')
        end
        if
            type(params) ~= 'table'
            or type(params.location) ~= 'string'
            or (params.portable ~= nil and type(params.portable) ~= 'boolean')
        then
            return Craft.Err('bad_request')
        end
        local who = Craft.Feather.Session(src)
        if not who or params.characterId ~= who.characterId or params.sessionId ~= who.sessionId then
            return Craft.Err('session_expired')
        end
        if locks[who.characterId] then
            return Craft.Err('busy')
        end
        locks[who.characterId] = true
        local called, result = xpcall(function()
            local access = Craft.Service.Access(src, Craft.Location(params.location), params.portable)
            if not access.ok then
                return access
            end
            if not Craft.Feather.Current(src, who) then
                return Craft.Err('session_expired')
            end
            return handler(src, who, params)
        end, debug.traceback)
        locks[who.characterId] = nil
        if not called then
            print('[h4nr-craft] ' .. tostring(result))
            return Craft.Err('pending')
        end
        return result
    end
end
function Craft.RegisterRoutes()
    for action, handler in pairs(Craft.Routes) do
        local result = Craft.Feather.RegisterRpc('h4nr-craft:' .. action, handler)
        assert(result and result.ok, 'Could not register crafting route ' .. action)
    end
end
