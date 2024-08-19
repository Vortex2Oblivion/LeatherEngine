package ui;

#if MODDING_ALLOWED
import sys.io.File;
import openfl.display.BitmapData;
import flixel.FlxSprite;

class ModIcon extends FlxSprite {
	/**
	 * Used for ModMenu! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(modID:String = 'Template Mod') {
		super();

		loadGraphic(BitmapData.fromFile("mods/" + modID + "/_polymod_icon.png"));
		setGraphicSize(150, 150);
		updateHitbox();
		
		scrollFactor.set();
		antialiasing = Options.getData("antialiasing");
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
		}
	}
}
#end