package states;

import game.CharacterPlayingAs;
import modding.helpers.FlxTweenUtil;
import haxe.Json;
import substates.ResultsSubstate;
import substates.ResultsSubstate.SaveScoreData;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxInput.FlxInputState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxGraphicAsset;
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
import game.SongLoader.Section as SwagSection;
import game.SongLoader;
import game.SoundGroup;
import game.StageGroup;
import game.StrumNote;
import game.TimeBar;
import lime.utils.Assets;
import modding.*;
import modding.scripts.*;
import modding.scripts.languages.*;
import substates.GameOverSubstate;
import substates.PauseSubState;
import toolbox.ChartingState;
import ui.DialogueBox;
import ui.HealthIcon;
import utilities.NoteVariables;
import utilities.Ratings;
import game.EventHandeler;
import sys.FileSystem;

using StringTools;

#if DISCORD_ALLOWED
import utilities.DiscordClient;
#end
#if MODDING_ALLOWED
import polymod.backends.PolymodAssets;
#end
#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideo;
#end
#if MODCHARTING_TOOLS
import modcharting.NoteMovement;
import modcharting.PlayfieldRenderer;
#end

/**
	The main gameplay state.
**/
@:publicFields
class PlayState extends MusicBeatState {
	/**
		Current instance of `PlayState`.
	**/
	static var instance:PlayState = null;

	/**
		The current stage in `PlayState`.
	**/
	static var curStage:String = '';

	/**
		Current song data in `PlayState`.
	**/
	static var SONG:SongData;

	/**
		`Bool` for whether we are currently in Story Mode.
	**/
	static var isStoryMode:Bool = false;

	/**
		Current Story Mode week as an `Int`.

		(Generally unused / deprecated).
	**/
	static var storyWeek:Int = 0;

	/**
		`Array` of all the songs that you are going
		to play next in Story Mode as `String`.
	**/
	static var storyPlaylist:Array<String> = [];

	/**
		`String` representation of the current Story Mode difficulty.
	**/
	static var storyDifficultyStr:String = "NORMAL";

	/**
		Total score over your current run in Story Mode.
	**/
	static var campaignScore:Int = 0;

	/**
		Title of current week in Story Mode.
	**/
	static var campaignTitle:String;

	/**
		Vocal tracks for the current song as a `SoundGroup`.
	**/
	var vocals:SoundGroup = new SoundGroup(2);

	/**
		Your current opponent.
	**/
	static var dad:Character;

	/**
		The current character in the middle of the 3 main characters.
	**/
	static var gf:Character;

	/**
		The current player character.
	**/
	static var boyfriend:Boyfriend;

	/**
		The current stage.
	**/
	var stage:StageGroup;

	/**
		`FlxTypedGroup` of all currently active notes in the game.
	**/
	var notes:FlxTypedGroup<Note>;

	/**
		`Array` of all the notes waiting to be spawned into the game (when their time comes to prevent lag).
	**/
	var unspawnNotes:Array<Note> = [];

	/**
		Simple `FlxSprite` to help represent the strum line the strums initially spawn at.
	**/
	var strumLine:FlxSprite;

	/**
		`FlxTypedGroup` of all current strums (enemy strums are first).
	**/
	static var strumLineNotes:FlxTypedGroup<StrumNote>;

	/**
		`FlxTypedGroup` of all current player strums.
	**/
	static var playerStrums:FlxTypedGroup<StrumNote>;

	/**
		`FlxTypedGroup` of all current enemy strums.
	**/
	static var enemyStrums:FlxTypedGroup<StrumNote>;

	/**
		Simple `FlxObject` to store the camera's current position that it's following.
	**/
	var camFollow:FlxObject;

	/**
	 * Should the camera be centered?
	 */
	var centerCamera:Bool = false;

	/**
	 * Should the camera be locked?
	 */
	var lockedCamera:Bool = false;

	/**
		Copy of `camFollow` used for transitioning between songs smoother.
	**/
	static var prevCamFollow:FlxObject;

	/**
		`Bool` for whether or not the camera is currently zooming in and out to the song's beat.
	**/
	var camZooming:Bool = false;

	/**
	 * `Bool` for if the camera is allowed to zoom in.
	 */
	var cameraZooms:Bool = Options.getData("cameraZooms");

	/**
		Speed of camera.
	**/
	var cameraSpeed:Float = 1;

	/**
		Speed of camera zooming.
	**/
	var cameraZoomSpeed:Float = 1;

	/**
	 * Multiplier for strength of camera bops.
	 */
	var cameraZoomStrength:Float = 1;

	/**
	 * Multiplier for speed of camera bops.
	 */
	var cameraZoomRate:Float = 1;

	/**
		Shortner for `SONG.song`.
	**/
	var curSong:String = "";

	/**
		The interval of beats the current `gf` waits till their `dance` function gets called. (as an `Int`)

		Example:
			1 = Every Beat,
			2 = Every Other Beat,
			etc.
	**/
	var gfSpeed:Int = 1;

	/**
		Current `health` of the player (stored as a range from `minHealth` to `maxHealth`, which is by default 0 to 2).
	**/
	var health:Float = 1;

	/**
		Current `health` being shown on the `healthBar`. (Is inverted from normal when playing as opponent)
	**/
	var healthShown:Float = 1;

	/**
		Minimum `health` value. (Defaults to 0)
	**/
	var minHealth:Float = 0;

	/**
		Maximum `health` value. (Defaults to 2)
	**/
	var maxHealth:Float = 2;

	/**
	 * Is the player dead?
	 */
	var dead(get, default):Bool = false;

	/**
		Current combo (or amount of notes hit in a row without a combo break).
	**/
	var combo:Int = 0;

	/**
		Current combo (or amount of notes hit in a row without a combo break).
	**/
	var maxCombo:Int = 0;

	/**
		Current score for the player.
	**/
	var songScore:Int = 0;

	/**
		Current miss count for the player.
	**/
	var misses:Int = 0;

	/**
		Current accuracy for the player (0 - 100).
	**/
	var accuracy:Float = 100.0;

	/**
		Background sprite for the health bar.
	**/
	var healthBarBG:FlxSprite;

	/**
		The health bar.
	**/
	var healthBar:FlxBar;

	/**
		The progress bar.
	**/
	var timeBar:TimeBar;

	/**
		Current time bar style selected by the player.
	**/
	var timeBarStyle(default, null):String = Options.getData("timeBarStyle");

	@:deprecated("infoTxt is deprecated, use timeBar.txt instead")
	var infoTxt(get, set):FlxText;

	@:deprecated("timeBarBG is deprecated, use timeBar.bg instead")
	var timeBarBG(get, set):FlxSprite;

	/**
		Variable for if `generateSong` has been called successfully yet.
	**/
	var generatedMusic:Bool = false;

	/**
		Whether or not the player has started the song yet.
	**/
	var startingSong:Bool = false;

	/**
		The icon for the player character (`bf`).
	**/
	var iconP1:HealthIcon;

	/**
		The icon for the opponent character (`dad`).
	**/
	var iconP2:HealthIcon;

	/**
		`FlxCamera` for all HUD/UI elements.
	**/
	var camHUD:FlxCamera;

	/**
		`FlxCamera` for all elements part of the main scene.
	**/
	var camGame:FlxCamera;

	/**
		Current text under the health bar (displays score and other stats).
	**/
	var scoreTxt:FlxText;

	/**
		Total notes interacted with. (Includes missing and hitting)
	**/
	var totalNotes:Int = 0;

	/**
		Total notes hit (is a `Float` because it's used for accuracy calculations).
	**/
	var hitNotes:Float = 0.0;

	/**
		`FlxGroup` for all the sprites that should go above the characters in a stage.
	**/
	var foregroundSprites:FlxGroup = new FlxGroup();

	/**
		The default camera zoom (used for camera zooming properly).
	**/
	var defaultCamZoom:Float = 1.05;

	/**
		The default hud camera zoom (used for zoom the hud properly).
	**/
	var defaultHudCamZoom:Float = 1.0;

	/**
		Current alt animation for any characters that may be using it (should just be `dad`).
	**/
	var altAnim:String = "";

	/**
		Whether or not you are currently in a cutscene.
	**/
	var inCutscene:Bool = false;

	/**
		Current group of weeks you are playing from.
	**/
	static var groupWeek:String = "";

	/**
		Small Icon to use in RPC.
	**/
	var iconRPC:String = "";

	/**
		Details to use in RPC.
	**/
	var detailsText:String = "Freeplay";

	/**
		Paused Details to use in RPC.
	**/
	var detailsPausedText:String = "";

	/**
		Length of the current song's instrumental track in milliseconds.
	**/
	var songLength:Float = 0;

	/**
		Your current key bindings stored as `Strings`.
	**/
	var binds:Array<String>;

	// wack ass ui shit i need to fucking change like oh god i hate this shit mate
	var ui_settings:Array<String> = [];
	var mania_size:Array<String> = [];
	var mania_offset:Array<String> = [];
	var mania_gap:Array<String> = [];
	var types:Array<String> = [];

	// this sucks too, sorry i'm not documentating this bullshit that ima replace at some point with nice clean yummy jsons
	// - leather128
	var arrow_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();
	var type_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();

	/**
		`Array` of cached miss sounds.
	**/
	var missSounds:Array<FlxSound> = [];

	/**
		Current song multiplier. (Should be minimum 0.25)
	**/
	static var songMultiplier:Float = 1;

	/**
		Variable that stores the original scroll speed before being divided by `songMultiplier`.

		Usage: ChartingState
	**/
	static var previousScrollSpeed:Float = 0;

	/**
		Current `Cutscene` data.
	**/
	var cutscene:Cutscene;

	/**
		Current time of the song in milliseconds used for the progress bar.
	**/
	var time:Float = 0.0;

	/**
		A `Map` of the `String` names of the ratings to the amount of times you got them.
	**/
	var ratings:Map<String, Int> = ["marvelous" => 0, "sick" => 0, "good" => 0, "bad" => 0, "shit" => 0];

	/**
		Current text that displays your ratings (plus misses and MA/PA).
	**/
	var ratingText:FlxText;

	/**
		Variable used by Lua Modcharts to stop the song midway.
	**/
	var stopSong:Bool = false;

	/**
		`Array` of current events used by the song.
	**/
	var events:Array<Array<Dynamic>> = [];

