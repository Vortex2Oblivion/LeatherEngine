package states;

import haxe.Json;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import utilities.MusicUtilities;
import ui.Option;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.utils.Assets;

using utilities.BackgroundUtil;

class OptionsMenu extends MusicBeatState {
	public var curSelected:Int = 0;

	public var inMenu = false;

	public var pages:Map<String, Array<Option>> = [
		"Categories" => [
			new PageOption("Gameplay", "Gameplay", "Change gameplay-related options,\nsuch as downscroll and ghost tapping."),
			new PageOption("Graphics", "Graphics", "Change graphical-related options,\nsuch as max FPS."),
			new PageOption("Misc", "Misc", "Change miscellaneous options that\ndon't fit in the other categories."),
			#if MODDING_ALLOWED
			new PageOption("Mod Options", "Mod Options", "Change options for specific mods."),
			#end
			new PageOption("Developer Options", "Developer Options", "Change options for developing mods.")
		],
		"Gameplay" => [
			new PageOption("Back", "Categories", "Go back to the main menu."),
			new GameSubStateOption("Binds", substates.ControlMenuSubstate, "Change key bindings."),
			new BoolOption("Key Bind Reminders", "extraKeyReminders", "Should key binding reminders show up\nwhen playing a non-4-key song."),
			new GameSubStateOption("Song Offset", substates.SongOffsetMenu, "Change the offset of the song."),
			new PageOption("Judgements", "Judgements", "Change settings related to judgments.\n(sick, good, bad, etc.)"),
			new PageOption("Input Options", "Input Options", "Change options related to note inputs."),
			new BoolOption("Downscroll", "downscroll", "Toggle downscroll."),
			new BoolOption("Middlescroll", "middlescroll", "Toggle middlescroll."),
			new BoolOption("Bot", "botplay", "Toggle botplay for songs.\nUseful for showcasing hard charts."),
			new BoolOption("Quick Restart", "quickRestart", "When toggled, the game over animation will not play."),
			new BoolOption("No Death", "noDeath", "When toggled, the player is unable to die."),
			new BoolOption("Use Custom Scrollspeed", "useCustomScrollSpeed", "When toggled, a custom scroll speed will be used."),
			new GameSubStateOption("Custom Scroll Speed", substates.ScrollSpeedMenu, "Change the value of the custom scroll speed."),
			new StringSaveOption("Hitsound", CoolUtil.coolTextFile(Paths.txt("hitsoundList")), "hitsound", "Change the hitsound used when hitting a note.")
		],
		"Graphics" => [
			new PageOption("Back", "Categories", "Go back to the main menu."),
			new PageOption("Note Options", "Note Options", "Change note-related options."),
			new PageOption("Info Display", "Info Display", "Change optiosn related to the info display.\n(FPS counter, memory display, etc)."),
			new PageOption("Optimizations", "Optimizations", "Change optimization options, such as anitaliasing."),
			new GameSubStateOption("Max FPS", substates.MaxFPSMenu, "Change the maximum framerate."),
			new BoolOption("VSync", "vSync", "Toggle VSync."),
			new BoolOption("Bigger Score Text", "biggerScoreInfo", "When toggled, the score text will have a larger font."),
			new BoolOption("Bigger Info Text", "biggerInfoText", "When toggled, the time bar will have a larger font."),
			new StringSaveOption("Time Bar Style", ["leather engine", "psych engine", "old kade engine"], "timeBarStyle", "Change the style of the time bar."),
			new PageOption("Screen Effects", "Screen Effects", "Toggle screen effect options, such as camera zooming and shaders."),
			new GameStateOption("Change Hud Settings", ui.HUDAdjustment, "Change the position of hud objects, such as the ratings.")
		],
		"Misc" => [
			new PageOption("Back", "Categories", "Go back to the main menu."),
			new BoolOption("Friday Night Title Music", "nightMusic", "When toggled, the music for playing\non a friday night will always play."),
			new BoolOption("Freeplay Music", "freeplayMusic", "When toggled, instrumentals for freeplay songs will auto play."),
			#if DISCORD_ALLOWED
			new BoolOption("Discord RPC", "discordRPC", "Toggles discord rich presence."),
			#end
			new StringSaveOption("Cutscenes Play On", ["story", "freeplay", "both"], "cutscenePlaysOn", "Change when cutscenes play."),
			new StringSaveOption("Play As", ["bf", "opponent"], "playAs", "Change which side of the chart you play."),
			new BoolOption("Disable Debug Menus", "disableDebugMenus", "Disable debug menus, such as the chart editor."),
			new BoolOption("Invisible Notes", "invisibleNotes", "Makes notes invisible.\n(why would you want this?)"),
			new BoolOption("Auto Pause", "autoPause", "Will the game automatically pause when losing focus."),
			#if (target.threaded)
			new BoolOption("Load Asynchronously", "loadAsynchronously", "Loads some elements of the game will be loaded\nasyncrnously to speed up load times."),
			#end
			new BoolOption("Flixel Splash Screen", "flixelStartupScreen", "Toggles the haxeflixel startup splash screen."),
			new BoolOption("Skip Results", "skipResultsScreen", "When toggled, the results screen will be skipped."),
			#if CHECK_FOR_UPDATES
			new BoolOption("Check For Updates", "checkForUpdates", "Disables the game checking for an update on startup."),
			#end
			new BoolOption("Show Score", "showScore", "Shows the current score."),
			new BoolOption("Dinnerbone Mode", "dinnerbone", "Dinnerbone mode."),
			new GameSubStateOption("Import Old Scores", substates.ImportHighscoresSubstate, "Import scores from legacy leather engine versions.")
		],
		"Optimizations" => [
			new PageOption("Back", "Graphics", "Go back to the graphics menu."),
			new BoolOption("Antialiasing", "antialiasing",
				"When toggled, antialiasing will be enabled,\nmaking sprites smoother at the cost of some performance.\n(Should only really matter on really low-end devices)"),
			new BoolOption("Low Quality", "lowQuality", "When toggled, the game will not load\nunneeded sprites to improve performance.\n(when possible)"),
			new BoolOption("Health Icons", "healthIcons", "Toggles health icons."),
			new BoolOption("Health Bar", "healthBar", "Toggles the health bar."),
			new BoolOption("Ratings and Combo", "ratingsAndCombo", "When toggled, ratings and combo popups will be displayed."),
			new BoolOption("Chars And BGs", "charsAndBGs", "When not toggled, the game will\nhide characters and stages while ingame."),
			new BoolOption("Menu Backgrounds", "menuBGs", "When not toggled, color rectangles will be\nloaded instead of the menu background image."),
			new BoolOption("Optimized Characters", "optimizedChars",
				"When toggled, the game will load optimized spritesheets,\nremoving all unneeded animations (when possible)"),
			new BoolOption("Animated Backgrounds", "animatedBGs",
				"When not toggled, the game will load non-animated\nversions of stage sprites (when possible)"),
			new BoolOption("Preload Stage Events", "preloadChangeBGs",
				"When toggled, the game will preload stage change events,\nincreasing memory usage,\nbut will prevent lag spikes on stage change."),
			new BoolOption("Persistent Cached Data", "memoryLeaks",
				"When toggled, the game will never clear stored memory,\nspeeding up load times.\n(WARNING: Can lead to VERY high memory usage)"),
			new BoolOption("VRAM Sprites", "vramSprites",
				"When toggled, the game will try and store\nsprites in your GPU, saving on RAM.\nTurn this off if you have a bad GPU."),
			#if MODCHARTING_TOOLS
			new BoolOption("Optimized Modcharts", "optimizedModcharts",
				"When toggled, modchart sustains will use a more\noptimized renderer,at the cost of stretchy sustains."),
			#end
		],
		"Info Display" => [
			new PageOption("Back", "Graphics", "Go back to the graphics menu."),
			new DisplayFontOption("Display Font", [
				"_sans",
				Assets.getFont(Paths.font("vcr.ttf")).fontName,
				Assets.getFont(Paths.font("pixel.otf")).fontName
			],
				"infoDisplayFont", "Change the font used for the info display."),
			new BoolOption("FPS Counter", "fpsCounter", "Should the FPS counter be shown?"),
			new BoolOption("Memory Counter", "memoryCounter", "Should the memory counter be shown?"),
			new BoolOption("Version Display", "versionDisplay", "Should the engine version be shown?"),
			new BoolOption("Commit Hash", "showCommitHash", "Should the hash for the current commit be shown?")
		],
		"Judgements" => [
			new PageOption("Back", "Gameplay", "Go back to the gameplay menu."),
			new GameSubStateOption("Timings", substates.JudgementMenu, "Edit the timings for ratings."),
			new StringSaveOption("Rating Mode", ["psych", "simple", "complex"], "ratingType", "Change how ratings are calculated."),
			new BoolOption("Marvelous Ratings", "marvelousRatings", "When toggled, marvelous ratings will be shown,\nelse, sick will be the max rating."),
			new BoolOption("Show Rating Count", "sideRatings", "Should ratings be shown on the side of the screen?")
		],
		"Input Options" => [
			new PageOption("Back", "Gameplay", "Go back to the gameplay menu."),
			new StringSaveOption("Input Mode", ["standard", "rhythm"], "inputSystem", "Change how inputs work."),
			new BoolOption("Anti Mash", "antiMash", "When toggled, mashing keys will punish the player."),
			new BoolOption("Shit gives Miss", "missOnShit", "When toggled, getting a \"shit\" rating will also count as a miss."),
			new BoolOption("Ghost Tapping", "ghostTapping", "When not toggled, hitting a key\nat the wrong time will give a miss."),
			new BoolOption("Gain Misses on Sustains", "missOnHeldNotes", "When toggled, each sustain segment will give misses."),
			new BoolOption("Death On Miss", "noHit", "When toggled, getting a miss will cause a death.\n(useful for when trying to FC a song.)"),
			new BoolOption("Reset Button", "resetButton", "When toggled, enables a keybind for causing an instant death.")
		],
		"Note Options" => [
			new PageOption("Back", "Graphics", "Go back to the graphics menu."),
			new GameSubStateOption("Note BG Alpha", substates.NoteBGAlphaMenu, "Change the alpha of the note lane underlay."),
			new BoolOption("Enemy Note Glow", "enemyStrumsGlow", "When toggled, enemy strums will\nlight up when the enemy hits a note."),
			new BoolOption("Player Note Splashes", "playerNoteSplashes",
				"When toggled, note splashes will show up\nwhen the player hits a \"sick\" or higher rating."),
			new BoolOption("Enemy Note Splashes", "opponentNoteSplashes",
				"When toggled, note splashes will show up\nwhen the enemy hits a \"sick\" or higher rating."),
			new BoolOption("Note Accuracy Text", "displayMs", "Toggles a text popup showing how early or late you hit a note."),
			new GameSubStateOption("Note Colors", substates.NoteColorSubstate, "Change the colors of notes."),
			new BoolOption("Color Quantization", "colorQuantization", "When toggled, note colors will be changed depending on the beat."),
			new GameSubStateOption("UI Skin", substates.UISkinSelect, "Change the UI skin for notes and menus.")
		],
		"Screen Effects" => [
			new PageOption("Back", "Graphics", "Go back to the graphics menu."),
			new BoolOption("Camera Tracks Direction", "cameraTracksDirections", "When toggled, the camera will follow the direction of the note."),
			new BoolOption("Camera Bounce", "cameraZooms", "When toggled, the game and hud will zoom in on beat."),
			new BoolOption("Flashing Lights", "flashingLights", "Toggles flashing lights."),
			new BoolOption("Screen Shake", "screenShakes", "Toggles screen shake effects."),
			new BoolOption("Shaders", "shaders", "Toggles shaders.")
		],
		"Developer Options" => [
			new PageOption("Back", "Categories", "Go back to the main menu."),
			new BoolOption("Developer Mode", "developer", "When toggled, enables developer tools.\n(traced lines display, toolbox, etc)"),
			new DeveloperOption("Throw Exception On Error", "throwExceptionOnError",
				"When toggled, the game will throw an\nexception when an error is thrown."),
			new DeveloperOption("Auto Open Charter", "autoOpenCharter",
				"When toggled, the game will automatically\nopen the chart editor when no chart is found."),
			new StepperSaveDeveloperOption("Chart Backup Interval", 1, 10, "backupDuration", 1,
				"Change how long the game will wait\nbefore creating a chart backup.\n(in minutes.)"),
		],
		#if MODDING_ALLOWED
		"Mod Options" => [new PageOption("Back", "Categories", "Go back to the main menu."),]
		#end
	];

