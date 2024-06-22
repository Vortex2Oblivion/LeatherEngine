package substates;

import states.OptionsMenu;
import flixel.util.FlxStringUtil;
import flixel.FlxCamera;
import game.Conductor;
import states.FreeplayState;
import states.StoryMenuState;
import states.PlayState;
import ui.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class PauseSubState extends MusicBeatSubstate {
	var grpMenuShit:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();

	var curSelected:Int = 0;

	var menus:Map<String, Array<String>> = [
		"default" => ['Resume', 'Restart Song', 'Options', 'Exit To Menu'],
		"restart" => ['Back', 'No Cutscenes', 'With Cutscenes'],
		"editors" => ['Back', 'Chart Editor', 'Character Editor', 'Modchart Editor']
	];

	var menu:String = "default";

	var pauseMusic:FlxSound = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);

	var pauseCamera:FlxCamera = new FlxCamera();

	var curTime:Float = Math.max(0, Conductor.songPosition);
	var skipTimeTracker:Alphabet;

	public function new() {
		super();

		pauseCamera.bgColor.alpha = 0;
		FlxG.cameras.add(pauseCamera, false);

		var optionsArray = menus.get("default");

		if(PlayState.chartingMode){
			optionsArray.insert(optionsArray.length - 1, "Skip Time");
			menus.set("default", optionsArray);
		}

		if (controls.mobileC) {
			final num:Int = !PlayState.chartingMode ? 2 : 3;
			optionsArray.insert(optionsArray.length - num, "Editors");
			menus.set("default", optionsArray);
		}


		pauseMusic.volume = 0;
		pauseMusic.play();
		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text = PlayState.SONG.song;
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text = PlayState.storyDifficultyStr.toUpperCase();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		add(grpMenuShit);

		updateAlphabets();

		cameras = [pauseCamera];
		if (PlayState.instance.usedLuaCameras)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];

		addVirtualPad(PlayState.chartingMode ? LEFT_FULL : UP_DOWN, A_B);
		addVirtualPadCamera();
	}

	var justPressedAcceptLol:Bool = true;

	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (!accepted)
			justPressedAcceptLol = false;


		if (-1 * Math.floor(FlxG.mouse.wheel) != 0)
			changeSelection(-1 * Math.floor(FlxG.mouse.wheel));
		if (upP)
			changeSelection(-1);
		if (downP)
			changeSelection(1);

		if (menus.get(menu)[curSelected].toLowerCase().contains("skip time")) 
		{
				if (controls.LEFT_P)
				{
					curTime -= 1000;
					holdTime = 0;
					updateAlphabets(false);
				}
				if (controls.RIGHT_P)
				{
					curTime += 1000;
					holdTime = 0;
					updateAlphabets(false);
				}

				if(controls.LEFT || controls.RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateAlphabets(false);
				}
		}

		if (accepted && !justPressedAcceptLol) {
			justPressedAcceptLol = true;

			var daSelected:String = menus.get(menu)[curSelected];

			switch (daSelected.toLowerCase()) {
				case "resume":
					pauseMusic.stop();
					pauseMusic.destroy();
					FlxG.sound.list.remove(pauseMusic);
					FlxG.cameras.remove(pauseCamera);
					PlayState.instance.call("onResume", []);
					close();
				case "restart song":
					menu = "restart";
					updateAlphabets();
				case "no cutscenes":
					PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
					PlayState.playCutscenes = true;

					PlayState.instance.closeLua();

					PlayState.SONG.keyCount = PlayState.instance.ogKeyCount;
					PlayState.SONG.playerKeyCount = PlayState.instance.ogPlayerKeyCount;

					pauseMusic.stop();
					pauseMusic.destroy();
					FlxG.sound.list.remove(pauseMusic);
					FlxG.cameras.remove(pauseCamera);

					FlxG.resetState();
				case "with cutscenes":
					PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;

					PlayState.instance.closeLua();

					PlayState.SONG.keyCount = PlayState.instance.ogKeyCount;
					PlayState.SONG.playerKeyCount = PlayState.instance.ogPlayerKeyCount;

					pauseMusic.stop();
					pauseMusic.destroy();
					FlxG.sound.list.remove(pauseMusic);
					FlxG.cameras.remove(pauseCamera);

					FlxG.resetState();
				case "skip time":
					if(curTime < Conductor.songPosition)
						{
							PlayState.startOnTime = curTime;
							PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
							PlayState.playCutscenes = true;

							PlayState.instance.closeLua();


							PlayState.SONG.keyCount = PlayState.instance.ogKeyCount;
							PlayState.SONG.playerKeyCount = PlayState.instance.ogPlayerKeyCount;

							pauseMusic.stop();
							pauseMusic.destroy();
							FlxG.sound.list.remove(pauseMusic);
							FlxG.cameras.remove(pauseCamera);
							FlxG.resetState();
						}
						else
						{
							if (curTime != Conductor.songPosition)
							{
								PlayState.instance.clearNotesBefore(curTime);
								PlayState.instance.setSongTime(curTime);
							}
							pauseMusic.stop();
							pauseMusic.destroy();
							FlxG.sound.list.remove(pauseMusic);
							FlxG.cameras.remove(pauseCamera);
							close();
						};
				case "options":{
					pauseMusic.stop();
					pauseMusic.destroy();
					FlxG.sound.list.remove(pauseMusic);
					FlxG.cameras.remove(pauseCamera);
					FlxG.switchState(new PauseOptions());
					PlayState.chartingMode = false;
				}
				case "back":
					menu = "default";
					updateAlphabets();
				case "exit to menu":
					PlayState.instance.closeLua();

					pauseMusic.stop();
					pauseMusic.destroy();
					FlxG.sound.list.remove(pauseMusic);
					FlxG.cameras.remove(pauseCamera);
					PlayState.chartingMode = false;

					if (PlayState.isStoryMode) {
						FlxG.switchState(new StoryMenuState());
					} else {
						FlxG.switchState(new FreeplayState());
					}
				case "editors":
					menu = "editors";
					updateAlphabets();
				case "chart editor":
					PlayState.instance.openChartEditor();
				case "character editor":
					PlayState.instance.openCharacterEditor();
				case "modchart editor":
					PlayState.instance.openModchartEditor();
			}
		}
	}

	function updateAlphabets(?jump:Bool = true) {
		grpMenuShit.clear();

		for (i in 0...menus.get(menu).length) {
			if(menus.get(menu)[i].toLowerCase().contains('skip time'))
				{

					var songText:Alphabet = new Alphabet(0, (70 * i) + 30, "Skip Time " + FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false), true);
					songText.isMenuItem = true;
					songText.targetY = i;

					grpMenuShit.add(songText);
				}
			else{
				var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menus.get(menu)[i], true);
				songText.isMenuItem = true;
				songText.targetY = i;

				grpMenuShit.add(songText);
			}
		}

		if(jump) curSelected = 0;
		else FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		changeSelection();
	}

	

	function changeSelection(change:Int = 0):Void {
		FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelected += change;

		if (curSelected < 0)
			curSelected = menus.get(menu).length - 1;
		if (curSelected >= menus.get(menu).length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
}
class PauseOptions extends OptionsMenu{
	override inline function goBack(){
		FlxG.switchState(new PlayState());
	}
}