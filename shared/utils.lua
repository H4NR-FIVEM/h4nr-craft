-- Pure helpers shared by the runtime and isolated contract tests.
Craft = { Recipes = {}, Locales = Locales or {} }
function Craft.Ok(value)
    return { ok = true, value = value }
end
function Craft.Err(code)
    return { ok = false, code = code }
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
