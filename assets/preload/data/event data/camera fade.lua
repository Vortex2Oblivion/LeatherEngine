function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "camera fade" then
        local colorString = string.lower(argument1)
        local duration = tonumber(argument2)

        if duration == nil then
            duration = 1
        end

        fadeCamera("game", colorString, duration)
    end
end