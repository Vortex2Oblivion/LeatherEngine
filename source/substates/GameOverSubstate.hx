package substates;

import game.CharacterGroup;
import flixel.sound.FlxSound;
import game.graphics.FlxAtlasSprite;
import lime.utils.Assets;
import game.Character;
import states.FreeplayState;
import states.StoryMenuState;
import game.Conductor;
import states.PlayState;
import game.Boyfriend;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.LoadingState;

class GameOverSubstate extends MusicBeatSubstate {
	public var bf:CharacterGroup;
	public var camFollow:FlxObject;

	public static var instance:GameOverSubstate = null;

	var gameOverRoll:Bool = FlxG.random.bool((1 / 4096) * 100);
	var fakeout:FlxAtlasSprite;

	public function new(x:Float, y:Float) {
		instance = this;
		super();
		PlayState.playCutscenes = true;

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if (Options.getData("quickRestart") && !gameOverRoll) {
			PlayState.instance.call("onRetry", []);
			PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
			FlxG.resetState();
		}

		Conductor.songPosition = 0;

		bf = new CharacterGroup(x, y, PlayState.boyfriend.getMainCharacter().deathCharacter, true, true);
		bf.x += bf.getMainCharacter().positioningOffset.x;
		bf.y += bf.getMainCharacter().positioningOffset.y;
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		if (FlxG.sound.music.active)
			FlxG.sound.music.stop();

		if (gameOverRoll) {
			bf.visible = false;
			var soundlol:FlxSound = new FlxSound().loadEmbedded(Paths.sound("deaths/fakeout_death", "shared"));
			soundlol.play();
			soundlol.onComplete = () -> {
				bfDies();
				fakeout.visible = false;
			}
			fakeout = new FlxAtlasSprite(bf.x * 1.5, bf.y * 1.75, Paths.getTextureAtlas('characters/bfFakeOut', 'shared'), {
				FrameRate: 24.0,
				Reversed: false,
				ShowPivot: false,
				Antialiasing: Options.getData("antialiasing"),
				ScrollFactor: new FlxPoint(bf.scrollFactor.x, bf.scrollFactor.y),
			});
			fakeout.anim.addBySymbol('fakeoutDeath', 'fake out death BF', 24, false);
			fakeout.anim.play('fakeoutDeath', true);
			add(fakeout);
		} else {
			bfDies();
		}
	}

	function bfDies() {
		var soundPath = Paths.sound("deaths/bf-dead/death");
		bf.visible = true;
		if (Assets.exists(Paths.sound("deaths/" + bf.character + "/death")))
			soundPath = Paths.sound("deaths/" + bf.character + "/death");

		FlxG.sound.play(soundPath);

		Conductor.changeBPM(100);
		bf.playAnimation('firstDeath', true);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.ACCEPT) {
			endBullshit();
		}

		if (controls.BACK) {
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(() -> new StoryMenuState());
			else
				FlxG.switchState(() -> new FreeplayState());
		}

		if (bf.getMainCharacter().animation.curAnim.name == 'firstDeath' && bf.getMainCharacter().animation.curAnim.curFrame == 12)
			FlxG.camera.follow(camFollow, LOCKON, 0.01);

		if (bf.getMainCharacter().animation.curAnim.name == 'firstDeath' && bf.getMainCharacter().animation.curAnim.finished) {
			var soundPath = Paths.music("deaths/bf-dead/loop");

			if (Assets.exists(Paths.music("deaths/" + bf.character + "/loop")))
				soundPath = Paths.music("deaths/" + bf.character + "/loop");

			FlxG.sound.playMusic(soundPath);
			PlayState.instance.call("onDeathLoop", []);
		}

		if (FlxG.sound.music.playing) {
			Conductor.songPosition = FlxG.sound.music.time;
		}

		FlxG.camera.followLerp = elapsed * 0.6;
	}

	var isEnding:Bool = false;

	function endBullshit():Void {
		if (!isEnding) {
			PlayState.instance.call("onRetry", []);
			isEnding = true;
			bf.playAnimation('deathConfirm', true);
			FlxG.sound.music.stop();

			var soundPath = Paths.music("deaths/bf-dead/retry");

			if (Assets.exists(Paths.music("deaths/" + bf.character + "/retry")))
				soundPath = Paths.music("deaths/" + bf.character + "/retry");

			FlxG.sound.play(soundPath);
			new FlxTimer().start(0.7, function(tmr:FlxTimer) {
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
					PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
					FlxG.resetState();
				});
			});
		}
	}
}
