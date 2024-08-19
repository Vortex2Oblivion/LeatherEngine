function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "hey!" then
        local charString = string.lower(argument1)

        if charString == "bf" or charString == "boyfriend" or charString == "player" or charString == "player1" then
            playCharAnim("boyfriend", "hey", true)
        elseif charString == "gf" or charString == "girlfriend" or charString == "player3" then
            playCharAnim("girlfriend", "cheer", true)
        else
            playCharAnim("boyfriend", "hey", true)
            playCharAnim("girlfriend", "cheer", true)
        end
    end
end