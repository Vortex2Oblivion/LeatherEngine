function createPost()
    if not shaders then return end
    initShader("colorShaderBf", "adjustColor")

    setShaderProperty("colorShaderBf", "hue", 12)
    setShaderProperty("colorShaderBf", "saturation", 0)
    setShaderProperty("colorShaderBf", "brightness", -23)
    setShaderProperty("colorShaderBf", "contrast", 7)

    initShader("colorShaderDad", "adjustColor")

    setShaderProperty("colorShaderDad", "hue", -32)
    setShaderProperty("colorShaderDad", "saturation", 0)
    setShaderProperty("colorShaderDad", "brightness", -33)
    setShaderProperty("colorShaderDad", "contrast", -23)

    initShader("colorShaderGf", "adjustColor")

    setShaderProperty("colorShaderGf", "hue", -9)
    setShaderProperty("colorShaderGf", "saturation", 0)
    setShaderProperty("colorShaderGf", "brightness", -30)
    setShaderProperty("colorShaderGf", "contrast", -4)

    if get('dad.isCharacterGroup') then
        for i = 0, get('dad.otherCharacters.length') - 1 do
            setActorShader('dadCharacter' .. i, "colorShaderDad")
        end
    else
        setActorShader("dad", "colorShaderDad")
    end

    if get('gf.isCharacterGroup') then
        for i = 0, get('gf.otherCharacters.length') - 1 do
            setActorShader('gfCharacter' .. i, "colorShaderGf")
        end
    else
        setActorShader("gf", "colorShaderGf")
    end

    if get('boyfriend.isCharacterGroup') then
        for i = 0, get('boyfriend.otherCharacters.length') - 1 do
            setActorShader('bfCharacter' .. i, "colorShaderBf")
        end
    else
        setActorShader("boyfriend", "colorShaderBf")
    end
end