	/**
		Original `Array` of the current song's events.
	**/
	var baseEvents:Array<Array<Dynamic>> = [];

	/**
	 * Used lua cameras?
	 */
	var usedLuaCameras:Bool = false;

	/**
	 * Is the player charting?
	 */
	static var chartingMode:Bool = false;

	/**
		Current character you are playing as stored as an `Int`.

		Values:

		0 = bf

		1 = opponent

		-1 = both
	**/
	static var characterPlayingAs:CharacterPlayingAs = BF;

	/**
		The current hitsound the player is using. (By default is 'none')
	**/
	var hitSoundString:String = Options.getData("hitsound");

	/**
		`Map` of `String` to `Boyfriend` for changing `bf`'s character.
	**/
	var bfMap:Map<String, Boyfriend> = [];

	/**
		`Map` of `String` to `Character` for changing `gf`'s character.
	**/
	var gfMap:Map<String, Character> = [];

	/**
		`Map` of `String` to `Character` for changing `dad`'s character.
	**/
	var dadMap:Map<String, Character> = [];

	/**
		`Map` of `String` to `StageGroup` for changing the `stage`.
	**/
	var stageMap:Map<String, StageGroup> = [];

	/**
		Whether the game will or will not load events from the chart's `events.json` file.
		(Disabled while charting as the events are already loaded)
	**/
	static var loadChartEvents:Bool = true;

	/**
		Keeps track of the original player key count.

		(Used when playing as opponent).
	**/
	var ogPlayerKeyCount:Int = 4;

	/**
		Keeps track of the original opponent (or both if not specified for player) key count.

		(Used when playing as opponent).
	**/
	var ogKeyCount:Int = 4;

	/**
		`Map` of `String` to `LuaScript` used for custom events.
	**/
	var scripts:Map<String, Script> = [];

	/**
		`FlxTypedGroup` of `NoteSplash`s used to contain all note splashes
		and make performance better as a result by using `.recycle`.
	**/
	var splash_group:FlxTypedSpriteGroup<NoteSplash> = new FlxTypedSpriteGroup<NoteSplash>();

	/**
	 * Should the player spawn a notesplash on a sick or marvelous rating?
	 */
	var playerNoteSplashes:Bool = Options.getData("playerNoteSplashes");

	/**
	 * Should the opponent spawn a notesplash on a sick or marvelous rating?
	 */
	var opponentNoteSplashes:Bool = Options.getData("opponentNoteSplashes");

	var enemyStrumsGlow:Bool = Options.getData("enemyStrumsGlow");

	var ratingsGroup:FlxSpriteGroup = new FlxSpriteGroup();

	var marvelousRatings:Bool = Options.getData("marvelousRatings");

	static var playCutscenes:Bool = false;

	/**
	 * Manages tweens in lua scripts to pause when game is
	 */
	var tweenManager:FlxTweenManager;

