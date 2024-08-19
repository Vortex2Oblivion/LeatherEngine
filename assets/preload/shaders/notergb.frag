#pragma header

uniform float red = 255;
uniform float green;
uniform float blue;

void main() {
  vec4  col = flixel_texture2D(bitmap, openfl_TextureCoordv);

  const vec3 target = vec3(1.0, 0.0, 0.0); // Find red

  // Get difference to use for falloff if required
  float diff = col.r - ((col.g + col.b) / 2.0);

  gl_FragColor = vec4(((col.g + col.b) / 2.0) + (red * diff), col.g + (green * diff), col.b + (blue * diff), col.a);
}