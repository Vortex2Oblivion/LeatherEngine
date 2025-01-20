
package substates;

import flixel.FlxCamera;
import ui.NoteGraph;
import game.Song;
import game.Highscore;
import states.LoadingState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import states.PlayState;

class ResultsScreenSubstate extends MusicBeatSubstate {
	var uiCamera:FlxCamera = new FlxCamera();

	public function new() {
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

		var ratings:FlxText = new FlxText(0, FlxG.height, 0, PlayState.instance.returnStupidRatingText());
		ratings.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		ratings.screenCenter(Y);
		ratings.scrollFactor.set();
		add(ratings);

		@:privateAccess
		var bottomText:FlxText = new FlxText(FlxG.width, FlxG.height, 0,
			"Press ENTER to close this menu\n" + (!PlayState.playingReplay
				&& PlayState.SONG.validScore ? "Press SHIFT to save this replay\nPress ESCAPE to view this replay\n" : ""));
		bottomText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		bottomText.setPosition(FlxG.width - bottomText.width - 2, FlxG.height - (!PlayState.playingReplay ? 96 : 32));
		bottomText.scrollFactor.set();
		add(bottomText);

		add(new NoteGraph(PlayState.instance.replay, FlxG.width - 550, 25));

		cameras = [uiCamera];
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER) {
			PlayState.instance.finishSongStuffs();
            return;
        }

		if (FlxG.keys.justPressed.SHIFT && !PlayState.playingReplay && PlayState.SONG.validScore)
			PlayState.instance.saveReplay();

		if (FlxG.keys.justPressed.ESCAPE && !PlayState.playingReplay && PlayState.SONG.validScore) {
			PlayState.instance.saveReplay();
			PlayState.instance.fixSettings();

			var replay = PlayState.instance.replay;
			var poop:String = Highscore.formatSong(replay.song, replay.difficulty);

			PlayState.SONG = Song.loadFromJson(poop, replay.song);
			PlayState.isStoryMode = false;
			PlayState.songMultiplier = replay.songMultiplier;
			PlayState.storyDifficultyStr = replay.difficulty.toUpperCase();
			PlayState.playingReplay = true;

			LoadingState.loadAndSwitchState(new PlayState(replay));
		}
	}
}
