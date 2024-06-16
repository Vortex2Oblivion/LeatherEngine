package states;

import flixel.math.FlxMath;
#if DISCORD_ALLOWED
import utilities.Discord.DiscordClient;
#end

import utilities.PlayerSettings;
import shaders.NoteColors;
import modding.ModList;
import game.Highscore;
import utilities.PlayerSettings;
#if discord_rpc
import utilities.Discord.DiscordClient;
#end
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

class TitleState extends MusicBeatState{
	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	static var firstTimeStarting:Bool = false;
	static var doneFlixelSplash:Bool = false;

	var swagShader:ColorSwapHSV;

	public static var instance:TitleState = null;

	public inline function call(func:String, ?args:Array<Dynamic>) {
		if(stateScript != null) stateScript.call(func, args);
	}

	override public function create():Void {
		MusicBeatState.windowNameSuffix = "";
		instance = this;
		swagShader = new ColorSwapHSV();

		if (!firstTimeStarting) {
			persistentUpdate = true;
			persistentDraw = true;

			FlxG.fixedTimestep = false;

			NoteVariables.init();
		
			Options.init();
			Options.fixBinds();

			PlayerSettings.init();
			PlayerSettings.player1.controls.loadKeyBinds();

			Highscore.load();
			NoteColors.load();
			#if MODDING_ALLOWED
			ModList.load();
			PolymodHandler.loadMods();
			#end
			MusicBeatState.windowNamePrefix = Assets.getText(Paths.txt("windowTitleBase", "preload"));
			CoolUtil.setWindowIcon("mods/"+Options.getData("curMod")+"/_polymod_icon.png");

			#if FLX_NO_DEBUG
			if (Options.getData("flixelStartupScreen") && !doneFlixelSplash) {
				doneFlixelSplash = true;
				FlxG.switchState(() -> new FlxSplash(new TitleState()));
				return;
			}
			#end

			if (Options.getData("flashingLights") == null)
				FlxG.switchState(new FlashingLightsMenu());

			curWacky = FlxG.random.getObject(getIntroTextShit());

			super.create();

			#if DISCORD_ALLOWED
			if (!DiscordClient.started && Options.getData("discordRPC"))
				DiscordClient.initialize();

			Application.current.onExit.add(function(exitCode) {
				DiscordClient.shutdown();

				for (key in Options.saves.keys()) {
					if (key != null)
						Options.saves.get(key).close();
				}
			}, false, 100);
			#end

			firstTimeStarting = true;
		}

		new FlxTimer().start(1, function(tmr:FlxTimer) startIntro());
	}

	var old_logo:FlxSprite;
	var old_logo_black:FlxSprite;

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	public static var version:String = "vnull";

	public static inline function playTitleMusic() {
		FlxG.sound.playMusic(MusicUtilities.GetTitleMusicPath(), 0);
	}

	function startIntro() {
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

			if (!Options.getData("oldTitle") && ((now.getDay() == 5 && now.getHours() >= 18) || Options.getData("nightMusic"))) {
				Conductor.changeBPM(117);
			}

			FlxG.sound.music.fadeIn(4, 0, 0.7);

			Main.toggleFPS(Options.getData("fpsCounter"));
			Main.toggleMem(Options.getData("memoryCounter"));
			Main.toggleVers(Options.getData("versionDisplay"));
			Main.toggleLogs(Options.getData("developer"));
			Main.changeFont(Options.getData("infoDisplayFont"));

			call("startIntroPost");
		}

		version = '${MusicBeatState.windowNamePrefix} (${CoolUtil.getCurrentVersion()})';

		var bg:FlxSprite = new FlxSprite();

		if (Options.getData("oldTitle")) {
			bg.loadGraphic(Paths.image("title/stageback"));
			bg.antialiasing = Options.getData("antialiasing");
			bg.setGraphicSize(Std.int(FlxG.width * 1.1));
			bg.updateHitbox();
			bg.screenCenter();
		} else {
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}

		add(bg);

		if (Options.getData("oldTitle")) {
			old_logo = new FlxSprite().loadGraphic(Paths.image('title/logo'));
			old_logo.screenCenter();
			old_logo.antialiasing = Options.getData("antialiasing");

			old_logo_black = new FlxSprite().loadGraphicFromSprite(old_logo);
			old_logo_black.screenCenter();
			old_logo_black.color = FlxColor.BLACK;
		} else {
			logoBl = new FlxSprite(0, 0);

			if (Options.getData("watermarks"))
				logoBl.frames = Paths.getSparrowAtlas('title/leatherLogoBumpin');
			else
				logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');

			logoBl.antialiasing = Options.getData("antialiasing");
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
			logoBl.animation.play('bump');
			logoBl.updateHitbox();
			logoBl.shader = swagShader.shader;
		}

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;
		gfDance.shader = swagShader.shader;

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = Options.getData("antialiasing");
		titleText.animation.play('idle');
		titleText.updateHitbox();
		titleText.shader = swagShader.shader;

