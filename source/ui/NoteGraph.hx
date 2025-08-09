package ui;

import openfl.utils.ByteArray;
import openfl.geom.Rectangle;
import states.PlayState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import game.Replay;
import flixel.group.FlxGroup;

class NoteGraph extends FlxGroup {
	public function new(replay:Replay, startX:Float = 0.0, startY:Float = 0.0) {
		super();

		var bg = new FlxSprite(startX, startY).makeGraphic(500, 332, FlxColor.BLACK);
		bg.alpha = 0.3;
		add(bg);

		add(new FlxText(startX, startY - 16, 0, "-166ms", 16).setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK));
		add(new FlxText(startX, startY + 332, 0, "166ms", 16).setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK));

		add(new FlxSprite(startX, startY).makeGraphic(500, 4, FlxColor.GRAY));
		add(new FlxSprite(startX, startY + 83).makeGraphic(500, 4, FlxColor.GRAY));
		add(new FlxSprite(startX, startY + 166).makeGraphic(500, 4, FlxColor.GRAY));
		add(new FlxSprite(startX, startY + 249).makeGraphic(500, 4, FlxColor.GRAY));

		var dots:FlxSprite = new FlxSprite(startX, startY).makeGraphic(500, 332);

		dots.graphic.bitmap.lock();
		dots.graphic.bitmap.floodFill(0, 0, 0x00000000);

		for (i in 0...replay.inputs.length) {
			var input = replay.inputs[i];

			var dif = input[1];
			var strumTime = input[0];

			dots.graphic.bitmap.fillRect(new Rectangle(500 * (strumTime / FlxG.sound.music.length), 166 + (dif / PlayState.songMultiplier), 6, 6),
				FlxColor.fromRGB(Math.floor(255 * (Math.abs(dif) / 166)), 255, 0));
		}

		dots.graphic.bitmap.unlock();
		add(dots);
	}
}
