function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "change character alpha" then
        local alpha = tonumber(argument2)

        if alpha == nil then
            alpha = 0.5
        end

        set(charFromEvent(argument1) .. '.alpha', alpha)
    end
end