	override function create() {
		// set instance because duh
		instance = this;
		tweenManager = new FlxTweenManager();

		FlxG.mouse.visible = false;

		// preload pause music
		new FlxSound().loadEmbedded(Paths.music('breakfast'));

		if (SONG == null) // this should never happen, but just in case
			SONG = SongLoader.loadFromJson('normal', 'tutorial');

		// gaming time
		curSong = SONG.song;

		// if we have a hitsound, preload it nerd
		if (hitSoundString != "none")
			hitsound = FlxG.sound.load(Paths.sound("hitsounds/" + hitSoundString.toLowerCase()));

		// set the character we playing as
		switch (Options.getData("playAs").toLowerCase()) {
			case "opponent":
				characterPlayingAs = OPPONENT;
			case "both":
				characterPlayingAs = BOTH;
			default:
				characterPlayingAs = BF;
		}

		// key count flipping
		ogPlayerKeyCount = SONG.playerKeyCount;
		ogKeyCount = SONG.keyCount;

		if (characterPlayingAs == OPPONENT) {
			var oldRegKeyCount = SONG.playerKeyCount;
			var oldPlrKeyCount = SONG.keyCount;

			SONG.playerKeyCount = oldPlrKeyCount;
			SONG.keyCount = oldRegKeyCount;
		}

		// check for invalid settings
		if (Options.getData("botplay") || Options.getData("noDeath") || characterPlayingAs != BF || PlayState.chartingMode) {
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

		previousScrollSpeed = SONG.speed;

		SONG.speed /= songMultiplier;

		// just in case haxe does something weird af
		if (SONG.speed < 0)
			SONG.speed = 0;

		speed = SONG.speed;

		Conductor.recalculateStuff(songMultiplier);
		Conductor.safeZoneOffset *= songMultiplier; // makes the game more fair

		// not sure why this is here and not later but sure
		noteBG = new FlxSprite(0, 0);
		noteBG.cameras = [camHUD];
		noteBG.makeGraphic(1, 1000, FlxColor.BLACK);
		add(noteBG);

		if (SONG.stage == null) {
			SONG.stage = 'stage';
		}

		// null ui skin
		if (SONG.ui_Skin == null)
			SONG.ui_Skin = "default";

		// yo poggars
		if (SONG.ui_Skin == "default")
			SONG.ui_Skin = Options.getData("uiSkin");

		// bull shit

		var uiSkinConfigPath:String = Assets.exists('assets/data/ui skins/${SONG.ui_Skin}') ? 'ui skins/${SONG.ui_Skin}' : 'ui skins/default';

		// who in the fuck thought this system was a good idea?
		ui_settings = CoolUtil.coolTextFile(Paths.txt('$uiSkinConfigPath/config'));
		mania_size = CoolUtil.coolTextFile(Paths.txt('$uiSkinConfigPath/maniasize'));
		mania_offset = CoolUtil.coolTextFile(Paths.txt('$uiSkinConfigPath/maniaoffset'));

		mania_gap = CoolUtil.coolTextFile(Paths.txt('$uiSkinConfigPath/maniagap'));

		types = CoolUtil.coolTextFile(Paths.txt('$uiSkinConfigPath/types'));

		arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt('$uiSkinConfigPath/default')));
		type_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("arrow types/default")));

		var uiSkinImagePath:String = Assets.exists('assets/shared/images/ui skins/${SONG.ui_Skin}') ? 'ui skins/${SONG.ui_Skin}' : 'ui skins/default';

		// preload ratings
		for (rating in ['marvelous', 'sick', 'good', 'bad', 'shit']) {
			uiMap.set(rating, Paths.gpuBitmap('$uiSkinImagePath/ratings/$rating'));
		}
		// preload numbers
		for (i in 0...10)
			uiMap.set('$i', Paths.gpuBitmap('$uiSkinImagePath/numbers/num$i'));

		curStage = SONG.stage;

		// set gf lol
		if (SONG.gf == null) {
			SONG.gf = 'gf';
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
		iconRPC = dad.icon;

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode";

		detailsPausedText = 'Paused - $detailsText';

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC);
		#end

		strumLine = new FlxSprite(0, 100).makeGraphic(FlxG.width, 10);

		if (Options.getData("downscroll"))
			strumLine.y = FlxG.height - 100;

		// stage maker
		stage = new StageGroup(Options.getData("charsAndBGs") ? curStage : "");
		stageMap.set(stage.stage, stage);
		if (stage.stageScript != null) {
			stage.stageScript.executeOn = STAGE;
			scripts.set(stage.stage, stage.stageScript);
		}
		add(stage);
		call("createStage", [stage.stage]);

		defaultCamZoom = stage.camZoom;
		camGame.bgColor = FlxColor.fromString(stage.stageData.backgroundColor ?? "#000000");

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
		var midPos:FlxPoint = dad.getMidpoint();

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

		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<StrumNote>();

		playerStrums = new FlxTypedGroup<StrumNote>();
		enemyStrums = new FlxTypedGroup<StrumNote>();

		#if (MODCHARTING_TOOLS)
		if (SONG.modchartingTools
			|| Assets.exists(Paths.json("song data/" + SONG.song.toLowerCase() + "/modchart"))
			|| Assets.exists(Paths.json("song data/" + SONG.song.toLowerCase() + "/modchart-" + storyDifficultyStr.toLowerCase()))) {
			SONG.modchartingTools = true;
		}
		#end

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

		var healthBarPosY:Float = FlxG.height * 0.9;

		if (Options.getData("downscroll"))
			healthBarPosY = 60;

		// Handels the loading of all scripts
		var foldersToCheck:Array<String> = [
			'assets/data/scripts/global/',
			'assets/data/scripts/local/',
			'assets/data/song data/${curSong.toLowerCase()}/',
			#if MODDING_ALLOWED
			'mods/${Options.getData("curMod")}/data/scripts/local/', 'mods/${Options.getData("curMod")}/data/song data/${curSong.toLowerCase()}/',
			#end
		];

		#if MODDING_ALLOWED
		for (mod in ModList.getActiveMods(PolymodHandler.metadataArrays)) {
			if (FileSystem.exists('mods/$mod/data/scripts/global/')) {
				foldersToCheck.push('mods/$mod/data/scripts/global/');
			}
		}
		#end

		for (folder in foldersToCheck) {
			if (FileSystem.exists(folder)) {
				for (file in FileSystem.readDirectory(folder)) {
					#if HSCRIPT_ALLOWED
					if (file.endsWith('.hx')) {
						scripts.set('$folder/$file.hx', new HScript('$folder$file'));
					}
					#end
					#if LUA_ALLOWED
					if (file.endsWith('.lua')) {
						scripts.set('$folder$file.lua', new LuaScript('$folder$file'));
					}
					#end
				}
			}
		}

		// TODO: Deprecate and convert this to new script system on script load.
		#if LUA_ALLOWED
		if (Assets.exists(Paths.lua("modcharts/" + PlayState.SONG.modchartPath))) {
			trace("The 'modcharts' folder is deprecated! Use the 'scripts' folder instead!", WARNING);
			scripts.set(PlayState.SONG.modchartPath, new LuaScript(Paths.getModPath(Paths.lua("modcharts/" + PlayState.SONG.modchartPath))));
		} else if (Assets.exists(Paths.lua("scripts/" + PlayState.SONG.modchartPath))) {
			scripts.set(PlayState.SONG.modchartPath, new LuaScript(Paths.getModPath(Paths.lua("scripts/" + PlayState.SONG.modchartPath))));
		}

		call("create", [PlayState.SONG.song.toLowerCase()], MODCHART);
		call("create", [stage.stage], STAGE);
		#end

		ratingsGroup.cameras = [camHUD];
		add(ratingsGroup);
		add(strumLineNotes);

		var cache_splash:NoteSplash = new NoteSplash();
		cache_splash.kill();

		splash_group.add(cache_splash);

		#if (MODCHARTING_TOOLS)
		NoteMovement.keyCount = SONG.keyCount;
		NoteMovement.playerKeyCount = SONG.playerKeyCount;
		NoteMovement.totalKeyCount = SONG.keyCount + SONG.playerKeyCount;
		if (SONG.modchartingTools
			|| Assets.exists(Paths.json("song data/" + SONG.song.toLowerCase() + "/modchart"))
			|| Assets.exists(Paths.json("song data/" + SONG.song.toLowerCase() + "/modchart-" + storyDifficultyStr.toLowerCase()))) {
			SONG.modchartingTools = true;
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
		var healthBarPath:String = Assets.exists(Paths.image('ui skins/${SONG.ui_Skin}/other/healthBar')) ? 'ui skins/${SONG.ui_Skin}/other/healthBar' : 'ui skins/default/other/healthBar';
		healthBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.gpuBitmap(healthBarPath));
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
		scoreTxt = new FlxText(0, healthBarBG.y + 45, 0, "", 20);
		scoreTxt.screenCenter(X);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), Options.getData("biggerScoreInfo") ? 20 : 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE_FAST,
			FlxColor.BLACK);
		scoreTxt.scrollFactor.set();

		// settings again
		if (Options.getData("biggerScoreInfo"))
			scoreTxt.borderSize = 1.25;

		add(scoreTxt);

		timeBar = new TimeBar(SONG, storyDifficultyStr);
		timeBar.cameras = [camHUD];
		timeBar.bar.color = dad.barColor;
		add(timeBar);

		if (Options.getData("sideRatings")) {
			ratingText = new FlxText(4, 0, 0, "bruh");
			ratingText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			ratingText.screenCenter(Y);
			ratingText.x += Options.getData("ratingTextOffset")[0];
			ratingText.y += Options.getData("ratingTextOffset")[1];
			ratingText.alignment = Options.getData("ratingTextAlign");
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
					#if HSCRIPT_ALLOWED
					var cutsceneScript:HScript = new HScript(Paths.hx('data/${cutscene.scriptPath}'));

					for (object in stage.stageObjects) {
						cutsceneScript.interp.variables.set(object[0], object[1]);
					}
					scripts.set(cutscene.scriptPath, cutsceneScript);
					cutsceneScript.call("startCutscene");
					#else
					throw "HScript is not enabled!";
					#end
				case "video":
					startVideo(cutscene.videoPath, cutscene.videoExt, false);

				case "dialogue":
					var box:DialogueBox = new DialogueBox(cutscene);
					box.scrollFactor.set();
					box.onDialogueFinish.add(() -> bruhDialogue(false));
					box.cameras = [camHUD];
					box.zIndex = FlxMath.MAX_VALUE_INT;
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

		Note.applyColorQuants(unspawnNotes);

		super.create();

		call("createPost", []);

		for (script in scripts) {
			script.createPost = true;
		}

		calculateAccuracy();
		updateSongInfoText();
	}

	function reorderCameras(?newCam:FlxCamera = null) {
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

	static var playCutsceneLmao:Bool = false;
	static var playCutsceneOnPauseLmao:Bool = false;

	function startDialogue(?dialogueBox:DialogueBox, ?endSongVar:Bool = false):Void {
		if (endSongVar) {
			paused = true;
			canPause = false;
			switchedStates = true;
			endingSong = true;
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer):Void {
			if (dialogueBox != null)
				add(dialogueBox);
			else {
				if (cutscene.cutsceneAfter == null) {
					if (!endSongVar)
						startCountdown();
					else
						moveToResultsScreen();
				} else {
					var oldcutscene = cutscene;

					cutscene = CutsceneUtil.loadFromJson(oldcutscene.cutsceneAfter);

					switch (cutscene.type.toLowerCase()) {
						case "script":
							#if HSCRIPT_ALLOWED
							var cutsceneScript:HScript = new HScript(Paths.hx('data/${cutscene.scriptPath}'));
							for (object in stage.stageObjects) {
								cutsceneScript.interp.variables.set(object[0], object[1]);
							}
							scripts.set(cutscene.scriptPath, cutsceneScript);
							cutsceneScript.call("startCutscene");
							#else
							throw "HScript is not enabled!";
							#end
						case "video":
							startVideo(cutscene.videoPath, cutscene.videoExt, endSongVar);

						case "dialogue":
							var box:DialogueBox = new DialogueBox(cutscene);
							box.scrollFactor.set();
							box.onDialogueFinish.add(() -> bruhDialogue(endSongVar));
							box.cameras = [camHUD];
							box.zIndex = FlxMath.MAX_VALUE_INT;
							startDialogue(box, endSongVar);

						default:
							if (!endSongVar)
								startCountdown();
							else
								moveToResultsScreen();
					}
				}
			}
		});
	}

	#if VIDEOS_ALLOWED
	var videoHandler:FlxVideo = new FlxVideo();
	#end

	function startVideo(name:String, ?ext:String, ?endSongVar:Bool = false):Void {
		inCutscene = true;

		if (endSongVar) {
			paused = true;
			canPause = false;
			switchedStates = true;
			endingSong = true;
		}

		#if VIDEOS_ALLOWED
		if (videoHandler.load(Paths.getModPath(Paths.video(name, ext))))
			FlxTimer.wait(0.001, () -> videoHandler.play());
		videoHandler.onEndReached.add(function() {
			videoHandler.dispose();
			FlxG.removeChild(videoHandler);
			bruhDialogue(endSongVar);
		}, true);
		FlxG.addChildBelowMouse(videoHandler);
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
				moveToResultsScreen();
		} else {
			var oldcutscene = cutscene;

			cutscene = CutsceneUtil.loadFromJson(oldcutscene.cutsceneAfter);

			switch (cutscene.type.toLowerCase()) {
				case "script":
					#if HSCRIPT_ALLOWED
					var cutsceneScript:HScript = new HScript(Paths.hx('data/${cutscene.scriptPath}'));
					for (object in stage.stageObjects) {
						cutsceneScript.interp.variables.set(object[0], object[1]);
					}
					scripts.set(cutscene.scriptPath, cutsceneScript);
					cutsceneScript.call("startCutscene");
					#else
					throw "HScript is not enabled!";
					#end
				case "video":
					startVideo(cutscene.videoPath, cutscene.videoExt, endSongVar);

				case "dialogue":
					var box:DialogueBox = new DialogueBox(cutscene);
					box.scrollFactor.set();
					box.onDialogueFinish.add(() -> bruhDialogue(endSongVar));
					box.cameras = [camHUD];
					box.zIndex = FlxMath.MAX_VALUE_INT;
					startDialogue(box, endSongVar);

				default:
					if (!endSongVar)
						startCountdown();
					else
						moveToResultsScreen();
			}
		}
	}

	var startTimer:FlxTimer = new FlxTimer();

	static var startOnTime:Float = 0;

	function startCountdown():Void {
		if (curStep < -20) {
			curStep = -20;
		}

		inCutscene = false;
		paused = false;
		canPause = true;

		if (Options.getData("middlescroll")) {
			generateStaticArrows(50, false);
			generateStaticArrows(0.5, true);
		} else {
			if (characterPlayingAs == BF) {
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
			resyncVocals();
			return;
		}

		#if LUA_ALLOWED
		for (script in scripts) {
			if (script is LuaScript) {
				script?.setup();
			}
		}

		for (i in 0...strumLineNotes.length) {
			var member = strumLineNotes.members[i];

			set("defaultStrum" + i + "X", member.x);
			set("defaultStrum" + i + "Y", member.y);
			set("defaultStrum" + i + "Angle", member.angle);

			set("defaultStrum" + i, {
				x: member.x,
				y: member.y,
				angle: member.angle,
			});

			if (enemyStrums.members.contains(member)) {
				set("enemyStrum" + i % SONG.keyCount, {
					x: member.x,
					y: member.y,
					angle: member.angle,
				});
			} else {
				set("playerStrum" + i % SONG.playerKeyCount, {
					x: member.x,
					y: member.y,
					angle: member.angle,
				});
			}
		}

		call("start", [SONG.song.toLowerCase()], BOTH);
		#end

		startTimer.start(Conductor.crochet / 1000, (tmr:FlxTimer) -> {
			call("countdownTick", [swagCounter]);
			if (dad.otherCharacters == null) {
				dad.dance();
			} else {
				for (character in dad.otherCharacters) {
					character.dance(altAnim);
				}
			}
			if (gf.otherCharacters == null) {
				gf.dance();
			} else {
				for (character in gf.otherCharacters) {
					character.dance();
				}
			}
			if (boyfriend.otherCharacters == null) {
				boyfriend.dance();
			} else {
				for (character in boyfriend.otherCharacters) {
					character.dance();
				}
			}
			var introPath:String = Assets.exists('assets/shared/images/ui skins/${SONG.ui_Skin}/countdown') ? 'ui skins/${SONG.ui_Skin}/countdown' : 'ui skins/default/countdown';

			var altSuffix:String = SONG.ui_Skin == 'pixel' ? "-pixel" : "";

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.gpuBitmap('$introPath/ready'));
					ready.scrollFactor.set();
					ready.updateHitbox();
					ready.antialiasing = ui_settings[3] == "true" && Options.getData("antialiasing");

					ready.setGraphicSize(ready.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[7]));
					ready.updateHitbox();

					ready.screenCenter();
					ready.zIndex = FlxMath.MAX_VALUE_INT;
					add(ready);

					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) ready.destroy()
					});

					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.gpuBitmap('$introPath/set'));
					set.scrollFactor.set();
					set.updateHitbox();
					set.antialiasing = ui_settings[3] == "true" && Options.getData("antialiasing");

					set.setGraphicSize(set.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[7]));
					set.updateHitbox();

					set.screenCenter();
					set.zIndex = FlxMath.MAX_VALUE_INT;
					add(set);

					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) set.destroy()
					});

					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.gpuBitmap('$introPath/go'));
					go.scrollFactor.set();
					go.updateHitbox();
					go.antialiasing = ui_settings[3] == "true" && Options.getData("antialiasing");

					go.setGraphicSize(go.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[7]));
					go.updateHitbox();

					go.screenCenter();
					go.zIndex = FlxMath.MAX_VALUE_INT;
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

	var invincible:Bool = false;

	function clearNotesBefore(time:Float) {
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var note:Note = unspawnNotes[i];
			if (note.strumTime - 350 < time) {
				note.active = false;
				note.visible = false;

				note.kill();
				unspawnNotes.remove(note);
				note.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var note:Note = notes.members[i];
			if (note.strumTime - 350 < time) {
				note.active = false;
				note.visible = false;
				invalidateNote(note);
			}
			--i;
		}
	}

	inline function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	function setSongTime(time:Float) {
		invincible = true;
		set("bot", true);
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		#if FLX_PITCH FlxG.sound.music.pitch = songMultiplier; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.maxLength) {
			vocals.time = time;
			#if FLX_PITCH
			vocals.pitch = songMultiplier;
			#end
		}
		vocals.play();
		Conductor.songPosition = time;
		invincible = false;
		set("bot", Options.getData("botplay"));
	}

	function startSong():Void {
		startingSong = false;

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
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC, true, songLength / songMultiplier);
		#end
		#end
		call("startSong", []);
		call("songStart", []);

		resyncVocals();
	}

	var maniaChanges:Array<Dynamic> = [];

	// https://github.com/TheZoroForce240/LeatherEngine/blob/main/source/states/PlayState.hx#L1432
	var currentParsingKeyCount:Int = SONG?.keyCount ?? 4;
	var currentParsingPlayerKeyCount:Int = SONG?.playerKeyCount ?? 4;

	var addedVocals:Array<String> = [];

	function generateSong(dataPath:String):Void {
		Conductor.changeBPM(SONG.bpm, songMultiplier);

		if (SONG.needsVoices) {
			for (character in ['player', 'opponent', SONG.player1, SONG.player2]) {
				if (vocals.members.length >= 2) {
					break;
				}
				var soundPath:String = Paths.voices(PlayState.SONG.song, SONG.specialAudioName ?? storyDifficultyStr.toLowerCase(), character,
					boyfriend.curCharacter);
				if (!addedVocals.contains(soundPath)) {
					vocals.add(FlxG.sound.list.add(new FlxSound().loadEmbedded(soundPath)));
					addedVocals.push(soundPath);
				}
			}
		}

		// LOADING MUSIC FOR CUSTOM SONGS
		if (FlxG.sound.music != null && FlxG.sound.music.active)
			FlxG.sound.music.stop();

		FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(SONG.song, SONG.specialAudioName ?? storyDifficultyStr.toLowerCase(),
			boyfriend.curCharacter));
		FlxG.sound.music.persist = true;

		notes = new FlxTypedGroup<Note>();

		if (Options.getData("invisibleNotes")) // this was really simple lmfao
			notes.visible = false;

		var noteData:Array<Section> = SONG.notes;

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

				if (characterPlayingAs == OPPONENT) {
					gottaHitNote = !gottaHitNote;
				} else if (characterPlayingAs == BOTH) {
					gottaHitNote = true;
				}

				var noteData:Int = Std.int(songNotes[1] % (currentParsingKeyCount + currentParsingPlayerKeyCount));
				if (section.mustHitSection && noteData >= SONG.playerKeyCount) {
					noteData -= SONG.playerKeyCount;
					noteData %= SONG.keyCount;
				} else if (!section.mustHitSection && noteData >= SONG.keyCount) {
					noteData -= SONG.keyCount;
					noteData %= SONG.playerKeyCount;
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

				var swagNote:Note = new Note(daStrumTime, noteData, oldNote, false, char, songNotes[4], null, chars, gottaHitNote);
				swagNote.sustainLength = songNotes[2];

				unspawnNotes.push(swagNote);

				var sustainGroup:Array<Note> = [];

				for (susNote in 0...Math.floor(swagNote.sustainLength / Std.int(Conductor.stepCrochet))) {
					oldNote = unspawnNotes[unspawnNotes.length - 1];

					var sustainNote:Note = new Note(daStrumTime
						+ (Conductor.stepCrochet * susNote)
						+ (Conductor.stepCrochet / ((Options.getData("downscroll") || SONG.modchartingTools) ? 1 : FlxMath.roundDecimal(speed, 2))),
						noteData, oldNote, true, char, songNotes[4], null, chars, gottaHitNote);
					sustainNote.scrollFactor.set();
					sustainNote.speed = oldNote.speed;
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

		if (characterPlayingAs == OPPONENT) {
			SONG.keyCount = ogPlayerKeyCount;
			SONG.playerKeyCount = ogKeyCount;
		}

		unspawnNotes.sort(sortNotes);
		generatedMusic = true;
		SONG.validScore = SONG.validScore == true ? songMultiplier >= 1 : false;
	}

	inline function sortNotes(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	/**
	 * The note underlay colored black.
	 * Turned off by default.
	 */
	var noteBG:FlxSprite;

	function generateStaticArrows(pos:Float, ?isPlayer:Bool = false, ?showReminders:Bool = true):Void {
		call("generateStaticArrows", [pos, isPlayer, showReminders]);
		var usedKeyCount:Int = isPlayer ? PlayState.SONG.playerKeyCount : PlayState.SONG.keyCount;

		for (i in 0...usedKeyCount) {
			var babyArrow:StrumNote = new StrumNote(0, strumLine.y, i, null, null, null, usedKeyCount, pos);
			babyArrow.scrollFactor.set();
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
			babyArrow.x += ((FlxG.width / 2) * pos);

			strumLineNotes.add(babyArrow);

			if (usedKeyCount != 4 && isPlayer && Options.getData("extraKeyReminders") && showReminders) {
				// var coolWidth = Std.int(40 - ((key_Count - 5) * 2) + (key_Count == 10 ? 30 : 0));
				// funny 4 key math i guess, full num is 2.836842105263158 (width / previous key width thingy which was 38)
				var coolWidth:Int = Math.ceil(babyArrow.width / 2.83684);

				// had to modify some backend shit to make this not clip off
				// https://github.com/HaxeFlixel/flixel/pull/3226
				// if this pr is merged there should be no issues.
				var keyThingLol:FlxText = new FlxText((babyArrow.x + (babyArrow.width / 2)) - (coolWidth / 2), babyArrow.y - (coolWidth / 2), coolWidth,
					binds[i], coolWidth);
				keyThingLol.cameras = [camHUD];
				keyThingLol.scrollFactor.set();
				keyThingLol.borderStyle = SHADOW_XY(6, 6);
				add(keyThingLol);
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

			noteBG.setGraphicSize(bruhVal, FlxG.height * 2);
			noteBG.updateHitbox();

			noteBG.x = playerStrums.members[0].x;
		}
	}

	inline function tweenCamIn():Void {
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * SONG.timescale[0] / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			FlxG.sound.music?.pause();

			vocals?.pause();

			#if LUA_ALLOWED
			for (sound in LuaScript.lua_Sounds) {
				sound?.pause();
			}
			#end

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

			#if LUA_ALLOWED
			for (sound in LuaScript.lua_Sounds) {
				sound?.resume();
			}
			#end

			paused = false;

			#if DISCORD_ALLOWED
			if (startTimer.finished) {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC, true,
					((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			} else {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC);
			}
			#end

			call("onResumePost", []);
		}

		super.closeSubState();
	}

	override function onFocus():Void {
		#if DISCORD_ALLOWED
		if (health > minHealth && !paused) {
			if (Conductor.songPosition > 0.0) {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC, true,
					((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			} else {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}

	override function onFocusLost():Void {
		#if DISCORD_ALLOWED
		if (health > minHealth && !paused) {
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC);
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

	var paused:Bool = false;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	var canFullscreen:Bool = true;

	var switchedStates:Bool = false;

	// give: [noteDataThingy, noteType]
	// get : [xOffsetToUse]
	var prevPlayerXVals:Map<String, Float> = [];
	var prevEnemyXVals:Map<String, Float> = [];

	var speed(default, set):Float = 1.0;

	var ratingStr:String = "";

	var song_info_timer:Float = 0.0;

	inline function fixedUpdate() {
		call("fixedUpdate", [1 / 120]);
	}

	var fixedUpdateTime:Float = 0.0;

	override function update(elapsed:Float) {
		super.update(elapsed);
		tweenManager.update(elapsed);
		#if (flixel < "6.0.0")
		FlxG.camera.followLerp = (elapsed * 2.4) * cameraSpeed;
		#else
		FlxG.camera.followLerp = 0.04 * cameraSpeed;
		#end
		var iconLerp:Float = elapsed * 9;
		var zoomLerp:Float = (elapsed * 3) * cameraZoomSpeed;

		iconP1.scale.set(FlxMath.lerp(iconP1.scale.x, iconP1.startSize, iconLerp * songMultiplier),
			FlxMath.lerp(iconP1.scale.y, iconP1.startSize, iconLerp * songMultiplier));
		iconP2.scale.set(FlxMath.lerp(iconP2.scale.x, iconP2.startSize, iconLerp * songMultiplier),
			FlxMath.lerp(iconP2.scale.y, iconP2.startSize, iconLerp * songMultiplier));

		iconP1.scale.set(Math.min(iconP1.scale.x, iconP1.startSize + 0.2 * iconP1.startSize),
			Math.min(iconP1.scale.y, iconP1.startSize + 0.2 * iconP1.startSize));
		iconP2.scale.set(Math.min(iconP2.scale.x, iconP2.startSize + 0.2 * iconP2.startSize),
			Math.min(iconP2.scale.y, iconP2.startSize + 0.2 * iconP2.startSize));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Float = 26.0;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset) - iconP1.offsetX;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (iconP2.width - iconOffset)
			- iconP2.offsetX;

		if (cameraZooms && camZooming && !switchedStates) {
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultCamZoom, zoomLerp);
			camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudCamZoom, zoomLerp);
		} else if (!cameraZooms) {
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
			paused = true;
			FlxG.sound.music.volume = 0;
			vocals.volume = 0;
			FlxG.sound.music.time = 0;
			vocals.time = 0;
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

		timeBar.time = time = endingSong ? FlxG.sound.music.length : FlxG.sound.music.time;
		health = Math.min(health, maxHealth);

		if (characterPlayingAs == OPPONENT)
			healthShown = maxHealth - health;
		else
			healthShown = health;

		if (healthBar.percent <= 20) {
			iconP1.animation.play("lose");
			iconP2.animation.play("win");
		} else if (healthBar.percent >= 80) {
			iconP1.animation.play("win");
			iconP2.animation.play("lose");
		} else {
			iconP1.animation.play("neutral");
			iconP2.animation.play("neutral");
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
			set("mustHit", PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)].mustHitSection);

			if (PlayState.SONG.moveCamera) {
				if (!PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)].mustHitSection) {
					turnChange('dad');
				}
				if (PlayState.SONG.notes[Std.int(curStep / Conductor.stepsPerSection)].mustHitSection) {
					turnChange('bf');
				}
			}

			if (!lockedCamera) {
				if (centerCamera) {
					var midPos:FlxPoint = boyfriend.getMainCharacter().getMidpoint();
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
							switch (boyfriend.getMainCharacter().curAnimName().toLowerCase()) {
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
							switch (dad.getMainCharacter().curAnimName().toLowerCase()) {
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
		}

		// RESET = Quick Game Over Screen
		if ((Options.getData("resetButton") && !switchedStates && controls.RESET) || (Options.getData("noHit") && misses > 0))
			health = minHealth;

		if (dead) {
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			camGame.bgColor = FlxColor.BLACK;

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if DISCORD_ALLOWED
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC);
			#end

			call("onDeath", [Conductor.songPosition]);
			// closeScripts();
		}

		health = Math.max(health, minHealth);

		if (unspawnNotes[0] != null && !switchedStates) {
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < (1500.0 * songMultiplier)) {
				notes.add(unspawnNotes[0]);
				unspawnNotes.splice(0, 1);
			}
		}

		if (generatedMusic && !switchedStates && startedCountdown && notes != null && playerStrums.members.length != 0 && enemyStrums.members.length != 0) {
			notes.forEachAlive(function(note:Note) {
				var coolStrum:StrumNote = (note.mustPress ? playerStrums.members[Math.floor(Math.abs(note.noteData)) % playerStrums.members.length] : enemyStrums.members[Math.floor(Math.abs(note.noteData)) % enemyStrums.members.length]);
				note.visible = true;
				note.active = true;
				note.y = coolStrum.y + Note.calculateY(note);
				if (note.isSustainNote) {
					var swagRect:FlxRect = new FlxRect(0, 0, note.frameWidth, note.frameHeight);
					// TODO: make this not... this
					if (Options.getData("downscroll")) {
						swagRect.height = (coolStrum.y + (coolStrum.width / 2) - note.y) / note.scale.y;
						swagRect.y = note.frameHeight - swagRect.height + (note.animation.curAnim.name.endsWith("end") ? note.height * 1.7 : 0);
					} else {
						// swagRect.width = note.width / note.scale.x;
						// swagRect.height = note.height / note.scale.y;
						swagRect.y = (coolStrum.y + Note.swagWidth / 2 - note.y) / note.scale.y;
						swagRect.height -= swagRect.y;
					}
					note.clipRect = swagRect;
				}
				note.calculateCanBeHit();
				if (!note.mustPress && note.canBeHit && note.shouldHit) {
					camZooming = true;

					var singAnim:String = NoteVariables.characterAnimations[getCorrectKeyCount(false) - 1][Std.int(Math.abs(note.noteData))]
						+ (characterPlayingAs == BF ? altAnim : "") + note.singAnimSuffix;
					if (note.singAnimPrefix != 'sing') {
						singAnim = singAnim.replace('sing', note.singAnimPrefix);
					}

					var luaData:Array<Dynamic> = [
						Math.abs(note.noteData),
						Conductor.songPosition,
						note.arrow_Type,
						note.strumTime,
						note.character
					];

					if (characterPlayingAs == BF) {
						if (dad.otherCharacters == null || dad.otherCharacters.length - 1 < note.character)
							dad.playAnim(singAnim, true);
						else {
							if (note.characters.length <= 1)
								dad.otherCharacters[note.character].playAnim(singAnim, true);
							else {
								for (character in note.characters) {
									if (dad.otherCharacters.length - 1 >= character)
										dad.otherCharacters[character].playAnim(singAnim, true);
								}
							}
						}

						if (note.isSustainNote) {
							call('playerTwoSingHeld', luaData);
						} else {
							call('playerTwoSing', luaData);
						}
					} else {
						if (boyfriend.otherCharacters == null || boyfriend.otherCharacters.length - 1 < note.character)
							boyfriend.playAnim(singAnim, true);
						else if (note.characters.length <= 1)
							boyfriend.otherCharacters[note.character].playAnim(singAnim, true);
						else {
							for (character in note.characters) {
								if (boyfriend.otherCharacters.length - 1 >= character)
									boyfriend.otherCharacters[character].playAnim(singAnim, true);
							}
						}

						if (note.isSustainNote) {
							call('playerOneSingHeld', luaData);
						} else {
							call('playerOneSing', luaData);
						}
					}

					call(getSingLuaFuncName(false) + 'SingExtra', [
						Math.abs(note.noteData),
						notes.members.indexOf(note),
						note.arrow_Type,
						note.isSustainNote
					]);

					// how was it THIS SIMPLE this WHOLE TIME??????
					// this has been broken for who knows how long :sob:
					note.wasGoodHit = true;

					if (enemyStrumsGlow && enemyStrums.members.length - 1 == SONG.keyCount - 1) {
						enemyStrums.forEach(function(spr:StrumNote) {
							if (Math.abs(note.noteData) == spr.ID) {
								spr.playAnim('confirm', true);
								spr.resetAnim = 0;
								if (note.colorSwap != null) {
									spr.colorSwap.r = note.colorSwap.r;
									spr.colorSwap.g = note.colorSwap.g;
									spr.colorSwap.b = note.colorSwap.b;
								}

								if (!note.isSustainNote && opponentNoteSplashes) {
									var splash:NoteSplash = splash_group.recycle(NoteSplash);
									splash.setup_splash(spr.ID, spr, false);
									if (note.colorSwap != null) {
										splash.colorSwap.r = note.colorSwap.r;
										splash.colorSwap.g = note.colorSwap.g;
										splash.colorSwap.b = note.colorSwap.b;
									}
									splash_group.add(splash);
								}

								spr.animation.onFinish.add((animName:String) -> spr.playAnim("static"));
							}
						});
					}

					if (characterPlayingAs == BF) {
						if (dad.otherCharacters == null || dad.otherCharacters.length - 1 < note.character)
							dad.holdTimer = 0;
						else {
							if (note.characters.length <= 1)
								dad.otherCharacters[note.character].holdTimer = 0;
							else {
								for (char in note.characters) {
									if (dad.otherCharacters.length - 1 >= char)
										dad.otherCharacters[char].holdTimer = 0;
								}
							}
						}
					} else {
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
					}
					/* @:privateAccess */
					if (vocals != null && /* vocals._transform != null && */ SONG != null && SONG.needsVoices) {
						vocals.volume = 1;
					}

					if (!note.isSustainNote) {
						invalidateNote(note);
					} else {
						// my favorite part about this hack is that you can technically override it with a script
						note.shouldHit = false;
					}
				}

				if (note != null && coolStrum != null) {
					if (note.mustPress && note != null) {
						var coolStrum:StrumNote = playerStrums.members[Math.floor(Math.abs(note.noteData))];
						var arrayVal:String = Std.string([note.noteData, note.arrow_Type, note.isSustainNote]);

						if (coolStrum != null)
							note.visible = coolStrum.visible;

						if (!prevPlayerXVals.exists(arrayVal) && prevPlayerXVals != null) {
							var tempShit:Float = 0.0;

							if (coolStrum != null)
								note.x = coolStrum.x;

							if (note != null && coolStrum != null) {
								while (Std.int(note.x + (note.width / 2)) != Std.int(coolStrum.x + (coolStrum.width / 2))
									&& coolStrum != null
									&& note != null) {
									note.x += (note.x + note.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
									tempShit += (note.x + note.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
								}
							}

							prevPlayerXVals.set(arrayVal, tempShit);
						} else {
							if (coolStrum != null)
								note.x = coolStrum.x + prevPlayerXVals.get(arrayVal) - note.xOffset;
						}

						if (coolStrum != null && !note.isSustainNote && note != null)
							note.modAngle = coolStrum.angle;

						if (coolStrum != null && coolStrum.alpha != 1 && note != null) {
							note.alpha = coolStrum.alpha;
						}

						if (!note.isSustainNote && coolStrum != null && note != null) {
							note.modAngle = coolStrum.angle;
						}

						if (coolStrum != null && note != null) {
							note.flipX = coolStrum.flipX;
						}

						if (!note.isSustainNote && coolStrum != null && note != null) {
							note.flipY = coolStrum.flipY;
						}

						if (coolStrum != null && note != null) {
							note.color = coolStrum.color;
						}
					} else if (!note?.wasGoodHit) {
						var coolStrum:StrumNote = enemyStrums.members[Math.floor(Math.abs(note.noteData))];
						var arrayVal:String = Std.string([note.noteData, note.arrow_Type, note.isSustainNote]);

						if (coolStrum != null && note != null)
							note.visible = coolStrum.visible;

						if (!prevEnemyXVals.exists(arrayVal) && coolStrum != null) {
							var tempShit:Float = 0.0;

							note.x = coolStrum.x;

							while (Std.int(note.x + (note.width / 2)) != Std.int(coolStrum.x + (coolStrum.width / 2))) {
								note.x += (note.x + note.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
								tempShit += (note.x + note.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
							}

							prevEnemyXVals.set(arrayVal, tempShit);
						} else {
							if (coolStrum != null)
								note.x = coolStrum.x + prevEnemyXVals.get(arrayVal) - note.xOffset;
						}

						if (coolStrum != null && !note.isSustainNote && note != null)
							note.modAngle = coolStrum.angle;

						if (coolStrum != null && coolStrum.alpha != 1 && note != null)
							note.alpha = coolStrum.alpha;

						if (coolStrum != null && !note.isSustainNote && note != null)
							note.modAngle = coolStrum.angle;

						if (coolStrum != null && !note.isSustainNote && note != null)
							note.flipX = coolStrum.flipX;

						if (coolStrum != null && !note.isSustainNote && note != null)
							note.flipY = coolStrum.flipY;

						if (coolStrum != null && note != null)
							note.color = coolStrum.color;
					}
				}

				if (Conductor.songPosition - Conductor.safeZoneOffset > note.strumTime) {
					if (note != null
						&& note.animation != null
						&& note.animation.curAnim != null
						&& note.mustPress
						&& note.playMissOnMiss
						&& !(note.isSustainNote && note.animation.curAnim.name == "holdend")
						&& !note.wasGoodHit) {
						if (vocals != null) {
							vocals.volume = 0;
						}

						noteMiss(note.noteData, note);
					}

					note.active = false;
					note.visible = false;

					invalidateNote(note);
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

			#if LUA_ALLOWED
			for (tween in LuaScript.lua_Tweens) {
				FlxTweenUtil.pauseTween(tween);
			}
			#end

			call('onPause', []);
			openSubState(new PauseSubState());
			call('onPausePost', []);
			#if DISCORD_ALLOWED
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyStr + ")", iconRPC);
			#end
		}

		if (!Options.getData("disableDebugMenus")) {
			if (FlxG.keys.justPressed.SEVEN && !switchedStates && !inCutscene) {
				PlayState.chartingMode = true;
				switchedStates = true;
				vocals.stop();
				SONG.keyCount = ogKeyCount;
				SONG.playerKeyCount = ogPlayerKeyCount;
				FlxG.switchState(() -> new ChartingState());
				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Chart Editor", null, null, true);
				#end
			}

			// #if debug
			if (FlxG.keys.justPressed.EIGHT && !switchedStates && !inCutscene) {
				switchedStates = true;
				vocals.stop();
				SONG.keyCount = ogKeyCount;
				SONG.playerKeyCount = ogPlayerKeyCount;
				FlxG.switchState(() -> new toolbox.CharacterCreator(SONG.player2, curStage));
				toolbox.CharacterCreator.lastState = "PlayState";
				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Creating A Character", null, null, true);
				#end
			}

			#if MODCHARTING_TOOLS
			if (FlxG.keys.justPressed.NINE && !switchedStates && !inCutscene) {
				switchedStates = true;
				vocals.stop();
				SONG.keyCount = ogKeyCount;
				SONG.playerKeyCount = ogPlayerKeyCount;
				FlxG.switchState(() -> new modcharting.ModchartEditorState());
				#if DISCORD_ALLOWED
				DiscordClient.changePresence("In The Modchart Editor", null, null, true);
				#end
			}
			#end
		}
		if (FlxG.keys.justPressed.F6) {
			toggleBotplay();
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
		if (generatedMusic && !switchedStates && startedCountdown) {
			for (shader in LuaScript.lua_Shaders) {
				shader.update(elapsed);
			}

			set("songPos", Conductor.songPosition);
			set("hudZoom", camHUD.zoom);
			set("curBeat", curBeat);
			set("cameraZoom", FlxG.camera.zoom);
			set("bpm", Conductor.bpm);
			set("songBpm", Conductor.bpm);
			set("crochet", Conductor.crochet);
			set("stepCrochet", Conductor.stepCrochet);
			set("conductor", {
				bpm: Conductor.bpm,
				crochet: Conductor.crochet,
				stepCrochet: Conductor.stepCrochet,
				songPosition: Conductor.songPosition,
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
			set("flxG", {
				width: FlxG.width,
				height: FlxG.height,
				elapsed: FlxG.elapsed,
			});

			call("update", [elapsed]);

			// var showOnlyStrums:Bool = getLuaVar("showOnlyStrums", "bool") ?? false;

			/*for (i in 0...SONG.keyCount) {
					strumLineNotes.members[i].visible = getLuaVar("strumLine1Visible", "bool") ?? true;
				}

				for (i in 0...SONG.playerKeyCount) {
					if (i <= playerStrums.length)
						playerStrums.members[i].visible = getLuaVar("strumLine2Visible", "bool") ?? true;
			}*/

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
		closeScripts();
		FlxG.camera.bgColor = FlxColor.BLACK;
		super.destroy();
	}

	function turnChange(char:String) {
		call("turnChange", [char]);
		switch (char) {
			case 'dad':
				var midPos:FlxPoint = dad.getMainCharacter().getMidpoint();

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

				if (!paused && !lockedCamera)
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
			case 'bf':
				var midPos:FlxPoint = boyfriend.getMainCharacter().getMidpoint();

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

				if (!paused && !lockedCamera)
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
		}
	}

	function endSong():Void {
		call("endSong", []);
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		// lol dude when a song ended in freeplay it legit reloaded the page and i was like:  o_o ok
		if (FlxG.state == instance) {
			if (SONG.validScore) {
				Highscore.saveScore(SONG.song, songScore, storyDifficultyStr);
				Highscore.saveRank(SONG.song, Ratings.getRank(accuracy, misses), storyDifficultyStr, accuracy);
			}

			if (playCutsceneOnPauseLmao && SONG.endCutscene != null && SONG.endCutscene != "") {
				cutscene = CutsceneUtil.loadFromJson(SONG.endCutscene);

				switch (cutscene.type.toLowerCase()) {
					case "script":
						#if HSCRIPT_ALLOWED
						var cutsceneScript:HScript = new HScript(Paths.hx('data/${cutscene.scriptPath}'));
						for (object in stage.stageObjects) {
							cutsceneScript.interp.variables.set(object[0], object[1]);
						}
						scripts.set(cutscene.scriptPath, cutsceneScript);
						cutsceneScript.call("startCutscene");
						#else
						throw "HScript is not enabled!";
						#end
					case "video":
						startVideo(cutscene.videoPath, cutscene.videoExt, true);

					case "dialogue":
						var box:DialogueBox = new DialogueBox(cutscene);
						box.scrollFactor.set();
						box.onDialogueFinish.add(() -> bruhDialogue(true));
						box.cameras = [camHUD];
						box.zIndex = FlxMath.MAX_VALUE_INT;
						startDialogue(box, true);
					default:
						persistentUpdate = false;
						persistentDraw = true;
						paused = true;
						moveToResultsScreen();
				}
			} else {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;
				moveToResultsScreen();
			}
		}
	}

	function finishSongStuffs() {
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

				FlxG.switchState(() -> new StoryMenuState());

				if (SONG.validScore)
					Highscore.saveWeekScore(campaignScore, storyDifficultyStr, (groupWeek != "" ? groupWeek + "Week" : "week") + Std.string(storyWeek));
			} else {
				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase());

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

				PlayState.SONG = SongLoader.loadFromJson(storyDifficultyStr, PlayState.storyPlaylist[0]);

				if (vocals != null && vocals.active)
					vocals.stop();
				if (FlxG.sound.music != null && FlxG.sound.music.active)
					FlxG.sound.music.stop();

				switchedStates = true;
				PlayState.loadChartEvents = true;
				LoadingState.loadAndSwitchState(() -> new PlayState());
			}
		} else {
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

	var uiMap:Map<String, FlxGraphicAsset> = [];

	function popUpScore(strumtime:Float, noteData:Int, ?setNoteDiff:Float):Void {
		var noteDiff:Float = (strumtime - Conductor.songPosition);

		if (Options.getData("botplay"))
			noteDiff = 0;

		if (setNoteDiff != null)
			noteDiff = setNoteDiff;

		if (vocals != null)
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
			playerStrums.forEachAlive(function(spr:StrumNote) {
				if (spr.ID == Math.abs(noteData)) {
					var splash:NoteSplash = splash_group.recycle(NoteSplash);
					splash.setup_splash(noteData, spr, true);
					if (spr.colorSwap != null) {
						splash.colorSwap.r = spr.colorSwap.r;
						splash.colorSwap.g = spr.colorSwap.g;
						splash.colorSwap.b = spr.colorSwap.b;
					}
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
		var initRatingX:Float = rating.x -= (Options.getData("middlescroll") ? 350 : (Options.getData("playAs") == 0 ? 0 : -150));
		var initRatingY:Float = rating.y -= 60;
		rating.x += Options.getData("ratingsOffset")[0];
		rating.y += Options.getData("ratingsOffset")[1];
		rating.velocity.y = FlxG.random.int(30, 60);
		rating.velocity.x = FlxG.random.int(-10, 10);

		var noteMath:Float = FlxMath.roundDecimal(noteDiff, 2);

		if (Options.getData("displayMs")) {
			accuracyText.text = noteMath + " ms" + (Options.getData("botplay") ? " (BOT)" : "");
			accuracyText.setPosition(initRatingX + Options.getData("accuracyTextOffset")[0], initRatingY + 100 + Options.getData("accuracyTextOffset")[1]);

			if (Math.abs(noteMath) == noteMath)
				accuracyText.color = FlxColor.CYAN;
			else
				accuracyText.color = FlxColor.ORANGE;

			accuracyText.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
			accuracyText.borderSize = 1;
			accuracyText.font = Paths.font("vcr.ttf");

			ratingsGroup.add(accuracyText);
		}

		ratingsGroup.add(rating);

		rating.setGraphicSize(rating.width * Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[4]));
		rating.antialiasing = ui_settings[3] == "true" && Options.getData("antialiasing");
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

			numScore.screenCenter();
			numScore.x -= (Options.getData("middlescroll") ? 350 : (characterPlayingAs == BF ? 0 : -150));

			numScore.x += (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.x += Options.getData("comboOffset")[0];
			numScore.y += Options.getData("comboOffset")[1];

			numScore.setGraphicSize(numScore.width * Std.parseFloat(ui_settings[1]));
			numScore.updateHitbox();

			numScore.antialiasing = ui_settings[3] == "true" && Options.getData("antialiasing");

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

	function updateScoreText() {
		scoreTxt.text = '<  ${Options.getData('showScore') ? 'Score:${songScore} ~ ' : ''}Misses:${misses} ~ Accuracy:${accuracy}% ~ ${ratingStr}  >';
		scoreTxt.screenCenter(X);
	}

	function toggleBotplay() {
		Options.setData(!Options.getData("botplay"), "botplay");
		set("bot", Options.getData("botplay"));
		SONG.validScore = false;
		updateSongInfoText();
	}

	var justPressedArray:Array<Bool> = [];
	var releasedArray:Array<Bool> = [];
	var justReleasedArray:Array<Bool> = [];
	var heldArray:Array<Bool> = [];
	var previousReleased:Array<Bool> = [];

	function keyShit() {
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
						call("keyPressed", [i ?? justPressedArray.length]);
					}
				}

				for (i in 0...releasedArray.length) {
					if (releasedArray[i]) {
						call("keyReleased", [i ?? justPressedArray.length]);
					}
				}

				if (justPressedArray.contains(true) && generatedMusic) {
					// variables
					var possibleNotes:Array<Note> = [];
					var dontHit:Array<Note> = [];

					// notes you can hit lol
					notes.forEachAlive(function(note:Note) {
						note.calculateCanBeHit();

						if (note.canBeHit && note.mustPress && !note.tooLate && !note.isSustainNote)
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

								if (characterPlayingAs == BF) {
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
					notes.forEachAlive(function(note:Note) {
						note.calculateCanBeHit();

						if (heldArray[note.noteData] && note.isSustainNote && note.mustPress) {
							if (note.canBeHit) {
								if (characterPlayingAs == BF) {
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
				}

				if (characterPlayingAs == BF) {
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
						spr.playAnim('pressed');
						spr.resetAnim = 0;
					}

					if (releasedArray[spr.ID]) {
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				});
			} else {
				notes.forEachAlive(function(note:Note) {
					if (note.shouldHit) {
						if (note.mustPress && note.strumTime <= Conductor.songPosition) {
							if (characterPlayingAs == BF) {
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

				if (characterPlayingAs == BF) {
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
			if (note.mustPress)
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
				if (characterPlayingAs == BF) {
					if (boyfriend.otherCharacters != null && !(boyfriend.otherCharacters.length - 1 < note.character)) {
						if (note.characters.length <= 1)
							boyfriend.otherCharacters[note.character].playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction]
								+ "miss", true);
						else {
							for (character in note.characters) {
								if (boyfriend.otherCharacters.length - 1 >= character)
									boyfriend.otherCharacters[character].playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction]
										+ "miss", true);
							}
						}
					} else
						boyfriend.playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction] + "miss", true);
				} else {
					if (dad.otherCharacters != null && !(dad.otherCharacters.length - 1 < note.character))
						if (note.characters.length <= 1)
							dad.otherCharacters[note.character].playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction] + "miss",
								true);
						else {
							for (character in note.characters) {
								if (dad.otherCharacters.length - 1 >= character)
									dad.otherCharacters[character].playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction] +
										"miss", true);
							}
						}
					else
						dad.playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction] + "miss", true);
				}
			} else {
				if (characterPlayingAs == BF)
					boyfriend.playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction] + "miss", true);
				else
					dad.playAnim(NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][direction] + "miss", true);
			}

			calculateAccuracy();

			call("playerOneMiss", [
				direction,
				Conductor.songPosition,
				(note != null ? note.arrow_Type : "default"),
				(note != null ? note.isSustainNote : false)
			]);

			#if LUA_ALLOWED
			set("misses", misses);
			#end
		}
	}

	var hitsound:FlxSound;

	function goodNoteHit(note:Note, ?setNoteDiff:Float):Void {
		#if HSCRIPT_ALLOWED
		for(script in scripts){
			if(script is HScript){
				script.call("goodNoteHit", [note, setNoteDiff]);
			}
		}
		#end
		if (!note.wasGoodHit) {
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

			var singAnim:String = NoteVariables.characterAnimations[getCorrectKeyCount(true) - 1][Std.int(Math.abs(note.noteData % getCorrectKeyCount(true)))]
				+ (characterPlayingAs == OPPONENT ? altAnim : "")
				+ note.singAnimSuffix;
			if (note.singAnimPrefix != 'sing') {
				singAnim = singAnim.replace('sing', note.singAnimPrefix);
			}
			if (characterPlayingAs == BF) {
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
						spr.playAnim('confirm', true);
						if (note.colorSwap != null) {
							spr.colorSwap.r = note.colorSwap.r;
							spr.colorSwap.g = note.colorSwap.g;
							spr.colorSwap.b = note.colorSwap.b;
						}
					}
				});
			}

			if (note.shouldHit && !note.isSustainNote) {
				combo++;
				maxCombo = Std.int(Math.max(maxCombo, combo));
				popUpScore(note.strumTime, note.noteData % getCorrectKeyCount(true), setNoteDiff);

				if (hitSoundString != "none") {
					hitsound.play(true);
				}
			} else if (!note.shouldHit) {
				health -= note.hitDamage;
				misses++;
				missSounds[FlxG.random.int(0, missSounds.length - 1)].play(true);
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote) {
				invalidateNote(note);
			}
		}
		call("goodNoteHitPost", [
			note.noteData,
			Conductor.songPosition,
			note.arrow_Type,
			note.strumTime,
			note.character,
			note.mustPress
		]);
	}

	override function stepHit() {
		super.stepHit();

		var gamerValue = 20 * songMultiplier;

		if (FlxG.sound.music.time > Conductor.songPosition + gamerValue
			|| FlxG.sound.music.time < Conductor.songPosition - gamerValue
			|| FlxG.sound.music.time < 500
			&& (FlxG.sound.music.time > Conductor.songPosition + 5 || FlxG.sound.music.time < Conductor.songPosition - 5))
			resyncVocals();

		set("curStep", curStep);
		call("stepHit", [curStep]);
	}

	override function beatHit() {
		super.beatHit();

		if (generatedMusic && startedCountdown)
			notes.sort(FlxSort.byY, (Options.getData("downscroll") ? FlxSort.ASCENDING : FlxSort.DESCENDING));

		if (SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)] != null) {
			if (timeBarStyle == 'leather engine'
				&& Math.floor(curStep / Conductor.stepsPerSection) != Math.floor((curStep - 1) / Conductor.stepsPerSection) && SONG.chartType != VSLICE) {
				var target:FlxColor = SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)].mustHitSection ? boyfriend.barColor : dad.barColor;
				FlxTween.color(timeBar.bar, Conductor.crochet * 0.002, timeBar.bar.color, target);
			}

			if (SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)].changeBPM) {
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / Conductor.stepsPerSection)].bpm, songMultiplier);
				/*Note.applyColorQuants(notes.members);
						Note.applyColorQuants(unspawnNotes); */
			}
		}

		// Dad doesnt interupt his own notes
		if (characterPlayingAs == BF) {
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
		if (camZooming
			&& FlxG.camera.zoom < (1.35 * FlxCamera.defaultZoom)
			&& cameraZoomRate > 0
			&& curBeat % ((Conductor.timeScale[0]) / cameraZoomRate) == 0) {
			FlxG.camera.zoom += 0.015 * cameraZoomStrength;
			camHUD.zoom += 0.03 * cameraZoomStrength;
		}

		iconP1.scale.add(0.2 * iconP1.startSize, 0.2 * iconP1.startSize);
		iconP2.scale.add(0.2 * iconP2.startSize, 0.2 * iconP2.startSize);

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset) - iconP1.offsetX;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (iconP2.width - iconOffset)
			- iconP2.offsetX;

		if (gfSpeed < 1)
			gfSpeed = 1;

		if (curBeat % gfSpeed == 0 && !dad.curCharacter.startsWith('gf')) {
			if (gf.otherCharacters == null) {
				gf.dance();
			} else {
				for (character in gf.otherCharacters) {
					character.dance();
				}
			}
		}

		if (dad.animation.curAnim != null) {
			if (!dad.animation.curAnim.name.startsWith("sing") && curBeat % gfSpeed == 0 && dad.curCharacter.startsWith('gf')) {
				if (dad.otherCharacters == null) {
					dad.dance();
				} else {
					for (character in dad.otherCharacters) {
						character.dance();
					}
				}
			}
		}

		if (characterPlayingAs == BF) {
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

		stage.beatHit();

		call("beatHit", [curBeat]);
	}

	function updateRatingText() {
		if (Options.getData("sideRatings")) {
			ratingText.text = getRatingText();
			ratingText.screenCenter(Y);
			ratingText.y += Options.getData("ratingTextOffset")[1];
		}
	}

	/**
		 * Move to the results screen right goddamn now.
		 */
	function moveToResultsScreen(?prevScoreData:SaveScoreData):Void {
		var isNewHighscore:Bool = (SONG.validScore) ? (isStoryMode ? campaignScore >= Highscore.getWeekScore(storyWeek, storyDifficultyStr,
			(groupWeek != "" ? groupWeek + "Week" : "week") + Std.string(storyWeek)) : songScore >= Highscore.getScore(SONG.song, storyDifficultyStr)) : false;
		persistentUpdate = false;
		vocals.stop();
		camHUD.alpha = 1;

		var res:ResultsSubstate = new ResultsSubstate({
			storyMode: isStoryMode,
			difficultyId: storyDifficultyStr.toLowerCase(),
			title: isStoryMode ? ('${campaignTitle}') : ('${SONG.song}'),
			prevScoreData: prevScoreData,
			scoreData: {
				score: isStoryMode ? campaignScore : songScore,
				tallies: {sick: ratings.get("marvelous") + ratings.get("sick"),
					good: ratings.get("good"),
					bad: ratings.get("bad"),
					shit: ratings.get("shit"),
					missed: misses,
					combo: combo,
					maxCombo: maxCombo,
					totalNotesHit: ratings.get("marvelous")
					+ ratings.get("sick")
					+ ratings.get("good")
					+ ratings.get("bad")
					+ ratings.get("shit"),
					totalNotes: totalNotes,
				},
			},
			isNewHighscore: isNewHighscore
		});
		this.persistentDraw = false;
		PlayState.chartingMode = false;
		openSubState(res);
	}

	function getRatingText():String {
		var ratingArray:Array<Int> = [
			ratings.get("marvelous"),
			ratings.get("sick"),
			ratings.get("good"),
			ratings.get("bad"),
			ratings.get("shit")
		];

		var MA:Int = ratingArray[1] + ratingArray[2] + ratingArray[3] + ratingArray[4];
		var PA:Int = MA - ratingArray[1];

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

	static function getCharFromEvent(eventVal:String):Character {
		switch (eventVal.toLowerCase()) {
			case "girlfriend" | "gf" | "player3" | "2":
				return PlayState.gf.getMainCharacter();
			case "dad" | "opponent" | "player2" | "1":
				return PlayState.dad.getMainCharacter();
		}

		return PlayState.boyfriend.getMainCharacter();
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

	function cacheEventCharacter(event:Array<Dynamic>) {
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
					for (script in scripts) {
						if (script is LuaScript)
							script.setup();
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
					for (script in scripts) {
						if (script is LuaScript)
							script.setup();
					}
					#end

					iconP2.scale.set(iconP2.startSize, iconP2.startSize);
					iconP2.setupIcon(dad.icon);

					healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
					healthBar.updateFilledBar();
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
						for (script in scripts) {
							if (script is LuaScript)
								script.setup();
						}
						#end
					}

					iconP1.scale.set(iconP1.startSize, iconP1.startSize);
					iconP1.setupIcon(boyfriend.icon);

					healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
					healthBar.updateFilledBar();
			}
		} else
			CoolUtil.coolError("The character " + event[3] + " isn't in any character cache!\nHow did this happen? ¯|_(ツ)_|¯",
				"Leather Engine's No Crash, We Help Fix Stuff Tool");

		addBgStuff();
	}

	function updateSongInfoText() {
		var songThingy:Float = songLength - FlxG.sound.music.time;

		var seconds:Int = Math.floor(songThingy / 1000);
		seconds = Std.int(seconds / songMultiplier);
		if (seconds < 0)
			seconds = 0;

		switch (timeBarStyle.toLowerCase()) {
			default: // includes 'leather engine'
				timeBar.text.text = SONG.song + " ~ " + storyDifficultyStr + ' (${FlxStringUtil.formatTime(seconds, false)})'
					+ (Options.getData("botplay") ? " (BOT)" : "") + (Options.getData("noDeath") ? " (NO DEATH)" : "");
				timeBar.text.screenCenter(X);
			case "psych engine":
				timeBar.text.text = '${FlxStringUtil.formatTime(seconds, false)}' + (Options.getData("botplay") ? " (BOT)" : "")
					+ (Options.getData("noDeath") ? " (NO DEATH)" : "");
				timeBar.text.screenCenter(X);
			case "old kade engine":
				timeBar.text.text = SONG.song + (Options.getData("botplay") ? " (BOT)" : "") + (Options.getData("noDeath") ? " (NO DEATH)" : "");
				timeBar.text.screenCenter(X);
		}
	}

	inline function set(name:String, data:Any, ?executeOn:ExecuteOn = BOTH) {
		for (script in scripts) {
			if (script.executeOn == executeOn || executeOn == BOTH) {
				script.set(name, data);
			}
		}
	}

	override function call(func:String, ?args:Array<Any>, executeOn:ExecuteOn = BOTH) {
		super.call(func, args);
		for (script in scripts) {
			if ((script.executeOn == executeOn || executeOn == BOTH)) {
				script.call(func, args);
			}
		}
	}

	function getLuaVar(name:String, type:String):Any {
		#if LUA_ALLOWED
		var luaVar:Any = null;

		for (script in scripts) {
			if (script is LuaScript) {
				var newLuaVar = cast(script, LuaScript).getVar(name, type);

				if (newLuaVar != null)
					luaVar = newLuaVar;
			}
		}

		if (luaVar != null)
			return luaVar;
		#end

		return null;
	}

	function closeScripts() {
		for (script in scripts) {
			script?.destroy();
		}
		#if LUA_ALLOWED
		for (sound in LuaScript.lua_Sounds) {
			sound?.stop();
			sound?.kill();
			sound?.destroy();
		}
		LuaScript.killShaders();
		LuaScript.lua_Characters.clear();
		LuaScript.lua_Sounds.clear();
		LuaScript.lua_Sprites.clear();
		LuaScript.lua_Shaders.clear();
		LuaScript.lua_Custom_Shaders.clear();
		LuaScript.lua_Cameras.clear();
		LuaScript.lua_Jsons.clear();
		#end
	}

	function processEvent(event:Array<Dynamic>) {
		#if LUA_ALLOWED
		if (scripts.exists(event[0].toLowerCase())) {
			for (i in 0...strumLineNotes.length) {
				var member = strumLineNotes.members[i];

				scripts.get(event[0].toLowerCase()).set("defaultStrum" + i + "X", member.x);
				scripts.get(event[0].toLowerCase()).set("defaultStrum" + i + "Y", member.y);
				scripts.get(event[0].toLowerCase()).set("defaultStrum" + i + "Angle", member.angle);

				scripts.get(event[0].toLowerCase()).set("defaultStrum" + i, {
					x: member.x,
					y: member.y,
					angle: member.angle,
				});
			}
		}
		#end

		EventHandeler.processEvent(this, event);

		//                name       pos      param 1   param 2
		call("onEvent", [event[0], event[1], event[2], event[3]]);
	}

	function calculateAccuracy() {
		if (totalNotes != 0 && !switchedStates)
			accuracy = FlxMath.roundDecimal(100.0 / (totalNotes / hitNotes), 2);

		#if LUA_ALLOWED
		set("accuracy", accuracy);
		#end

		updateRating();
		updateScoreText();
	}

	inline function updateRating()
		ratingStr = Ratings.getRank(accuracy, misses);

	function generareNoteChangeEvents():Void {
		if (SONG.events.length > 0) {
			for (event in SONG.events) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		if (Assets.exists(Paths.songEvents(SONG.song.toLowerCase(), storyDifficultyStr.toLowerCase())) && loadChartEvents) {
			var eventFunnies:Array<Array<Dynamic>> = SongLoader.parseLegacy(Json.parse(Assets.getText(Paths.songEvents(SONG.song.toLowerCase(),
				storyDifficultyStr.toLowerCase()))), SONG.song)
				.events;

			for (event in eventFunnies) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		for (event in events) {
			// cache shit
			if (event[0].toLowerCase() == "change keycount" || event[0].toLowerCase() == "change mania") {
				maniaChanges.push([event[1], Std.parseInt(event[2]), Std.parseInt(event[3])]); // track strumtime, p1 keycount, p2 keycount
			}
		}

		events.sort((a, b) -> Std.int(a[1] - b[1]));
	}

	function generateEvents():Void {
		if (SONG.events.length > 0) {
			for (event in SONG.events) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		if (Assets.exists(Paths.songEvents(SONG.song.toLowerCase(), storyDifficultyStr.toLowerCase())) && loadChartEvents) {
			var eventFunnies:Array<Array<Dynamic>> = SongLoader.parseLegacy(Json.parse(Assets.getText(Paths.songEvents(SONG.song.toLowerCase(),
				storyDifficultyStr.toLowerCase()))), SONG.song)
				.events;

			for (event in eventFunnies) {
				baseEvents.push(event);
				events.push(event);
			}
		}

		try {
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
						var tmr:Float = Sys.time();
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

						trace('Cached ${event[3]} in ${FlxMath.roundDecimal(Sys.time() - tmr, 2)} seconds');
					}

					if (event[0].toLowerCase() == "change stage"
						&& event[1] <= FlxG.sound.music.length
						&& !stageMap.exists(event[2])
						&& Options.getData("preloadChangeBGs")) {
						var funnyStage = new StageGroup(event[2]);
						funnyStage.visible = false;

						stageMap.set(event[2], funnyStage);
					}
				}

				#if LUA_ALLOWED
				if (!scripts.exists(event[0].toLowerCase()) && Assets.exists(Paths.lua("event data/" + event[0].toLowerCase()))) {
					scripts.set(event[0].toLowerCase(), new LuaScript(Paths.getModPath(Paths.lua("event data/" + event[0].toLowerCase()))));
				}
				#end

				#if HSCRIPT_ALLOWED
				if (!scripts.exists(event[0].toLowerCase()) && Assets.exists(Paths.hx("data/event data/" + event[0].toLowerCase()))) {
					scripts.set(event[0].toLowerCase(), new HScript(Paths.hx("data/event data/" + event[0].toLowerCase())));
				}
				#end
			}

			events.sort((a, b) -> Std.int(a[1] - b[1]));
		} catch (e) {
			// trace(e, ERROR);
		}
	}

	function setupNoteTypeScript(noteType:String) {
		if (FlxG.state != this)
			return;
		#if LUA_ALLOWED
		if (!scripts.exists(noteType.toLowerCase()) && Assets.exists(Paths.lua("arrow types/" + noteType))) {
			scripts.set(noteType.toLowerCase(), new LuaScript(Paths.getModPath(Paths.lua("arrow types/" + noteType))));
		}
		#end
		#if HSCRIPT_ALLOWED
		if (Assets.exists(Paths.hx("data/arrow types/" + noteType))) {
			scripts.set(noteType.toLowerCase(), new HScript(Paths.hx("data/arrow types/" + noteType)));
		}
		#end
	}

	function getCorrectKeyCount(player:Bool) {
		var kc = SONG.keyCount;
		if ((player && characterPlayingAs == BF) || (characterPlayingAs == OPPONENT && !player)) {
			kc = SONG.playerKeyCount;
		}
		return kc;
	}

	function getSingLuaFuncName(player:Bool) {
		var name = "playerTwo";
		if ((player && characterPlayingAs == BF) || (characterPlayingAs == OPPONENT && !player)) {
			name = "playerOne";
		}
		return name;
	}

	function addBehindGF(behind:FlxBasic) {
		insert(members.indexOf(gf), behind);
	}

	function addBehindDad(behind:FlxBasic) {
		insert(members.indexOf(dad), behind);
	}

	function addBehindBF(behind:FlxBasic) {
		insert(members.indexOf(boyfriend), behind);
	}

	@:noCompletion
	function set_speed(speed:Float):Float {
		if (Options.getData("useCustomScrollSpeed")) {
			speed = Options.getData("customScrollSpeed") / songMultiplier;
		}
		if (notes?.members != null && unspawnNotes != null) {
			for (note in notes.members) {
				note.speed = speed;
			}
			for (note in unspawnNotes) {
				note.speed = speed;
			}
		}
		return this.speed = speed;
	}

	@:noCompletion
	inline private function get_dead():Bool {
		return health <= minHealth && !switchedStates && !invincible && !Options.getData("noDeath");
	}

	@:noCompletion
	inline private function get_infoTxt():FlxText {
		return timeBar.text;
	}

	@:noCompletion
	inline private function set_infoTxt(value:FlxText):FlxText {
		return timeBar.text = value;
	}

	@:noCompletion
	inline private function set_timeBarBG(value:FlxSprite):FlxSprite {
		return timeBar.bg = value;
	}

	@:noCompletion
	inline private function get_timeBarBG():FlxSprite {
		return timeBar.bg;
	}
}
