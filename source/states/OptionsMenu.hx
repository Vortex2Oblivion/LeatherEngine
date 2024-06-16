package states;

import utilities.Options;
import substates.UISkinSelect;
import substates.ControlMenuSubstate;
import utilities.MusicUtilities;
import ui.Option;
import ui.Checkbox;
import flixel.group.FlxGroup;
import toolbox.ChartingState;
import toolbox.StageMakingState;
import flixel.sound.FlxSound;
import toolbox.CharacterCreator;
import utilities.Controls.Control;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import ui.Alphabet;
import game.Song;
import toolbox.StageMakingState;
import game.Highscore;
import openfl.utils.Assets as OpenFLAssets;

class OptionsMenu extends MusicBeatState {
	var curSelected:Int = 0;
	var ui_Skin:Null<String>;

	public var inMenu = false;

	public var pages:Map<String, Array<Dynamic>> = [
		"Categories" => [
			new PageOption("Gameplay", "Gameplay", "Test Description"),
			new PageOption("Graphics", "Graphics"),
			new PageOption("Misc", "Misc"),
			new PageOption("Mobile Options", "Mobile Options"),
			new PageOption("Developer Options", "Developer Options")
		],
		"Gameplay" => [
			new PageOption("Back", "Categories"),
			new GameSubStateOption("Binds", substates.ControlMenuSubstate),
			new BoolOption("Key Bind Reminders", "extraKeyReminders"),
			new GameSubStateOption("Song Offset", substates.SongOffsetMenu),
			new PageOption("Judgements", "Judgements"),
			new PageOption("Input Options", "Input Options"),
			new BoolOption("Downscroll", "downscroll"),
			new BoolOption("Middlescroll", "middlescroll"),
			new BoolOption("Bot", "botplay"),
			new BoolOption("Quick Restart", "quickRestart"),
			new BoolOption("No Death", "noDeath"),
			new BoolOption("Use Custom Scrollspeed", "useCustomScrollSpeed"),
			new GameSubStateOption("Custom Scroll Speed", substates.ScrollSpeedMenu),
			new StringSaveOption("Hitsound", CoolUtil.coolTextFile(Paths.txt("hitsoundList")), "hitsound")
		],
		"Graphics" => [
			new PageOption("Back", "Categories"),
			new PageOption("Note Options", "Note Options"),
			new PageOption("Info Display", "Info Display"),
			new PageOption("Optimizations", "Optimizations"),
			new GameSubStateOption("Max FPS", substates.MaxFPSMenu),
			new BoolOption("Bigger Score Text", "biggerScoreInfo"),
			new BoolOption("Bigger Info Text", "biggerInfoText"),
			new StringSaveOption("Time Bar Style", ["leather engine", "psych engine", "old kade engine"], "timeBarStyle"),
			new PageOption("Screen Effects", "Screen Effects"),
			new GameStateOption("Change Hud Settings", new ui.HUDAdjustment())
		],
		"Misc" => [
			new PageOption("Back", "Categories"),
			new BoolOption("Prototype Title Screen", "oldTitle"),
			new BoolOption("Friday Night Title Music", "nightMusic"),
			new BoolOption("Watermarks", "watermarks"),
			new BoolOption("Freeplay Music", "freeplayMusic"),
			#if DISCORD_ALLOWED
			new BoolOption("Discord RPC", "discordRPC"),
			#end
			new StringSaveOption("Cutscenes Play On", ["story", "freeplay", "both"], "cutscenePlaysOn"),
			new StringSaveOption("Play As", ["bf", "opponent"], "playAs"),
			new BoolOption("Disable Debug Menus", "disableDebugMenus"),
			new BoolOption("Invisible Notes", "invisibleNotes"),
			new BoolOption("Auto Pause", "autoPause"),
			new BoolOption("Load Asynchronously", "loadAsynchronously"),
			new BoolOption("Flixel Splash Screen", "flixelStartupScreen"),
			new BoolOption("Show Score", "showScore"),
			new BoolOption("Dinnerbone Mode", "dinnerbone"),
			new GameSubStateOption("Import Old Scores", substates.ImportHighscoresSubstate)
		],
		"Optimizations" => [
			new PageOption("Back", "Graphics"),
			new BoolOption("Antialiasing", "antialiasing"),
			new BoolOption("Health Icons", "healthIcons"),
			new BoolOption("Health Bar", "healthBar"),
			new BoolOption("Ratings and Combo", "ratingsAndCombo"),
			new BoolOption("Chars And BGs", "charsAndBGs"),
			new BoolOption("Menu Backgrounds", "menuBGs"),
			new BoolOption("Optimized Characters", "optimizedChars"),
			new BoolOption("Animated Backgrounds", "animatedBGs"),
			new BoolOption("Preload Stage Events", "preloadChangeBGs"),
			new BoolOption("Persistent Cached Data", "memoryLeaks"),
			#if MODCHARTING_TOOLS
			new BoolOption("Optimized Modcharts", "optimizedModcharts"),
			#end
		],
		"Info Display" => [
			new PageOption("Back", "Graphics"),
			new DisplayFontOption("Display Font", [
				"_sans",
				OpenFLAssets.getFont(Paths.font("vcr.ttf")).fontName,
				OpenFLAssets.getFont(Paths.font("pixel.otf")).fontName
			], "infoDisplayFont"),
			new BoolOption("FPS Counter", "fpsCounter"),
			new BoolOption("Memory Counter", "memoryCounter"),
			new BoolOption("Version Display", "versionDisplay")
		],
		"Judgements" => [
			new PageOption("Back", "Gameplay"),
			new GameSubStateOption("Timings", substates.JudgementMenu),
			new StringSaveOption("Rating Mode", ["psych", "simple", "complex"], "ratingType"),
			new BoolOption("Marvelous Ratings", "marvelousRatings"),
			new BoolOption("Show Rating Count", "sideRatings")
		],
		"Input Options" => [
			new PageOption("Back", "Gameplay"),
			new StringSaveOption("Input Mode", ["standard", "rhythm"], "inputSystem"),
			new BoolOption("Anti Mash", "antiMash"),
			new BoolOption("Shit gives Miss", "missOnShit"),
			new BoolOption("Ghost Tapping", "ghostTapping"),
			new BoolOption("Gain Misses on Sustains", "missOnHeldNotes"),
			new BoolOption("No Miss", "noHit"),
			new BoolOption("Reset Button", "resetButton")
		],
		"Note Options" => [
			new PageOption("Back", "Graphics"),
			new GameSubStateOption("Note BG Alpha", substates.NoteBGAlphaMenu),
			new BoolOption("Player Note Glow When Hit", "playerStrumsGlow"),
			new BoolOption("Enemy Note Glow When Hit", "enemyStrumsGlow"),
			new BoolOption("Note Glow When Can Hit", "playerStrumsGlowWhenCanBeHit"),
			new BoolOption("Player Note Splashes", "playerNoteSplashes"),
			new BoolOption("Enemy Note Splashes", "opponentNoteSplashes"),
			new BoolOption("Note Accuracy Text", "displayMs"),
			new GameSubStateOption("Note Colors", substates.NoteColorSubstate),
			new BoolOption("Color Quantization", "colorQuantization"),
			new GameSubStateOption("UI Skin", substates.UISkinSelect)
		],
		"Screen Effects" => [
			new PageOption("Back", "Graphics"),
			new BoolOption("Camera Tracks Direction", "cameraTracksDirections"),
			new BoolOption("Camera Bounce", "cameraZooms"),
			new BoolOption("Flashing Lights", "flashingLights"),
			new BoolOption("Screen Shake", "screenShakes"),
			new BoolOption("Shaders", "shaders")
		],
		"Mobile Options" => [
			new PageOption("Back", "Categories"),
			new GameSubStateOption("Mobile Controls Opacity", mobile.substates.MobileControlsAlphaMenu),
			new StringSaveOption("Hitbox Design", ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"], "hitboxType")#if mobile ,
			new BoolOption("Allow Phone Screensaver", "screenSaver")
			#end
		],
		"Developer Options" => [
			new PageOption("Back", "Categories"),
			new BoolOption("Developer Mode", "developer")
		]
	];

	public var page:FlxTypedGroup<Option> = new FlxTypedGroup<Option>();
	public var pageName:String = "Categories";
	public static var instance:OptionsMenu;

	override function create():Void {
		if (ui_Skin == null || ui_Skin == "default")
			ui_Skin = Options.getData("uiSkin");

		MusicBeatState.windowNameSuffix = "";
		instance = this;

		var menuBG:FlxSprite;

		if(Options.getData("menuBGs"))
			if (!Assets.exists(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuDesat')))
				menuBG = new FlxSprite().loadGraphic(Paths.image('ui skins/default/backgrounds/menuDesat'));
			else
				menuBG = new FlxSprite().loadGraphic(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuDesat'));
		else
			menuBG = new FlxSprite().makeGraphic(128630, FlxColor.fromString("#E1E1E1"), false, "optimizedMenuDesat");

		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		addVirtualPad(UP_DOWN, A_B);

		super.create();

		add(page);

		loadPage("Categories");

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(MusicUtilities.GetOptionsMenuMusic(), 0.7, true);
	}

	public function loadPage(loadedPageName:String):Void {
		pageName = loadedPageName;

		inMenu = true;
		instance.curSelected = 0;

		var curPage:FlxTypedGroup<Option> = instance.page;
		curPage.clear();

		for (x in instance.pages.get(loadedPageName).copy()) {
			curPage.add(x);
		}

		inMenu = false;
		var bruh:Int = 0;

		for (x in instance.page.members) {
			x.alphabetText.targetY = bruh - instance.curSelected;
			bruh++;
		}
	}

	function goBack() {
		if (pageName != "Categories") {
			loadPage(cast(page.members[0], PageOption).pageName);
			return;
		}

		FlxG.switchState(new MainMenuState());
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!inMenu) {
			if (-1 * Math.floor(FlxG.mouse.wheel) != 0) {
				curSelected -= 1 * Math.floor(FlxG.mouse.wheel);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.UP_P) {
				curSelected --;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.DOWN_P) {
				curSelected ++;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.BACK)
				goBack();
		} else {
			if (controls.BACK)
				inMenu = false;
		}

		if (curSelected < 0)
			curSelected = page.length - 1;

		if (curSelected >= page.length)
			curSelected = 0;

		var bruh = 0;

		for (x in page.members) {
			x.alphabetText.targetY = bruh - curSelected;
			bruh++;
		}

		for (x in page.members) {
			if (x.alphabetText.targetY != 0) {
				for (item in x.members) {
					item.alpha = 0.6;
				}
			} else {
				for (item in x.members) {
					item.alpha = 1;
				}
			}
		}
	}

	override function closeSubState() {
		persistentUpdate = true;
		removeVirtualPad();
		addVirtualPad(UP_DOWN, A_B);
		super.closeSubState();
	}
}
