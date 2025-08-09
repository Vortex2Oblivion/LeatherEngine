package substates;

import ui.NoteGraph;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import game.Replay;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import states.PlayState;

class ResultsSubstate extends MusicBeatSubstate {
	var uiCamera:FlxCamera = new FlxCamera();

	public function new(replay:Replay) {
		super();

		if (utilities.Options.getData("skipResultsScreen")) {
			PlayState.instance.finishSongStuffs();
			return;
		}

		uiCamera.bgColor.alpha = 0;
		FlxG.cameras.add(uiCamera, false);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		bg.y -= 100;
		add(bg);

		FlxTween.tween(bg, {alpha: 0.6, y: bg.y + 100}, 0.4, {ease: FlxEase.quartInOut});

		var topString = PlayState.SONG.song + " - " + PlayState.storyDifficultyStr.toUpperCase() + " complete! (" + Std.string(PlayState.songMultiplier) + "x)";

		var topText:FlxText = new FlxText(4, 4, 0, topString, 32);
		topText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		topText.scrollFactor.set();
		add(topText);

		var ratings:FlxText = new FlxText(0, FlxG.height, 0, PlayState.instance.getRatingText());
		ratings.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		ratings.screenCenter(Y);
		ratings.scrollFactor.set();
		add(ratings);

		var bottomText:FlxText = new FlxText(FlxG.width, FlxG.height, 0, "Press ENTER to close this menu\n");
		bottomText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		bottomText.setPosition(FlxG.width - bottomText.width - 2, FlxG.height - 96);
		bottomText.scrollFactor.set();
		add(bottomText);

		add(new NoteGraph(replay, FlxG.width - 550, 25));

		cameras = [uiCamera];
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER) {
			PlayState.instance.finishSongStuffs();
		}
	}
}
