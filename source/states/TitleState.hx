package states;

#if linux
import hxgamemode.GamemodeClient;
#end
import lime.system.System;
import flixel.system.debug.log.LogStyle;
import flixel.math.FlxMath;
#if DISCORD_ALLOWED
import utilities.DiscordClient;
#end
import utilities.PlayerSettings;
import shaders.NoteColors;
import modding.ModList;
import game.Highscore;
import utilities.PlayerSettings;
import utilities.Options;
import utilities.NoteVariables;
import substates.OutdatedSubState;
import modding.PolymodHandler;
import utilities.MusicUtilities;
import game.Conductor;
import ui.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import shaders.ColorSwapHSV;
import flixel.system.FlxSplash;
import haxe.Http;

using StringTools;

class TitleState extends MusicBeatState {
	public static var initialized:Bool = false;

	public var blackScreen:FlxSprite;
	public var credGroup:FlxGroup;
	public var textGroup:FlxGroup;
	public var newgrounds:FlxSprite;

	public var curWacky:Array<String> = [];

	public static var firstTimeStarting:Bool = false;
	public static var doneFlixelSplash:Bool = false;

	public var swagShader:ColorSwapHSV;

	public static var instance:TitleState = null;

	override public function create():Void {
		call('create');
		MusicBeatState.windowNameSuffix = "";
		instance = this;
		swagShader = new ColorSwapHSV();

		if (!firstTimeStarting) {
			persistentUpdate = true;
			persistentDraw = true;

			FlxG.fixedTimestep = false;

			NoteVariables.init();

			Options.init();

			LogStyle.ERROR.throwException = Options.getData("throwExceptionOnError");

			FlxSprite.defaultAntialiasing = Options.getData("antialiasing");

			FlxG.stage.window.vsync = Options.getData("vSync");

			PlayerSettings.init();
			PlayerSettings.player1.controls.loadKeyBinds();

			Highscore.load();
			NoteColors.load();
			#if MODDING_ALLOWED
			ModList.load();
			PolymodHandler.loadMods();
			MusicBeatState.windowNamePrefix = Options.getData("curMod");
			CoolUtil.setWindowIcon("mods/" + Options.getData("curMod") + "/_polymod_icon.png");
			Options.initModOptions();
			#end
			NoteVariables.init();
			Options.fixBinds();
			FlxG.drawFramerate = Options.getData("maxFPS");

			#if FLX_NO_DEBUG
			if (Options.getData("flixelStartupScreen") && !doneFlixelSplash) {
				doneFlixelSplash = true;
				FlxG.switchState(() -> new FlxSplash(() -> new TitleState()));
				return;
			}
			#end

			if (Options.getData("flashingLights") == null)
				FlxG.switchState(() -> new FlashingLightsMenu());

			curWacky = FlxG.random.getObject(getIntroTextShit());

			super.create();

			#if DISCORD_ALLOWED
			if (Options.getData("discordRPC"))
				DiscordClient.startup();

			DiscordClient.loadModPresence();

			Application.current.onExit.add(function(exitCode) {
				DiscordClient.shutdown();

				#if linux
				if (GamemodeClient.request_end() != 0) {
					trace('Failed to request gamemode end: ${GamemodeClient.error_string()}...', ERROR);
					System.exit(1);
				} else{
					trace('Succesfully requested gamemode to end...');
				}
				#end

				for (key in Options.saves.keys()) {
					if (key != null)
						Options.saves.get(key).close();
				}
			}, false, 100);
			#end

			firstTimeStarting = true;
		}

		new FlxTimer().start(1, function(tmr:FlxTimer) startIntro());
		call('createPost');
	}

	public var logoBl:FlxSprite;
	public var gfDance:FlxSprite;
	public var danceLeft:Bool = false;
	public var titleText:FlxSprite;

	public static var version:String = "vnull";

	public static inline function playTitleMusic() {
		FlxG.sound.playMusic(MusicUtilities.getTitleMusic(), 0);
	}

	public function startIntro() {
		if (!initialized) {
			call("startIntro");

			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;

			playTitleMusic();
			Conductor.changeBPM(102);

			var now:Date = Date.now();

			if (((now.getDay() == 5 && now.getHours() >= 18) || Options.getData("nightMusic"))) {
				Conductor.changeBPM(117);
			}

			FlxG.sound.music.fadeIn(4, 0, 0.7);

			Main.toggleFPS(Options.getData("fpsCounter"));
			Main.toggleMem(Options.getData("memoryCounter"));
			Main.toggleVers(Options.getData("versionDisplay"));
			Main.toggleLogs(Options.getData("developer"));
			Main.changeFont(Options.getData("infoDisplayFont"));
			Main.toggleCommitHash(Options.getData("showCommitHash"));

			call("startIntroPost");
		}

		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			playTitleMusic();
		}

		version = '${Application.current.meta.get('name')} ${CoolUtil.getCurrentVersion()}';

		call("createTitleAssets");

		logoBl = new FlxSprite(0, 0);
		logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		logoBl.shader = swagShader.shader;

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.shader = swagShader.shader;

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.animation.play('idle');
		titleText.updateHitbox();
		titleText.shader = swagShader.shader;

