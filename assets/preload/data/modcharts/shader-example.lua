function createPost()
    initShader('id', 'filename') 
    --creating the shader. 
    --'id' is how you will refer to the shader in other parts of your code
    --filename is the name of the file (without the .frag) of the shader. shaders must be put in yourmod/shaders
    --OPTIONAL. you can add a 3rd paramater in the initShader function for changing the glsl version, defaults to 120.
    setActorShader('actor', 'id')
    --setting the shader to an object
    --'actor' is where you put the object you want the shader to be applied to, eg: 'boyfriend'
    --'id' is the id of the shader in initShader.
    setCameraShader('camera', 'id')
    --setting the shader to an camera
    --'camera' is where you put the camera you want the shader to be applied to, game or hud.
    --'id' is the id of the shader in initShader.
    removeCameraShader('camera', 'id')
    --removes a shader from a camera
    --'camera' is where you put the camera you want the shader to be removed from, game or hud.
    --'id' is the id of the shader in initShader.
    setShaderProperty('id', 'property', 'value')
    --sets the property of a shader. Only supports Bool, Float, and FloatArray right now.
    --'id' is the id of the shader in initShader.
    --'property' is the property of the shader you want to change
    --'value' is what to chane too. ex: true, false, 10, {1, 5, 9}.

    tweenShaderProperty('id', 'property', 'value', duration)
    --tweens the float property of a shader
    --'id' is the id of the shader in initShader.
    --'property' is the property of the shader you want to change.
    --'duration' is how long the tween should take, should be float.
    --OPTIONAL. you can specify the ease with a 4th paramater, defaults to 'linear'
    --OPTIONAL. you can specify the start delay with a 5th paramater, defaults to 0.0
    --OPTIONAL. you can specify onComplete with a 6th paramater. 
    --Should be tweenShaderProperty('id', 'property', 'value', duration, 'ease', startDelay, function()
        --code here
    --end)
end