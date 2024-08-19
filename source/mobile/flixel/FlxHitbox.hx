package mobile.flixel;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import mobile.flixel.FlxButton;

/**
 * A zone with 4 hints (A hitbox).
 * It's really easy to customize the layout.
 *
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class FlxHitbox extends FlxSpriteGroup {
	/**
	 * Array of FlxButton representing the hints.
	 */
	public var hints(default, null):Array<FlxButton>;

	final guh2:Float = 0.00001;
	final guh:Float = Options.getData("mobileCAlpha") >= 0.9 ? Options.getData("mobileCAlpha") - 0.2 : Options.getData("mobileCAlpha");

	/**
	 * Creates the zone with the specified number of hints.
	 *
	 * @param ammo The amount of hints you want to create.
	 * @param perHintWidth The width that the hints will use.
	 * @param perHintHeight The height that the hints will use.
	 * @param colors The color per hint.
	 */
	public function new(ammo:UInt, perHintWidth:Int, perHintHeight:Int, ?colors:Array<FlxColor>):Void {
		super();

		hints = new Array<FlxButton>();

		if (colors == null)
			switch (ammo) {
				case 1:
					colors = [0xCCCCCC];
				case 2:
					colors = [0xC24B99, 0xF9393F];
				case 3:
					colors = [0xC24B99, 0xCCCCCC, 0xF9393F];
				case 5:
					colors = [0xC24B99, 0x00FFFF, 0xCCCCCC, 0x12FA05, 0xF9393F];
				case 6:
					colors = [0xC24B99, 0x12FA05, 0xF9393F, 0xFFFF00, 0x00FFFF, 0x0033FF];
				case 7:
					colors = [0xC24B99, 0x12FA05, 0xF9393F, 0xCCCCCC, 0xFFFF00, 0x00FFFF, 0x0033FF];
				case 8:
					colors = [0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF];
				case 9:
					colors = [
						0xC24B99,
						0x00FFFF,
						0x12FA05,
						0xF9393F,
						0xCCCCCC,
						0xFFFF00,
						0x8B4AFF,
						0xFF0000,
						0x0033FF
					];
				case 10:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0x12FA05, 0x00FFFF, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF
					];
				case 11:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0x12FA05, 0xC24B99, 0x00FFFF, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF
					];
				case 12:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFF0000, 0x00FFFF, 0x12FA05, 0x0033FF, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF
					];
				case 13:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFF0000, 0x1E29FF, 0xCCCCCC, 0x6200FF, 0x1EFF69, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF
					];
				case 14:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFF0000, 0x1E29FF, 0xCCCCCC, 0xC24B99, 0x6200FF, 0x1EFF69, 0xFFFF00, 0x8B4AFF, 0xFF0000,
						0x0033FF
					];
				case 15:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFF0000, 0x1E29FF, 0x12FA05, 0xC24B99, 0xFF8300, 0x6200FF, 0x1EFF69, 0xFFFF00, 0x8B4AFF,
						0xFF0000, 0x0033FF
					];
				case 16:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFF0000, 0x00FFFF, 0x12FA05, 0x1E29FF, 0x6200FF, 0xA9FF1E, 0xFF8300, 0x1EFF69, 0xFFFF00,
						0x8B4AFF, 0xFF0000, 0x0033FF
					];
				case 17:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xC24B99, 0xFF0000, 0xCCCCCC, 0x00FFFF, 0xC24B99, 0x12FA05, 0xCCCCCC, 0x0033FF, 0xC24B99,
						0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF
					];
				case 18:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF, 0xCCCCCC, 0xC24B99, 0xFF0000, 0x00FFFF, 0x12FA05,
						0x0033FF, 0x8B4AFF, 0xA9FF1E, 0xFF8300, 0x1EFF69
					];
				case 19:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF, 0xFF8300, 0xC24B99, 0xA9FF1E, 0xFF0000, 0x00FFFF,
						0x12FA05, 0x0033FF, 0x8B4AFF, 0xA9FF1E, 0xFF8300, 0x1EFF69
					];
				case 20:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF, 0x8B4AFF, 0xA9FF1E, 0xFF8300, 0x12FA05, 0xFF0000,
						0x00FFFF, 0x12FA05, 0x0033FF, 0x8B4AFF, 0xA9FF1E, 0xFF8300, 0x1EFF69
					];
				case 21:
					colors = [
						0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F, 0xFFFF00, 0x8B4AFF, 0xFF0000, 0x0033FF, 0x8B4AFF, 0xA9FF1E, 0xC24B99, 0xFF8300, 0x12FA05,
						0xFF0000, 0x00FFFF, 0x12FA05, 0x0033FF, 0x8B4AFF, 0xA9FF1E, 0xFF8300, 0x1EFF69
					];
				default:
					colors = [0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F];
			}

		for (i in 0...ammo)
			add(hints[i] = createHint(i * perHintWidth, 0, perHintWidth, perHintHeight, colors[i]));

		scrollFactor.set();
	}

	/**
	 * Cleans up memory.
	 */
	override public function destroy():Void {
		super.destroy();

		for (i in 0...hints.length)
			hints[i] = FlxDestroyUtil.destroy(hints[i]);

		hints.splice(0, hints.length);
	}

	/**
	 * Creates a hint with specified properties.
	 *
	 * @param X The x position of the hint.
	 * @param Y The y position of the hint.
	 * @param Width The width of the hint.
	 * @param Height The height of the hint.
	 * @param Color The color of the hint.
	 * @return The created FlxButton representing the hint.
	 */
	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):FlxButton {
		var hint:FlxButton = new FlxButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height, Color));
		hint.solid = false;
		hint.multiTouch = true;
		hint.immovable = true;
		hint.moves = false;
		hint.antialiasing = Options.getData("antialiasing");
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.active = !Options.getData("botplay");
		if (Options.getData("hitboxType") != "Hidden")
		{
			hint.onDown.callback = function()
			{
				if (hint.alpha != guh)
					hint.alpha = guh;
			}
			hint.onUp.callback = function() {
				if (hint.alpha != guh2)
					hint.alpha = guh2;
			}
			hint.onOut.callback = function() {
				if (hint.alpha != guh2)
					hint.alpha = guh2;
			}
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	/**
	 * Creates the graphic for a hint with specified properties.
	 *
	 * @param Width The width of the hint.
	 * @param Height The height of the hint.
	 * @param Color The color of the hint.
	 * @return The created BitmapData representing the hint graphic.
	 */
	private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF):BitmapData {
		var shape:Shape = new Shape();
		shape.graphics.beginFill(Color);
		if (Options.getData("hitboxType") == "No Gradient") {
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(Width, Height, 0, 0, 0);

			shape.graphics.beginGradientFill(RADIAL, [Color, Color], [0, guh], [60, 255], matrix, PAD, RGB, 0);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		} else if (Options.getData("hitboxType") == "No Gradient (Old)") {
			shape.graphics.lineStyle(10, Color, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		} else {
			shape.graphics.lineStyle(3, Color, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.lineStyle(0, 0, 0);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
			shape.graphics.beginGradientFill(RADIAL, [Color, FlxColor.TRANSPARENT], [guh, 0], [0, 255], null, null, null, 0.5);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
		}
		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape, true);
		return bitmap;
	}
}
