package shaders;

import flixel.system.FlxAssets.FlxShader;

/**
 * Stripped down version of https://github.com/FNF-CNE-Devs/YoshiCrafterEngine/blob/main/source/NoteShader.hx
 */
class ColorSwap {
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();
	public var r(default, set):Float = 255;
	public var g(default, set):Float = 0;
	public var b(default, set):Float = 0;

	private function set_r(value:Float) {
		r = value;
		shader.red.value = [r/255];
		return r;
	}

	private function set_g(value:Float) {
		g = value;
		shader.green.value = [g/255];
		return g;
	}

	private function set_b(value:Float) {
		b = value;
		shader.blue.value = [b/255];
		return b;
	}

	public function new() {
		r = 255/255;
		g = 0/255;
		b = 0/255;
	}
}

//modified from yoshicrafterengine
class ColorSwapShader extends FlxShader {
	@:glFragmentSource('
	#pragma header

	uniform float red;
	uniform float green;
	uniform float blue;

	void main() {

	vec4  col = flixel_texture2D(bitmap, openfl_TextureCoordv);
		
	// Get difference to use for falloff if required
	float diff = col.r - ((col.g + col.b) / 2.0);
	
	gl_FragColor = vec4(((col.g + col.b) / 2.0) + (red * diff), col.g + (green * diff), col.b + (blue * diff), col.a);
	}
	')
	public function new() {
		super();
	}
}