		if (!Options.getData("oldTitle")) {
			add(logoBl);
			add(gfDance);
			add(titleText);
		} else {
			add(old_logo_black);
			add(old_logo);

			FlxTween.tween(old_logo_black, {y: old_logo_black.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
			FlxTween.tween(old_logo, {y: old_logo.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
		}

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('title/polymod_logo'));
		ngSpr.setGraphicSize(290); // aprox what newgrounds_logo.width * 0.8 was (289.6), only used cuz polymod_logo is different size than it lol!!!
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = Options.getData("antialiasing");
		ngSpr.visible = false;
		add(ngSpr);

		if (Options.getData("watermarks"))
			titleTextData = CoolUtil.coolTextFile(Paths.txt("watermarkTitleText", "preload"));
		else
			titleTextData = CoolUtil.coolTextFile(Paths.txt("titleText", "preload"));
		
		if (initialized) {
			skipIntro();
		}
			
		FlxG.mouse.visible = false;
		initialized = true;
	}

	function getIntroTextShit():Array<Array<String>> {
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray) {
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.Y) {
			FlxTween.tween(FlxG.stage.window, {x: FlxG.stage.window.x + 300}, 1.4, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.35});
			FlxTween.tween(FlxG.stage.window, {y: FlxG.stage.window.y + 100}, 0.7, {ease: FlxEase.quadInOut, type: PINGPONG});
		}

		if (controls.LEFT)
			swagShader.hue -= elapsed * 0.1;

		if (controls.RIGHT)
			swagShader.hue += elapsed * 0.1;

		#if MODDING_ALLOWED
		if(FlxG.keys.justPressed.TAB){
			openSubState(new modding.SwitchModSubstate());
			persistentUpdate = false;
		}
		#end

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

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

			if (Options.getData("oldTitle"))
				FlxG.sound.play(Paths.music("titleShoot"), 0.7);
			else
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;

			call("checkForUpdate");
			new FlxTimer().start(2, (tmr:FlxTimer) -> {
				var http:Http = new Http("https://raw.githubusercontent.com/Vortex2Oblivion/LeatherEngine-Extended-Support/main/version.txt");
				http.onData = (data:String) -> {
					data = 'v' + data;
					trace(data);

					if (CoolUtil.getCurrentVersion() != data) {
						trace('Outdated Version Detected! ' + data + ' != ' + CoolUtil.getCurrentVersion(), WARNING);
						FlxG.switchState(new OutdatedSubState(data));
					} else {
						FlxG.switchState(new MainMenuState());
					}
				}

				http.onError = (error:String) -> {
					trace('$error', ERROR);
					FlxG.switchState(new MainMenuState()); // fail so we go anyway
				}

				http.request();
			});
		}

		if (pressedEnter && !skippedIntro) {
			skipIntro();
		}

		super.update(elapsed);
		call("update", [elapsed]);
	}

	function createCoolText(textArray:Array<String>) {
		call("createCoolText", textArray);
		for (i in 0...textArray.length) {
			addMoreText(textArray[i]);
		}
		call("createCoolTextPost", textArray);
	}

	function addMoreText(text:String) {
		call("addMoreText", [text]);
		var coolText:Alphabet = new Alphabet(0, 0, text.toUpperCase(), true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
		call("addMoreTextPost", [text]);
	}

	function deleteCoolText() {
		call("deleteCoolText");
		while (textGroup.members.length > 0) {
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
		call("deleteCoolTextPost");
	}

	function textDataText(line:Int) {
		if (titleTextData == null || line < 0) {
			return;
		}

		var lineText:Null<String> = titleTextData[line];
		if (lineText == null) {
			return;
		}

		if (lineText.contains("~")) {
			var coolText = lineText.split("~");
			createCoolText(coolText);
		} else {
			addMoreText(lineText);
		}
	}

	public var titleTextData:Array<String>;

	override function beatHit() {
		super.beatHit();

		if (!Options.getData("oldTitle")) {
			if (logoBl != null) {
				logoBl.animation.play('bump');
			}
			danceLeft = !danceLeft;

			if(gfDance != null){
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
					ngSpr.visible = true;
				case 8:
					deleteCoolText();
					ngSpr.visible = false;
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
		} else {
			remove(ngSpr);
			remove(credGroup);
			skippedIntro = true;
			MusicBeatState.windowNameSuffix = "";
		}
		
		call("beatHit");
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void {
		call("skipIntro");
		if (!skippedIntro) {
			MusicBeatState.windowNameSuffix = "";

			if (Options.getData("flashingLights"))
				FlxG.camera.flash(FlxColor.WHITE, 4);

			remove(ngSpr);
			remove(credGroup);
			skippedIntro = true;
		}
		call("skipIntroPost");
	}
}
