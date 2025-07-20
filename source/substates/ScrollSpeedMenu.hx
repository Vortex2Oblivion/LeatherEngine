package substates;

import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class ScrollSpeedMenu extends MusicBeatSubstate {
	public var alphaValue:Float = 0.0;
	public var offsetText:FlxText = new FlxText(0, 0, 0, "Scrollspeed: 0", 64).setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

	public function new() {
		super();

		alphaValue = Options.getData("customScrollSpeed");

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

		offsetText.text = "Scrollspeed: " + alphaValue;
		offsetText.screenCenter();
		add(offsetText);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;

		var back = controls.BACK;

		if (back) {
			Options.setData(alphaValue, "customScrollSpeed");
			FlxG.state.closeSubState();
		}

		if (leftP)
			alphaValue -= 0.1;
		if (rightP)
			alphaValue += 0.1;

		alphaValue = FlxMath.roundDecimal(alphaValue, 1);

		if (alphaValue > 10)
			alphaValue = 10;

		if (alphaValue < 0.1)
			alphaValue = 0.1;

		offsetText.text = "Scrollspeed: " + alphaValue;
		offsetText.screenCenter();
	}
}
