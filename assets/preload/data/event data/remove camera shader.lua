
function onEvent(name, position, value1, value2)
    if string.lower(name) == "remove camera shader" then
        if value2 == "hud" then
            removeCameraShader("hud", value1)
        elseif value2 == "game" then
            removeCameraShader("game", value1)
        else
            removeCameraShader("game", value1)
            removeCameraShader("hud", value1)
        end
    end
end