	public var page:FlxTypedGroup<Option> = new FlxTypedGroup<Option>();
	public var pageName:String = "Categories";

	public static var instance:OptionsMenu;

	public var menuBG:FlxSprite;

	public static var playing:Bool = false;

	private var defaultPage:String;
	private var backgroundColor:FlxColor;

	public var descriptionText:FlxText;
	public var descriptionBackground:FlxSprite;

	override public function new(defaultPage:String = "Categories", backgroundColor:FlxColor = 0xFFea71fd) {
		this.defaultPage = defaultPage;
		this.backgroundColor = backgroundColor;
		super();
	}

	public override function create():Void {
		#if MODDING_ALLOWED
		for (mod in modding.ModList.getActiveMods(modding.PolymodHandler.metadataArrays)) {
			pages.get("Mod Options").push(new PageOption(mod, mod, modding.ModList.modMetadatas.get(mod).description));
			pages.set(mod, [new PageOption("Back", "Mod Options", "Go back to mod options.")]);
			if (sys.FileSystem.exists('mods/$mod/data/options.json')) {
				var modOptions:modding.ModOptions = cast Json.parse(sys.io.File.getContent('mods/$mod/data/options.json'));
				for (option in modOptions.options) {
					switch (StringTools.trim(option.type).toLowerCase()) { // thank you haxe for not wanting to cast it to a string.
						case "bool":
							pages.get(mod).push(new BoolOption(option.name, option.save, option.description, mod));
						case "string":
							pages.get(mod).push(new StringSaveOption(option.name, option.values, option.save, option.description, mod));
						#if HSCRIPT_ALLOWED
						case "state":
							pages.get(mod).push(new GameStateOption(option.name, new modding.custom.CustomState(option.script), option.description));
						case "substate":
							pages.get(mod).push(new GameSubStateOption(option.name, new modding.custom.CustomSubstate(option.script), option.description));
						#end
						default:
							throw 'Option type \'${option.type}\' is not a valid option type!';
					}
				}
			}
		}
		#end
		MusicBeatState.windowNameSuffix = "";
		instance = this;

		menuBG = new FlxSprite().makeBackground(backgroundColor);
		menuBG.scale.set(1.1, 1.1);
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		super.create();

		add(page);

		loadPage(defaultPage);

		descriptionBackground = new FlxSprite();
		descriptionBackground.makeGraphic(FlxG.width, 300, FlxColor.BLACK);
		descriptionBackground.alpha = 0.5;
		add(descriptionBackground);

		descriptionText = new FlxText();
		descriptionText.alignment = CENTER;
		descriptionText.borderStyle = OUTLINE;
		descriptionText.borderColor = FlxColor.BLACK;
		descriptionText.screenCenter(X);
		descriptionText.y = FlxG.height - 80;
		descriptionText.size = 32;
		descriptionText.font = Paths.font("vcr.ttf");
		descriptionText.borderSize = 2;
		add(descriptionText);

		FlxG.sound.playMusic(MusicUtilities.getOptionsMusic(), 0.7, true);
		OptionsMenu.playing = true;
	}

