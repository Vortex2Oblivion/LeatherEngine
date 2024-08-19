function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "play animation" then
        local anim = argument1

        if anim == "" then
            anim = "idle"
        end

        playCharAnim(charFromEvent(argument2), anim, true)
    end
end