		add(gfDance);
		add(logoBl);
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		newgrounds = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.gpuBitmap('title/newgrounds_logo'));
		newgrounds.scale.set(0.8, 0.8);
		newgrounds.updateHitbox();
		newgrounds.screenCenter(X);
		newgrounds.visible = false;
		add(newgrounds);

		call("createTitleAssetsPost");

		titleTextData = CoolUtil.coolTextFile(Paths.txt("titleText", "preload"));

		if (initialized) {
			skipIntro();
		}

		FlxG.mouse.visible = false;
		initialized = true;
	}

	public function getIntroTextShit():Array<Array<String>> {
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray) {
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	public var transitioning:Bool = false;

	public override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.Y) {
			FlxTween.tween(FlxG.stage.window, {x: FlxG.stage.window.x + 300}, 1.4, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.35});
			FlxTween.tween(FlxG.stage.window, {y: FlxG.stage.window.y + 100}, 0.7, {ease: FlxEase.quadInOut, type: PINGPONG});
		}

		if (controls.LEFT)
			swagShader.hue -= elapsed * 0.1;

		if (controls.RIGHT)
			swagShader.hue += elapsed * 0.1;

		#if MODDING_ALLOWED
		if (FlxG.keys.justPressed.TAB && !transitioning) {
			openSubState(new modding.SwitchModSubstate());
			persistentUpdate = false;
		}
		#end

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || FlxG.mouse.justPressed;

		for (touch in FlxG.touches.list) {
			if (touch.justPressed) {
				pressedEnter = true;
			}
		}

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null) {
			if (gamepad.justPressed.START)
				pressedEnter = true;
		}

		if (pressedEnter && !transitioning && skippedIntro) {
			if (titleText != null)
				titleText.animation.play('press');

			if (Options.getData("flashingLights"))
				FlxG.camera.flash(FlxColor.WHITE, 1);

			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;

			call("checkForUpdate");
			#if CHECK_FOR_UPDATES
			if (Options.getData("checkForUpdates")) {
				new FlxTimer().start(2, (tmr:FlxTimer) -> {
					var http:Http = new Http("https://raw.githubusercontent.com/Vortex2Oblivion/LeatherEngine/main/version.txt");
					http.onData = (data:String) -> {
						data = 'v' + data;
						if (CoolUtil.getCurrentVersion() != data) {
							trace('Outdated Version Detected! ' + data.trim() + ' != ' + CoolUtil.getCurrentVersion(), WARNING);
							Main.display.version += ' - UPDATE AVALIABLE (${data.trim()})';
							FlxG.switchState(() -> new OutdatedSubState(data.trim()));
						} else {
							FlxG.switchState(() -> new MainMenuState());
						}
					}

					http.onError = (error:String) -> {
						trace(error, ERROR);
						FlxG.switchState(() -> new MainMenuState()); // fail so we go anyway
					}

					http.request();
				});
			} else {
				new FlxTimer().start(2, (tmr:FlxTimer) -> {
					FlxG.switchState(() -> new MainMenuState());
				});
			}
			#else
			new FlxTimer().start(2, (tmr:FlxTimer) -> {
				FlxG.switchState(() -> new MainMenuState());
			});
			#end
		}

		if (pressedEnter && !skippedIntro) {
			skipIntro();
		}

		super.update(elapsed);
		call("update", [elapsed]);
	}

	public function createCoolText(textArray:Array<String>) {
		call("createCoolText", textArray);
		for (i in 0...textArray.length) {
			addMoreText(textArray[i]);
		}
		call("createCoolTextPost", textArray);
	}

	public function addMoreText(text:String) {
		call("addMoreText", [text]);
		var coolText:Alphabet = new Alphabet(0, 0, text.toUpperCase(), true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
		call("addMoreTextPost", [text]);
	}

	public function deleteCoolText() {
		call("deleteCoolText");
		if (textGroup?.members != null) {
			while (textGroup.members.length > 0) {
				credGroup.remove(textGroup.members[0], true);
				textGroup.remove(textGroup.members[0], true);
			}
		}
		call("deleteCoolTextPost");
	}

	public function textDataText(line:Int) {
		if (titleTextData == null || line < 0) {
			return;
		}

		var lineText:Null<String> = titleTextData[line];
		if (lineText == null) {
			return;
		}

		if (lineText.contains("~")) {
			createCoolText(lineText.split("~"));
		} else {
			addMoreText(lineText);
		}
	}

	public var titleTextData:Array<String>;

	override function beatHit() {
		super.beatHit();

		if (logoBl != null) {
			logoBl.animation.play('bump');
		}
		danceLeft = !danceLeft;

		if (gfDance != null) {
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if (skippedIntro) {
			return;
		}

		switch (curBeat) {
			case 1:
				textDataText(0);
			case 3:
				textDataText(1);
			case 4:
				deleteCoolText();
			case 5:
				textDataText(2);
			case 7:
				textDataText(3);
				if (newgrounds != null)
					newgrounds.visible = true;
			case 8:
				deleteCoolText();
				if (newgrounds != null)
					newgrounds.visible = false;
			case 9:
				if (curWacky[0] != null) {
					createCoolText([curWacky[0]]);
				}
			case 11:
				if (curWacky[1] != null) {
					addMoreText(curWacky[1]);
				}
			case 12:
				deleteCoolText();
			// yipee
			case 13 | 14 | 15:
				textDataText(curBeat - 9);
			case 16:
				skipIntro();
		}

		MusicBeatState.windowNameSuffix = skippedIntro ? "" : " " + Std.string(FlxMath.bound(16 - curBeat, 1, 15));

		call("beatHit");
	}

	public var skippedIntro:Bool = false;

	public function skipIntro():Void {
		call("skipIntro");
		if (!skippedIntro) {
			MusicBeatState.windowNameSuffix = "";

			if (Options.getData("flashingLights"))
				FlxG.camera.flash(FlxColor.WHITE, 4);

			remove(newgrounds);
			remove(credGroup);
			skippedIntro = true;
		}
		call("skipIntroPost");
	}
}
