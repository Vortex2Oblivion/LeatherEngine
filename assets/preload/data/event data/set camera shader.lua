
function onEvent(name, position, value1, value2)
    if string.lower(name) == "set camera shader" then
        if value2 == "hud" then
            setCameraShader("hud", value1)
        elseif value2 == "game" then
            setCameraShader("game", value1)
        else
            setCameraShader("game", value1)
            setCameraShader("hud", value1)
        end
    end
end