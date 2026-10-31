-- Resource-local Romanian translations with complete English fallback.
function _U(key, ...)
    local text = (Locales[Config.DefaultLang] or {})[key] or (Locales.en_us or {})[key] or key
    if select('#', ...) > 0 then
        return text:format(...)
    end
    return text
end
