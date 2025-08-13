function new()
    loadScript("../stage data/philly")
end

function createPost()
    if not shaders then return end
    initShader("adjustColor", "adjustColor")

    setShaderProperty("adjustColor", "hue", -26)
    setShaderProperty("adjustColor", "saturation", -16)
    setShaderProperty("adjustColor", "brightness", -5)
    setShaderProperty("adjustColor", "contrast", 0)

    if get('dad.isCharacterGroup') then
        for i = 0, get('dad.otherCharacters.length') - 1 do
            setActorShader('dadCharacter' .. i, "adjustColor")
        end
    else
        setActorShader("dad", "adjustColor")
    end

    if get('gf.isCharacterGroup') then
        for i = 0, get('gf.otherCharacters.length') - 1 do
            setActorShader('gfCharacter' .. i, "adjustColor")
        end
    else
        setActorShader("gf", "adjustColor")
    end

    if get('boyfriend.isCharacterGroup') then
        for i = 0, get('boyfriend.otherCharacters.length') - 1 do
            setActorShader('bfCharacter' .. i, "adjustColor")
        end
    else
        setActorShader("boyfriend", "adjustColor")
    end

    setActorShader("train", "adjustColor")
end
