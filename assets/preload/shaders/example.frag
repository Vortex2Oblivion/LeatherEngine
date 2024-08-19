//taken from https://github.com/47rooks/parasol/blob/main/parasol/shaders/GrayscaleShader.hx
#pragma header

void main()
{
    vec2 st = openfl_TextureCoordv.xy;  // Note, already normalized

    vec4 color = flixel_texture2D(bitmap, st);
    gl_FragColor = vec4(vec3(dot(color.rgb, vec3(0.2126, 0.7152, 0.0722))), color.a);
}
