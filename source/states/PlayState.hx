package states;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxInput.FlxInputState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxShader;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import game.Boyfriend;
import game.Character;
import game.Conductor;
import game.Cutscene;
import game.Highscore;
import game.Note;
import game.NoteSplash;
import game.Section.SwagSection;
import game.Song;
import game.StageGroup;
import game.StrumNote;
import haxe.Json;
import haxe.io.Path;
import lime.app.Application;
import lime.media.AudioSource;
import lime.utils.Assets;
import modding.ModList;
import modding.ModchartUtilities;
import modding.scripts.languages.HScript;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import shaders.NoteColors;
import substates.GameOverSubstate;
import substates.PauseSubState;
import toolbox.ChartingState;
import ui.DialogueBox;
import ui.HealthIcon;
import utilities.NoteVariables;
import utilities.Ratings;

using StringTools;

#if sys
import sys.FileSystem;
#end
#if DISCORD_ALLOWED
import utilities.Discord.DiscordClient;
#end
#if MODDING_ALLOWED
import polymod.backends.PolymodAssets;
#end
#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideo;
#end
#if MODCHARTING_TOOLS
import modcharting.ModchartEditorState;
import modcharting.ModchartFuncs;
import modcharting.NoteMovement;
import modcharting.PlayfieldRenderer;
#end

/**
	The main gameplay state.
**/
class PlayState extends MusicBeatState {
	/**
		Current instance of `PlayState`.
	**/
	public static var instance:PlayState = null;

	/**
		The current stage in `PlayState`.
	**/
	public static var curStage:String = '';

	/**
		Current song data in `PlayState`.
	**/
	public static var SONG:SwagSong;

	/**
		`Bool` for whether we are currently in Story Mode.
	**/
	public static var isStoryMode:Bool = false;

	/**
		Current Story Mode week as an `Int`.

		(Generally unused / deprecated).
	**/
	public static var storyWeek:Int = 0;

	/**
		`Array` of all the songs that you are going
		to play next in Story Mode as `Strings`.
	**/
	public static var storyPlaylist:Array<String> = [];

	/**
		`String` representation of the current Story Mode difficulty.
	**/
	public static var storyDifficultyStr:String = "NORMAL";

	/**
		Total score over your current run in Story Mode.
	**/
	public static var campaignScore:Int = 0;

	/**
		Vocal track for the current song as a `FlxSound`.
	**/
	public var vocals:FlxSound;

	/**
		Your current opponent.
	**/
	public static var dad:Character;

	/**
		The current character in the middle of the 3 main characters.
	**/
	public static var gf:Character;

	/**
		The current player character.
	**/
	public static var boyfriend:Boyfriend;

	/**
		The current stage.
	**/
	public var stage:StageGroup;

	/**
		`FlxTypedGroup` of all currently active notes in the game.
	**/
	public var notes:FlxTypedGroup<Note>;

	/**
		`Array` of all the notes waiting to be spawned into the game (when their time comes to prevent lag).
	**/
	public var unspawnNotes:Array<Note> = [];

	/**
		Simple `FlxSprite` to help represent the strum line the strums initially spawn at.
	**/
	public var strumLine:FlxSprite;

	/**
		`FlxTypedGroup` of all current strums (enemy strums are first).
	**/
	public static var strumLineNotes:FlxTypedGroup<StrumNote>;

	/**
		`FlxTypedGroup` of all current player strums.
	**/
	public static var playerStrums:FlxTypedGroup<StrumNote>;

	/**
		`FlxTypedGroup` of all current enemy strums.
	**/
	public static var enemyStrums:FlxTypedGroup<StrumNote>;

	/**
		Simple `FlxObject` to store the camera's current position that it's following.
	**/
	public var camFollow:FlxObject;

	/**
	 * Should the camera be centered?
	 */
	public var centerCamera:Bool = false;

	/**
		Copy of `camFollow` used for transitioning between songs smoother.
	**/
	public static var prevCamFollow:FlxObject;

	/**
		`Bool` for whether or not the camera is currently zooming in and out to the song's beat.
	**/
	public var camZooming:Bool = false;

	/**
		Speed of camera.
	**/
	public var cameraSpeed:Float = 1;

	/**
		Speed of camera zooming.
	**/
	public var cameraZoomSpeed:Float = 1;

	/**
		Shortner for `SONG.song`.
	**/
	public var curSong:String = "";

	/**
		The interval of beats the current `gf` waits till their `dance` function gets called. (as an `Int`)

		Example:
			1 = Every Beat,
			2 = Every Other Beat,
			etc.
	**/
	public var gfSpeed:Int = 1;

	/**
		Current `health` of the player (stored as a range from `minHealth` to `maxHealth`, which is by default 0 to 2).
	**/
	public var health:Float = 1;

	/**
		Current `health` being shown on the `healthBar`. (Is inverted from normal when playing as opponent)
	**/
	public var healthShown:Float = 1;

	/**
		Minimum `health` value. (Defaults to 0)
	**/
	public var minHealth:Float = 0;

	/**
		Maximum `health` value. (Defaults to 2)
	**/
	public var maxHealth:Float = 2;

	/**
		Current combo (or amount of notes hit in a row without a combo break).
	**/
	public var combo:Int = 0;

	/**
		Current score for the player.
	**/
	public var songScore:Int = 0;

	/**
		Current miss count for the player.
	**/
	public var misses:Int = 0;

	/**
		Current accuracy for the player (0 - 100).
	**/
	public var accuracy:Float = 100.0;

	/**
		Background sprite for the health bar.
	**/
	public var healthBarBG:FlxSprite;

	/**
		The health bar.
	**/
	public var healthBar:FlxBar;

	/**
		Background sprites for the progress bar.
	**/
	public var timeBarBG:FlxSprite;

	/**
		The progress bar.
	**/
	public var timeBar:FlxBar;

	/**
		Variable for if `generateSong` has been called successfully yet.
	**/
	public var generatedMusic:Bool = false;

	/**
		Whether or not the player has started the song yet.
	**/
	public var startingSong:Bool = false;

	/**
		The icon for the player character (`bf`).
	**/
	public var iconP1:HealthIcon;

	/**
		The icon for the opponent character (`dad`).
	**/
	public var iconP2:HealthIcon;

	/**
		`FlxCamera` for all HUD/UI elements.
	**/
	public var camHUD:FlxCamera;

	/**
		`FlxCamera` for all elements part of the main scene.
	**/
	public var camGame:FlxCamera;

	/**
		Current text under the health bar (displays score and other stats).
	**/
	public var scoreTxt:FlxText;

	/**
		Current text near the progress / time bar.
	**/
	public var infoTxt:FlxText;

	/**
		Total notes interacted with. (Includes missing and hitting)
	**/
	public var totalNotes:Int = 0;

	/**
		Total notes hit (is a `Float` because it's used for accuracy calculations).
	**/
	public var hitNotes:Float = 0.0;

	/**
		`FlxGroup` for all the sprites that should go above the characters in a stage.
	**/
	public var foregroundSprites:FlxGroup = new FlxGroup();

	/**
		The default camera zoom (used for camera zooming properly).
	**/
	public var defaultCamZoom:Float = 1.05;

	/**
		The default hud camera zoom (used for zoom the hud properly).
	**/
	public var defaultHudCamZoom:Float = 1.0;

	/**
		Current alt animation for any characters that may be using it (should just be `dad`).
	**/
	public var altAnim:String = "";

	/**
		how big to stretch the pixel art assets

		@author ninjamuffin99 probably
	**/
	public static var daPixelZoom:Float = 6;

	/**
		Whether or not you are currently in a cutscene.
	**/
	public var inCutscene:Bool = false;

	/**
		Current group of weeks you are playing from.
	**/
	public static var groupWeek:String = "";

	// Discord RPC variables

	/**
		Difficulty name in RPC.
	**/
	public var storyDifficultyText:String = "";

	/**
		Small Icon to use in RPC.
	**/
	public var iconRPC:String = "";

	/**
		Details to use in RPC.
	**/
	public var detailsText:String = "";

	/**
		Paused Details to use in RPC.
	**/
	public var detailsPausedText:String = "";

	/**
		Whether or not there is currently a lua modchart active.
	**/
	public var executeModchart:Bool = false;

	#if LUA_ALLOWED
	/**
		The current lua modchart.
	**/
	public static var luaModchart:ModchartUtilities = null;
	#end

	/**
		Length of the current song's instrumental track in milliseconds.
	**/
	public var songLength:Float = 0;

	/**
		Your current key bindings stored as `Strings`.
	**/
	public var binds:Array<String>;

	// wack ass ui shit i need to fucking change like oh god i hate this shit mate
	public var ui_settings:Array<String>;
	public var mania_size:Array<String>;
	public var mania_offset:Array<String>;
	public var mania_gap:Array<String>;
	public var types:Array<String>;

	// this sucks too, sorry i'm not documentating this bullshit that ima replace at some point with nice clean yummy jsons
	// - leather128
	public var arrow_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();
	public var type_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();

	/**
		`Array` of cached miss sounds.
	**/
	public var missSounds:Array<FlxSound> = [];

	/**
		Current song multiplier. (Should be minimum 0.25)
	**/
	public static var songMultiplier:Float = 1;

	/**
		Variable that stores the original scroll speed before being divided by `songMultiplier`.

		Usage: ChartingState
	**/
	public static var previousScrollSpeedLmao:Float = 0;

	/**
		Current `Cutscene` data.
	**/
	public var cutscene:Cutscene;

	/**
		Current time of the song in milliseconds used for the progress bar.
	**/
	public var time:Float = 0.0;

	/**
		A `Map` of the `String` names of the ratings to the amount of times you got them.
	**/
	public var ratings:Map<String, Int> = ["marvelous" => 0, "sick" => 0, "good" => 0, "bad" => 0, "shit" => 0];

	/**
		Current text that displays your ratings (plus misses and MA/PA).
	**/
	public var ratingText:FlxText;

	/**
		Variable used by Lua Modcharts to stop the song midway.
	**/
	public var stopSong:Bool = false;

	/**
		`Array` of current events used by the song.
	**/
	public var events:Array<Array<Dynamic>> = [];

	/**
		Original `Array` of the current song's events.
	**/
	public var baseEvents:Array<Array<Dynamic>> = [];

	/**
	 * Used lua cameras?
	 */
	public var usedLuaCameras:Bool = false;

	/**
	 * Is the player charting?
	 */
	public static var chartingMode:Bool = false;

	/**
		Current character you are playing as stored as an `Int`.

		Values:

		0 = bf

		1 = opponent

		-1 = both
	**/
	public static var characterPlayingAs:Int = 0;

	/**
		The current hitsound the player is using. (By default is 'none')
	**/
	public var hitSoundString:String = Options.getData("hitsound");

	/**
		`Map` of `Strings` to `Boyfriends` for changing `bf`'s character.
	**/
	public var bfMap:Map<String, Boyfriend> = [];

	/**
		`Map` of `Strings` to `Characters` for changing `gf`'s character.
	**/
	public var gfMap:Map<String, Character> = [];

	/**
		`Map` of `Strings` to `Characters` for changing `dad`'s character.
	**/
	public var dadMap:Map<String, Character> = [];

	/**
		`Map` of `Strings` to `StageGroups` for changing the `stage`.
	**/
	public var stageMap:Map<String, StageGroup> = [];

	/**
		Whether the game will or will not load events from the chart's `events.json` file.
		(Disabled while charting as the events are already loaded)
	**/
	public static var loadChartEvents:Bool = true;

	/**
		Current time bar style selected by the player.
	**/
	public var funnyTimeBarStyle:String = Options.getData("timeBarStyle");

	/**
		Keeps track of the original player key count.

		(Used when playing as opponent).
	**/
	public var ogPlayerKeyCount:Int = 4;

	/**
		Keeps track of the original opponent (or both if not specified for player) key count.

		(Used when playing as opponent).
	**/
	public var ogKeyCount:Int = 4;

	#if LUA_ALLOWED
	/**
		`Map` of `Strings` to Lua Modcharts used for custom events.
	**/
	public var event_luas:Map<String, ModchartUtilities> = [];

	/**
		Array of Lua scripts in the "scripts/global" folder
	**/
	public var luaScriptArray:Array<ModchartUtilities> = [];
	#end

	/**
		`FlxTypedGroup` of `NoteSplash`s used to contain all note splashes
		and make performance better as a result by using `.recycle`.
	**/
	public var splash_group:FlxTypedSpriteGroup<NoteSplash> = new FlxTypedSpriteGroup<NoteSplash>();

	/**
	 * Should the player spawn a notesplash on a sick or marvelous rating?
	 */
	public var playerNoteSplashes:Bool = Options.getData("playerNoteSplashes");

	/**
	 * Should the opponent spawn a notesplash on a sick or marvelous rating?
	 */
	public var opponentNoteSplashes:Bool = Options.getData("opponentNoteSplashes");

	public var playerStrumsGlow:Bool = Options.getData("playerStrumsGlow");
	public var enemyStrumsGlow:Bool = Options.getData("enemyStrumsGlow");

	public var ratingsGroup:FlxSpriteGroup = new FlxSpriteGroup();

	public var marvelousRatings:Bool = Options.getData("marvelousRatings");

	public static var playCutscenes:Bool = false;

	/**
	 * Manages tweens in lua scripts to pause when game is
	 */
	public var tweenManager:FlxTweenManager;

	public function clearLuaObjects() {
		#if LUA_ALLOWED
		// clear dumb lua stuffs
		ModchartUtilities.killShaders();
		ModchartUtilities.lua_Characters.clear();
		ModchartUtilities.lua_Sounds.clear();
		ModchartUtilities.lua_Sprites.clear();
		ModchartUtilities.lua_Shaders.clear();
		ModchartUtilities.lua_Custom_Shaders.clear();
		ModchartUtilities.lua_Cameras.clear();
		#end
	}

	override public function create() {
		tweenManager = new FlxTweenManager();
		// set instance because duh
		instance = this;

		FlxG.mouse.visible = false;

		// preload pause music
		new FlxSound().loadEmbedded(Paths.music('breakfast'));

		if (SONG == null) // this should never happen, but just in case
			SONG = Song.loadFromJson('tutorial');

		// gaming time
		curSong = SONG.song;

		clearLuaObjects();

		// if we have a hitsound, preload it nerd
		if (hitSoundString != "none")
			hitsound = FlxG.sound.load(Paths.sound("hitsounds/" + Std.string(hitSoundString).toLowerCase()));

		// set the character we playing as
		switch (Options.getData("playAs")) {
			case "bf":
				characterPlayingAs = 0;
			case "opponent":
				characterPlayingAs = 1;
			case "both":
				characterPlayingAs = -1;
			default:
				characterPlayingAs = 0;
		}

		// key count flipping
		ogPlayerKeyCount = SONG.playerKeyCount;
		ogKeyCount = SONG.keyCount;

		if (characterPlayingAs == 1) {
			var oldRegKeyCount = SONG.playerKeyCount;
			var oldPlrKeyCount = SONG.keyCount;

			SONG.playerKeyCount = oldPlrKeyCount;
			SONG.keyCount = oldRegKeyCount;
		}

		// check for invalid settings
		if (Options.getData("botplay") || Options.getData("noDeath") || characterPlayingAs != 0 || PlayState.chartingMode) {
			SONG.validScore = false;
		}

		// preload the miss sounds
		for (i in 0...2) {
			var sound = FlxG.sound.load(Paths.sound('missnote' + Std.string((i + 1))), 0.2);
			missSounds.push(sound);
		}

		// load our binds
		binds = Options.getData("binds", "binds")[SONG.playerKeyCount - 1];

		// remove old insts and destroy them
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}

