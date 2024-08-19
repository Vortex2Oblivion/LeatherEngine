function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "character will idle" then
        set(charFromEvent(argument1) .. '.shouldDance', string.lower(tostring(argument2)) == "true")
    end
end