	public function loadPage(loadedPageName:String):Void {
		pageName = loadedPageName;

		inMenu = true;
		instance.curSelected = 0;

		var curPage:FlxTypedGroup<Option> = instance.page;
		curPage.clear();

		for (x in instance.pages.get(loadedPageName).copy()) {
			if (x != null) {
				curPage.add(x);
			}
		}

		inMenu = false;
		var bruh:Int = 0;

		for (x in instance.page.members) {
			x.alphabetText.targetY = bruh - instance.curSelected;
			bruh++;
		}
	}

	public function goBack() {
		if (pageName != defaultPage) {
			loadPage((cast(page.members[0], PageOption).pageName) ?? "Categories");
			return;
		}

		FlxG.switchState(() -> new MainMenuState());
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!inMenu) {
			if (-1 * Math.floor(FlxG.mouse.wheel) != 0) {
				curSelected -= 1 * Math.floor(FlxG.mouse.wheel);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.UP_P) {
				curSelected--;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.DOWN_P) {
				curSelected++;
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

		descriptionText.text = page.members[curSelected].optionDescription;
		descriptionText.screenCenter(X);
		descriptionText.y = FlxG.height - descriptionText.height - 50;

		descriptionBackground.setPosition(descriptionText.x - 10, descriptionText.y - 10);
		descriptionBackground.setGraphicSize(descriptionText.width + 20, descriptionText.height + 25);
		descriptionBackground.updateHitbox();
		for (x in page.members) {
			if (x.alphabetText.targetY != 0) {
				x.alpha = 0.6;
			} else {
				x.alpha = 1;
			}
			if ((x is DeveloperOption || x is StepperSaveDeveloperOption) && !Options.getData("developer")) {
				x.alpha *= 0.5;
			}
		}
	}
}