		// setup the cameras
		camGame = new FlxCamera();
		camHUD = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false); // false so it's not a default camera

		camHUD.bgColor.alpha = 0;

		persistentUpdate = true;
		persistentDraw = true;

		#if sys
		// minimum of 0.25
		songMultiplier = FlxMath.bound(songMultiplier, 0.25);
		#else
		// this shouldn't happen, but just in case
		songMultiplier = 1;
		#end

		// this is broken btw
		Conductor.timeScale = SONG.timescale;

		// bpm shits
		Conductor.mapBPMChanges(SONG, songMultiplier);
		Conductor.changeBPM(SONG.bpm, songMultiplier);

		previousScrollSpeedLmao = SONG.speed;

		SONG.speed /= songMultiplier;

		// just in case haxe does something weird af
		if (SONG.speed < 0)
			SONG.speed = 0;

		speed = Options.getData("useCustomScrollSpeed") ? Options.getData("customScrollSpeed") / songMultiplier : SONG.speed;

		Conductor.recalculateStuff(songMultiplier);
		Conductor.safeZoneOffset *= songMultiplier; // makes the game more fair

		// not sure why this is here and not later but sure
		noteBG = new FlxSprite(0, 0);
		noteBG.cameras = [camHUD];
		noteBG.makeGraphic(1, 1000, FlxColor.BLACK);
		add(noteBG);

		// set stage lol (yes im too lazy to put the stage in the jsons for base game)
		if (SONG.stage == null) {
			SONG.stage = 'stage';

			switch (curSong.toLowerCase()) {
				case 'spookeez' | 'south' | 'monster':
					SONG.stage = 'spooky';
				case 'pico' | 'philly nice' | 'blammed':
					SONG.stage = 'philly';
				case 'satin panties' | 'high' | 'm.i.l.f':
					SONG.stage = 'limo';
				case 'cocoa' | 'eggnog':
					SONG.stage = 'mall';
				case 'winter horrorland':
					SONG.stage = 'evil-mall';
				case 'senpai':
					SONG.stage = 'school';
				case 'roses':
					SONG.stage = 'school-mad';
				case 'thorns':
					SONG.stage = 'evil-school';
			}
		}

		// null ui skin
		if (SONG.ui_Skin == null)
			SONG.ui_Skin = SONG.stage == "school" || SONG.stage == "school-mad" || SONG.stage == "evil-school" ? "pixel" : "default";

		// yo poggars
		if (SONG.ui_Skin == "default")
			SONG.ui_Skin = Options.getData("uiSkin");

		// bull shit
		ui_settings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/config"));
		mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniasize"));
		mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniaoffset"));

		// if the file exists, use it dammit
		if (Assets.exists(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniagap")))
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniagap"));
		else
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

		types = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/types"));

		arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/default")));
		type_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("arrow types/default")));

		// preload ratings
		uiMap.set("marvelous", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/marvelous")));
		uiMap.set("sick", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/sick")));
		uiMap.set("good", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/good")));
		uiMap.set("bad", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/bad")));
		uiMap.set("shit", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/shit")));

		// preload numbers
		for (i in 0...10)
			uiMap.set(Std.string(i), FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/numbers/num" + Std.string(i))));

		curStage = SONG.stage;

		// set gf lol
		if (SONG.gf == null) {
			switch (curStage) {
				case 'limo':
					SONG.gf = 'gf-car';
				case 'mall' | 'evil-mall':
					SONG.gf = 'gf-christmas';
				case 'school' | 'school-mad' | 'evil-school':
					SONG.gf = 'gf-pixel';
				default:
					SONG.gf = 'gf';
			}
		}

		/* character time :) */

		// create the characters nerd
		if (!Options.getData("charsAndBGs")) {
			gf = new Character(400, 130, "");
			gf.scrollFactor.set(0.95, 0.95);

			dad = new Character(100, 100, "");
			boyfriend = new Boyfriend(770, 450, "");
		} else {
			gf = new Character(400, 130, SONG.gf);
			gf.scrollFactor.set(0.95, 0.95);

			dad = new Character(100, 100, SONG.player2);
			boyfriend = new Boyfriend(770, 450, SONG.player1);

			bfMap.set(SONG.player1, boyfriend);
			dadMap.set(SONG.player2, dad);
			gfMap.set(SONG.gf, gf);
		}
		/* end of character time */

		#if DISCORD_ALLOWED
		// weird ass rpc stuff from muffin man
		storyDifficultyText = storyDifficultyStr;
		iconRPC = dad.icon;

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode";
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end

		// stage maker
		stage = new StageGroup(Options.getData("charsAndBGs") ? curStage : "");
		stageMap.set(stage.stage, stage);
		add(stage);
		call("createStage", [stage.stage]);

		defaultCamZoom = stage.camZoom;

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		if (dad.curCharacter.startsWith("gf")) {
			dad.setPosition(gf.x, gf.y);
			gf.visible = false;

			if (isStoryMode) {
				camPos.x += 600;
				tweenCamIn();
			}
		}

		// REPOSITIONING PER STAGE
		if (Options.getData("charsAndBGs"))
			stage.setCharOffsets();

		if (gf.otherCharacters == null) {
			if (gf.coolTrail != null)
				add(gf.coolTrail);

			add(gf);
		} else {
			for (character in gf.otherCharacters) {
				if (character.coolTrail != null)
					add(character.coolTrail);

				add(character);
			}
		}

		if (!dad.curCharacter.startsWith("gf"))
			add(stage.infrontOfGFSprites);

		if (dad.otherCharacters == null) {
			if (dad.coolTrail != null)
				add(dad.coolTrail);

			add(dad);
		} else {
			for (character in dad.otherCharacters) {
				if (character.coolTrail != null)
					add(character.coolTrail);

				add(character);
			}
		}

		if (dad.curCharacter.startsWith("gf"))
			add(stage.infrontOfGFSprites);

		/* we do a little trolling */
		var midPos = dad.getMidpoint();

		camPos.set(midPos.x + 150 + dad.cameraOffset[0], midPos.y - 100 + dad.cameraOffset[1]);

		switch (dad.curCharacter) {
			case 'mom':
				camPos.y = midPos.y;
			case 'senpai':
				camPos.y = midPos.y - 430;
				camPos.x = midPos.x - 100;
			case 'senpai-angry':
				camPos.y = midPos.y - 430;
				camPos.x = midPos.x - 100;
		}

		if (boyfriend.otherCharacters == null) {
			if (boyfriend.coolTrail != null)
				add(boyfriend.coolTrail);

			add(boyfriend);
		} else {
			for (character in boyfriend.otherCharacters) {
				if (character.coolTrail != null)
					add(character.coolTrail);

				add(character);
			}
		}

		add(stage.foregroundSprites);

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 100).makeGraphic(FlxG.width, 10);

		if (Options.getData("downscroll"))
			strumLine.y = FlxG.height - 100;

		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<StrumNote>();

		playerStrums = new FlxTypedGroup<StrumNote>();
		enemyStrums = new FlxTypedGroup<StrumNote>();

		generareNoteChangeEvents();
		generateSong(SONG.song);
		generateEvents();

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		if (Options.getData("charsAndBGs")) {
			FlxG.camera.follow(camFollow, LOCKON, 0.04);
			FlxG.camera.zoom = defaultCamZoom;
			FlxG.camera.focusOn(camFollow.getPosition());
		}

		FlxG.fixedTimestep = false;

		var healthBarPosY = FlxG.height * 0.9;

		if (Options.getData("downscroll"))
			healthBarPosY = 60;

		// global scripts yay.
		#if sys
		var modList = modding.ModList.getActiveMods(modding.PolymodHandler.metadataArrays);

		if (modList.length > 0) {
			for (mod in modList) {
				if (sys.FileSystem.exists("mods/" + mod + "/data/scripts/global/")) {
					var modGlobalScripts = sys.FileSystem.readDirectory("mods/" + mod + "/data/scripts/global/");

					if (modGlobalScripts.length > 0) {
						for (file in modGlobalScripts) {
							if (file.endsWith('.hx')) {
								var script = new HScript("mods/" + mod + "/data/scripts/global/" + file, true);
								script.start();

								scripts.push(script);
							}
							#if LUA_ALLOWED
							if (file.endsWith('.lua')) {
								var script = (new ModchartUtilities("mods/" + mod + "/data/scripts/global/" + file));

								luaScriptArray.push(script);
							}
							#end
						}
					}
				}
			}
		}
		if (sys.FileSystem.exists("assets/data/scripts/global/")) {
			var assetsGlobalScripts = sys.FileSystem.readDirectory("assets/data/scripts/global/");

			if (assetsGlobalScripts.length > 0) {
				for (file in assetsGlobalScripts) {
					if (file.endsWith('.hx')) {
						var script = new HScript("assets/data/scripts/global/" + file, true);
						script.start();

						scripts.push(script);
					}
					#if LUA_ALLOWED
					if (file.endsWith('.lua')) {
						var script = (new ModchartUtilities("assets/data/scripts/global/" + file));

						luaScriptArray.push(script);
					}
					#end
				}
			}
		}

		// local scripts yay
		if (sys.FileSystem.exists("mods/" + Options.getData("curMod") + "/data/scripts/local/")) {
			var localScripts = sys.FileSystem.readDirectory("mods/" + Options.getData("curMod") + "/data/scripts/local/");
			if (localScripts.length > 0) {
				for (file in localScripts) {
					if (file.endsWith('.hx')) {
						var script = new HScript("mods/" + Options.getData("curMod") + "/data/scripts/local/" + file, true);
						script.start();

						scripts.push(script);
					}
					#if LUA_ALLOWED
					if (file.endsWith('.lua')) {
						var script = (new ModchartUtilities("mods/" + Options.getData("curMod") + "/data/scripts/local/" + file));
						luaScriptArray.push(script);
					}
					#end
				}
			}
		}

		// so we don't run the function 4978349576438578439 times
		var lowercaseCurSong:String = curSong.toLowerCase();
		if (sys.FileSystem.exists("mods/" + Options.getData("curMod") + "/data/song data/" + lowercaseCurSong + "/")) {
			var songScripts = sys.FileSystem.readDirectory("mods/" + Options.getData("curMod") + "/data/song data/" + lowercaseCurSong + "/");
			if (songScripts.length > 0) {
				for (file in songScripts) {
					if (file.endsWith('.hx')) {
						var script = new HScript("mods/" + Options.getData("curMod") + "/data/song data/" + lowercaseCurSong + "/" + file, true);
						script.start();
						scripts.push(script);
					}

					#if LUA_ALLOWED
					if (file.endsWith('.lua')) {
						var script = new ModchartUtilities("mods/" + Options.getData("curMod") + "/data/song data/" + lowercaseCurSong + "/" + file);
						luaScriptArray.push(script);
					}
					#end
				}
			}
		}

		if (sys.FileSystem.exists("assets/data/song data/" + lowercaseCurSong + "/")) {
			var songScripts = sys.FileSystem.readDirectory("assets/data/song data/" + lowercaseCurSong + "/");
			if (sys.FileSystem.readDirectory("assets/data/song data/" + lowercaseCurSong + "/").length > 0) {
				for (file in songScripts) {
					if (file.endsWith('.hx')) {
						var script = new HScript("assets/data/song data/" + lowercaseCurSong + "/" + file, true);
						script.start();
						scripts.push(script);
					}

					#if LUA_ALLOWED
					if (file.endsWith('.lua')) {
						var script = new ModchartUtilities("assets/data/song data/" + lowercaseCurSong + "/" + file);
						luaScriptArray.push(script);
					}
					#end
				}
			}
		}
		#end

		#if LUA_ALLOWED
		executeModchart = !(PlayState.SONG.modchartPath == '' || PlayState.SONG.modchartPath == null);

		if (executeModchart) {
			if (Assets.exists(Paths.lua("modcharts/" + PlayState.SONG.modchartPath))) {
				luaModchart = new ModchartUtilities(PolymodAssets.getPath(Paths.lua("modcharts/" + PlayState.SONG.modchartPath)));
			} else if (Assets.exists(Paths.lua("scripts/" + PlayState.SONG.modchartPath))) {
				luaModchart = new ModchartUtilities(PolymodAssets.getPath(Paths.lua("scripts/" + PlayState.SONG.modchartPath)));
			}
		}

		call("create", [PlayState.SONG.song.toLowerCase()], MODCHART);
		stage.createLuaStuff();
		call("create", [stage.stage], STAGE);
		#end

		ratingsGroup.cameras = [camHUD];
		add(ratingsGroup);
		add(strumLineNotes);

		var cache_splash = new NoteSplash();
		cache_splash.kill();

		splash_group.add(cache_splash);

		#if (MODCHARTING_TOOLS)
		if (SONG.modchartingTools
			|| Assets.exists(Paths.json("song data/" + SONG.song.toLowerCase() + "/modchart"))
			|| Assets.exists(Paths.json("song data/" + SONG.song.toLowerCase() + "/modchart" + storyDifficultyStr.toLowerCase()))) {
			playfieldRenderer = new PlayfieldRenderer(strumLineNotes, notes, this);
			playfieldRenderer.cameras = [camHUD];
			add(playfieldRenderer);
		}
		#end

		add(splash_group);
		splash_group.cameras = [camHUD];

		add(camFollow);
		add(notes);

		// health bar
		healthBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('ui skins/' + SONG.ui_Skin + '/other/healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.pixelPerfectPosition = true;
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'healthShown', minHealth, maxHealth);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
		healthBar.pixelPerfectPosition = true;
		add(healthBar);

		// haha ez
		healthBar.visible = healthBarBG.visible = Options.getData('healthBar');

		// icons
		iconP1 = new HealthIcon(boyfriend.icon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2) - iconP1.offsetY;
		if (!iconP1.visible)
			iconP1.graphic.destroy();
		add(iconP1);

		iconP2 = new HealthIcon(dad.icon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2) - iconP2.offsetY;
		iconP2.visible = iconP1.visible = Options.getData("healthIcons");
		if (!iconP2.visible)
			iconP2.graphic.destroy();
		add(iconP2);

		// settings moment
		var scoreTxtSize:Int = Options.getData("biggerScoreInfo") ? 20 : 16;
		var funnyBarOffset:Int = 45;

		scoreTxt = new FlxText(0, healthBarBG.y + funnyBarOffset, 0, "", 20);
		scoreTxt.screenCenter(X);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), scoreTxtSize, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.antialiasing = Options.getData("antialiasing");
		scoreTxt.scrollFactor.set();

		// settings again
		if (Options.getData("biggerScoreInfo"))
			scoreTxt.borderSize = 1.25;

		add(scoreTxt);

		// correct rehe
		var infoTxtSize:Int = Options.getData("biggerInfoText") ? 20 : 16;

		infoTxt = new FlxText(0, 0, 0, SONG.song + " - " + storyDifficultyStr + (Options.getData("botplay") ? " (BOT)" : ""), 20);
		infoTxt.setFormat(Paths.font("vcr.ttf"), infoTxtSize, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoTxt.screenCenter(X);

		infoTxt.scrollFactor.set();
		infoTxt.antialiasing = Options.getData("antialiasing");
		// don't ask why this is different idfk
		infoTxt.cameras = [camHUD];

		// time bars cuz fuck you
		switch (funnyTimeBarStyle.toLowerCase()) {
			default: // includes 'leather engine'
				timeBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('ui skins/' + SONG.ui_Skin + '/other/healthBar'));
				timeBarBG.screenCenter(X);
				timeBarBG.scrollFactor.set();
				// timeBarBG.pixelPerfectPosition = true;
				timeBarBG.y = Options.getData("downscroll") ? FlxG.height - (timeBarBG.height + 1) : 1;
				add(timeBarBG);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
					'time', 0, FlxG.sound.music.length);
				timeBar.scrollFactor.set();
				timeBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
				// timeBar.pixelPerfectPosition = true;
				timeBar.numDivisions = 400;

				if (SONG.notes.length > 0) {
					timeBar.color = SONG.notes[0].mustHitSection ? boyfriend.barColor : dad.barColor;
				}
				add(timeBar);

				// inverted basically
				infoTxt.y = timeBarBG.y;
			case "psych engine":
				// repeat other shit but make it look like psych basically
				timeBarBG = new FlxSprite(0, healthBarPosY).makeGraphic(400, 19, FlxColor.BLACK);
				timeBarBG.screenCenter(X);
				timeBarBG.scrollFactor.set();
				// timeBarBG.pixelPerfectPosition = true;

				if (Options.getData("downscroll"))
					timeBarBG.y = FlxG.height - 36;
				else
					timeBarBG.y = 10;

				add(timeBarBG);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
					'time', 0, FlxG.sound.music.length);
				timeBar.scrollFactor.set();
				timeBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
				// timeBar.pixelPerfectPosition = true;
				timeBar.numDivisions = 800;
				add(timeBar);

				infoTxt.borderSize = Options.getData("biggerInfoText") ? 2 : 1.5;
				infoTxt.size = Options.getData("biggerInfoText") ? 32 : 20;

				infoTxt.y = timeBarBG.y - (infoTxt.height / 4);
			case "old kade engine":
				// yeah
				timeBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('ui skins/' + SONG.ui_Skin + '/other/healthBar'));
				timeBarBG.screenCenter(X);
				timeBarBG.scrollFactor.set();
				// timeBarBG.pixelPerfectPosition = true;

				if (Options.getData("downscroll"))
					timeBarBG.y = FlxG.height * 0.9 + 45;
				else
					timeBarBG.y = 10;

				add(timeBarBG);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
					'time', 0, FlxG.sound.music.length);
				timeBar.scrollFactor.set();
				timeBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
				// timeBar.pixelPerfectPosition = true;
				timeBar.numDivisions = 400;
				add(timeBar);

				infoTxt.y = timeBarBG.y;
		}

		// mhm
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		add(infoTxt);

		// the funny
		// MARVELOUS: 0
		// SICK: 0
		// etc

		if (Options.getData("sideRatings")) {
			ratingText = new FlxText(4, 0, 0, "bruh");
			ratingText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ratingText.screenCenter(Y);
			ratingText.antialiasing = Options.getData("antialiasing");
			ratingText.scrollFactor.set();
			add(ratingText);

			ratingText.cameras = [camHUD];

			updateRatingText();
		}

		// grouped cuz fuck you this is based on base game B)
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		startingSong = true;

		// WINDOW TITLE POG
		MusicBeatState.windowNameSuffix = " - " + SONG.song + " " + (isStoryMode ? "(Story Mode)" : "(Freeplay)");

		var cutscenePlays:String = Options.getData("cutscenePlaysOn");
		playCutsceneOnPauseLmao = playCutsceneLmao = ((cutscenePlays == "both")
			|| (isStoryMode && cutscenePlays == "story")
			|| (!isStoryMode && cutscenePlays == "freeplay"))
			&& !playCutscenes;

		playCutscenes = false;

		if (playCutsceneLmao && SONG.cutscene != null && SONG.cutscene != "") {
			cutscene = CutsceneUtil.loadFromJson(SONG.cutscene);

			switch (cutscene.type.toLowerCase()) {
				case "script":
					var cutscene = new HScript(Paths.hx('data/${cutscene.scriptPath}'));
					for (object in stage.stage_Objects) {
						cutscene.interp.variables.set(object[0], object[1]);
					}
					scripts.push(cutscene);
					cutscene.call("startCutscene");
				case "video":
					startVideo(cutscene.videoPath, cutscene.videoExt, false);

				case "dialogue":
					var box:DialogueBox = new DialogueBox(cutscene);
					box.scrollFactor.set();
					// i love this
					box.finish_Function = function():Void {
						bruhDialogue(false);
					};
					box.cameras = [camHUD];

					startDialogue(box, false);

				default:
					startCountdown();
			}
		} else {
			startCountdown();
		}

		for (event in events) {
			call("onEventLoaded", [event[0], event[1], event[2], event[3]]);
		}

		// @see https://discord.com/channels/929608653173051392/1034954605253107844/1163134784277590056
		if (Options.getData('colorQuantization')) {
			for (note in unspawnNotes) {
				if (note.affectedbycolor) {
					var quantStrumTime = note.isSustainNote ? note.prevNote.prevNoteStrumtime : note.strumTime;
					var currentStepCrochet = Conductor.stepCrochet;
					var noteBeat = Math.floor(((quantStrumTime / (currentStepCrochet * 4)) * 48) + 0.5);
					var col:Array<Int> = [142, 142, 142];
					for (beat in 0...note.beats.length - 1) {
						if ((noteBeat % (192 / note.beats[beat]) == 0)) {
							noteBeat = note.beats[beat];
							col = note.quantColors[beat];
							break;
						}
					}
					note.colorSwap.r = col[0];
					note.colorSwap.g = col[1];
					note.colorSwap.b = col[2];
				}
			}
		}

		super.create();

		for (script_funny in scripts) {
			script_funny.create_post = true;
		}

		call("createPost", []);

		calculateAccuracy();
		updateSongInfoText();
	}

	public var scripts:Array<HScript> = [];
	public var hscriptEvents:Map<String, HScript> = [];

	public function reorderCameras(?newCam:FlxCamera = null) {
		var cameras = FlxG.cameras.list.copy();
		for (c in cameras) {
			FlxG.cameras.remove(c, false);
		}
		for (i in 0...cameras.length) {
			if (i == cameras.length - 1 && newCam != null) {
				FlxG.cameras.add(newCam, false);
			}
			FlxG.cameras.add(cameras[i], false);
		}
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
	}

	public static var playCutsceneLmao:Bool = false;
	public static var playCutsceneOnPauseLmao:Bool = false;

	// this will become hscript one day
	function schoolIntro(?dialogueBox:DialogueBox):Void {
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000001);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns') {
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
				add(red);
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer) {
			black.alpha -= 0.15;

			if (black.alpha > 0) {
				tmr.reset(0.3);
			} else {
				if (dialogueBox != null) {
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns') {
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1) {
								swagTimer.reset();
							} else {
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function() {
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					} else {
						add(dialogueBox);
					}
				} else
					startCountdown();

				remove(black);
			}
		});
	}

	function startDialogue(?dialogueBox:DialogueBox, ?endSongVar:Bool = false):Void {
		if (endSongVar) {
			paused = true;
			canPause = false;
			switchedStates = true;
			endingSong = true;
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer):Void {
			trace("Start Dialogue");

			if (dialogueBox != null)
				add(dialogueBox);
			else {
				if (cutscene.cutsceneAfter == null) {
					if (!endSongVar)
						startCountdown();
					else
						finishSongStuffs();
				} else {
					var oldcutscene = cutscene;

					cutscene = CutsceneUtil.loadFromJson(oldcutscene.cutsceneAfter);

					switch (cutscene.type.toLowerCase()) {
						case "script":
							var cutscene = new HScript(Paths.hx('data/${cutscene.scriptPath}'));
							for (object in stage.stage_Objects) {
								cutscene.interp.variables.set(object[0], object[1]);
							}
							scripts.push(cutscene);
							cutscene.call("startCutscene");

						case "video":
							startVideo(cutscene.videoPath, cutscene.videoExt, endSongVar);

						case "dialogue":
							var box:DialogueBox = new DialogueBox(cutscene);
							box.scrollFactor.set();
							box.finish_Function = () -> {
								bruhDialogue(endSongVar);
							};
							box.cameras = [camHUD];

							startDialogue(box, endSongVar);

						default:
							if (!endSongVar)
								startCountdown();
							else
								finishSongStuffs();
					}
				}
			}
		});
	}

	public function startVideo(name:String, ?ext:String, ?endSongVar:Bool = false):Void {
		inCutscene = true;

		if (endSongVar) {
			paused = true;
			canPause = false;
			switchedStates = true;
			endingSong = true;
		}

		#if VIDEOS_ALLOWED
		var video_handler:FlxVideo = new FlxVideo();

		video_handler.onEndReached.add(function() {
			bruhDialogue(endSongVar);
			return;
		}, true);
		video_handler.onEndReached.add(video_handler.dispose);
		video_handler.load(PolymodAssets.getPath(Paths.video(name, ext)));
		video_handler.play();
		video_handler.mute = false;
		#else
		bruhDialogue(endSongVar);
		trace("Videos aren't supported on this platform!", ERROR);
		#end
	}

	function bruhDialogue(?endSongVar:Bool = false):Void {
		if (cutscene.cutsceneAfter == null) {
			if (!endSongVar)
				startCountdown();
			else
				finishSongStuffs();
		} else {
			var oldcutscene = cutscene;

			cutscene = CutsceneUtil.loadFromJson(oldcutscene.cutsceneAfter);

			switch (cutscene.type.toLowerCase()) {
				case "script":
					var cutscene = new HScript(Paths.hx('data/${cutscene.scriptPath}'));
					for (object in stage.stage_Objects) {
						cutscene.interp.variables.set(object[0], object[1]);
					}
					scripts.push(cutscene);
					cutscene.call("startCutscene");

				case "video":
					startVideo(cutscene.videoPath, cutscene.videoExt, endSongVar);

				case "dialogue":
					var box:DialogueBox = new DialogueBox(cutscene);
					box.scrollFactor.set();
					box.finish_Function = function() {
						bruhDialogue(endSongVar);
					};
					box.cameras = [camHUD];

					startDialogue(box, endSongVar);

				default:
					if (!endSongVar)
						startCountdown();
					else
						finishSongStuffs();
			}
		}
	}

	var startTimer:FlxTimer = new FlxTimer();

	public static var startOnTime:Float = 0;

	function startCountdown():Void {
		call("generateStaticArrows", []);

		inCutscene = false;
		paused = false;
		canPause = true;

		if (Options.getData("middlescroll")) {
			generateStaticArrows(50, false);
			generateStaticArrows(0.5, true);
		} else {
			if (characterPlayingAs == 0) {
				generateStaticArrows(0, false);
				generateStaticArrows(1, true);
			} else {
				generateStaticArrows(1, false);
				generateStaticArrows(0, true);
			}
		}

		#if MODCHARTING_TOOLS
		NoteMovement.getDefaultStrumPos(this);
		#end

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;
		if (startOnTime > 0) {
			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);
			return;
		}

		#if LUA_ALLOWED
		if (executeModchart && luaModchart != null)
			luaModchart.setupTheShitCuzPullRequestsSuck();

		if (stage.stageScript != null)
			stage.stageScript.setupTheShitCuzPullRequestsSuck();

		if (generatedSomeDumbEventLuas) {
			for (key in event_luas.keys()) {
				var event_lua:ModchartUtilities = event_luas.get(key);
				event_lua.setupTheShitCuzPullRequestsSuck();
			}
		}

		if (luaScriptArray.length != 0) {
			for (i in luaScriptArray) {
				i.setupTheShitCuzPullRequestsSuck();
			}
		}

		for (i in 0...strumLineNotes.length) {
			var member = strumLineNotes.members[i];

			setLuaVar("defaultStrum" + i + "X", member.x);
			setLuaVar("defaultStrum" + i + "Y", member.y);
			setLuaVar("defaultStrum" + i + "Angle", member.angle);

			setLuaVar("defaultStrum" + i, {
				x: member.x,
				y: member.y,
				angle: member.angle,
			});

			if (enemyStrums.members.contains(member)) {
				setLuaVar("enemyStrum" + i % SONG.keyCount, {
					x: member.x,
					y: member.y,
					angle: member.angle,
				});
			} else {
				setLuaVar("playerStrum" + i % SONG.playerKeyCount, {
					x: member.x,
					y: member.y,
					angle: member.angle,
				});
			}
		}

		call("start", [SONG.song.toLowerCase()], BOTH, [stage.stage]);
		#end

		startTimer.start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			call("startCountdown", [swagCounter]);
			dad.dance(altAnim);
			gf.dance();
			boyfriend.dance();

			var introAssets:Array<String> = [
				"ui skins/" + SONG.ui_Skin + "/countdown/ready",
				"ui skins/" + SONG.ui_Skin + "/countdown/set",
				"ui skins/" + SONG.ui_Skin + "/countdown/go"
			];

			var altSuffix = SONG.ui_Skin == 'pixel' ? "-pixel" : "";

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAssets[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					ready.setGraphicSize(Std.int(ready.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[7])));
					ready.updateHitbox();

					ready.screenCenter();
					add(ready);

					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) ready.destroy()
					});

					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAssets[1]));
					set.scrollFactor.set();
					set.updateHitbox();

					set.setGraphicSize(Std.int(set.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[7])));
					set.updateHitbox();

					set.screenCenter();
					add(set);

					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) set.destroy()
					});

					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAssets[2]));
					go.scrollFactor.set();
					go.updateHitbox();

					go.setGraphicSize(Std.int(go.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[7])));
					go.updateHitbox();

					go.screenCenter();
					add(go);

					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) go.destroy()
					});

					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			swagCounter++;
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	var invincible:Bool = false;

	public function clearNotesBefore(time:Float) {
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	inline function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function setSongTime(time:Float) {
		invincible = true;
		setLuaVar("bot", true);
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		#if FLX_PITCH FlxG.sound.music.pitch = songMultiplier; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length) {
			vocals.time = time;
			#if FLX_PITCH
			vocals.pitch = songMultiplier;
			#end
		}
		vocals.play();
		Conductor.songPosition = time;
		invincible = false;
		setLuaVar("bot", Options.getData("botplay"));
	}

	function startSong():Void {
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused) {
			FlxG.sound.music.play();
		}

		vocals.play();

		if (startOnTime > 0)
			setSongTime(startOnTime - 500);
		startOnTime = 0;

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		#if desktop
		Conductor.recalculateStuff(songMultiplier);

		// Updating Discord Rich Presence (with Time Left)
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength / songMultiplier);
		#end
		#end
		call("startSong", []);
		call("songStart", []);

		resyncVocals();
	}

	private var maniaChanges:Array<Dynamic> = [];

	// https://github.com/TheZoroForce240/LeatherEngine/blob/main/source/states/PlayState.hx#L1432
	var currentParsingKeyCount = SONG.keyCount;
	var currentParsingPlayerKeyCount = SONG.playerKeyCount;

	public function generateSong(dataPath:String):Void {
		var songData = SONG;
		Conductor.changeBPM(songData.bpm, songMultiplier);

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song,
				(SONG.specialAudioName == null ? storyDifficultyStr.toLowerCase() : SONG.specialAudioName)));
		else
			vocals = new FlxSound();

		// LOADING MUSIC FOR CUSTOM SONGS
		if (FlxG.sound.music != null)
			if (FlxG.sound.music.active)
				FlxG.sound.music.stop();

		FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(SONG.song,
			(SONG.specialAudioName == null ? storyDifficultyStr.toLowerCase() : SONG.specialAudioName)));
		FlxG.sound.music.persist = true;

		vocals.persist = false;
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();

		if (Options.getData("invisibleNotes")) // this was really simple lmfao
			notes.visible = false;

		var noteData:Array<SwagSection> = songData.notes;

		for (section in noteData) {
			Conductor.recalculateStuff(songMultiplier);

			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0] + Conductor.offset + SONG.chartOffset;

				for (mchange in maniaChanges) {
					if (daStrumTime >= mchange[0]) {
						currentParsingKeyCount = mchange[2];
						currentParsingPlayerKeyCount = mchange[1];

						SONG.keyCount = currentParsingKeyCount; // so notes are correct anim/scale and whatever
						SONG.playerKeyCount = currentParsingPlayerKeyCount;
					}
				}

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] >= (!gottaHitNote ? currentParsingKeyCount : currentParsingPlayerKeyCount))
					gottaHitNote = !section.mustHitSection;

				switch (characterPlayingAs) {
					case 1:
						gottaHitNote = !gottaHitNote;
					case -1:
						gottaHitNote = true;
				}

				var daNoteData:Int = Std.int(songNotes[1] % (currentParsingKeyCount + currentParsingPlayerKeyCount));
				if (section.mustHitSection && daNoteData >= SONG.playerKeyCount) {
					daNoteData -= SONG.playerKeyCount;
					daNoteData %= SONG.keyCount;
				} else if (!section.mustHitSection && daNoteData >= SONG.keyCount) {
					daNoteData -= SONG.keyCount;
					daNoteData %= SONG.playerKeyCount;
				}
				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				if (!Std.isOfType(songNotes[0], Float) && !Std.isOfType(songNotes[0], Int))
					songNotes[0] = 0;

				if (!Std.isOfType(songNotes[1], Int))
					songNotes[1] = 0;

				if (!Std.isOfType(songNotes[2], Int) && !Std.isOfType(songNotes[2], Float))
					songNotes[2] = 0;

				if (!Std.isOfType(songNotes[3], Int) && !Std.isOfType(songNotes[3], Array)) {
					if (Std.string(songNotes[3]).toLowerCase() == "hurt note")
						songNotes[4] = "hurt";

					songNotes[3] = 0;
				}

				if (!Std.isOfType(songNotes[4], String))
					songNotes[4] = "default";

				var char:Dynamic = songNotes[3];

				var chars:Array<Int> = [];

				if (Std.isOfType(char, Array)) {
					chars = char;
					char = chars[0];
				}

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, char, songNotes[4], null, chars, gottaHitNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Std.int(Conductor.stepCrochet);
				unspawnNotes.push(swagNote);

				var sustainGroup:Array<Note> = [];

				for (susNote in 0...Math.floor(susLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, char,
						songNotes[4], null, chars, gottaHitNote);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					sustainGroup.push(sustainNote);
					sustainNote.sustains = sustainGroup;
				}

				swagNote.sustains = sustainGroup;
				swagNote.mustPress = gottaHitNote;
			}
		}

		SONG.keyCount = ogKeyCount;
		SONG.playerKeyCount = ogPlayerKeyCount;

		if (characterPlayingAs == 1) {
			SONG.keyCount = ogPlayerKeyCount;
			SONG.playerKeyCount = ogKeyCount;
		}

		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
		SONG.validScore = SONG.validScore == true ? songMultiplier >= 1 : false;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	var noteBG:FlxSprite;

	var babyArrow:StrumNote;

	public function generateStaticArrows(player:Float, ?isPlayer:Bool = false, ?showReminders:Bool = true):Void {
		var usedKeyCount = SONG.keyCount;

		if (isPlayer)
			usedKeyCount = SONG.playerKeyCount;

		for (i in 0...usedKeyCount) {
			var babyArrow = new StrumNote(0, strumLine.y, i, null, null, null, usedKeyCount, player);

			babyArrow.frames = Paths.getSparrowAtlas('ui skins/' + SONG.ui_Skin + "/arrows/default");

			babyArrow.antialiasing = ui_settings[3] == "true";

			babyArrow.setGraphicSize(Std.int((babyArrow.width * Std.parseFloat(ui_settings[0])) * (Std.parseFloat(ui_settings[2])
				- (Std.parseFloat(mania_size[usedKeyCount - 1])))));
			babyArrow.updateHitbox();

			var animation_Base_Name = NoteVariables.Note_Count_Directions[usedKeyCount - 1][Std.int(Math.abs(i))].toLowerCase();

			babyArrow.animation.addByPrefix('static', animation_Base_Name + " static");
			babyArrow.animation.addByPrefix('pressed', NoteVariables.Other_Note_Anim_Stuff[usedKeyCount - 1][i] + ' press', 24, false);
			babyArrow.animation.addByPrefix('confirm', NoteVariables.Other_Note_Anim_Stuff[usedKeyCount - 1][i] + ' confirm', 24, false);

			babyArrow.scrollFactor.set();

			babyArrow.playAnim('static');

			babyArrow.x += (babyArrow.width
				+ (2 + Std.parseFloat(mania_gap[usedKeyCount - 1]))) * Math.abs(i)
				+ Std.parseFloat(mania_offset[usedKeyCount - 1]);
			babyArrow.y = strumLine.y - (babyArrow.height / 2);

			if (isStoryMode && showReminders) {
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (isPlayer)
				playerStrums.add(babyArrow);
			else
				enemyStrums.add(babyArrow);

			babyArrow.x += 100 - ((usedKeyCount - 4) * 16) + (usedKeyCount >= 10 ? 30 : 0);
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);

			if (usedKeyCount != 4 && isPlayer && Options.getData("extraKeyReminders") && showReminders) {
				// var coolWidth = Std.int(40 - ((key_Count - 5) * 2) + (key_Count == 10 ? 30 : 0));
				// funny 4 key math i guess, full num is 2.836842105263158 (width / previous key width thingy which was 38)
				var coolWidth = Math.ceil(babyArrow.width / 2.83684);

				var keyThingLolShadow = new FlxText((babyArrow.x + (babyArrow.width / 2)) - (coolWidth / 2), babyArrow.y - (coolWidth / 2), coolWidth,
					binds[i], coolWidth);
				keyThingLolShadow.cameras = [camHUD];
				keyThingLolShadow.color = FlxColor.BLACK;
				keyThingLolShadow.scrollFactor.set();
				add(keyThingLolShadow);

				var keyThingLol = new FlxText(keyThingLolShadow.x - 6, keyThingLolShadow.y - 6, coolWidth, binds[i], coolWidth);
				keyThingLol.cameras = [camHUD];
				keyThingLol.scrollFactor.set();
				add(keyThingLol);

				FlxTween.tween(keyThingLolShadow, {y: keyThingLolShadow.y + 10, alpha: 0}, 3, {
					ease: FlxEase.circOut,
					startDelay: 0.5 + (0.2 * i),
					onComplete: function(_) {
						remove(keyThingLolShadow);
						keyThingLolShadow.kill();
						keyThingLolShadow.destroy();
					}
				});

				FlxTween.tween(keyThingLol, {y: keyThingLol.y + 10, alpha: 0}, 3, {
					ease: FlxEase.circOut,
					startDelay: 0.5 + (0.2 * i),
					onComplete: function(_) {
						remove(keyThingLol);
						keyThingLol.kill();
						keyThingLol.destroy();
					}
				});
			}
		}

		if (isPlayer && Options.getData("noteBGAlpha") != 0) {
			updateNoteBGPos();
			noteBG.alpha = Options.getData("noteBGAlpha");
		}
	}

	function updateNoteBGPos() {
		if (startedCountdown) {
			var bruhVal:Float = 0.0;

			for (note in playerStrums) {
				bruhVal += note.swagWidth + (2 + Std.parseFloat(mania_gap[SONG.playerKeyCount - 1]));
			}

			noteBG.setGraphicSize(Std.int(bruhVal), FlxG.height * 2);
			noteBG.updateHitbox();

			noteBG.x = playerStrums.members[0].x;
		}
	}

	inline function tweenCamIn():Void {
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * SONG.timescale[0] / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			if (FlxG.sound.music != null)
				FlxG.sound.music.pause();

			if (vocals != null)
				vocals.pause();

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished && startTimer != null)
				startTimer.active = true;

			paused = false;

			#if DISCORD_ALLOWED
			if (startTimer.finished) {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true,
					((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			} else {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
			#end

			call("onResumePost", []);
		}

		super.closeSubState();
	}

	override public function onFocus():Void {
		#if DISCORD_ALLOWED
		if (health > minHealth && !paused) {
			if (Conductor.songPosition > 0.0) {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true,
					((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			} else {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void {
		#if DISCORD_ALLOWED
		if (health > minHealth && !paused) {
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void {
		FlxG.sound.music.pitch = songMultiplier;

		if (vocals.active && vocals.playing)
			vocals.pitch = songMultiplier;

		if (!switchedStates) {
			if (!(Conductor.songPosition > 20 && FlxG.sound.music.time < 20)) {
				#if debug
				trace('Resynced Vocals {Conductor.songPosition: ${Conductor.songPosition}, FlxG.sound.music.time: ${FlxG.sound.music.time} / ${FlxG.sound.music.length}}',
					DEBUG);
				#end

				vocals.pause();
				FlxG.sound.music.pause();

				if (FlxG.sound.music.time >= FlxG.sound.music.length)
					Conductor.songPosition = FlxG.sound.music.length;
				else
					Conductor.songPosition = FlxG.sound.music.time;

				vocals.time = Conductor.songPosition;

				FlxG.sound.music.play();
				vocals.play();
			} else {
				while (Conductor.songPosition > 20 && FlxG.sound.music.time < 20) {
					#if debug
					trace('Resynced Vocals {Conductor.songPosition: ${Conductor.songPosition}, FlxG.sound.music.time: ${FlxG.sound.music.time} / ${FlxG.sound.music.length}}',
						DEBUG);
					#end

					FlxG.sound.music.time = Conductor.songPosition;
					vocals.time = Conductor.songPosition;

					FlxG.sound.music.play();
					vocals.play();
				}
			}
		}
	}

	public var paused:Bool = false;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	public var canFullscreen:Bool = true;

	var switchedStates:Bool = false;

	// give: [noteDataThingy, noteType]
	// get : [xOffsetToUse]
	public var prevPlayerXVals:Map<String, Float> = [];
	public var prevEnemyXVals:Map<String, Float> = [];

	var speed:Float = 1.0;

	#if LUA_ALLOWED
	public var generatedSomeDumbEventLuas:Bool = false;
	#end

	public var ratingStr:String = "";

	var song_info_timer:Float = 0.0;

	inline function fixedUpdate() {
		call("fixedUpdate", [1 / 120]);
	}

	var fixedUpdateTime:Float = 0.0;

	override public function update(elapsed:Float) {
		super.update(elapsed);
		tweenManager.update(elapsed);

		FlxG.camera.followLerp = (elapsed * 2.4) * cameraSpeed;
		var iconLerp:Float = elapsed * 9;
		var zoomLerp:Float = (elapsed * 3) * cameraZoomSpeed;

		iconP1.scale.set(FlxMath.lerp(iconP1.scale.x, iconP1.startSize, iconLerp * songMultiplier),
			FlxMath.lerp(iconP1.scale.y, iconP1.startSize, iconLerp * songMultiplier));
		iconP2.scale.set(FlxMath.lerp(iconP2.scale.x, iconP2.startSize, iconLerp * songMultiplier),
			FlxMath.lerp(iconP2.scale.y, iconP2.startSize, iconLerp * songMultiplier));

		iconP1.scale.set(Math.min(iconP1.scale.x, iconP1.startSize + 0.2), Math.min(iconP1.scale.y, iconP1.startSize + 0.2));
		iconP2.scale.set(Math.min(iconP2.scale.x, iconP2.startSize + 0.2), Math.min(iconP2.scale.y, iconP2.startSize + 0.2));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Float = 26.0;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset) - iconP1.offsetX;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (iconP2.width - iconOffset)
			- iconP2.offsetX;

		if (Options.getData("cameraZooms") && camZooming && !switchedStates) {
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultCamZoom, zoomLerp);
			camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudCamZoom, zoomLerp);
		} else if (!Options.getData("cameraZooms")) {
			FlxG.camera.zoom = defaultCamZoom;
			camHUD.zoom = 1;
		}

		song_info_timer += elapsed;
		fixedUpdateTime += elapsed;

		if (fixedUpdateTime >= 1 / 120) {
			fixedUpdate();
			fixedUpdateTime = 0;
		}

		if (song_info_timer >= 0.25 / songMultiplier) {
			updateSongInfoText();
			song_info_timer = 0;
		}

		if (stopSong && !switchedStates) {
			PlayState.instance.paused = true;

			FlxG.sound.music.volume = 0;
			PlayState.instance.vocals.volume = 0;

			FlxG.sound.music.time = 0;
			PlayState.instance.vocals.time = 0;
			Conductor.songPosition = 0;
		}

		if (!switchedStates) {
			if (SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)] != null) {
				if (SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)].altAnim)
					altAnim = '-alt';
				else
					altAnim = "";
			}
		}

		if (generatedMusic && startedCountdown && canPause && !endingSong && !switchedStates) {
			// Song ends abruptly on slow rate even with second condition being deleted,
			// and if it's deleted on songs like cocoa then it would end without finishing instrumental fully,
			// so no reason to delete it at all
			if (FlxG.sound.music.length - Conductor.songPosition <= 20) {
				time = FlxG.sound.music.length;
				endSong();
			}
		}

		time = endingSong ? FlxG.sound.music.length : FlxG.sound.music.time;
		health = Math.min(health, maxHealth);

		if (characterPlayingAs == 1)
			healthShown = maxHealth - health;
		else
			healthShown = health;

		if (healthBar.percent < 20) {
			if (!iconP1.animatedIcon)
				iconP1.animation.curAnim.curFrame = 1;
			if (!iconP2.animatedIcon)
				iconP2.animation.curAnim.curFrame = 2;

			if (iconP2.animation.curAnim.curFrame != 2 && !iconP2.animatedIcon)
				iconP2.animation.curAnim.curFrame = 0;
		} else {
			if (!iconP1.animatedIcon)
				iconP1.animation.curAnim.curFrame = 0;

			if (!iconP2.animatedIcon)
				iconP2.animation.curAnim.curFrame = 0;
		}

		if (healthBar.percent > 80) {
			if (!iconP2.animatedIcon)
				iconP2.animation.curAnim.curFrame = 1;
			if (!iconP1.animatedIcon)
				iconP1.animation.curAnim.curFrame = 2;

			if (iconP1.animation.curAnim.curFrame != 2 && !iconP1.animatedIcon)
				iconP1.animation.curAnim.curFrame = 0;
		}

		if (!switchedStates) {
			if (startingSong) {
				if (startedCountdown) {
					Conductor.songPosition += FlxG.elapsed * 1000.0;

					if (Conductor.songPosition >= 0.0) {
						startSong();
					}
				}
			} else {
				Conductor.songPosition += (FlxG.elapsed * 1000.0) * songMultiplier;
			}
		}

		if (generatedMusic
			&& PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)] != null
			&& !switchedStates
			&& startedCountdown) {
			// offsetX = luaModchart.getVar("followXOffset", "float");
			// offsetY = luaModchart.getVar("followYOffset", "float");

			setLuaVar("mustHit", PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)].mustHitSection);

			if (!PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)].mustHitSection) {
				var midPos = dad.getMainCharacter().getMidpoint();

				if (Options.getData("cameraTracksDirections") && dad.getMainCharacter().hasAnims()) {
					switch (dad.curAnimName().toLowerCase()) {
						case "singleft":
							midPos.x -= 50;
						case "singright":
							midPos.x += 50;
						case "singup":
							midPos.y -= 50;
						case "singdown":
							midPos.y += 50;
					}
				}

				midPos.x += stage.p2_Cam_Offset.x;
				midPos.y += stage.p2_Cam_Offset.y;

				// if(camFollow.x != midPos.x + 150 + dad.cameraOffset[0] || camFollow.y != midPos.y + - 100 + dad.cameraOffset[1])
				// {
				if (!paused)
					camFollow.setPosition(midPos.x + 150 + dad.getMainCharacter().cameraOffset[0], midPos.y - 100 + dad.getMainCharacter().cameraOffset[1]);

				switch (dad.curCharacter) {
					case 'mom':
						camFollow.y = midPos.y;
					case 'senpai':
						camFollow.y = midPos.y - 430;
						camFollow.x = midPos.x - 100;
					case 'senpai-angry':
						camFollow.y = midPos.y - 430;
						camFollow.x = midPos.x - 100;
				}

				call("playerTwoTurn", []);
				call("turnChange", ['dad']);
				// }
			}

			if (PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)].mustHitSection) {
				var midPos = boyfriend.getMainCharacter().getMidpoint();

				if (Options.getData("cameraTracksDirections") && boyfriend.getMainCharacter().hasAnims()) {
					switch (boyfriend.curAnimName().toLowerCase()) {
						case "singleft":
							midPos.x -= 50;
						case "singright":
							midPos.x += 50;
						case "singup":
							midPos.y -= 50;
						case "singdown":
							midPos.y += 50;
					}
				}

				midPos.x += stage.p1_Cam_Offset.x;
				midPos.y += stage.p1_Cam_Offset.y;

				// if(camFollow.x != midPos.x - 100 + boyfriend.cameraOffset[0] || camFollow.y != midPos.y - 100 + boyfriend.cameraOffset[1])
				// {
				if (!paused)
					camFollow.setPosition(midPos.x
						- 100
						+ boyfriend.getMainCharacter().cameraOffset[0],
						midPos.y
						- 100
						+ boyfriend.getMainCharacter().cameraOffset[1]);

				switch (curStage) {
					case 'limo':
						camFollow.x = midPos.x - 300;
					case 'mall':
						camFollow.y = midPos.y - 200;
				}

				call("playerOneTurn", []);
				call("turnChange", ['bf']);
				// }
			}

			if (centerCamera) {
				var midPos = boyfriend.getMainCharacter().getMidpoint();
				midPos.x += stage.p1_Cam_Offset.x;
				midPos.y += stage.p1_Cam_Offset.y;
				camFollow.setPosition(midPos.x
					- 100
					+ boyfriend.getMainCharacter().cameraOffset[0],
					midPos.y
					- 100
					+ boyfriend.getMainCharacter().cameraOffset[1]);
				midPos = dad.getMainCharacter().getMidpoint();
				midPos.x += stage.p2_Cam_Offset.x;
				midPos.y += stage.p2_Cam_Offset.y;
				camFollow.x += midPos.x + 150 + dad.getMainCharacter().cameraOffset[0];
				camFollow.y += midPos.y - 100 + dad.getMainCharacter().cameraOffset[1];
				camFollow.x *= 0.5;
				camFollow.y *= 0.5;
				if (PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)].mustHitSection) {
					if (Options.getData("cameraTracksDirections") && boyfriend.getMainCharacter().hasAnims()) {
						switch (boyfriend.curAnimName().toLowerCase()) {
							case "singleft":
								camFollow.x -= 50;
							case "singright":
								camFollow.x += 50;
							case "singup":
								camFollow.y -= 50;
							case "singdown":
								camFollow.y += 50;
						}
					}
				} else {
					if (Options.getData("cameraTracksDirections") && dad.getMainCharacter().hasAnims()) {
						switch (dad.curAnimName().toLowerCase()) {
							case "singleft":
								camFollow.x -= 50;
							case "singright":
								camFollow.x += 50;
							case "singup":
								camFollow.y -= 50;
							case "singdown":
								camFollow.y += 50;
						}
					}
				}
			}
		}

		// RESET = Quick Game Over Screen
		if ((Options.getData("resetButton") && !switchedStates && controls.RESET) || (Options.getData("noHit") && misses > 0))
			health = minHealth;

		if (health <= minHealth && !switchedStates && !invincible && !Options.getData("noDeath")) {
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getMainCharacter().getScreenPosition().x, boyfriend.getMainCharacter().getScreenPosition().y));

			#if DISCORD_ALLOWED
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end

			call("onDeath", [Conductor.songPosition]);
		}

		health = Math.max(health, minHealth);

		if (unspawnNotes[0] != null && !switchedStates) {
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < (1500.0 * songMultiplier)) {
				notes.add(unspawnNotes[0]);
				unspawnNotes.splice(0, 1);
			}
		}

		if (generatedMusic && !switchedStates && startedCountdown && notes != null && playerStrums.members.length != 0 && enemyStrums.members.length != 0) {
			notes?.forEachAlive(function(daNote:Note) {
				var coolStrum = (daNote.shouldHit ? playerStrums.members[Math.floor(Math.abs(daNote.noteData)) % playerStrums.members.length] : enemyStrums.members[Math.floor(Math.abs(daNote.noteData)) % enemyStrums.members.length]);
				var strumY = coolStrum.y;
				daNote.visible = true;
				daNote.active = true;

				if (Options.getData("downscroll")) {
					// Remember = minus makes notes go up, plus makes them go down
					daNote.y = strumY + (0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(speed, 2));

					if (daNote.isSustainNote) {
						if (daNote.animation.curAnim.name.endsWith("end") && daNote.prevNote != null)
							daNote.y += daNote.prevNote.height;
						else
							daNote.y += daNote.height / 2;

						if (((daNote.wasGoodHit || daNote.prevNote.wasGoodHit) && daNote.shouldHit)
							&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2)) {
							// Clip to strumline
							var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
							swagRect.height = (coolStrum.y + (coolStrum.width / 2) - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				} else {
					daNote.y = strumY - (0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(speed, 2));

					if (daNote.isSustainNote) {
						if (((daNote.wasGoodHit || daNote.prevNote.wasGoodHit) && daNote.shouldHit)
							&& daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2)) {
							// Clip to strumline
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (coolStrum.y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;
							daNote.clipRect = swagRect;
						}
					}
				}
				daNote.calculateCanBeHit();

				if (!daNote.checkPlayerMustPress() && daNote.strumTime <= Conductor.songPosition && daNote.shouldHit) {
					camZooming = true;

					var singAnim:String = NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(false) - 1][Std.int(Math.abs(daNote.noteData))]
						+ (characterPlayingAs == 0 ? altAnim : "") + daNote.singAnimSuffix;
					if (daNote.singAnimPrefix != 'sing') {
						singAnim = singAnim.replace('sing', daNote.singAnimPrefix);
					}

					if (characterPlayingAs == 0) {
						if (dad.otherCharacters == null || dad.otherCharacters.length - 1 < daNote.character)
							dad.playAnim(singAnim, true);
						else {
							if (daNote.characters.length <= 1)
								dad.otherCharacters[daNote.character].playAnim(singAnim, true);
							else {
								for (character in daNote.characters) {
									if (dad.otherCharacters.length - 1 >= character)
										dad.otherCharacters[character].playAnim(singAnim, true);
								}
							}
						}

						if (daNote.isSustainNote) {
							call('playerTwoSingHeld', [
								Math.abs(daNote.noteData),
								Conductor.songPosition,
								daNote.arrow_Type,
								daNote.strumTime,
								daNote.character
							]);
						} else {
							call('playerTwoSing', [
								Math.abs(daNote.noteData),
								Conductor.songPosition,
								daNote.arrow_Type,
								daNote.strumTime,
								daNote.character
							]);
						}
					} else {
						if (boyfriend.otherCharacters == null || boyfriend.otherCharacters.length - 1 < daNote.character)
							boyfriend.playAnim(singAnim, true);
						else if (daNote.characters.length <= 1)
							boyfriend.otherCharacters[daNote.character].playAnim(singAnim, true);
						else {
							for (character in daNote.characters) {
								if (boyfriend.otherCharacters.length - 1 >= character)
									boyfriend.otherCharacters[character].playAnim(singAnim, true);
							}
						}

						if (daNote.isSustainNote) {
							call('playerOneSingHeld', [
								Math.abs(daNote.noteData),
								Conductor.songPosition,
								daNote.arrow_Type,
								daNote.strumTime,
								daNote.character
							]);
						} else {
							call('playerOneSing', [
								Math.abs(daNote.noteData),
								Conductor.songPosition,
								daNote.arrow_Type,
								daNote.strumTime,
								daNote.character
							]);
						}
					}

					call(getSingLuaFuncName(false) + 'SingExtra', [
						Math.abs(daNote.noteData),
						notes.members.indexOf(daNote),
						daNote.arrow_Type,
						daNote.isSustainNote
					]);

					if (enemyStrumsGlow && enemyStrums.members.length - 1 == SONG.keyCount - 1) {
						enemyStrums.forEach(function(spr:StrumNote) {
							if (Math.abs(daNote.noteData) == spr.ID) {
								spr.playAnim('confirm', true);
								spr.resetAnim = 0;

								if (!daNote.isSustainNote && opponentNoteSplashes) {
									var splash = splash_group.recycle(NoteSplash);
									splash.setup_splash(spr.ID, spr, false);

									splash_group.add(splash);
								}

								spr.animation.finishCallback = function(_) spr.playAnim("static");
							}
						});
					}

					if (characterPlayingAs == 0) {
						if (dad.otherCharacters == null || dad.otherCharacters.length - 1 < daNote.character)
							dad.holdTimer = 0;
						else {
							if (daNote.characters.length <= 1)
								dad.otherCharacters[daNote.character].holdTimer = 0;
							else {
								for (char in daNote.characters) {
									if (dad.otherCharacters.length - 1 >= char)
										dad.otherCharacters[char].holdTimer = 0;
								}
							}
						}
					} else {
						if (boyfriend.otherCharacters == null || boyfriend.otherCharacters.length - 1 < daNote.character)
							boyfriend.holdTimer = 0;
						else if (daNote.characters.length <= 1)
							boyfriend.otherCharacters[daNote.character].holdTimer = 0;
						else {
							for (char in daNote.characters) {
								if (boyfriend.otherCharacters.length - 1 >= char)
									boyfriend.otherCharacters[char].holdTimer = 0;
							}
						}
					}

					if (SONG.needsVoices && vocals != null && SONG != null)
						vocals.volume = 1;

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if (daNote != null && coolStrum != null) {
					if (daNote.checkPlayerMustPress() && daNote != null) {
						var coolStrum = playerStrums.members[Math.floor(Math.abs(daNote.noteData))];
						var arrayVal = Std.string([daNote.noteData, daNote.arrow_Type, daNote.isSustainNote]);

						if (coolStrum != null)
							daNote.visible = coolStrum.visible;

						if (!prevPlayerXVals.exists(arrayVal) && prevPlayerXVals != null) {
							var tempShit:Float = 0.0;

							if (coolStrum != null)
								daNote.x = coolStrum.x;

							if (daNote != null && coolStrum != null) {
								while (Std.int(daNote.x + (daNote.width / 2)) != Std.int(coolStrum.x + (coolStrum.width / 2))
									&& coolStrum != null
									&& daNote != null) {
									daNote.x += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
									tempShit += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
								}
							}

							prevPlayerXVals.set(arrayVal, tempShit);
						} else {
							if (coolStrum != null)
								daNote.x = coolStrum.x + prevPlayerXVals.get(arrayVal) - daNote.xOffset;
						}

						if (coolStrum != null && !daNote.isSustainNote && daNote != null)
							daNote.modAngle = coolStrum.angle;

						if (coolStrum != null && coolStrum.alpha != 1 && daNote != null) {
							try {
								daNote.alpha = coolStrum.alpha;
							} catch (e)
								trace(e, ERROR);
						}

						if (!daNote.isSustainNote && coolStrum != null && daNote != null) {
							try {
								daNote.modAngle = coolStrum.angle;
							} catch (e)
								trace(e, ERROR);
						}

						if (coolStrum != null && daNote != null) {
							try {
								daNote.flipX = coolStrum.flipX;
							} catch (e)
								trace(e, ERROR);
						}

						if (!daNote.isSustainNote && coolStrum != null && daNote != null) {
							try {
								daNote.flipY = coolStrum.flipY;
							} catch (e)
								trace(e, ERROR);
						}

						if (coolStrum != null && daNote != null) {
							try {
								daNote.color = coolStrum.color;
							} catch (e)
								trace(e, ERROR);
						}
					} else if (!daNote?.wasGoodHit) {
						var coolStrum = enemyStrums.members[Math.floor(Math.abs(daNote.noteData))];
						var arrayVal = Std.string([daNote.noteData, daNote.arrow_Type, daNote.isSustainNote]);

						if (coolStrum != null && daNote != null)
							daNote.visible = coolStrum.visible;

						if (!prevEnemyXVals.exists(arrayVal) && coolStrum != null) {
							var tempShit:Float = 0.0;

							daNote.x = coolStrum.x;

							while (Std.int(daNote.x + (daNote.width / 2)) != Std.int(coolStrum.x + (coolStrum.width / 2))) {
								daNote.x += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
								tempShit += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
							}

							prevEnemyXVals.set(arrayVal, tempShit);
						} else {
							if (coolStrum != null)
								daNote.x = coolStrum.x + prevEnemyXVals.get(arrayVal) - daNote.xOffset;
						}

						if (coolStrum != null && !daNote.isSustainNote && daNote != null)
							daNote.modAngle = coolStrum.angle;

						if (coolStrum != null && coolStrum.alpha != 1 && daNote != null)
							daNote.alpha = coolStrum.alpha;

						if (coolStrum != null && !daNote.isSustainNote && daNote != null)
							daNote.modAngle = coolStrum.angle;

						if (coolStrum != null && !daNote.isSustainNote && daNote != null)
							daNote.flipX = coolStrum.flipX;

						if (coolStrum != null && !daNote.isSustainNote && daNote != null)
							daNote.flipY = coolStrum.flipY;

						if (coolStrum != null && daNote != null)
							daNote.color = coolStrum.color;
					}
				}

				if (Conductor.songPosition - Conductor.safeZoneOffset > daNote.strumTime) {
					if (daNote != null
						&& daNote.animation != null
						&& daNote.animation.curAnim != null
						&& daNote.checkPlayerMustPress()
						&& daNote.playMissOnMiss
						&& !(daNote.isSustainNote && daNote.animation.curAnim.name == "holdend")
						&& !daNote.wasGoodHit) {
						if (vocals != null) {
							vocals.volume = 0;
						}

						noteMiss(daNote.noteData, daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});

			if (Options.getData("noteBGAlpha") != 0 && !switchedStates)
				updateNoteBGPos();
		}

		if (!inCutscene && !switchedStates)
			keyShit();

		if (FlxG.keys.checkStatus(FlxKey.fromString(Options.getData("pauseBind", "binds")), FlxInputState.JUST_PRESSED)
			&& startedCountdown
			&& canPause
			&& !switchedStates) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			call('onPause', []);
			openSubState(new PauseSubState());

			#if DISCORD_ALLOWED
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (!Options.getData("disableDebugMenus")) {
			if (FlxG.keys.justPressed.SEVEN && !switchedStates && !inCutscene) {
				closeLua();

				PlayState.chartingMode = true;

				switchedStates = true;

				vocals.stop();

				SONG.keyCount = ogKeyCount;
				SONG.playerKeyCount = ogPlayerKeyCount;

				FlxG.switchState(new ChartingState());

				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Chart Editor", null, null, true);
				#end
			}

			// #if debug
			if (FlxG.keys.justPressed.EIGHT && !switchedStates && !inCutscene) {
				closeLua();

				switchedStates = true;

				vocals.stop();

				SONG.keyCount = ogKeyCount;
				SONG.playerKeyCount = ogPlayerKeyCount;

				FlxG.switchState(new toolbox.CharacterCreator(SONG.player2, curStage));

				toolbox.CharacterCreator.lastState = "PlayState";

				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Creating A Character", null, null, true);
				#end
			}

			#if MODCHARTING_TOOLS
			if (FlxG.keys.justPressed.NINE && !switchedStates && !inCutscene) {
				closeLua();

				switchedStates = true;

				vocals.stop();

				SONG.keyCount = ogKeyCount;
				SONG.playerKeyCount = ogPlayerKeyCount;

				FlxG.switchState(new modcharting.ModchartEditorState());

				#if DISCORD_ALLOWED
				DiscordClient.changePresence("In The Modchart Editor", null, null, true);
				#end
			}
			#end
		}

		if (!switchedStates) {
			for (event in events) {
				// activate funni lol
				if (event[1] + Conductor.offset <= Conductor.songPosition) {
					processEvent(event);
					events.remove(event);
				}
			}
		}

		splash_group.forEachDead(function(splash:NoteSplash) {
			if (splash_group.length - 1 > 0) {
				splash_group.remove(splash, true);
				splash.destroy();
			}
		});

		splash_group.forEachAlive(function(splash:NoteSplash) {
			if (splash.animation.finished)
				splash.kill();
		});

		#if LUA_ALLOWED
		if (((stage.stageScript != null || (luaModchart != null && executeModchart))
			|| generatedSomeDumbEventLuas
			|| luaScriptArray.length != 0)
			&& generatedMusic
			&& !switchedStates
			&& startedCountdown) {
			var shaderThing = modding.ModchartUtilities.lua_Shaders;

			for (shaderKey in shaderThing.keys()) {
				if (shaderThing.exists(shaderKey))
					shaderThing.get(shaderKey).update(elapsed);
			}

			setLuaVar("songPos", Conductor.songPosition);
			setLuaVar("hudZoom", camHUD.zoom);
			setLuaVar("curBeat", curBeat);
			setLuaVar("cameraZoom", FlxG.camera.zoom);
			setLuaVar("bpm", Conductor.bpm);
			setLuaVar("songBpm", Conductor.bpm);
			setLuaVar("crochet", Conductor.crochet);
			setLuaVar("stepCrochet", Conductor.stepCrochet);
			setLuaVar("Conductor", {
				bpm: Conductor.bpm,
				crochet: Conductor.crochet,
				stepCrochet: Conductor.stepCrochet,
				songPosition: Conductor.songPosition,
				lastSongPos: Conductor.lastSongPos,
				offset: Conductor.offset,
				safeFrames: Conductor.safeFrames,
				safeZoneOffset: Conductor.safeZoneOffset,
				bpmChangeMap: Conductor.bpmChangeMap,
				timeScaleChangeMap: Conductor.timeScaleChangeMap,
				timeScale: Conductor.timeScale,
				stepsPerSection: Conductor.stepsPerSection,
				curBeat: curBeat,
				curStep: curStep,
			});
			setLuaVar("FlxG", {
				width: FlxG.width,
				height: FlxG.height,
				elapsed: FlxG.elapsed,
			});

			call("update", [elapsed]);

			if (getLuaVar("showOnlyStrums", "bool")) {
				healthBarBG.visible = false;
				infoTxt.visible = false;
				healthBar.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
				scoreTxt.visible = false;

				if (Options.getData("sideRatings"))
					ratingText.visible = false;

				timeBar.visible = false;
				timeBarBG.visible = false;
			} else {
				healthBarBG.visible = true;
				infoTxt.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
				scoreTxt.visible = true;

				if (Options.getData("sideRatings"))
					ratingText.visible = true;

				timeBar.visible = true;
				timeBarBG.visible = true;
			}

			var p1 = getLuaVar("strumLine1Visible", "bool");
			var p2 = getLuaVar("strumLine2Visible", "bool");

			for (i in 0...SONG.keyCount) {
				strumLineNotes.members[i].visible = p1;
			}

			for (i in 0...SONG.playerKeyCount) {
				if (i <= playerStrums.length)
					playerStrums.members[i].visible = p2;
			}

			if (!canFullscreen && FlxG.fullscreen)
				FlxG.fullscreen = false;
		} else {
		#else
		call("update", [elapsed]);
		#end
		#if LUA_ALLOWED
		}
		#end

		call("updatePost", [elapsed]);
	}

	override function destroy() {
		call("onDestroy", []);
		closeLua();
		super.destroy();
		// instance = null;
	}

	function endSong():Void {
		call("endSong", []);
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		// lol dude when a song ended in freeplay it legit reloaded the page and i was like:  o_o ok
		if (FlxG.state == instance) {
			#if LUA_ALLOWED
			if (executeModchart && luaModchart != null) {
				for (sound in ModchartUtilities.lua_Sounds) {
					sound.stop();
					sound.kill();
					sound.destroy();
				}
			}
			closeLua();
			#end

			if (SONG.validScore) {
				Highscore.saveScore(SONG.song, songScore, storyDifficultyStr);
				Highscore.saveRank(SONG.song, Ratings.getRank(accuracy, misses), storyDifficultyStr, accuracy);
			}

			if (playCutsceneOnPauseLmao) {
				if (SONG.endCutscene != null && SONG.endCutscene != "") {
					cutscene = CutsceneUtil.loadFromJson(SONG.endCutscene);

					switch (cutscene.type.toLowerCase()) {
						case "script":
							var cutscene = new HScript(Paths.hx('data/${cutscene.scriptPath}'));
							for (object in stage.stage_Objects) {
								cutscene.interp.variables.set(object[0], object[1]);
							}
							scripts.push(cutscene);
							cutscene.call("startCutscene");

						case "video":
							startVideo(cutscene.videoPath, cutscene.videoExt, true);

						case "dialogue":
							var box:DialogueBox = new DialogueBox(cutscene);
							box.scrollFactor.set();
							box.finish_Function = function() {
								bruhDialogue(true);
							};
							box.cameras = [camHUD];

							startDialogue(box, true);

						default:
							persistentUpdate = false;
							persistentDraw = true;
							paused = true;

							finishSongStuffs();
					}
				} else {
					persistentUpdate = false;
					persistentDraw = true;
					paused = true;

					finishSongStuffs();
				}
			} else {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				finishSongStuffs();
			}
		}
	}

	public function finishSongStuffs() {
		if (isStoryMode) {
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				switchedStates = true;

				if (vocals != null && vocals.active)
					vocals.stop();
				if (FlxG.sound.music != null && FlxG.sound.music.active)
					FlxG.sound.music.stop();

				SONG.keyCount = ogKeyCount;
				SONG.playerKeyCount = ogPlayerKeyCount;

				FlxG.switchState(new StoryMenuState());

				if (SONG.validScore)
					Highscore.saveWeekScore(campaignScore, storyDifficultyStr, (groupWeek != "" ? groupWeek + "Week" : "week") + Std.string(storyWeek));
			} else {
				var difficulty:String = "";

				if (storyDifficultyStr.toLowerCase() != "normal")
					difficulty = '-' + storyDifficultyStr.toLowerCase();

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog') {
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);

					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);

				if (vocals != null && vocals.active)
					vocals.stop();
				if (FlxG.sound.music != null && FlxG.sound.music.active)
					FlxG.sound.music.stop();

				switchedStates = true;
				PlayState.loadChartEvents = true;
				LoadingState.loadAndSwitchState(new PlayState());
			}
		} else {
			trace('WENT BACK TO FREEPLAY??');
			switchedStates = true;

			if (vocals != null && vocals.active)
				vocals.stop();
			if (FlxG.sound.music != null && FlxG.sound.music.active)
				FlxG.sound.music.stop();

			SONG.keyCount = ogKeyCount;
			SONG.playerKeyCount = ogPlayerKeyCount;

			FlxG.switchState(() -> new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	var rating:FlxSprite = new FlxSprite();
	var ratingTween:VarTween;

	var accuracyText:FlxText = new FlxText(0, 0, 0, "bruh", 24);
	var accuracyTween:VarTween;

	var numbers:Array<FlxSprite> = [];
	var number_Tweens:Array<VarTween> = [];

	var uiMap:Map<String, FlxGraphic> = [];

	public function popUpScore(strumtime:Float, noteData:Int, ?setNoteDiff:Float):Void {
		var noteDiff:Float = (strumtime - Conductor.songPosition);

		if (Options.getData("botplay"))
			noteDiff = 0;

		if (setNoteDiff != null)
			noteDiff = setNoteDiff;

		vocals.volume = 1;

		var daRating:String = Ratings.getRating(Math.abs(noteDiff));
		var score:Int = Ratings.getScore(daRating);

		var hitNoteAmount:Float = 0;

		// health switch case
		switch (daRating) {
			case 'sick' | 'marvelous':
				health += 0.035;
			case 'good':
				health += 0.015;
			case 'bad':
				health += 0.005;
			case 'shit':
				if (Options.getData("antiMash"))
					health -= 0.075; // yes its more than a miss so that spamming with ghost tapping on is bad

				if (Options.getData("missOnShit"))
					misses++;

				combo = 0;
		}

		call("popUpScore", [daRating, combo]);

		if (ratings.exists(daRating))
			ratings.set(daRating, ratings.get(daRating) + 1);

		if (Options.getData("sideRatings"))
			updateRatingText();

		switch (daRating) {
			case "sick" | "marvelous":
				hitNoteAmount = 1;
			case "good":
				hitNoteAmount = 0.8;
			case "bad":
				hitNoteAmount = 0.3;
		}

		hitNotes += hitNoteAmount;

		if ((daRating == "sick" || daRating == "marvelous") && playerNoteSplashes) {
			playerStrums.forEachAlive(function(spr:FlxSprite) {
				if (spr.ID == Math.abs(noteData)) {
					var splash = splash_group.recycle(NoteSplash);
					splash.setup_splash(noteData, spr, true);

					splash_group.add(splash);
				}
			});
		}

		songScore += score;
		calculateAccuracy();

		// ez
		if (!Options.getData('ratingsAndCombo'))
			return;

		rating.alpha = 1;
		rating.loadGraphic(uiMap.get(daRating), false, 0, 0, true, daRating);

		rating.screenCenter();
		rating.x = Options.getData("ratingsSettings")[0];
		rating.x -= (Options.getData("middlescroll") ? 350 : (characterPlayingAs == 0 ? 0 : -150));
		rating.y = Options.getData("ratingsSettings")[1];
		rating.y -= 60;
		rating.velocity.y = FlxG.random.int(30, 60);
		rating.velocity.x = FlxG.random.int(-10, 10);

		var noteMath:Float = FlxMath.roundDecimal(noteDiff, 2);

		if (Options.getData("displayMs")) {
			accuracyText.setPosition(rating.x, rating.y + 100);
			accuracyText.text = noteMath + " ms" + (Options.getData("botplay") ? " (BOT)" : "");

			if (Math.abs(noteMath) == noteMath)
				accuracyText.color = FlxColor.CYAN;
			else
				accuracyText.color = FlxColor.ORANGE;

			accuracyText.borderStyle = FlxTextBorderStyle.OUTLINE;
			accuracyText.borderSize = 1;
			accuracyText.font = Paths.font("vcr.ttf");
			accuracyText.antialiasing = ui_settings[3] == "true";

			ratingsGroup.add(accuracyText);
		}

		ratingsGroup.add(rating);

		rating.setGraphicSize(Std.int(rating.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[4])));
		rating.antialiasing = ui_settings[3] == "true";
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		for (i in 0...Std.string(combo).length) {
			seperatedScore.push(Std.parseInt(Std.string(combo).split("")[i]));
		}

		var daLoop:Int = 0;

		for (i in seperatedScore) {
			if (numbers.length - 1 < daLoop)
				numbers.push(new FlxSprite());

			var numScore = numbers[daLoop];
			numScore.alpha = 1;

			numScore.loadGraphic(uiMap.get(Std.string(i)), false, 0, 0, true, Std.string(i));

			numScore.x = Options.getData("comboSettings")[0];
			numScore.y = Options.getData("comboSettings")[1];
			numScore.x -= (Options.getData("middlescroll") ? 350 : (characterPlayingAs == 0 ? 0 : -150));

			numScore.x += (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.setGraphicSize(Std.int(numScore.width * Std.parseFloat(ui_settings[1])));
			numScore.updateHitbox();

			numScore.antialiasing = ui_settings[3] == "true";

			numScore.velocity.y = FlxG.random.int(30, 60);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			ratingsGroup.add(numScore);

			if (number_Tweens[daLoop] == null) {
				number_Tweens[daLoop] = FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.002
				});
			} else {
				numScore.alpha = 1;

				number_Tweens[daLoop].cancel();

				number_Tweens[daLoop] = FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.002
				});
			}

			daLoop++;
		}

		if (ratingTween == null) {
			ratingTween = FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001
			});
		} else {
			rating.alpha = 1;

			ratingTween.cancel();

			ratingTween = FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001
			});
		}

		if (Options.getData("displayMs")) {
			if (accuracyTween == null) {
				accuracyTween = FlxTween.tween(accuracyText, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.001
				});
			} else {
				accuracyText.alpha = 1;

				accuracyTween.cancel();

				accuracyTween = FlxTween.tween(accuracyText, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.001
				});
			}
		}
	}

	public function updateScoreText() {
		scoreTxt.text = '<  ${Options.getData('showScore') ? 'Score:${songScore} ~ ' : ''}Misses:${misses} ~ Accuracy:${accuracy}% ~ ${ratingStr}  >';
		// scoreTxt.text = "Score: " + songScore + " | " + "Misses: " + misses + " | " + "Accuracy: " + accuracy + "% | " + ratingStr;

		scoreTxt.screenCenter(X);
	}

	var justPressedArray:Array<Bool> = [];
	var releasedArray:Array<Bool> = [];
	var justReleasedArray:Array<Bool> = [];
	var heldArray:Array<Bool> = [];
	var previousReleased:Array<Bool> = [];

	public function keyShit() {
		if (generatedMusic && startedCountdown) {
			if (!Options.getData("botplay")) {
				var bruhBinds:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];

				justPressedArray = [];
				justReleasedArray = [];

				previousReleased = releasedArray;

				releasedArray = [];
				heldArray = [];

				for (i in 0...binds.length) {
					justPressedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.JUST_PRESSED);
					releasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.RELEASED);
					justReleasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.JUST_RELEASED);
					heldArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.PRESSED);

					if (releasedArray[i] && SONG.playerKeyCount == 4) {
						justPressedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.JUST_PRESSED);
						releasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.RELEASED);
						justReleasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.JUST_RELEASED);
						heldArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.PRESSED);
					}
				}

				for (i in 0...justPressedArray.length) {
					if (justPressedArray[i]) {
						call("keyPressed", [i]);
					}
				}

				for (i in 0...releasedArray.length) {
					if (releasedArray[i]) {
						call("keyReleased", [i]);
					}
				}

				if (justPressedArray.contains(true) && generatedMusic) {
					// variables
					var possibleNotes:Array<Note> = [];
					var dontHit:Array<Note> = [];

					// notes you can hit lol
					notes.forEachAlive(function(note:Note) {
						note.calculateCanBeHit();

						if (note.canBeHit && note.checkPlayerMustPress() && !note.tooLate && !note.isSustainNote)
							possibleNotes.push(note);
					});

					if (Options.getData("inputSystem") == "rhythm")
						possibleNotes.sort((b, a) -> Std.int(Conductor.songPosition - a.strumTime));
					else
						possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					if (Options.getData("inputSystem") == "rhythm") {
						var coolNote:Note = null;

						for (note in possibleNotes) {
							if (coolNote != null) {
								if (note.strumTime > coolNote.strumTime && note.shouldHit)
									dontHit.push(note);
							} else if (note.shouldHit)
								coolNote = note;
						}
					}

					var noteDataPossibles:Array<Bool> = [];
					var rythmArray:Array<Bool> = [];
					var noteDataTimes:Array<Float> = [];

					for (i in 0...SONG.playerKeyCount) {
						noteDataPossibles.push(false);
						noteDataTimes.push(-1);

						rythmArray.push(false);
					}

					// if there is actual notes to hit
					if (possibleNotes.length > 0) {
						for (i in 0...possibleNotes.length) {
							if (justPressedArray[possibleNotes[i].noteData] && !noteDataPossibles[possibleNotes[i].noteData]) {
								noteDataPossibles[possibleNotes[i].noteData] = true;
								noteDataTimes[possibleNotes[i].noteData] = possibleNotes[i].strumTime;

								if (characterPlayingAs == 0) {
									if (boyfriend.otherCharacters == null
										|| boyfriend.otherCharacters.length - 1 < possibleNotes[i].character)
										boyfriend.holdTimer = 0;
									else if (possibleNotes[i].characters.length <= 1)
										boyfriend.otherCharacters[possibleNotes[i].character].holdTimer = 0;
									else {
										for (char in possibleNotes[i].characters) {
											if (boyfriend.otherCharacters.length - 1 >= char)
												boyfriend.otherCharacters[char].holdTimer = 0;
										}
									}
								} else {
									if (dad.otherCharacters == null || dad.otherCharacters.length - 1 < possibleNotes[i].character)
										dad.holdTimer = 0;
									else if (possibleNotes[i].characters.length <= 1)
										dad.otherCharacters[possibleNotes[i].character].holdTimer = 0;
									else {
										for (char in possibleNotes[i].characters) {
											if (dad.otherCharacters.length - 1 >= char)
												dad.otherCharacters[char].holdTimer = 0;
										}
									}
								}

								goodNoteHit(possibleNotes[i]);

								if (dontHit.contains(possibleNotes[i])) // rythm mode only ?????
								{
									noteMiss(possibleNotes[i].noteData, possibleNotes[i]);
									rythmArray[i] = true;
								}
							}
						}
					}

					if (possibleNotes.length > 0) {
						for (i in 0...possibleNotes.length) {
							if (possibleNotes[i].strumTime == noteDataTimes[possibleNotes[i].noteData])
								goodNoteHit(possibleNotes[i]);
						}
					}

					if (!Options.getData("ghostTapping")) {
						for (i in 0...justPressedArray.length) {
							if (justPressedArray[i] && !noteDataPossibles[i] && !rythmArray[i])
								noteMiss(i);
						}
					}
				}

				if (heldArray.contains(true) && generatedMusic) {
					notes.forEachAlive(function(daNote:Note) {
						daNote.calculateCanBeHit();

						if (heldArray[daNote.noteData] && daNote.isSustainNote && daNote.checkPlayerMustPress()) {
							if (daNote.canBeHit) {
								if (characterPlayingAs == 0) {
									if (boyfriend.otherCharacters == null || boyfriend.otherCharacters.length - 1 < daNote.character)
										boyfriend.holdTimer = 0;
									else if (daNote.characters.length <= 1)
										boyfriend.otherCharacters[daNote.character].holdTimer = 0;
									else {
										for (char in daNote.characters) {
											if (boyfriend.otherCharacters.length - 1 >= char)
												boyfriend.otherCharacters[char].holdTimer = 0;
										}
									}
								} else {
									if (dad.otherCharacters == null || dad.otherCharacters.length - 1 < daNote.character)
										dad.holdTimer = 0;
									else if (daNote.characters.length <= 1)
										dad.otherCharacters[daNote.character].holdTimer = 0;
									else {
										for (char in daNote.characters) {
											if (dad.otherCharacters.length - 1 >= char)
												dad.otherCharacters[char].holdTimer = 0;
										}
									}
								}

								goodNoteHit(daNote);
							}
						}
					});
				}

				if (characterPlayingAs == 0) {
					if (boyfriend.otherCharacters == null) {
						if (boyfriend.animation.curAnim != null)
							if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
								if (boyfriend.animation.curAnim.name.startsWith('sing')
									&& !boyfriend.animation.curAnim.name.endsWith('miss'))
									boyfriend.dance();
					} else {
						for (character in boyfriend.otherCharacters) {
							if (character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
									if (character.animation.curAnim.name.startsWith('sing')
										&& !character.animation.curAnim.name.endsWith('miss'))
										character.dance();
						}
					}
				} else {
					if (dad.otherCharacters == null) {
						if (dad.animation.curAnim != null)
							if (dad.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
								if (dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss'))
									dad.dance(altAnim);
					} else {
						for (character in dad.otherCharacters) {
							if (character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
									if (character.animation.curAnim.name.startsWith('sing')
										&& !character.animation.curAnim.name.endsWith('miss'))
										character.dance(altAnim);
						}
					}
				}

				playerStrums.forEach(function(spr:StrumNote) {
					if (justPressedArray[spr.ID] && spr.animation.curAnim.name != 'confirm') {
						if (playerStrumsGlow) {
							spr.playAnim('pressed');
							spr.resetAnim = 0;
						}
					}

					if (releasedArray[spr.ID]) {
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				});
			} else {
				notes.forEachAlive(function(note:Note) {
					if (note.shouldHit) {
						if (note.checkPlayerMustPress() && note.strumTime <= Conductor.songPosition) {
							if (characterPlayingAs == 0) {
								if (boyfriend.otherCharacters == null || boyfriend.otherCharacters.length - 1 < note.character)
									boyfriend.holdTimer = 0;
								else if (note.characters.length <= 1)
									boyfriend.otherCharacters[note.character].holdTimer = 0;
								else {
									for (char in note.characters) {
										if (boyfriend.otherCharacters.length - 1 >= char)
											boyfriend.otherCharacters[char].holdTimer = 0;
									}
								}
							} else {
								if (dad.otherCharacters == null || dad.otherCharacters.length - 1 < note.character)
									dad.holdTimer = 0;
								else if (note.characters.length <= 1)
									dad.otherCharacters[note.character].holdTimer = 0;
								else {
									for (char in note.characters) {
										if (dad.otherCharacters.length - 1 >= char)
											dad.otherCharacters[char].holdTimer = 0;
									}
								}
							}

							goodNoteHit(note);
						}
					}
				});

				playerStrums.forEach(function(spr:StrumNote) {
					if (spr.animation.finished) {
						spr.playAnim("static");
					}
				});

				if (characterPlayingAs == 0) {
					if (boyfriend.otherCharacters == null) {
						if (boyfriend.animation.curAnim != null)
							if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001)
								if (boyfriend.animation.curAnim.name.startsWith('sing')
									&& !boyfriend.animation.curAnim.name.endsWith('miss'))
									boyfriend.dance();
					} else {
						for (character in boyfriend.otherCharacters) {
							if (character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001)
									if (character.animation.curAnim.name.startsWith('sing')
										&& !character.animation.curAnim.name.endsWith('miss'))
										character.dance();
						}
					}
				} else {
					if (dad.otherCharacters == null) {
						if (dad.animation.curAnim != null)
							if (dad.holdTimer > Conductor.stepCrochet * 4 * 0.001)
								if (dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss'))
									dad.dance(altAnim);
					} else {
						for (character in dad.otherCharacters) {
							if (character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001)
									if (character.animation.curAnim.name.startsWith('sing')
										&& !character.animation.curAnim.name.endsWith('miss'))
										character.dance(altAnim);
						}
					}
				}
			}
		}
	}

	function noteMiss(direction:Int = 1, ?note:Note):Void {
		var canMiss = false;

		if (note == null)
			canMiss = true;
		else {
			if (note.checkPlayerMustPress())
				canMiss = true;
		}

		if (canMiss && !invincible && !Options.getData("botplay")) {
			if (note != null) {
				if (!note.isSustainNote)
					health -= note.missDamage;
				else
					health -= note.heldMissDamage;
			} else
				health -= Std.parseFloat(type_Configs.get("default")[2]);

			if (combo > 5 && gf.animOffsets.exists('sad'))
				gf.playAnim('sad');

			combo = 0;

			var missValues = false;

			if (note != null) {
				if (!note.isSustainNote || (Options.getData("missOnHeldNotes") && !note.missesSustains))
					missValues = true;
			} else
				missValues = true;

			if (missValues) {
				if (note != null) {
					if (Options.getData("missOnHeldNotes") && !note.missesSustains) {
						note.missesSustains = true;

						for (sustain in note.sustains) {
							if (sustain != null)
								sustain.missesSustains = true;
						}
					}
				}

				misses++;

				if (Options.getData("sideRatings"))
					updateRatingText();

				updateScoreText();
			}

			totalNotes++;

			missSounds[FlxG.random.int(0, missSounds.length - 1)].play(true);

			songScore -= 10;

			if (note != null) {
				if (characterPlayingAs == 0) {
					if (boyfriend.otherCharacters != null && !(boyfriend.otherCharacters.length - 1 < note.character)) {
						if (note.characters.length <= 1)
							boyfriend.otherCharacters[note.character].playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction]
								+ "miss", true);
						else {
							for (character in note.characters) {
								if (boyfriend.otherCharacters.length - 1 >= character)
									boyfriend.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction]
										+ "miss", true);
							}
						}
					} else
						boyfriend.playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction] + "miss", true);
				} else {
					if (dad.otherCharacters != null && !(dad.otherCharacters.length - 1 < note.character))
						if (note.characters.length <= 1)
							dad.otherCharacters[note.character].playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction]
								+ "miss", true);
						else {
							for (character in note.characters) {
								if (dad.otherCharacters.length - 1 >= character)
									dad.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction]
										+ "miss", true);
							}
						}
					else
						dad.playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction] + "miss", true);
				}
			} else {
				if (characterPlayingAs == 0)
					boyfriend.playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction] + "miss", true);
				else
					dad.playAnim(NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][direction] + "miss", true);
			}

			calculateAccuracy();

			call("playerOneMiss", [
				direction,
				Conductor.songPosition,
				(note != null ? note.arrow_Type : "default"),
				(note != null ? note.isSustainNote : false)
			]);

			#if LUA_ALLOWED
			setLuaVar("misses", misses);
			#end
		}
	}

	var hitsound:FlxSound;

	function goodNoteHit(note:Note, ?setNoteDiff:Float):Void {
		if (!note.wasGoodHit) {
			if (note.shouldHit && !note.isSustainNote) {
				combo++;
				popUpScore(note.strumTime, note.noteData % getCorrectKeyCount(true), setNoteDiff);

				if (hitSoundString != "none")
					hitsound.play(true);
			} else if (!note.shouldHit) {
				health -= note.hitDamage;
				misses++;
				missSounds[FlxG.random.int(0, missSounds.length - 1)].play(true);
			}

			if (note.shouldHit && note.isSustainNote)
				health += 0.02;

			if (!note.isSustainNote)
				totalNotes++;

			calculateAccuracy();

			var lua_Data:Array<Dynamic> = [
				note.noteData,
				Conductor.songPosition,
				note.arrow_Type,
				note.strumTime,
				note.character
			];

			var singAnim:String = NoteVariables.Character_Animation_Arrays[getCorrectKeyCount(true) - 1][Std.int(Math.abs(note.noteData % getCorrectKeyCount(true)))]
				+ (characterPlayingAs == 1 ? altAnim : "")
				+ note.singAnimSuffix;
			if (note.singAnimPrefix != 'sing') {
				singAnim = singAnim.replace('sing', note.singAnimPrefix);
			}
			if (characterPlayingAs == 0) {
				if (boyfriend.otherCharacters != null && !(boyfriend.otherCharacters.length - 1 < note.character))
					if (note.characters.length <= 1)
						boyfriend.otherCharacters[note.character].playAnim(singAnim, true);
					else {
						for (character in note.characters) {
							if (boyfriend.otherCharacters.length - 1 >= character)
								boyfriend.otherCharacters[character].playAnim(singAnim, true);
						}
					}
				else
					boyfriend.playAnim(singAnim, true);

				if (note.isSustainNote) {
					call("playerOneSingHeld", lua_Data);
				} else {
					call("playerOneSing", lua_Data);
				}
				call('playerOneSingExtra', [
					Math.abs(note.noteData),
					notes.members.indexOf(note),
					note.arrow_Type,
					note.isSustainNote
				]);
			} else {
				if (dad.otherCharacters != null && !(dad.otherCharacters.length - 1 < note.character))
					if (note.characters.length <= 1)
						dad.otherCharacters[note.character].playAnim(singAnim, true);
					else {
						for (character in note.characters) {
							if (dad.otherCharacters.length - 1 >= character)
								dad.otherCharacters[character].playAnim(singAnim, true);
						}
					}
				else
					dad.playAnim(singAnim, true);

				if (note.isSustainNote) {
					call("playerTwoSingHeld", lua_Data);
				} else {
					call("playerTwoSing", lua_Data);
				}
			}

			if (startedCountdown) {
				playerStrums.forEach(function(spr:StrumNote) {
					if (Math.abs(note.noteData) == spr.ID) {
						if (playerStrumsGlow) {
							spr.playAnim('confirm', true);
						}
					}
				});
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	override function stepHit() {
		super.stepHit();

		var gamerValue = 20 * songMultiplier;

		if (FlxG.sound.music.time > Conductor.songPosition + gamerValue
			|| FlxG.sound.music.time < Conductor.songPosition - gamerValue
			|| FlxG.sound.music.time < 500
			&& (FlxG.sound.music.time > Conductor.songPosition + 5 || FlxG.sound.music.time < Conductor.songPosition - 5))
			resyncVocals();

		setLuaVar("curStep", curStep);
		call("stepHit", [curStep]);
	}

	override function beatHit() {
		super.beatHit();

		if (generatedMusic && startedCountdown)
			notes.sort(FlxSort.byY, (Options.getData("downscroll") ? FlxSort.ASCENDING : FlxSort.DESCENDING));

		if (SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)] != null) {
			if (funnyTimeBarStyle == 'leather engine'
				&& Math.floor(curStep / Conductor.stepsPerSection) != Math.floor((curStep - 1) / Conductor.stepsPerSection)) {
				var target:FlxColor = SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)].mustHitSection ? boyfriend.barColor : dad.barColor;
				FlxTween.color(timeBar, Conductor.crochet * 0.002, timeBar.color, target);
			}

			if (SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)].changeBPM)
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)].bpm, songMultiplier);

			// Dad doesnt interupt his own notes
			if (characterPlayingAs == 0) {
				if (dad.otherCharacters == null) {
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing'))
						if (!dad.curCharacter.startsWith('gf'))
							dad.dance(altAnim);
				} else {
					for (character in dad.otherCharacters) {
						if (character.animation.curAnim != null && !character.animation.curAnim.name.startsWith('sing'))
							if (!character.curCharacter.startsWith('gf'))
								character.dance(altAnim);
					}
				}
			} else {
				if (boyfriend.otherCharacters == null) {
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
						if (!boyfriend.curCharacter.startsWith('gf'))
							boyfriend.dance();
				} else {
					for (character in boyfriend.otherCharacters) {
						if (character.animation.curAnim != null && !character.animation.curAnim.name.startsWith('sing'))
							if (!character.curCharacter.startsWith('gf'))
								character.dance();
					}
				}
			}
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % Conductor.timeScale[0] == 0) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.scale.set(iconP1.scale.x + (0.2 / (songMultiplier < 1 ? 1 : songMultiplier)),
			iconP1.scale.y + (0.2 / (songMultiplier < 1 ? 1 : songMultiplier)));
		iconP2.scale.set(iconP2.scale.x + (0.2 / (songMultiplier < 1 ? 1 : songMultiplier)),
			iconP2.scale.y + (0.2 / (songMultiplier < 1 ? 1 : songMultiplier)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset) - iconP1.offsetX;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (iconP2.width - iconOffset)
			- iconP2.offsetX;

		if (gfSpeed < 1)
			gfSpeed = 1;

		if (curBeat % gfSpeed == 0 && !dad.curCharacter.startsWith('gf'))
			gf.dance();

		if (dad.animation.curAnim != null)
			if (!dad.animation.curAnim.name.startsWith("sing") && curBeat % gfSpeed == 0 && dad.curCharacter.startsWith('gf'))
				dad.dance();

		if (characterPlayingAs == 0) {
			if (boyfriend.otherCharacters == null) {
				if (boyfriend.animation.curAnim != null)
					if (!boyfriend.animation.curAnim.name.startsWith("sing"))
						boyfriend.dance();
			} else {
				for (character in boyfriend.otherCharacters) {
					if (character.animation.curAnim != null)
						if (!character.animation.curAnim.name.startsWith("sing"))
							character.dance();
				}
			}
		} else {
			if (dad.otherCharacters == null) {
				if (dad.animation.curAnim != null)
					if (!dad.animation.curAnim.name.startsWith("sing"))
						dad.dance(altAnim);
			} else {
				for (character in dad.otherCharacters) {
					if (character.animation.curAnim != null)
						if (!character.animation.curAnim.name.startsWith("sing"))
							character.dance(altAnim);
				}
			}
		}

		if (curBeat % 8 == 7 && SONG.song.toLowerCase() == 'bopeebo' && boyfriend.otherCharacters == null)
			boyfriend.playAnim('hey', true);

		if (curBeat % 16 == 15 && SONG.song.toLowerCase() == 'tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48) {
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		} else if (curBeat % 16 == 15
			&& SONG.song.toLowerCase() == 'tutorial'
			&& dad.curCharacter != 'gf'
			&& curBeat > 16
			&& curBeat < 48) {
			boyfriend.playAnim('hey', true);
			gf.playAnim('cheer', true);
		}

		stage.beatHit();

		call("beatHit", [curBeat]);
	}

	function updateRatingText() {
		if (Options.getData("sideRatings")) {
			ratingText.text = returnStupidRatingText();
			ratingText.screenCenter(Y);
		}
	}

	public function returnStupidRatingText():String {
		var ratingArray = [
			ratings.get("marvelous"),
			ratings.get("sick"),
			ratings.get("good"),
			ratings.get("bad"),
			ratings.get("shit")
		];

		var MA = ratingArray[1] + ratingArray[2] + ratingArray[3] + ratingArray[4];
		var PA = ratingArray[2] + ratingArray[3] + ratingArray[4];

		return ((marvelousRatings ? "Marvelous: " + Std.string(ratingArray[0]) + "\n" : "")
			+ "Sick: "
			+ Std.string(ratingArray[1])
			+ "\n"
			+ "Good: "
			+ Std.string(ratingArray[2])
			+ "\n"
			+ "Bad: "
			+ Std.string(ratingArray[3])
			+ "\n"
			+ "Shit: "
			+ Std.string(ratingArray[4])
			+ "\n"
			+ "Misses: "
			+ Std.string(misses)
			+ "\n"
			+ (marvelousRatings
				&& ratingArray[0] > 0
				&& MA > 0 ? "MA: " + Std.string(FlxMath.roundDecimal(ratingArray[0] / MA, 2)) + "\n" : "")
			+ (ratingArray[1] > 0
				&& PA > 0 ? "PA: " + Std.string(FlxMath.roundDecimal((ratingArray[1] + ratingArray[0]) / PA, 2)) + "\n" : ""));
	}

	public static function getCharFromEvent(eventVal:String):Character {
		switch (eventVal.toLowerCase()) {
			case "girlfriend" | "gf" | "player3" | "2":
				return PlayState.gf;
			case "dad" | "opponent" | "player2" | "1":
				return PlayState.dad;
			case "bf" | "boyfriend" | "player" | "player1" | "0":
				return PlayState.boyfriend;
		}

		return PlayState.boyfriend;
	}

	function removeBgStuff() {
		remove(stage);
		remove(stage.foregroundSprites);
		remove(stage.infrontOfGFSprites);

		if (gf.otherCharacters == null) {
			if (gf.coolTrail != null)
				remove(gf.coolTrail);

			remove(gf);
		} else {
			for (character in gf.otherCharacters) {
				if (character.coolTrail != null)
					remove(character.coolTrail);

				remove(character);
			}
		}

		if (dad.otherCharacters == null) {
			if (dad.coolTrail != null)
				remove(dad.coolTrail);

			remove(dad);
		} else {
			for (character in dad.otherCharacters) {
				if (character.coolTrail != null)
					remove(character.coolTrail);

				remove(character);
			}
		}

		if (boyfriend.otherCharacters == null) {
			if (boyfriend.coolTrail != null)
				remove(boyfriend.coolTrail);

			remove(boyfriend);
		} else {
			for (character in boyfriend.otherCharacters) {
				if (character.coolTrail != null)
					remove(character.coolTrail);

				remove(character);
			}
		}
	}

	function addBgStuff() {
		stage.setCharOffsets();

		add(stage);

		if (dad.curCharacter.startsWith("gf")) {
			dad.setPosition(gf.x, gf.y);
			gf.visible = false;
		} else if (!gf.visible && gf.curCharacter != "")
			gf.visible = true;

		if (gf.otherCharacters == null) {
			if (gf.coolTrail != null) {
				remove(gf.coolTrail);
				add(gf.coolTrail);
			}

			remove(gf);
			add(gf);
		} else {
			for (character in gf.otherCharacters) {
				if (character.coolTrail != null) {
					remove(character.coolTrail);
					add(character.coolTrail);
				}

				remove(character);
				add(character);
			}
		}

		if (!dad.curCharacter.startsWith("gf"))
			add(stage.infrontOfGFSprites);

		if (dad.otherCharacters == null) {
			if (dad.coolTrail != null) {
				remove(dad.coolTrail);
				add(dad.coolTrail);
			}

			remove(dad);
			add(dad);
		} else {
			for (character in dad.otherCharacters) {
				if (character.coolTrail != null) {
					remove(character.coolTrail);
					add(character.coolTrail);
				}

				remove(character);
				add(character);
			}
		}

		if (dad.curCharacter.startsWith("gf"))
			add(stage.infrontOfGFSprites);

		if (boyfriend.otherCharacters == null) {
			if (boyfriend.coolTrail != null) {
				remove(boyfriend.coolTrail);
				add(boyfriend.coolTrail);
			}

			remove(boyfriend);
			add(boyfriend);
		} else {
			for (character in boyfriend.otherCharacters) {
				if (character.coolTrail != null) {
					remove(character.coolTrail);
					add(character.coolTrail);
				}

				remove(character);
				add(character);
			}
		}

		add(stage.foregroundSprites);
	}

	function eventCharacterShit(event:Array<Dynamic>) {
		removeBgStuff();

		if (gfMap.exists(event[3]) || bfMap.exists(event[3]) || dadMap.exists(event[3])) // prevent game crash
		{
			switch (event[2].toLowerCase()) {
				case "girlfriend" | "gf" | "2":
					var oldGf = gf;
					oldGf.alpha = 0.00001;

					if (oldGf.otherCharacters != null) {
						for (character in oldGf.otherCharacters) {
							character.alpha = 0.00001;
						}
					}

					var newGf = gfMap.get(event[3]);
					newGf.alpha = 1;
					gf = newGf;
					gf.dance();

					if (newGf.otherCharacters != null) {
						for (character in newGf.otherCharacters) {
							character.alpha = 1;
						}
					}

					#if LUA_ALLOWED
					if (executeModchart && luaModchart != null)
						luaModchart.setupTheShitCuzPullRequestsSuck();

					if (stage.stageScript != null)
						stage.stageScript.setupTheShitCuzPullRequestsSuck();

					if (generatedSomeDumbEventLuas) {
						for (event in event_luas.keys()) {
							if (event_luas.exists(event))
								event_luas.get(event).setupTheShitCuzPullRequestsSuck();
						}
					}

					if (luaScriptArray.length != 0) {
						for (i in luaScriptArray) {
							i.setupTheShitCuzPullRequestsSuck();
						}
					}
					#end
				case "dad" | "opponent" | "1":
					var oldDad = dad;
					oldDad.alpha = 0.00001;

					if (oldDad.otherCharacters != null) {
						for (character in oldDad.otherCharacters) {
							character.alpha = 0.00001;
						}
					}

					var newDad = dadMap.get(event[3]);
					newDad.alpha = 1;
					dad = newDad;
					dad.dance();

					if (newDad.otherCharacters != null) {
						for (character in newDad.otherCharacters) {
							character.alpha = 1;
						}
					}

					#if LUA_ALLOWED
					if (executeModchart && luaModchart != null)
						luaModchart.setupTheShitCuzPullRequestsSuck();

					if (stage.stageScript != null)
						stage.stageScript.setupTheShitCuzPullRequestsSuck();

					if (generatedSomeDumbEventLuas) {
						for (event in event_luas.keys()) {
							if (event_luas.exists(event))
								event_luas.get(event).setupTheShitCuzPullRequestsSuck();
						}
					}

					if (luaScriptArray.length != 0) {
						for (i in luaScriptArray) {
							i.setupTheShitCuzPullRequestsSuck();
						}
					}
					#end

					@:privateAccess
					{
						var bar = PlayState.instance.healthBar;

						iconP2.scale.set(1, 1);
						iconP2.changeIconSet(dad.icon);

						bar.createFilledBar(dad.barColor, boyfriend.barColor);
						bar.updateFilledBar();
					}
				case "bf" | "boyfriend" | "player" | "0":
					{
						var oldBF = boyfriend;
						oldBF.alpha = 0.00001;

						if (oldBF.otherCharacters != null) {
							for (character in oldBF.otherCharacters) {
								character.alpha = 0.00001;
							}
						}

						var newBF = bfMap.get(event[3]);
						newBF.alpha = 1;
						boyfriend = newBF;
						boyfriend.dance();

						if (newBF.otherCharacters != null) {
							for (character in newBF.otherCharacters) {
								character.alpha = 1;
							}
						}

						#if LUA_ALLOWED
						if (executeModchart && luaModchart != null)
							luaModchart.setupTheShitCuzPullRequestsSuck();

						if (stage.stageScript != null)
							stage.stageScript.setupTheShitCuzPullRequestsSuck();

						if (generatedSomeDumbEventLuas) {
							for (event in event_luas.keys()) {
								if (event_luas.exists(event))
									event_luas.get(event).setupTheShitCuzPullRequestsSuck();
							}
						}

						if (luaScriptArray.length != 0) {
							for (i in luaScriptArray) {
								i.setupTheShitCuzPullRequestsSuck();
							}
						}
						#end
					}

					@:privateAccess
					{
						var bar = PlayState.instance.healthBar;

						iconP1.scale.set(1, 1);
						iconP1.changeIconSet(boyfriend.icon);

						bar.createFilledBar(dad.barColor, boyfriend.barColor);
						bar.updateFilledBar();
					}
			}
		} else
			CoolUtil.coolError("The character " + event[3] + " isn't in any character cache!\nHow did this happen? ¯|_(ツ)_|¯",
				"Leather Engine's No Crash, We Help Fix Stuff Tool");

		addBgStuff();
	}

	public function updateSongInfoText() {
		var songThingy = songLength - FlxG.sound.music.time;

		var seconds = Math.floor(songThingy / 1000);
		seconds = Std.int(seconds / songMultiplier);
		if (seconds < 0)
			seconds = 0;

		switch (funnyTimeBarStyle.toLowerCase()) {
			default: // includes 'leather engine'
				infoTxt.text = SONG.song + " ~ " + storyDifficultyStr + ' (${FlxStringUtil.formatTime(seconds, false)})'
					+ (Options.getData("botplay") ? " (BOT)" : "") + (Options.getData("noDeath") ? " (NO DEATH)" : "");
				infoTxt.screenCenter(X);
			case "psych engine":
				infoTxt.text = '${FlxStringUtil.formatTime(seconds, false)}' + (Options.getData("botplay") ? " (BOT)" : "")
					+ (Options.getData("noDeath") ? " (NO DEATH)" : "");
				infoTxt.screenCenter(X);
			case "old kade engine":
				infoTxt.text = SONG.song + (Options.getData("botplay") ? " (BOT)" : "") + (Options.getData("noDeath") ? " (NO DEATH)" : "");
				infoTxt.screenCenter(X);
		}
	}

	public inline function set(name:String, data:Dynamic, ?execute_on:Execute_On = BOTH, ?stage_data:Dynamic) {
		setLuaVar(name, data, execute_on, stage_data);
		for (script in scripts) {
			if (execute_on != STAGE) {
				script.interp.variables.set(name, data);
			}
		}
	}

	public inline function call(func:String, ?args:Array<Dynamic>, ?execute_on:Execute_On = BOTH, ?stage_arguments:Array<Dynamic>) {
		hscriptCall(func, (args == []) ? null : args, execute_on);
		#if LUA_ALLOWED
		executeALuaState(func, args, execute_on, stage_arguments);
		#end
	}

	public function hscriptCall(func:String, ?args:Array<Dynamic>, ?execute_on:Execute_On = BOTH) {
		if (scripts.length != 0 && execute_on != STAGE) {
			for (cool_script in scripts) {
				cool_script.call(func, args);
			}
		}

		if (execute_on != STAGE) {
			for (cool_script in hscriptEvents.keys()) {
				if (hscriptEvents.exists(cool_script))
					hscriptEvents.get(cool_script).call(func, args);
			}
		}
	}

	public function executeALuaState(name:String, arguments:Array<Dynamic>, ?execute_on:Execute_On = BOTH, ?stage_arguments:Array<Dynamic>) {
		if (stage_arguments == null)
			stage_arguments = arguments;

		#if LUA_ALLOWED
		if (executeModchart && luaModchart != null && execute_on != STAGE)
			luaModchart.executeState(name, arguments);

		if (stage.stageScript != null && execute_on != MODCHART)
			stage.stageScript.executeState(name, stage_arguments);

		if (execute_on != STAGE) {
			for (script in event_luas.keys()) {
				if (event_luas.exists(script))
					event_luas.get(script).executeState(name, arguments);
			}
		}

		if (luaScriptArray.length != 0 && execute_on != STAGE) {
			for (script in luaScriptArray) {
				script.executeState(name, arguments);
			}
		}
		#end
	}

	function setLuaVar(name:String, data:Dynamic, ?execute_on:Execute_On = BOTH, ?stage_data:Dynamic) {
		if (stage_data == null)
			stage_data = data;

		#if LUA_ALLOWED
		if (executeModchart && luaModchart != null && execute_on != STAGE) {
			luaModchart.setVar(name, data);
		}

		if (luaScriptArray.length != 0 && execute_on != STAGE) {
			for (i in luaScriptArray) {
				i.setVar(name, data);
			}
		}

		if (stage.stageScript != null && execute_on != MODCHART)
			stage.stageScript.setVar(name, stage_data);

		if (execute_on != STAGE) {
			for (script in event_luas.keys()) {
				if (event_luas.exists(script))
					event_luas.get(script).setVar(name, data);
			}
		}
		#end
	}

	function getLuaVar(name:String, type:String):Dynamic {
		#if LUA_ALLOWED
		var luaVar:Dynamic = null;

		// we prioritize modchart cuz frick you

		if (stage.stageScript != null) {
			var newLuaVar = stage.stageScript.getVar(name, type);

			if (newLuaVar != null)
				luaVar = newLuaVar;
		}

		for (script in event_luas.keys()) {
			if (event_luas.exists(script)) {
				var newLuaVar = event_luas.get(script).getVar(name, type);

				if (newLuaVar != null)
					luaVar = newLuaVar;
			}
		}

		if (executeModchart && luaModchart != null) {
			var newLuaVar = luaModchart.getVar(name, type);

			if (newLuaVar != null)
				luaVar = newLuaVar;
		}

		if (luaScriptArray.length != 0) {
			for (i in luaScriptArray) {
				var newLuaVar = i.getVar(name, type);

				if (newLuaVar != null)
					luaVar = newLuaVar;
			}
		}
		if (luaVar != null)
			return luaVar;
		#end

		return null;
	}

	public function closeLua() {
		clearLuaObjects();

		#if LUA_ALLOWED
		if (executeModchart && luaModchart != null) {
			luaModchart.die();
			luaModchart = null;
		}
		if (stage.stageScript != null) {
			stage.stageScript.die();
			stage.stageScript = null;
		}

		/*if (generatedSomeDumbEventLuas) {
			for (key in event_luas.keys()) {
				var event_lua:ModchartUtilities = event_luas.get(key);
				if(event_lua != null){
					event_lua.die();
					event_lua = null;
				}
			}
		}*/

		if (luaScriptArray.length != 0) {
			for (i in luaScriptArray) {
				if (i != null) {
					i.die();
					i = null;
				}
			}
		}
		luaScriptArray = [];
		#end
	}

	public function processEvent(event:Array<Dynamic>) {
		#if LUA_ALLOWED
		if (!event_luas.exists(event[0].toLowerCase()) && Assets.exists(Paths.lua("event data/" + event[0].toLowerCase()))) {
			event_luas.set(event[0].toLowerCase(), new ModchartUtilities(PolymodAssets.getPath(Paths.lua("event data/" + event[0].toLowerCase()))));
			generatedSomeDumbEventLuas = true;

			for (i in 0...strumLineNotes.length) {
				var member = strumLineNotes.members[i];

				event_luas.get(event[0].toLowerCase()).setVar("defaultStrum" + i + "X", member.x);
				event_luas.get(event[0].toLowerCase()).setVar("defaultStrum" + i + "Y", member.y);
				event_luas.get(event[0].toLowerCase()).setVar("defaultStrum" + i + "Angle", member.angle);

				event_luas.get(event[0].toLowerCase()).setVar("defaultStrum" + i, {
					x: member.x,
					y: member.y,
					angle: member.angle,
				});
			}
		}
		#end
		if (!hscriptEvents.exists(event[0].toLowerCase()) && Assets.exists(Paths.hx("data/event data/" + event[0].toLowerCase()))) {
			hscriptEvents.set(event[0].toLowerCase(), new HScript(Paths.hx("data/event data/" + event[0].toLowerCase())));
		}

		switch (event[0].toLowerCase()) {
			#if !linc_luajit
			case "hey!":
				var charString = event[2].toLowerCase();

				var char:Int = 0;

				if (charString == "bf" || charString == "boyfriend" || charString == "player" || charString == "player1")
					char = 1;

				if (charString == "gf" || charString == "girlfriend" || charString == "player3")
					char = 2;

				switch (char) {
					case 0:
						boyfriend.playAnim("hey", true);
						gf.playAnim("cheer", true);
					case 1:
						boyfriend.playAnim("hey", true);
					case 2:
						gf.playAnim("cheer", true);
				}
			case "set gf speed":
				if (Std.parseInt(event[2]) != null)
					gfSpeed = Std.parseInt(event[2]);
			case "character will idle":
				var char = getCharFromEvent(event[2]);

				var funny = Std.string(event[3]).toLowerCase() == "true";

				char.shouldDance = funny;
			case "set camera zoom":
				var defaultCamZoomThing:Float = Std.parseFloat(event[2]);
				var hudCamZoomThing:Float = Std.parseFloat(event[3]);

				if (Math.isNaN(defaultCamZoomThing))
					defaultCamZoomThing = defaultCamZoom;

				if (Math.isNaN(hudCamZoomThing))
					hudCamZoomThing = 1;

				defaultCamZoom = defaultCamZoomThing;
				defaultHudCamZoom = hudCamZoomThing;
			case "change character alpha":
				var char = getCharFromEvent(event[2]);

				var alphaVal:Float = Std.parseFloat(event[3]);

				if (Math.isNaN(alphaVal))
					alphaVal = 0.5;

				char.alpha = alphaVal;
			case "play character animation":
				var character:Character = getCharFromEvent(event[2]);

				var anim:String = "idle";

				if (event[3] != "")
					anim = event[3];

				character.playAnim(anim, true);
			case "camera flash":
				var time = Std.parseFloat(event[3]);

				if (Math.isNaN(time))
					time = 1;

				if (Options.getData("flashingLights"))
					camGame.flash(FlxColor.fromString(event[2].toLowerCase()), time);
			case "camera fade":
				var time = Std.parseFloat(event[3]);

				if (Math.isNaN(time))
					time = 1;

				if (Options.getData("flashingLights"))
					camGame.fade(FlxColor.fromString(event[2].toLowerCase()), time);
			#end
			case "add camera zoom":
				if (Options.getData("cameraZooms") && ((FlxG.camera.zoom < 1.35 && camZooming) || !camZooming)) {
					var addGame:Float = Std.parseFloat(event[2]);
					var addHUD:Float = Std.parseFloat(event[3]);

					if (Math.isNaN(addGame))
						addGame = 0.015;

					if (Math.isNaN(addHUD))
						addHUD = 0.03;

					FlxG.camera.zoom += addGame;
					camHUD.zoom += addHUD;
				}
			case "screen shake":
				if (Options.getData("screenShakes")) {
					var valuesArray:Array<String> = [event[2], event[3]];
					var targetsArray:Array<FlxCamera> = [camGame, camHUD];

					for (i in 0...targetsArray.length) {
						var split:Array<String> = valuesArray[i].split(',');
						var duration:Float = 0;
						var intensity:Float = 0;

						if (split[0] != null)
							duration = Std.parseFloat(split[0].trim());
						if (split[1] != null)
							intensity = Std.parseFloat(split[1].trim());
						if (Math.isNaN(duration))
							duration = 0;
						if (Math.isNaN(intensity))
							intensity = 0;

						if (duration > 0 && intensity != 0)
							targetsArray[i].shake(intensity, duration);
					}
				}
			case "change scroll speed":
				var duration:Float = Std.parseFloat(event[3]);

				if (duration == Math.NaN)
					duration = 0;

				var funnySpeed = Std.parseFloat(event[2]);

				if (!Math.isNaN(funnySpeed)) {
					if (duration > 0)
						FlxTween.tween(this, {speed: funnySpeed}, duration);
					else
						speed = funnySpeed;
				}
			case "change camera speed":
				var speed:Float = Std.parseFloat(event[2]);
				if (Math.isNaN(speed))
					speed = 1;
				cameraSpeed = speed;
			case "change camera zoom speed":
				var speed:Float = Std.parseFloat(event[2]);
				if (Math.isNaN(speed))
					speed = 1;
				cameraZoomSpeed = speed;
			case "character will idle?":
				var char = getCharFromEvent(event[2]);

				var funny = Std.string(event[3]).toLowerCase() == "true";

				char.shouldDance = funny;
			case "change character":
				if (Options.getData("charsAndBGs"))
					eventCharacterShit(event);
			case "change stage":
				if (Options.getData("charsAndBGs")) {
					removeBgStuff();

					if (!Options.getData("preloadChangeBGs")) {
						stage.kill();
						stage.foregroundSprites.kill();
						stage.infrontOfGFSprites.kill();

						stage.foregroundSprites.destroy();
						stage.infrontOfGFSprites.destroy();
						stage.destroy();
					} else {
						stage.active = false;

						stage.visible = false;
						stage.foregroundSprites.visible = false;
						stage.infrontOfGFSprites.visible = false;
					}

					if (!Options.getData("preloadChangeBGs"))
						stage = new StageGroup(event[2]);
					else
						stage = stageMap.get(event[2]);

					stage.visible = true;
					stage.foregroundSprites.visible = true;
					stage.infrontOfGFSprites.visible = true;
					stage.active = true;

					defaultCamZoom = stage.camZoom;

					#if LUA_ALLOWED
					stage.createLuaStuff();
					#end

					call("create", [stage.stage], STAGE);
					call("createStage", [stage.stage]);

					#if LUA_ALLOWED
					if (stage.stageScript != null)
						stage.stageScript.setupTheShitCuzPullRequestsSuck();
					#end

					call("start", [stage.stage], STAGE);

					addBgStuff();
				}
			case "change keycount":
				var toChange:Int = Std.parseInt(event[2]);
				var toChangeAlt:Int = Std.parseInt(event[3]);
				if (toChange < 1 || Math.isNaN(toChange))
					toChange = 1;

				if (toChangeAlt < 1 || Math.isNaN(toChangeAlt))
					toChangeAlt = 1;

				SONG.keyCount = toChangeAlt;
				SONG.playerKeyCount = toChange;
				playerStrums.clear();
				enemyStrums.clear();
				strumLineNotes.clear();
				splash_group.clear();
				binds = Options.getData("binds", "binds")[SONG.playerKeyCount - 1];
				if (Options.getData("middlescroll")) {
					generateStaticArrows(50, false);
					generateStaticArrows(0.5, true);
				} else {
					if (characterPlayingAs == 0) {
						generateStaticArrows(0, false);
						generateStaticArrows(1, true);
					} else {
						generateStaticArrows(1, false);
						generateStaticArrows(0, true);
					}
				}
				/*for (note in notes.members){
						trace(note.reloadNotes == null, DEBUG);
						if(note != null){
							note.reloadNotes(
							note.strumTime, 
							note.noteData, 	
							note.prevNote, 
							note.isSustainNote, 
							note.character, 
							note.arrow_Type, 
							PlayState.SONG, 
							note.characters, 
							note.checkPlayerMustPress(), 
							note.inEditor);
						}
					}
					for(note in unspawnNotes){
						if(note != null){
							note.reloadNotes(
							note.strumTime, 
							note.noteData, 
							note.prevNote, 
							note.isSustainNote, 
							note.character, 
							note.arrow_Type, 
							PlayState.SONG, 
							note.characters, 
							note.checkPlayerMustPress(), 
							note.inEditor);
						}
				}*/
				#if LUA_ALLOWED
				for (i in 0...strumLineNotes.length) {
					var member = strumLineNotes.members[i];

					setLuaVar("defaultStrum" + i + "X", member.x);
					setLuaVar("defaultStrum" + i + "Y", member.y);
					setLuaVar("defaultStrum" + i + "Angle", member.angle);

					setLuaVar("defaultStrum" + i, {
						x: member.x,
						y: member.y,
						angle: member.angle,
					});

					if (enemyStrums.members.contains(member)) {
						setLuaVar("enemyStrum" + i % SONG.keyCount, {
							x: member.x,
							y: member.y,
							angle: member.angle,
						});
					} else {
						setLuaVar("playerStrum" + i % SONG.playerKeyCount, {
							x: member.x,
							y: member.y,
							angle: member.angle,
						});
					}
				}
				#end
				if (Options.getData('colorQuantization')) {
					for (note in notes.members) {
						if (note.affectedbycolor) {
							var quantStrumTime = note.isSustainNote ? note.prevNote.prevNoteStrumtime : note.strumTime;
							var currentStepCrochet = Conductor.stepCrochet;
							var noteBeat = Math.floor(((quantStrumTime / (currentStepCrochet * 4)) * 48) + 0.5);
							var col:Array<Int> = [142, 142, 142];
							for (beat in 0...note.beats.length - 1) {
								if ((noteBeat % (192 / note.beats[beat]) == 0)) {
									noteBeat = note.beats[beat];
									col = note.quantColors[beat];
									break;
								}
							}
							note.colorSwap.r = col[0];
							note.colorSwap.g = col[1];
							note.colorSwap.b = col[2];
						}
					}
				}
				if (Options.getData('colorQuantization')) {
					for (note in unspawnNotes) {
						if (note.affectedbycolor) {
							var quantStrumTime = note.isSustainNote ? note.prevNote.prevNoteStrumtime : note.strumTime;
							var currentStepCrochet = Conductor.stepCrochet;
							var noteBeat = Math.floor(((quantStrumTime / (currentStepCrochet * 4)) * 48) + 0.5);
							var col:Array<Int> = [142, 142, 142];
							for (beat in 0...note.beats.length - 1) {
								if ((noteBeat % (192 / note.beats[beat]) == 0)) {
									noteBeat = note.beats[beat];
									col = note.quantColors[beat];
									break;
								}
							}
							note.colorSwap.r = col[0];
							note.colorSwap.g = col[1];
							note.colorSwap.b = col[2];
						}
					}
				}
			case "change ui skin":
				var noteskin:String = Std.string(event[2]);
				SONG.ui_Skin = noteskin;
				ui_settings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/config"));
				mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniasize"));
				mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniaoffset"));

				// if the file exists, use it dammit
				if (Assets.exists(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniagap")))
					mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniagap"));
				else
					mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

				types = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/types"));

				arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/default")));
				type_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("arrow types/default")));

				// reload ratings
				uiMap.set("marvelous", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/marvelous")));
				uiMap.set("sick", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/sick")));
				uiMap.set("good", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/good")));
				uiMap.set("bad", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/bad")));
				uiMap.set("shit", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/shit")));

				// preload numbers
				for (i in 0...10)
					uiMap.set(Std.string(i), FlxGraphic.fromAssetKey(Paths.image("ui skins/" + SONG.ui_Skin + "/numbers/num" + Std.string(i))));
				var healthBarPosY = FlxG.height * 0.9;

				if (Options.getData("downscroll"))
					healthBarPosY = 60;
				if (funnyTimeBarStyle.toLowerCase() == 'leather engine') {
					healthBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('ui skins/' + SONG.ui_Skin + '/other/healthBar'));
				}
				if (funnyTimeBarStyle.toLowerCase() != ' engine')
					timeBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('ui skins/' + SONG.ui_Skin + '/other/healthBar'));

				playerStrums.clear();
				enemyStrums.clear();
				strumLineNotes.clear();
				splash_group.clear();
				if (Options.getData("middlescroll")) {
					generateStaticArrows(50, false, false);
					generateStaticArrows(0.5, true, false);
				} else {
					if (characterPlayingAs == 0) {
						generateStaticArrows(0, false, false);
						generateStaticArrows(1, true, false);
					} else {
						generateStaticArrows(1, false, false);
						generateStaticArrows(0, true, false);
					}
				}
		}

		//                name       pos      param 1   param 2
		call("onEvent", [event[0], event[1], event[2], event[3]]);
	}

	public function calculateAccuracy() {
		if (totalNotes != 0 && !switchedStates)
			accuracy = FlxMath.roundDecimal(100.0 / (totalNotes / hitNotes), 2);

		#if LUA_ALLOWED
		setLuaVar("accuracy", accuracy);
		#end

		updateRating();
		updateScoreText();
	}

	public inline function updateRating()
		ratingStr = Ratings.getRank(accuracy, misses);

	function generareNoteChangeEvents():Void {
		baseEvents = [];
		events = [];

		if (SONG.events.length > 0) {
			for (event in SONG.events) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		if (Assets.exists(Paths.songEvents(SONG.song.toLowerCase(), storyDifficultyStr.toLowerCase())) && loadChartEvents) {
			var eventFunnies:Array<Array<Dynamic>> = Song.parseJSONshit(Assets.getText(Paths.songEvents(SONG.song.toLowerCase(),
				storyDifficultyStr.toLowerCase())))
				.events;

			for (event in eventFunnies) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		for (event in events) {
			var map:Map<String, Dynamic>;

			// cache shit
			if (event[0].toLowerCase() == "change keycount" || event[0].toLowerCase() == "change mania") {
				maniaChanges.push([event[1], Std.parseInt(event[2]), Std.parseInt(event[3])]); // track strumtime, p1 keycount, p2 keycount
			}
		}

		events.sort((a, b) -> Std.int(a[1] - b[1]));
	}

	function generateEvents():Void {
		baseEvents = [];
		events = [];

		if (SONG.events.length > 0) {
			for (event in SONG.events) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		if (Assets.exists(Paths.songEvents(SONG.song.toLowerCase(), storyDifficultyStr.toLowerCase())) && loadChartEvents) {
			var eventFunnies:Array<Array<Dynamic>> = Song.parseJSONshit(Assets.getText(Paths.songEvents(SONG.song.toLowerCase(),
				storyDifficultyStr.toLowerCase())))
				.events;

			for (event in eventFunnies) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		for (event in events) {
			var map:Map<String, Dynamic>;

			switch (event[2].toLowerCase()) {
				case "dad" | "opponent" | "player2" | "1":
					map = dadMap;
				case "gf" | "girlfriend" | "player3" | "2":
					map = gfMap;
				default:
					map = bfMap;
			}

			// cache shit
			if (Options.getData("charsAndBGs")) {
				if (event[0].toLowerCase() == "change character" && event[1] <= FlxG.sound.music.length && !map.exists(event[3])) {
					#if sys
					var tmr:Float = Sys.time();
					#end
					var funnyCharacter:Character;
					trace('Caching ${event[3]}');

					if (map == bfMap)
						funnyCharacter = new Boyfriend(100, 100, event[3]);
					else
						funnyCharacter = new Character(100, 100, event[3]);

					funnyCharacter.alpha = 0.00001;
					add(funnyCharacter);

					map.set(event[3], funnyCharacter);

					if (funnyCharacter.otherCharacters != null) {
						for (character in funnyCharacter.otherCharacters) {
							character.alpha = 0.00001;
							add(character);
						}
					}

					#if sys
					trace('Cached ${event[3]} in ${FlxMath.roundDecimal(Sys.time() - tmr, 2)} seconds');
					#end
				}

				if (event[0].toLowerCase() == "change stage"
					&& event[1] <= FlxG.sound.music.length
					&& !stageMap.exists(event[2])
					&& Options.getData("preloadChangeBGs")) {
					var funnyStage = new StageGroup(event[2]);
					funnyStage.visible = false;

					stageMap.set(event[2], funnyStage);

					trace(funnyStage.stage);
				}
			}

			#if LUA_ALLOWED
			if (!event_luas.exists(event[0].toLowerCase()) && Assets.exists(Paths.lua("event data/" + event[0].toLowerCase()))) {
				event_luas.set(event[0].toLowerCase(), new ModchartUtilities(PolymodAssets.getPath(Paths.lua("event data/" + event[0].toLowerCase()))));
				generatedSomeDumbEventLuas = true;
			}
			#end

			if (!hscriptEvents.exists(event[0].toLowerCase()) && Assets.exists(Paths.hx("data/event data/" + event[0].toLowerCase()))) {
				hscriptEvents.set(event[0].toLowerCase(), new HScript(Paths.hx("data/event data/" + event[0].toLowerCase())));
			}
		}

		events.sort((a, b) -> Std.int(a[1] - b[1]));
	}

	public function setupNoteTypeScript(noteType:String) {
		#if LUA_ALLOWED
		if (!event_luas.exists(noteType.toLowerCase()) && Assets.exists(Paths.lua("arrow types/" + noteType))) {
			event_luas.set(noteType.toLowerCase(), new ModchartUtilities(PolymodAssets.getPath(Paths.lua("arrow types/" + noteType))));
			generatedSomeDumbEventLuas = true;
		}
		#end
		if (Assets.exists(Paths.hx("data/arrow types/" + noteType))) {
			var script = new HScript(Paths.hx("data/arrow types/" + noteType));
			script.start();
			scripts.push(script);
		}
	}

	function getCorrectKeyCount(player:Bool) {
		var kc = SONG.keyCount;
		if ((player && characterPlayingAs == 0) || (characterPlayingAs == 1 && !player)) {
			kc = SONG.playerKeyCount;
		}
		return kc;
	}

	function getSingLuaFuncName(player:Bool) {
		var name = "playerTwo";
		if ((player && characterPlayingAs == 0) || (characterPlayingAs == 1 && !player)) {
			name = "playerOne";
		}
		return name;
	}

	public function addBehind(behind:FlxBasic, obj:FlxBasic) {
		insert(members.indexOf(obj), behind);
	}

	public function addBehindGF(behind:FlxBasic) {
		insert(members.indexOf(gf), behind);
	}

	public function addBehindDad(behind:FlxBasic) {
		insert(members.indexOf(dad), behind);
	}

	public function addBehindBF(behind:FlxBasic) {
		insert(members.indexOf(boyfriend), behind);
	}
}

enum Execute_On {
	BOTH;
	MODCHART;
	STAGE;
}
