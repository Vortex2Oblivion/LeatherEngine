local shaderTime = 0.0

function createPost()
    initShader('wiggle', 'wiggle')
    setShaderProperty('wiggle', 'uSpeed', 2)
    setShaderProperty('wiggle', 'uFrequency', 4)
    setShaderProperty('wiggle', 'uWaveAmplitude', 0.017)
    setCustomShaderInt('wiggle', 'effectType', 0)
    setShaderProperty('wiggle', 'uTime', 0)
    setActorShader('evilSchoolBG', 'wiggle')
    setActorShader('evilSchoolFG', 'wiggle')
end

function update(elapsed)
    shaderTime = shaderTime + elapsed
    setShaderProperty('wiggle', 'uTime', shaderTime)
end