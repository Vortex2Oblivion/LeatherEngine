package game;

import flixel.FlxSprite;

class DancingSprite extends FlxSprite {
	var dancingRight:Bool = false;
	var oneDanceAnimation:Bool = false;

	public function new(x:Float, y:Float, ?oneDanceAnimation:Bool = false, ?antialiasing:Bool = true) {
		super(x, y);

		this.antialiasing = antialiasing;
		this.oneDanceAnimation = oneDanceAnimation;
	}

	public function dance(?altAnim:String = ''):Void {
		if (!oneDanceAnimation) {
			dancingRight = !dancingRight;

			if (dancingRight)
				animation.play('danceRight' + altAnim, true);
			else
				animation.play('danceLeft' + altAnim, true);
		} else
			animation.play('dance' + altAnim, true);
	}
}

class BackgroundGirls extends DancingSprite {
	public function new(x:Float, y:Float) {
		super(x, y, false, false);

		frames = Paths.getSparrowAtlas('school/bgFreaks', "stages");

		animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);

		dance();
	}

	public function getScared():Void {
		animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);

		dance();
	}
}
