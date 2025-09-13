function createPost()
    for i = 0, getUnspawnNotes() - 1 do
        if string.lower(getUnspawnedNoteNoteType(i)) == 'gf sing' then
            setUnspawnedNoteSingAnimPrefix(i, nil)
        end
    end
end

function singGF(data, player)
    playAnimation("girlfriend", getSingDirectionAnim(data, (player and playerKeyCount or keyCount)), true)
end

function playerOneSing(data, time, type)
    if string.lower(type) == 'gf sing' then singGF(data, true) end
end
function playerOneSingHeld(data, time, type)
    if string.lower(type) == 'gf sing' then singGF(data, true) end
end

function playerTwoSing(data, time, type)
    if string.lower(type) == 'gf sing' then singGF(data, false) end
end
function playerTwoSingHeld(data, time, type)
    if string.lower(type) == 'gf sing' then singGF(data, false) end
end