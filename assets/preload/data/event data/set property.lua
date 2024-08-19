
function onEvent(name, position, value1, value2)
    if string.lower(name) == "set property" then
        set(value1, value2)
    end
end