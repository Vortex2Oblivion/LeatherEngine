function playerOneSing(data, time, type)
    playAnimFunc(type, "boyfriend")
end
function playerOneSingHeld(data, time, type)
    playAnimFunc(type, "boyfriend")
end

function playerTwoSing(data, time, type)
    playAnimFunc(type, "dad")
end
function playerTwoSingHeld(data, time, type)
    playAnimFunc(type, "dad")
end

function playAnimFunc(t, c)
    if t == "cheer" then
        playCharAnim(c, "cheer", true)
    end
end