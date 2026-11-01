-- Pure helpers shared by the runtime and isolated contract tests.
Craft = { Recipes = {}, Locales = Locales or {} }
function Craft.Ok(value)
    return { ok = true, value = value }
end
function Craft.Err(code, message)
    return { ok = false, code = code, message = message or _U(code) }
end
function Craft.Route(action)
    return 'h4nr-craft:' .. action .. '.v1'
end
function Craft.Integer(value, low, high)
    return type(value) == 'number' and value == value and value % 1 == 0 and value >= low and value <= high
end
function Craft.Location(id)
    for _, location in ipairs(Config.Locations) do
        if location.Id == id then
            return location
        end
    end
end
function Craft.Level(xp)
    return math.min(Config.MaxLevel, 1 + math.floor(xp / Config.XpPerLevel))
end

function Craft.ToolWear(tool, batches)
    if tool.Wear <= 0 then
        return 0
    end
    return math.max(1, math.ceil(tool.Wear / tool.Maximum * 100)) * batches
end
