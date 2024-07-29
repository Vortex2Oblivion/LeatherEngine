package modding;

#if LUA_ALLOWED
#if MODCHARTING_TOOLS
import modcharting.ModchartFuncs;
#end
import flixel.addons.effects.FlxTrail;
import flixel.text.FlxText;
import openfl.display.BlendMode;
import flixel.FlxCamera;
import game.DancingSprite;
import game.Boyfriend;
import ui.HealthIcon;
import ui.logs.Logs;
import hxnoise.Perlin;
import utilities.NoteVariables;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.FlxInput.FlxInputState;
import game.Note;
import flixel.math.FlxMath;
import openfl.filters.BitmapFilter;
import flixel.math.FlxPoint;
import openfl.display.ShaderParameter;
import shaders.custom.CustomShader;
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxTimer;
import game.Character;
import flixel.util.FlxColor;
import llua.Convert;
import llua.Lua;
import llua.Lua.Lua_helper;
import llua.State;
import llua.LuaL;
import flixel.FlxSprite;
import states.PlayState;
import lime.utils.Assets;
import flixel.sound.FlxSound;
#if MODDING_ALLOWED
import polymod.backends.PolymodAssets;
#end
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import game.Conductor;
import lime.app.Application;
import modding.helpers.FlxTextFix;
#if android
import android.widget.Toast as AndroidToast;
import android.Tools as AndroidTools;
import android.utilities.LeatherJNI;
#end

using StringTools;

typedef LuaCamera = {
	var cam:FlxCamera;
	var shaders:Array<BitmapFilter>;
	var shaderNames:Array<String>;
}

class ModchartUtilities {
	public var lua:State = null;

	public static var lua_Sprites:Map<String, FlxSprite> = [
		'boyfriend' => PlayState.boyfriend,
		'girlfriend' => PlayState.gf,
		'dad' => PlayState.dad,
	];

	public static var lua_Characters:Map<String, Character> = [
		'boyfriend' => PlayState.boyfriend,
		'girlfriend' => PlayState.gf,
		'dad' => PlayState.dad,
	];

	public static var lua_Sounds:Map<String, FlxSound> = [];
	public static var lua_Shaders:Map<String, shaders.Shaders.ShaderEffect> = [];
	public static var lua_Custom_Shaders:Map<String, CustomShader> = [];
	public static var lua_Cameras:Map<String, LuaCamera> = [];

	public var functions_called:Array<String> = [];

	public static var instance:ModchartUtilities = null;

	function getActorByName(id:String):Dynamic {
		// lua objects or what ever
		if (lua_Sprites.exists(id))
			return lua_Sprites.get(id);
		else if (lua_Sounds.exists(id))
			return lua_Sounds.get(id);
		else if (lua_Shaders.exists(id))
			return lua_Shaders.get(id);
		else if (lua_Custom_Shaders.exists(id))
			return lua_Custom_Shaders.get(id);
		else if (lua_Cameras.exists(id))
			return lua_Cameras.get(id).cam;

		if (Reflect.getProperty(PlayState.instance, id) != null)
			return Reflect.getProperty(PlayState.instance, id);
		else if (Reflect.getProperty(PlayState, id) != null)
			return Reflect.getProperty(PlayState, id);

		if (PlayState.strumLineNotes.length - 1 >= Std.parseInt(id)) @:privateAccess
			return PlayState.strumLineNotes.members[Std.parseInt(id)];

		return null;
	}

	function getCharacterByName(id:String):Dynamic {
		// lua objects or what ever
		if (lua_Characters.exists(id))
			return lua_Characters.get(id);

		return null;
	}

	function getCameraByName(id:String):LuaCamera {
		if (lua_Cameras.exists(id))
			return lua_Cameras.get(id);

		switch (id.toLowerCase()) {
			case 'camhud' | 'hud':
				return lua_Cameras.get("hud");
		}

		return lua_Cameras.get("game");
	}

	public static function killShaders() {
		for (cam in lua_Cameras) {
			cam.shaders = [];
			cam.shaderNames = [];
		}
	}

	public function die() {
		PlayState.songMultiplier = oldMultiplier;

		lua_Sprites.clear();
		lua_Characters.clear();
		lua_Shaders.clear();
		lua_Custom_Shaders.clear();
		lua_Cameras.clear();
		lua_Sounds.clear();

		Lua.close(lua);
		lua = null;
	}

	function getLuaErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);

		return v;
	}

	function callLua(func_name:String, args:Array<Dynamic>, ?type:String):Dynamic {
		functions_called.push(func_name);
		var result:Any = null;

		Lua.getglobal(lua, func_name);

		for (arg in args) {
			Convert.toLua(lua, arg);
		}

		result = Lua.pcall(lua, args.length, 1, 0);

		var p = Lua.tostring(lua, result);
		var e = getLuaErrorMessage(lua);

		if (result == null) {
			return null;
		} else {
			return convert(result, type);
		}
	}

	public function setVar(name:String, value:Dynamic):Void {
		Convert.toLua(lua, value);
		Lua.setglobal(lua, name);
	}

	var oldMultiplier:Float = PlayState.songMultiplier;

	public var trails:Map<String, FlxTrail> = [];

	public var extra_scripts:Array<ModchartUtilities> = [];

	public var perlin:Perlin;

	/**
	 * Easy wrapper for `Lua_helper.add_callback`.
	 * @param name Function name
	 * @param func Function to use
	 */
	@:inline function setLuaFunction(name:String, func:Dynamic):Void {
		Lua_helper.add_callback(lua, name, func);
	}

	public function new(path:String) {
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		instance = this;

		oldMultiplier = PlayState.songMultiplier;

		perlin = new Perlin();

		lua_Sprites.set("boyfriend", PlayState.boyfriend);
		lua_Sprites.set("girlfriend", PlayState.gf);
		lua_Sprites.set("dad", PlayState.dad);

		lua_Characters.set("boyfriend", PlayState.boyfriend);
		lua_Characters.set("girlfriend", PlayState.gf);
		lua_Characters.set("dad", PlayState.dad);

		lua_Cameras.set("game", {cam: PlayState.instance.camGame, shaders: [], shaderNames: []});
		lua_Cameras.set("hud", {cam: PlayState.instance.camHUD, shaders: [], shaderNames: []});

		lua_Sounds.set("Inst", FlxG.sound.music);
		@:privateAccess
		lua_Sounds.set("Voices", PlayState.instance.vocals);

		trace('Loading script at path \'${path}\'');
		// trace("lua version: " + Lua.version());
		// trace("LuaJIT version: " + Lua.versionJIT());

		Lua.init_callbacks(lua);

		if (path == null)
			path = #if MODDING_ALLOWED PolymodAssets #else Assets #end.getPath(Paths.lua("modcharts/" + PlayState.SONG.modchartPath));

		var result = LuaL.dofile(lua, path); // execute le file

		if (result != 0) {
			CoolUtil.coolError("Lua ERROR:\n" + Lua.tostring(lua, result), "Leather Engine Modcharts");
			// FlxG.switchState(new MainMenuState());
		}

		// get some fukin globals up in here bois
		setVar("songLower", PlayState.SONG.song.toLowerCase());
		setVar("difficulty", PlayState.storyDifficultyStr);
		setVar("bpm", Conductor.bpm);
		setVar("songBpm", PlayState.SONG.bpm);
		setVar("keyCount", PlayState.SONG.keyCount);
		setVar("playerKeyCount", PlayState.SONG.playerKeyCount);
		setVar("scrollspeed", PlayState.SONG.speed);
		setVar("fpsCap", Options.getData("maxFPS"));
		setVar("opponentPlay", PlayState.characterPlayingAs == 1);
		setVar("bot", Options.getData("botplay"));
		setVar("noDeath", Options.getData("noDeath"));
		setVar("downscroll", Options.getData("downscroll") == true ? 1 : 0); // fuck you compatibility
		setVar("downscrollBool", Options.getData("downscroll"));
		setVar("middlescroll", Options.getData("middlescroll"));
		setVar("flashingLights", Options.getData("flashingLights"));
		setVar("flashing", Options.getData("flashingLights"));
		setVar("distractions", true);
		setVar("cameraZooms", Options.getData("cameraZooms"));
		setVar("shaders", Options.getData("shaders"));

		setVar("animatedBackgrounds", Options.getData("animatedBGs"));
		setVar("charsAndBGs", Options.getData("charsAndBGs"));

		setVar("curStep", 0);
		setVar("curBeat", 0);
		setVar("stepCrochet", Conductor.stepCrochet);
		setVar("crochetUnscaled", Conductor.stepCrochet);
		setVar("crochet", Conductor.crochet);
		setVar("safeZoneOffset", Conductor.safeZoneOffset);

		setVar("hudZoom", PlayState.instance.camHUD.zoom);
		setVar("cameraZoom", FlxG.camera.zoom);

		setVar("cameraAngle", FlxG.camera.angle);
		setVar("camHudAngle", PlayState.instance.camHUD.angle);

		setVar("followXOffset", 0);
		setVar("followYOffset", 0);

		setVar("showOnlyStrums", false);
		setVar("strumLine1Visible", true);
		setVar("strumLine2Visible", true);

		setVar("screenWidth", Application.current.window.display.currentMode.width);
		setVar("screenHeight", Application.current.window.display.currentMode.height);
		setVar("windowWidth", FlxG.width);
		setVar("windowHeight", FlxG.height);

		setVar("hudWidth", PlayState.instance.camHUD.width);
		setVar("hudHeight", PlayState.instance.camHUD.height);

		setVar("mustHit", false);
		setVar("strumLineX", PlayState.instance.strumLine.x);
		setVar("strumLineY", PlayState.instance.strumLine.y);

		setVar("characterPlayingAs", PlayState.characterPlayingAs);
		setVar("inReplay", false);

		setVar("player1", PlayState.SONG.player1);
		setVar("player2", PlayState.SONG.player2);

		setVar("curStage", PlayState.SONG.stage);

		setVar("mobile", FlxG.onMobile);


		setVar("curMod", Options.getData("curMod"));
		setVar("developer", Options.getData("developer"));

		// other globals

		setVar('FlxColor', {
			TRANSPARENT: 0x00000000,
			WHITE: 0xFFFFFFFF,
			GRAY: 0xFF808080,
			BLACK: 0xFF000000,

			GREEN: 0xFF008000,
			LIME: 0xFF00FF00,
			YELLOW: 0xFFFFFF00,
			ORANGE: 0xFFFFA500,
			RED: 0xFFFF0000,
			PURPLE: 0xFF800080,
			BLUE: 0xFF0000FF,
			BROWN: 0xFF8B4513,
			PINK: 0xFFFFC0CB,
			MAGENTA: 0xFFFF00FF,
			CYAN: 0xFF00FFFF,
		});

		setVar("Conductor", {
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
		});

		setVar("FlxG", {
			width: FlxG.width,
			height: FlxG.height,
			elapsed: FlxG.elapsed,
		});

		setVar("FlxMath", {
			EPSILON: FlxMath.EPSILON,
			MAX_VALUE_FLOAT: FlxMath.MAX_VALUE_FLOAT,
			MAX_VALUE_INT: FlxMath.MAX_VALUE_INT,
			MIN_VALUE_FLOAT: FlxMath.MIN_VALUE_FLOAT,
			MIN_VALUE_INT: FlxMath.MIN_VALUE_INT,
			SQUARE_ROOT_OF_TWO: FlxMath.SQUARE_ROOT_OF_TWO,
		});

		setVar("Math", {
			NEGATIVE_INFINITY: Math.NEGATIVE_INFINITY,
			NaN: Math.NaN,
			PI: Math.PI,
			POSITIVE_INFINITY: Math.NEGATIVE_INFINITY,
		});

		setVar("lua", {
			version: Lua.version(),
			versionJIT: Lua.versionJIT(),
		});

		setVar("SONG", PlayState.SONG);

		setVar("leatherEngine", {
			version: CoolUtil.getCurrentVersion().replace('v', ''),
			path: Sys.programPath(),
			cwd: Sys.getCwd(),
			systemName: Sys.systemName(),
		});

		setVar("version", CoolUtil.getCurrentVersion().replace('v', ''));

		// callbacks
		setLuaFunction("trace", function(str:Dynamic = "", ?printType:String = "LOG") {
			trace(str, Logs.printTypeFromSting(printType));
		});

		setLuaFunction("print", function(str:Dynamic = "", ?printType:String = "LOG") {
			trace(str, Logs.printTypeFromSting(printType));
		});

		setLuaFunction("flashCamera", function(camera:String = "", color:String = "#FFFFFF", time:Float = 1, force:Bool = false) {
			if (Options.getData("flashingLights"))
				cameraFromString(camera).flash(FlxColor.fromString(color), time, null, force);
		});

		setLuaFunction("fadeCamera", function(camera:String = "", color:String = "#FFFFFF", time:Float = 1, fadeIn:Bool = false, force:Bool = false) {
			if (Options.getData("flashingLights"))
				cameraFromString(camera).fade(FlxColor.fromString(color), time, fadeIn, null, force);
		});

		setLuaFunction("triggerEvent", function(event_name:String, argument_1:Dynamic, argument_2:Dynamic) {
			var string_arg_1:String = Std.string(argument_1);
			var string_arg_2:String = Std.string(argument_2);

			if (!PlayState.instance.event_luas.exists(event_name.toLowerCase())
				&& Assets.exists(Paths.lua("event data/" + event_name.toLowerCase()))) {
				PlayState.instance.event_luas.set(event_name.toLowerCase(),
					new ModchartUtilities(#if MODDING_ALLOWED PolymodAssets #else Assets #end.getPath(Paths.lua("event data/" + event_name.toLowerCase()))));
				PlayState.instance.generatedSomeDumbEventLuas = true;
			}

			PlayState.instance.processEvent([event_name, Conductor.songPosition, string_arg_1, string_arg_2]);
		});

		setLuaFunction("addCharacterToMap", function(m:String, character:String) {
			var map:Map<String, Dynamic>;

			switch (m.toLowerCase()) {
				case "dad" | "opponent" | "player2" | "1":
					map = PlayState.instance.dadMap;
				case "gf" | "girlfriend" | "player3" | "2":
					map = PlayState.instance.gfMap;
				default:
					map = PlayState.instance.bfMap;
			}
			var funnyCharacter:Character;

			if (map == PlayState.instance.bfMap)
				funnyCharacter = new Boyfriend(100, 100, character);
			else
				funnyCharacter = new Character(100, 100, character);

			funnyCharacter.alpha = 0.00001;
			PlayState.instance.add(funnyCharacter);

			map.set(character, funnyCharacter);

			if (funnyCharacter.otherCharacters != null) {
				for (character in funnyCharacter.otherCharacters) {
					character.alpha = 0.00001;
					PlayState.instance.add(character);
				}
			}
		});

		setLuaFunction("setCamera", function(id:String, camera:String = "") {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				Reflect.setProperty(actor, "cameras", [cameraFromString(camera)]);
		});

		setLuaFunction("setObjectCamera", function(id:String, camera:String = "") {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				Reflect.setProperty(actor, "cameras", [cameraFromString(camera)]);
		});

		setLuaFunction("justPressedDodgeKey", function() {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
			if (gamepad != null) {
				if (gamepad.checkStatus(FlxGamepadInputID.fromString("SPACE"), FlxInputState.JUST_PRESSED)) {
					return true;
				}
			}
			return FlxG.keys.checkStatus(FlxKey.fromString("SPACE"), FlxInputState.JUST_PRESSED);
		});

		setLuaFunction("justPressed", function(key:String = "SPACE") {
			return Reflect.getProperty(FlxG.keys.justPressed, key);
		});

		setLuaFunction("pressed", function(key:String = "SPACE") {
			return Reflect.getProperty(FlxG.keys.pressed, key);
		});

		setLuaFunction("justReleased", function(key:String = "SPACE") {
			return Reflect.getProperty(FlxG.keys.justReleased, key);
		});

		setLuaFunction("setGraphicSize", function(id:String, width:Int = 0, height:Int = 0) {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.setGraphicSize(width, height);
		});

		setLuaFunction("updateHitbox", function(id:String) {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.updateHitbox();
		});

		setLuaFunction("setBlendMode", function(id:String, blend:String = '') {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.blend = blendModeFromString(blend);
		});

		setLuaFunction("getSingDirectionID", function(id:Int) {
			var thing = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
			var singDir = NoteVariables.Character_Animation_Arrays[PlayState.SONG.playerKeyCount - 1][Std.int(Math.abs(id % PlayState.SONG.playerKeyCount))];
			return thing.indexOf(singDir);
		});

		// sprites

		// stage

		setLuaFunction("makeStageSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);
				@:privateAccess
				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.image(PlayState.instance.stage.stage + "/" + filename, "stages"));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.antialiasing = Options.getData("antialiasing");
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				@:privateAccess
				PlayState.instance.stage.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeStageAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);
				@:privateAccess
				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.antialiasing = Options.getData("antialiasing");
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				@:privateAccess
				PlayState.instance.stage.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeStageDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);
					@:privateAccess
					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

					Sprite.scale.set(size, sizeY == null ? size : sizeY);
					Sprite.antialiasing = Options.getData("antialiasing");
					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);

					@:privateAccess
					PlayState.instance.stage.add(Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		// regular

		setLuaFunction("makeGraphic", function(id:String, width:Int, height:Int, color:String) {
			if (getActorByName(id) != null)
				getActorByName(id).makeGraphic(width, height, FlxColor.fromString(color));
		});

		setLuaFunction("makeGraphicRGB", function(id:String, width:Int, height:Int, color:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).visible = true;
				var colors = color.split(',');
				var red = Std.parseInt(colors[0]);
				var green = Std.parseInt(colors[1]);
				var blue = Std.parseInt(colors[2]);
				getActorByName(id).makeGraphic(width, height, FlxColor.fromRGB(red, green, blue));
			}
		});

		setLuaFunction("exists", function(id:String):Bool {
			if (getActorByName(id) != null)
				return Reflect.getProperty(getActorByName(id), 'exists') != true ? false : true;

			return false;
		});

		setLuaFunction("color", function(r:Int, g:Int, b:Int, a:Int = 255):Int {
			return FlxColor.fromRGB(r, g, b, a);
		});

		setLuaFunction("colorString", function(color:String):Int {
			return FlxColor.fromString(color);
		});

		setLuaFunction("colorRGB", function(r:Int, g:Int, b:Int):Int {
			return FlxColor.fromRGB(r, g, b);
		});

		setLuaFunction("colorRGBA", function(r:Int, g:Int, b:Int, a:Int):Int {
			return FlxColor.fromRGB(r, g, b, a);
		});

		setLuaFunction("rgbToHsv", function(r:Int, g:Int, b:Int):Array<Int> {
			return CoolUtil.rgbToHsv(r, g, b);
		});

		setLuaFunction("dominantColor", function(id:String):Int {
			if (getActorByName(id) != null)
				return CoolUtil.dominantColor(getActorByName(id));
			return 0;
		});

		setLuaFunction("dominantColorFrame", function(id:String):Int {
			if (getActorByName(id) != null)
				return CoolUtil.dominantColorFrame(getActorByName(id));
			return 0;
		});

		// sprite functions

		setLuaFunction("screenCenter", function(id:String, ?direction:String = "xy") {
			if (getActorByName(id) != null)
				getActorByName(id).screenCenter((direction.toLowerCase().contains('x') ? 0x01 : 0x00) + (direction.toLowerCase().contains('y') ? 0x10 : 0x00));
		});

		setLuaFunction("center", function(id:String, ?direction:String = "xy") {
			if (getActorByName(id) != null)
				getActorByName(id).screenCenter((direction.toLowerCase().contains('x') ? 0x01 : 0x00) + (direction.toLowerCase().contains('y') ? 0x10 : 0x00));
		});

		setLuaFunction("actorScreenCenter", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].screenCenter();
					return;
				}
			}
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				actor.screenCenter();
			}
		});

		setLuaFunction("add", function(id:String) {
			FlxG.state.add(getActorByName(id));
		});

		setLuaFunction("remove", function(id:String, splice:Bool = true) {
			FlxG.state.remove(getActorByName(id), splice);
		});

		setLuaFunction("kill", function(id:String) {
			getActorByName(id).kill();
		});

		setLuaFunction("destroy", function(id:String) {
			getActorByName(id).destroy();
		});

		setLuaFunction("insert", function(id:String, position:Int) {
			FlxG.state.insert(position, getActorByName(id));
		});

		// stage sprite functions

		setLuaFunction("addStage", function(id:String) {
			PlayState.instance.stage.add(getActorByName(id));
		});

		setLuaFunction("removeStage", function(id:String, splice:Bool = true) {
			PlayState.instance.stage.remove(getActorByName(id), splice);
		});

		setLuaFunction("insertStage", function(id:String, position:Int) {
			PlayState.instance.stage.insert(position, getActorByName(id));
		});

		setLuaFunction("setActorTextColor", function(id:String, color:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "color", FlxColor.fromString(color));
		});

		setLuaFunction("setActorText", function(id:String, text:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "text", text);
		});

		setLuaFunction("setActorFont", function(id:String, font:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "font", Paths.font(font));
		});

		setLuaFunction("setActorOutlineColor", function(id:String, color:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "borderColor", FlxColor.fromString(color));
		});

		setLuaFunction("setActorAlignment", function(id:String, align:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "alignment", align);
		});

		setLuaFunction("makeText", function(id:String, text:String, x:Float, y:Float, size:Int = 32, font:String = "vcr.ttf", fieldWidth:Float = 0) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxTextFix = new FlxTextFix(x, y, fieldWidth, text, size);
				Sprite.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
				// Sprite.setFormat(Paths.font(font), size);
				Sprite.font = Paths.font(font);
				Sprite.antialiasing = true;

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("newText", function(id:String, text:String, x:Float, y:Float, size:Int = 32, font:String = "vcr.ttf", fieldWidth:Float = 0) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxText = new FlxText(x, y, fieldWidth, text, size);
				Sprite.font = Paths.font(font);

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("newSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.image(filename));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.antialiasing = Options.getData("antialiasing");
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("newSpriteCopy", function(id:String, targetID:String) {
			var actor:FlxSprite = null;
			if (getCharacterByName(targetID) != null) {
				var character = getCharacterByName(targetID);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					actor = character.otherCharacters[0];
				}
			}
			if (getActorByName(targetID) != null && actor == null)
				actor = getActorByName(targetID);

			if (!lua_Sprites.exists(id) && actor != null) {
				var Sprite:FlxSprite = new FlxSprite(actor.x, actor.y);

				Sprite.loadGraphicFromSprite(actor);

				Sprite.alpha = actor.alpha;
				Sprite.angle = actor.angle;
				Sprite.offset.x = actor.offset.x;
				Sprite.offset.y = actor.offset.y;
				Sprite.origin.x = actor.origin.x;
				Sprite.origin.y = actor.origin.y;
				Sprite.scale.x = actor.scale.x;
				Sprite.scale.y = actor.scale.y;
				Sprite.active = false;
				Sprite.animation.frameIndex = actor.animation.frameIndex;
				Sprite.flipX = actor.flipX;
				Sprite.flipY = actor.flipY;
				Sprite.animation.curAnim = actor.animation.curAnim;
				// trace('made sprite copy');
				lua_Sprites.set(id, Sprite);
			}
		});

		setLuaFunction("newAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(filename);

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.antialiasing = Options.getData("antialiasing");
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("newDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(filename);

					Sprite.scale.set(size, sizeY == null ? size : sizeY);
					Sprite.antialiasing = Options.getData("antialiasing");
					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		setLuaFunction("makeSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.image(filename));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.antialiasing = Options.getData("antialiasing");
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeSpriteCopy", function(id:String, targetID:String) {
			var actor:FlxSprite = null;
			if (getCharacterByName(targetID) != null) {
				var character = getCharacterByName(targetID);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					actor = character.otherCharacters[0];
				}
			}
			if (getActorByName(targetID) != null && actor == null)
				actor = getActorByName(targetID);

			if (!lua_Sprites.exists(id) && actor != null) {
				var Sprite:FlxSprite = new FlxSprite(actor.x, actor.y);

				Sprite.loadGraphicFromSprite(actor);

				Sprite.alpha = actor.alpha;
				Sprite.angle = actor.angle;
				Sprite.offset.x = actor.offset.x;
				Sprite.offset.y = actor.offset.y;
				Sprite.origin.x = actor.origin.x;
				Sprite.origin.y = actor.origin.y;
				Sprite.scale.x = actor.scale.x;
				Sprite.scale.y = actor.scale.y;
				Sprite.active = false;
				Sprite.animation.frameIndex = actor.animation.frameIndex;
				Sprite.flipX = actor.flipX;
				Sprite.flipY = actor.flipY;
				Sprite.animation.curAnim = actor.animation.curAnim;
				// trace('made sprite copy');
				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			}
		});

		setLuaFunction("makeAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(filename);

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.antialiasing = Options.getData("antialiasing");
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(filename);

					Sprite.scale.set(size, sizeY == null ? size : sizeY);
					Sprite.antialiasing = Options.getData("antialiasing");
					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);

					PlayState.instance.add(Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		setLuaFunction("destroySprite", function(id:String) {
			var sprite = lua_Sprites.get(id);

			if (sprite == null)
				return false;

			lua_Sprites.remove(id);

			PlayState.instance.remove(sprite);
			sprite.kill();
			sprite.destroy();

			return true;
		});

		setLuaFunction("getIsColliding", function(sprite1Name:String, sprite2Name:String) {
			var sprite1 = getActorByName(sprite1Name);

			if (sprite1 != null) {
				var sprite2 = getActorByName(sprite2Name);

				if (sprite2 != null)
					return sprite1.overlaps(sprite2);
			}

			return false;
		});

		setLuaFunction("addActorTrail", function(id:String, length:Int = 10, delay:Int = 3, alpha:Float = 0.4, diff:Float = 0.05) {
			if (!trails.exists(id) && getActorByName(id) != null) {
				var trail = new FlxTrail(getActorByName(id), null, length, delay, alpha, diff);

				PlayState.instance.insert(PlayState.instance.members.indexOf(getActorByName(id)) - 1, trail);

				trails.set(id, trail);
			} else
				trace("Trail " + id + " already exists (or actor is null)!!!");
		});

		setLuaFunction("removeActorTrail", function(id:String) {
			if (trails.exists(id)) {
				PlayState.instance.remove(trails.get(id));

				trails.get(id).destroy();
				trails.remove(id);
			} else
				trace("Trail " + id + " doesn't exist!!!");
		});

		setLuaFunction("getActorLayer", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					return PlayState.instance.members.indexOf(character.otherCharacters[0]);
				}
			}
			var actor = getActorByName(id);

			if (actor != null)
				return PlayState.instance.members.indexOf(actor);
			else
				return -1;
		});

		setLuaFunction("setActorLayer", function(id:String, layer:Int) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					PlayState.instance.remove(character.otherCharacters[0]);
					PlayState.instance.insert(layer, character.otherCharacters[0]);
					return;
				}
			}
			var actor = getActorByName(id);

			if (actor != null) {
				if (trails.exists(id)) {
					PlayState.instance.remove(trails.get(id));
					PlayState.instance.insert(layer - 1, trails.get(id));
				}

				PlayState.instance.remove(actor);
				PlayState.instance.insert(layer, actor);
			}
		});

		// health

		setLuaFunction("getHealth", function() {
			return PlayState.instance.health;
		});

		setLuaFunction("setHealth", function(heal:Float) {
			PlayState.instance.health = heal;
		});

		setLuaFunction("getMinHealth", function() {
			return PlayState.instance.minHealth;
		});

		setLuaFunction("getMaxHealth", function() {
			return PlayState.instance.maxHealth;
		});

		setLuaFunction('changeHealthRange', function(minHealth:Float, maxHealth:Float) {
			@:privateAccess
			{
				var bar = PlayState.instance.healthBar;
				PlayState.instance.minHealth = minHealth;
				PlayState.instance.maxHealth = maxHealth;
				bar.setRange(minHealth, maxHealth);
			}
		});

		// hud/camera

		setLuaFunction("setHudAngle", function(angle:Float) {
			PlayState.instance.camHUD.angle = angle;
		});

		setLuaFunction("setHudPosition", function(x:Int, y:Int) {
			PlayState.instance.camHUD.x = x;
			PlayState.instance.camHUD.y = y;
		});

		setLuaFunction("getHudX", function() {
			return PlayState.instance.camHUD.x;
		});

		setLuaFunction("getHudY", function() {
			return PlayState.instance.camHUD.y;
		});

		setLuaFunction("makeCamera", function(camStr:String) {
			var newCam:FlxCamera = new FlxCamera();
			newCam.bgColor.alpha = 0;
			PlayState.instance.reorderCameras(newCam);
			lua_Cameras.set(camStr, {cam: newCam, shaders: [], shaderNames: []});
			PlayState.instance.usedLuaCameras = true;
		});

		setLuaFunction("setNoteCameras", function(camStr:String) {
			var cameras = camStr.split(',');
			var camList:Array<FlxCamera> = [];
			for (c in cameras) {
				var cam = getCameraByName(c);
				if (cam != null)
					camList.push(cam.cam);
			}
			if (camList.length > 0) {
				PlayState.strumLineNotes.cameras = camList;
				PlayState.instance.notes.cameras = camList;
			}
		});

		setLuaFunction("setObjectCameras", function(id:String, camStr:String) {
			var cameras = camStr.split(',');
			var actor:FlxSprite = getActorByName(id);
			var camList:Array<FlxCamera> = [];
			for (c in cameras) {
				var cam = getCameraByName(c);
				if (cam != null)
					camList.push(cam.cam);
			}
			if (camList.length > 0) {
				if (actor != null)
					Reflect.setProperty(actor, "cameras", camList);
			}
		});

		setLuaFunction("getCameraScrollX", function(camStr:String) {
			var cam = getCameraByName(camStr);
			if (cam != null) {
				return cam.cam.scroll.x;
			}
			return 0.0;
		});

		setLuaFunction("getCameraScrollY", function(camStr:String) {
			var cam = getCameraByName(camStr);
			if (cam != null) {
				return cam.cam.scroll.y;
			}
			return 0.0;
		});

		setLuaFunction("setCamPosition", function(x:Int, y:Int) {
			@:privateAccess
			{
				PlayState.instance.camFollow.x = x;
				PlayState.instance.camFollow.y = y;
			}
		});

		setLuaFunction("getCameraX", function() {
			@:privateAccess
			return PlayState.instance.camFollow.x;
		});

		setLuaFunction("getCameraY", function() {
			@:privateAccess
			return PlayState.instance.camFollow.y;
		});

		setLuaFunction("getCamZoom", function() {
			return FlxG.camera.zoom;
		});

		setLuaFunction("getHudZoom", function() {
			return PlayState.instance.camHUD.zoom;
		});

		setLuaFunction("setCamZoom", function(zoomAmount:Float) {
			FlxG.camera.zoom = zoomAmount;
		});

		setLuaFunction("setHudZoom", function(zoomAmount:Float) {
			PlayState.instance.camHUD.zoom = zoomAmount;
		});

		// strumline

		setLuaFunction("setStrumlineX", function(x:Float, ?dontMove:Bool = false) {
			PlayState.instance.strumLine.x = x;

			if (!dontMove) {
				for (note in PlayState.strumLineNotes) {
					note.x = x;
				}
			}
		});

		setLuaFunction("setStrumlineY", function(y:Float, ?dontMove:Bool = false) {
			PlayState.instance.strumLine.y = y;

			if (!dontMove) {
				for (note in PlayState.strumLineNotes) {
					note.y = y;
				}
			}
		});

		// actors

		setLuaFunction("getNoteProperty", function(note:Note, property:String):Dynamic {
			return Reflect.getProperty(note, property);
		});

		setLuaFunction("makeNoteCopy", function(id:String, noteIdx:Int) {
			var actor:FlxSprite = PlayState.instance.notes.members[noteIdx];

			if (!lua_Sprites.exists(id) && actor != null) {
				var Sprite:FlxSprite = new FlxSprite(actor.x, actor.y);

				Sprite.loadGraphicFromSprite(actor);

				Sprite.alpha = actor.alpha;
				Sprite.angle = actor.angle;
				Sprite.offset.x = actor.offset.x;
				Sprite.offset.y = actor.offset.y;
				Sprite.origin.x = actor.origin.x;
				Sprite.origin.y = actor.origin.y;
				Sprite.scale.x = actor.scale.x;
				Sprite.scale.y = actor.scale.y;
				Sprite.active = false;
				Sprite.animation.frameIndex = actor.animation.frameIndex;
				Sprite.flipX = actor.flipX;
				Sprite.flipY = actor.flipY;
				Sprite.animation.curAnim = actor.animation.curAnim;
				// trace('made sprite copy');
				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			}
		});

		setLuaFunction("getUnspawnNotes", function() {
			return PlayState.instance.unspawnNotes.length;
		});

		setLuaFunction("getUnspawnedNoteNoteType", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].arrow_Type;
		});

		setLuaFunction("getUnspawnedNoteArrowType", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].arrow_Type;
		});

		setLuaFunction("getUnspawnedNoteStrumtime", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].strumTime;
		});

		setLuaFunction("getUnspawnedNoteMustPress", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].mustPress;
		});

		setLuaFunction("getUnspawnedNoteSustainNote", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].isSustainNote;
		});

		setLuaFunction("getUnspawnedNoteNoteData", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].noteData;
		});

		setLuaFunction("getUnspawnedNoteData", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].noteData;
		});

		setLuaFunction("getUnspawnedNoteScaleX", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].scale.x;
		});

		setLuaFunction("getUnspawnedNoteScaleY", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].scale.y;
		});

		setLuaFunction("getUnspawnedNoteSingAnimPrefix", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].singAnimPrefix;
		});

		setLuaFunction("setUnspawnedNoteSingAnimPrefix", function(id:Int, prefix:String) {
			PlayState.instance.unspawnNotes[id].singAnimPrefix = prefix;
		});

		setLuaFunction("setUnspawnedNoteXOffset", function(id:Int, offset:Float) {
			PlayState.instance.unspawnNotes[id].xOffset = offset;
		});

		setLuaFunction("setUnspawnedNoteYOffset", function(id:Int, offset:Float) {
			PlayState.instance.unspawnNotes[id].yOffset = offset;
		});

		setLuaFunction("setUnspawnedNoteAngle", function(id:Int, offset:Float) {
			PlayState.instance.unspawnNotes[id].localAngle = offset;
		});

		setLuaFunction("getRenderedNotes", function() {
			return PlayState.instance.notes.length;
		});

		setLuaFunction("getRenderedNoteX", function(id:Int) {
			return PlayState.instance.notes.members[id].x;
		});

		setLuaFunction("getRenderedNoteY", function(id:Int) {
			return PlayState.instance.notes.members[id].y;
		});

		setLuaFunction("getRenderedNoteType", function(id:Int) {
			return PlayState.instance.notes.members[id].noteData;
		});

		setLuaFunction("getRenderedNoteData", function(id:Int) {
			return PlayState.instance.notes.members[id].noteData;
		});

		setLuaFunction("getRenderedNoteArrowType", function(id:Int) {
			return PlayState.instance.notes.members[id].arrow_Type;
		});

		setLuaFunction("getRenderedNoteParentX", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.x;
		});

		setLuaFunction("getRenderedNoteParentY", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.y;
		});

		setLuaFunction("getRenderedNoteHit", function(id:Int) {
			return PlayState.instance.notes.members[id].mustPress;
		});

		setLuaFunction("getRenderedNoteCalcX", function(id:Int) {
			if (PlayState.instance.notes.members[id].mustPress)
				return PlayState.playerStrums.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;

			return PlayState.strumLineNotes.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
		});

		setLuaFunction("getRenderedNoteStrumtime", function(id:Int) {
			return PlayState.instance.notes.members[id].strumTime;
		});

		setLuaFunction("getRenderedNoteScaleX", function(id:Int) {
			return PlayState.instance.notes.members[id].scale.x;
		});

		setLuaFunction("getRenderedNoteScaleY", function(id:Int) {
			return PlayState.instance.notes.members[id].scale.y;
		});

		setLuaFunction("setRenderedNotePos", function(x:Float, y:Float, id:Int) {
			if (PlayState.instance.notes.members[id] == null)
				throw('error! you cannot set a rendered notes position when it doesnt exist! ID: ' + id);
			else {
				PlayState.instance.notes.members[id].x = x;
				PlayState.instance.notes.members[id].y = y;
			}
		});

		setLuaFunction("setRenderedNoteAlpha", function(alpha:Float, id:Int) {
			PlayState.instance.notes.members[id].alpha = alpha;
		});

		setLuaFunction("setRenderedNoteScale", function(scale:Float, id:Int) {
			PlayState.instance.notes.members[id].setGraphicSize(Std.int(PlayState.instance.notes.members[id].width * scale));
		});

		setLuaFunction("setRenderedNoteScale", function(scaleX:Int, scaleY:Int, id:Int) {
			PlayState.instance.notes.members[id].setGraphicSize(scaleX, scaleY);
		});

		setLuaFunction("setRenderedNoteScaleX", function(scale:Float, id:Int) {
			PlayState.instance.notes.members[id].scale.x = scale;
		});

		setLuaFunction("setRenderedNoteScaleY", function(scale:Float, id:Int) {
			PlayState.instance.notes.members[id].scale.y = scale;
		});

		setLuaFunction("setRenderedNoteScaleXY", function(scaleX:Int, scaleY:Int, id:Int) {
			PlayState.instance.notes.members[id].scale.set(scaleX, scaleY);
		});

		setLuaFunction("isRenderedNoteSustainEnd", function(id:Int) {
			if (PlayState.instance.notes.members[id].animation.curAnim != null)
				return PlayState.instance.notes.members[id].animation.curAnim.name.endsWith('end');
			return false;
		});

		setLuaFunction("getRenderedNoteSustainScaleY", function(id:Int) {
			return PlayState.instance.notes.members[id].sustainScaleY;
		});

		setLuaFunction("getRenderedNoteOffsetX", function(id:Int) {
			var daNote:Note = PlayState.instance.notes.members[id];
			if (daNote.mustPress) {
				var arrayVal = Std.string([daNote.noteData, daNote.arrow_Type, daNote.isSustainNote]);
				if (PlayState.instance.prevPlayerXVals.exists(arrayVal))
					return PlayState.instance.prevPlayerXVals.get(arrayVal) - daNote.xOffset;
			} else {
				var arrayVal = Std.string([daNote.noteData, daNote.arrow_Type, daNote.isSustainNote]);
				if (PlayState.instance.prevEnemyXVals.exists(arrayVal))
					return PlayState.instance.prevEnemyXVals.get(arrayVal) - daNote.xOffset;
			}

			return 0;
		});

		setLuaFunction("getRenderedNoteOffsetY", function(id:Int) {
			var daNote:Note = PlayState.instance.notes.members[id];
			return daNote.yOffset;
		});

		setLuaFunction("getRenderedNoteWidth", function(id:Int) {
			return PlayState.instance.notes.members[id].width;
		});

		setLuaFunction("getRenderedNoteHeight", function(id:Int) {
			return PlayState.instance.notes.members[id].height;
		});

		setLuaFunction("getRenderedNotePrevNoteStrumtime", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNoteStrumtime;
		});

		setLuaFunction("setRenderedNoteAngle", function(angle:Float, id:Int) {
			PlayState.instance.notes.members[id].modAngle = angle;
		});

		setLuaFunction("isSustain", function(id:Int) {
			return PlayState.instance.notes.members[id].isSustainNote;
		});

		setLuaFunction("isParentSustain", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.isSustainNote;
		});

		setLuaFunction("anyNotes", function() {
			return PlayState.instance.notes.members.length != 0;
		});

		setLuaFunction("setActorPos", function(x:Float, y:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].x = x;
					character.otherCharacters[0].y = y;
					return;
				}
			}
			var actor = getActorByName(id);

			if (actor != null) {
				actor.x = x;
				actor.y = y;
			}
		});

		setLuaFunction("setActorScroll", function(x:Float, y:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].scrollFactor.set(x, y);
					return;
				}
			}
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				actor.scrollFactor.set(x, y);
			}
		});

		setLuaFunction("setActorX", function(x:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].x = x;
					return;
				}
			}
			if (getActorByName(id) != null)
				getActorByName(id).x = x;
		});

		setLuaFunction("getOriginalCharX", function(character:Int) {
			@:privateAccess
			return PlayState.instance.stage.getCharacterPos(character)[0];
		});

		setLuaFunction("getOriginalCharY", function(character:Int) {
			@:privateAccess
			return PlayState.instance.stage.getCharacterPos(character)[1];
		});

		setLuaFunction("setActorAccelerationX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).acceleration.x = x;
			}
		});

		setLuaFunction("setActorDragX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).drag.x = x;
			}
		});

		setLuaFunction("setActorVelocityX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).velocity.x = x;
			}
		});

		setLuaFunction("setActorOriginX", function(x:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].origin.x = x;
					return;
				}
			}
			if (getActorByName(id) != null)
				getActorByName(id).origin.x = x;
		});

		setLuaFunction("setActorOriginY", function(x:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].origin.y = x;
					return;
				}
			}
			if (getActorByName(id) != null)
				getActorByName(id).origin.y = x;
		});

		setLuaFunction("setActorAntialiasing", function(antialiasing:Bool, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).antialiasing = antialiasing;
			}
		});

		setLuaFunction("addActorAnimation", function(id:String, prefix:String, anim:String, fps:Int = 30, looped:Bool = true) {
			if (getActorByName(id) != null) {
				getActorByName(id).animation.addByPrefix(prefix, anim, fps, looped);
			}
		});

		setLuaFunction("addActorAnimationIndices", function(id:String, prefix:String, indiceString:String, anim:String, fps:Int = 30, looped:Bool = true) {
			if (getActorByName(id) != null) {
				var indices:Array<Dynamic> = indiceString.split(",");

				for (indiceIndex in 0...indices.length) {
					indices[indiceIndex] = Std.parseInt(indices[indiceIndex]);
				}

				getActorByName(id).animation.addByIndices(anim, prefix, indices, "", fps, looped);
			}
		});

		setLuaFunction("playCharAnim", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).playAnim(anim, force, reverse, frame);
			}
		});

		setLuaFunction("playAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).animation.play(anim, force, reverse, frame);
			}
		});

		setLuaFunction("dance", function(id:String, ?altAnim:String = '') {
			if (getActorByName(id) != null) {
				getActorByName(id).dance(altAnim);
			}
		});

		setLuaFunction("playActorAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].animation.play(anim, force, reverse, frame);
					return;
				}
			}
			if (getActorByName(id) != null) {
				getActorByName(id).animation.play(anim, force, reverse, frame);
			}
		});

		setLuaFunction("playActorDance", function(id:String, ?altAnim:String = '') {
			if (getActorByName(id) != null) {
				getActorByName(id).dance(altAnim);
			}
		});

		setLuaFunction("playCharacterAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).playAnim(anim, force, reverse, frame);
			}
		});

		setLuaFunction("setCharacterShouldDance", function(id:String, shouldDance:Bool = true) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].shouldDance = shouldDance;
					return;
				}
			}
			if (getActorByName(id) != null) {
				getActorByName(id).shouldDance = shouldDance;
			}
		});
		setLuaFunction("setCharacterPlayFullAnim", function(id:String, playFullAnim:Bool = true) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].playFullAnim = playFullAnim;
					return;
				}
			}
			if (getActorByName(id) != null) {
				getActorByName(id).playFullAnim = playFullAnim;
			}
		});

		setLuaFunction("setCharacterSingPrefix", function(id:String, prefix:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].singAnimPrefix = prefix;
					return;
				}
			}
			if (getActorByName(id) != null) {
				getActorByName(id).singAnimPrefix = prefix;
			}
		});

		setLuaFunction("setCharacterPreventDanceForAnim", function(id:String, preventDanceForAnim:Bool = true) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].preventDanceForAnim = preventDanceForAnim;
					return;
				}
			}
			if (getActorByName(id) != null) {
				getActorByName(id).preventDanceForAnim = preventDanceForAnim;
			}
		});

		setLuaFunction("playCharacterDance", function(id:String, ?altAnim:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].dance(altAnim);
					return;
				}
			}
			if (getActorByName(id) != null)
				getActorByName(id).dance(altAnim);
		});

		setLuaFunction("getPlayingActorAnimation", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0)
					return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(character.otherCharacters[0], "animation"), "curAnim"), "name");
			}
			if (getActorByName(id) != null) {
				if (Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim") != null)
					return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim"), "name");
			}

			return "unknown";
		});

		setLuaFunction("getPlayingActorAnimationFrame", function(id:String) {
			if (getActorByName(id) != null) {
				if (Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim") != null)
					return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim"), "curFrame");
			}

			return 0;
		});

		setLuaFunction("setActorAlpha", function(alpha:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "alpha", alpha);
					return;
				}
			}
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "alpha", alpha);
		});

		setLuaFunction("setActorVisible", function(visible:Bool, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					character.otherCharacters[0].visible = visible;
					return;
				}
			}
			if (getActorByName(id) != null)
				getActorByName(id).visible = visible;
		});

		setLuaFunction("setActorColor", function(id:String, r:Int, g:Int, b:Int, alpha:Int = 255) {
			if (getActorByName(id) != null) {
				Reflect.setProperty(getActorByName(id), "color", FlxColor.fromRGB(r, g, b, alpha));
			}
		});

		setLuaFunction("setActorColorRGB", function(id:String, color:String) {
			var actor:FlxSprite = getActorByName(id);

			var colors = color.split(',');
			var red = Std.parseInt(colors[0]);
			var green = Std.parseInt(colors[1]);
			var blue = Std.parseInt(colors[2]);

			if (actor != null)
				Reflect.setProperty(actor, "color", FlxColor.fromRGB(red, green, blue));
		});

		setLuaFunction("setActorY", function(y:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "y", y);
					return;
				}
			}
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "y", y);
		});

		setLuaFunction("setActorAccelerationY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).acceleration.y = y;
			}
		});

		setLuaFunction("setActorDragY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).drag.y = y;
			}
		});

		setLuaFunction("setActorVelocityY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).velocity.y = y;
			}
		});

		setLuaFunction("setActorAngle", function(angle:Float, id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "angle", angle);
					return;
				}
			}
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "angle", angle);
		});

		setLuaFunction("setActorModAngle", function(angle:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).modAngle = angle;
		});

		setLuaFunction("setActorScale", function(scale:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scale));
		});

		setLuaFunction("setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scaleX), Std.int(getActorByName(id).height * scaleY));
		});

		setLuaFunction("setActorFlipX", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).flipX = flip;
		});

		setLuaFunction("setActorFlipY", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).flipY = flip;
		});

		setLuaFunction("getActorFlipX", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).flipX;
			return false;
		});

		setLuaFunction("getActorFlipY", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).flipY;
			return false;
		});

		setLuaFunction("setActorTrailVisible", function(id:String, visibleVal:Bool) {
			var char = getCharacterByName(id);

			if (char != null) {
				if (char.coolTrail != null) {
					char.coolTrail.visible = visibleVal;
					return true;
				} else
					return false;
			} else
				return false;
		});

		setLuaFunction("getActorTrailVisible", function(id:String) {
			var char = getCharacterByName(id);

			if (char != null) {
				if (char.coolTrail != null)
					return char.coolTrail.visible;
				else
					return false;
			} else
				return false;
		});

		setLuaFunction("getActorWidth", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					return character.otherCharacters[0].width;
				}
			}
			if (getActorByName(id) != null)
				return getActorByName(id).width;
			else
				return 0;
		});

		setLuaFunction("getActorHeight", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					return character.otherCharacters[0].height;
				}
			}
			if (getActorByName(id) != null)
				return getActorByName(id).height;
			else
				return 0;
		});

		setLuaFunction("getActorAlpha", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					return character.otherCharacters[0].alpha;
				}
			}
			if (getActorByName(id) != null)
				return getActorByName(id).alpha;
			else
				return 0.0;
		});

		setLuaFunction("getActorAngle", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					return character.otherCharacters[0].angle;
				}
			}
			if (getActorByName(id) != null)
				return getActorByName(id).angle;
			else
				return 0.0;
		});

		setLuaFunction("getActorX", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					return character.otherCharacters[0].x;
				}
			}
			if (getActorByName(id) != null)
				return getActorByName(id).x;
			else
				return 0.0;
		});

		setLuaFunction("getActorY", function(id:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					return character.otherCharacters[0].y;
				}
			}
			if (getActorByName(id) != null)
				return getActorByName(id).y;
			else
				return 0.0;
		});

		setLuaFunction("setActorReflection", function(id:String, r:Bool) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					for (i in 0...character.otherCharacters.length)
						character.otherCharacters[i].drawReflection = r;
					return;
				}
			}
			Reflect.setProperty(getActorByName(id), "drawReflection", r);
		});

		setLuaFunction("setActorReflectionYOffset", function(id:String, y:Float) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "reflectionYOffset", y);
					return;
				}
			}
			Reflect.setProperty(getActorByName(id), "reflectionYOffset", y);
		});

		setLuaFunction("setActorReflectionAlpha", function(id:String, a:Float) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "reflectionAlpha", a);
					return;
				}
			}
			Reflect.setProperty(getActorByName(id), "reflectionAlpha", a);
		});

		setLuaFunction("setActorReflectionColor", function(id:String, color:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "reflectionColor", FlxColor.fromString(color));
					return;
				}
			}
			Reflect.setProperty(getActorByName(id), "reflectionColor", FlxColor.fromString(color));
		});

		setLuaFunction("setWindowPos", function(x:Int, y:Int) {
			Application.current.window.move(x, y);
		});

		setLuaFunction("getWindowX", function() {
			return Application.current.window.x;
		});

		setLuaFunction("getWindowY", function() {
			return Application.current.window.y;
		});

		setLuaFunction("getCenteredWindowX", function() {
			return (Application.current.window.display.currentMode.width / 2) - (Application.current.window.width / 2);
		});

		setLuaFunction("getCenteredWindowY", function() {
			return (Application.current.window.display.currentMode.height / 2) - (Application.current.window.height / 2);
		});

		setLuaFunction("resizeWindow", function(Width:Int, Height:Int) {
			Application.current.window.resize(Width, Height);
		});

		setLuaFunction("getScreenWidth", function() {
			return Application.current.window.display.currentMode.width;
		});

		setLuaFunction("getScreenHeight", function() {
			return Application.current.window.display.currentMode.height;
		});

		setLuaFunction("getWindowWidth", function() {
			return Application.current.window.width;
		});

		setLuaFunction("getWindowHeight", function() {
			return Application.current.window.height;
		});

		setLuaFunction("setCanFullscreen", function(can_Fullscreen:Bool) {
			PlayState.instance.canFullscreen = can_Fullscreen;
		});

		setLuaFunction("changeDadCharacter", function(character:String) {
			var oldDad = PlayState.dad;
			PlayState.instance.remove(oldDad);

			var dad = new Character(100, 100, character);
			PlayState.dad = dad;

			if (dad.otherCharacters == null) {
				if (dad.coolTrail != null)
					PlayState.instance.add(dad.coolTrail);

				PlayState.instance.add(dad);
			} else {
				for (character in dad.otherCharacters) {
					if (character.coolTrail != null)
						PlayState.instance.add(character.coolTrail);

					PlayState.instance.add(character);
				}
			}

			lua_Sprites.remove("dad");

			oldDad.kill();
			oldDad.destroy();

			lua_Sprites.set("dad", dad);

			@:privateAccess
			{
				var oldIcon = PlayState.instance.iconP2;
				var bar = PlayState.instance.healthBar;

				PlayState.instance.remove(oldIcon);
				oldIcon.kill();
				oldIcon.destroy();

				PlayState.instance.iconP2 = new HealthIcon(dad.icon, false);
				PlayState.instance.iconP2.y = PlayState.instance.healthBar.y - (PlayState.instance.iconP2.height / 2);
				PlayState.instance.iconP2.cameras = [PlayState.instance.camHUD];
				PlayState.instance.add(PlayState.instance.iconP2);

				bar.createFilledBar(dad.barColor, PlayState.boyfriend.barColor);
				bar.updateFilledBar();

				PlayState.instance.stage.setCharOffsets();
			}
		});

		setLuaFunction("changeBoyfriendCharacter", function(character:String) {
			var oldBF = PlayState.boyfriend;
			PlayState.instance.remove(oldBF);

			var boyfriend = new Boyfriend(770, 450, character);
			PlayState.boyfriend = boyfriend;

			if (boyfriend.otherCharacters == null) {
				if (boyfriend.coolTrail != null)
					PlayState.instance.add(boyfriend.coolTrail);

				PlayState.instance.add(boyfriend);
			} else {
				for (character in boyfriend.otherCharacters) {
					if (character.coolTrail != null)
						PlayState.instance.add(character.coolTrail);

					PlayState.instance.add(character);
				}
			}

			lua_Sprites.remove("boyfriend");

			oldBF.kill();
			oldBF.destroy();

			lua_Sprites.set("boyfriend", boyfriend);

			@:privateAccess
			{
				var oldIcon = PlayState.instance.iconP1;
				var bar = PlayState.instance.healthBar;

				PlayState.instance.remove(oldIcon);
				oldIcon.kill();
				oldIcon.destroy();

				PlayState.instance.iconP1 = new HealthIcon(boyfriend.icon, false);
				PlayState.instance.iconP1.y = PlayState.instance.healthBar.y - (PlayState.instance.iconP1.height / 2);
				PlayState.instance.iconP1.cameras = [PlayState.instance.camHUD];
				PlayState.instance.iconP1.flipX = true;
				PlayState.instance.add(PlayState.instance.iconP1);

				bar.createFilledBar(PlayState.dad.barColor, boyfriend.barColor);
				bar.updateFilledBar();

				PlayState.instance.stage.setCharOffsets();
			}
		});

		// scroll speed

		var original_Scroll_Speed = PlayState.SONG.speed;

		setLuaFunction("getBaseScrollSpeed", function() {
			return original_Scroll_Speed;
		});

		setLuaFunction("getScrollSpeed", function() {
			return PlayState.SONG.speed;
		});

		setLuaFunction("setScrollSpeed", function(speed:Float) {
			PlayState.SONG.speed = speed;
		});

		// sounds

		setLuaFunction("createSound", function(id:String, file_Path:String, library:String, ?looped:Bool = false) {
			if (lua_Sounds.get(id) == null) {
				lua_Sounds.set(id, new FlxSound().loadEmbedded(Paths.sound(file_Path, library), looped));
				FlxG.sound.list.add(lua_Sounds.get(id));
			} else
				trace("Error! Sound " + id + " already exists! Try another sound name!");
		});

		setLuaFunction("removeSound", function(id:String) {
			if (lua_Sounds.get(id) != null) {
				FlxG.sound.list.remove(lua_Sounds.get(id));

				var sound = lua_Sounds.get(id);
				sound.stop();
				sound.kill();
				sound.destroy();

				lua_Sounds.set(id, null);
			}
		});

		setLuaFunction("playSound", function(id:String, ?forceRestart:Bool = false) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).play(forceRestart);
		});

		setLuaFunction("stopSound", function(id:String) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).stop();
		});

		setLuaFunction("setSoundVolume", function(id:String, volume:Float) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).volume = volume;
		});

		setLuaFunction("getSoundTime", function(id:String) {
			if (lua_Sounds.get(id) != null)
				return lua_Sounds.get(id).time;

			return 0;
		});

		// tweens

		setLuaFunction("tween", function(obj:String, properties:Dynamic, duration:Float, ease:String, ?startDelay:Float = 0.0, ?onComplete:Dynamic) {
			var spr:Dynamic = getActorByName(obj);

			if (spr != null) {
				FlxTween.tween(spr, properties, duration, {
					ease: easeFromString(ease),
					onComplete: function(twn) {
						if (onComplete != null)
							onComplete();
					},
					startDelay: startDelay,
				});
			} else {
				trace('Object named $obj doesn\'t exist!', ERROR);
			}
		});

		setLuaFunction("tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenPos", function(id:String, toX:Int, toY:Int, time:Float, ?onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.quintInOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.quintInOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						executeState(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenFadeOut", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.circOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenFadeCubeInOut", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.cubeInOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenActorColor", function(id:String, r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int, time:Float, onComplete:String = "") {
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				FlxTween.color(actor, time, FlxColor.fromRGB(r1, g1, b1, 255), FlxColor.fromRGB(r2, g2, b2, 255), {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
			}
		});

		setLuaFunction("tweenScaleX", function(id:String, toAlpha:Float, time:Float, easeStr:String = "", onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id).scale, {x: toAlpha}, time, {
					ease: easeFromString(easeStr),
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});
		setLuaFunction("tweenScaleY", function(id:String, toAlpha:Float, time:Float, easeStr:String = "", onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id).scale, {y: toAlpha}, time, {
					ease: easeFromString(easeStr),
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							executeState(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenActorProperty", function(id:String, prop:String, value:Dynamic, time:Float, easeStr:String = "linear") {
			var actor = getActorByName(id);
			var ease = easeFromString(easeStr);

			if (actor != null && Reflect.getProperty(actor, prop) != null) {
				var startVal = Reflect.getProperty(actor, prop);

				PlayState.instance.tweenManager.num(startVal, value, time, {
					onUpdate: function(tween:FlxTween) {
						var ting = FlxMath.lerp(startVal, value, ease(tween.percent));
						Reflect.setProperty(actor, prop, ting);
					},
					ease: ease,
					onComplete: function(tween:FlxTween) {
						Reflect.setProperty(actor, prop, value);
					}
				});
			}
		});

		setLuaFunction("setActorProperty", function(id:String, prop:String, value:Dynamic) {
			var actor = getActorByName(id);
			if (actor != null && Reflect.getProperty(actor, prop) != null) {
				Reflect.setProperty(actor, prop, value);
			}
		});

		setLuaFunction("tweenActorColor", function(id:String, r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int, time:Float, onComplete:String = "") {
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				FlxTween.color(actor, time, FlxColor.fromRGB(r1, g1, b1, 255), FlxColor.fromRGB(r2, g2, b2, 255), {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
			}
		});

		// properties

		setLuaFunction("set", function(property:Dynamic, value:Dynamic):Void {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = getActorByName(seperated_path[0]);
			var property:String = property;

			for (i in 1...seperated_path.length) {
				if (i < seperated_path.length - 1) {
					if (seperated_path[i].contains('[')) {
						var array = seperated_path[i].substr(0, seperated_path[i].indexOf('['));
						object = Reflect.getProperty(object, array)[Std.parseInt(seperated_path[i].split(']')[0].split('[')[1])];
					} else
						object = Reflect.getProperty(object, seperated_path[i]);
				} else
					property = seperated_path[i];
			}

			if (seperated_path.length > 1) {
				Reflect.setProperty(object, property, value);
			} else {
				if (Reflect.getProperty(PlayState.instance, property) != null)
					Reflect.setProperty(PlayState.instance, property, value);
				else
					Reflect.setProperty(PlayState, property, value);
			}
		});

		setLuaFunction("get", function(property:Dynamic):Dynamic {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = getActorByName(seperated_path[0]);
			var property:String = property;

			for (i in 1...seperated_path.length) {
				if (i < seperated_path.length - 1)
					object = Reflect.getProperty(object, seperated_path[i]);
				else
					property = seperated_path[i];
			}

			if (seperated_path.length > 1) {
				return Reflect.getProperty(object, property);
			} else {
				if (Reflect.getProperty(PlayState.instance, property) != null)
					return Reflect.getProperty(PlayState.instance, property);
				else
					return Reflect.getProperty(PlayState, property);
			}
		});

		setLuaFunction("setClass", function(class_name:String, property:Dynamic, value:Dynamic):Void {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = Type.resolveClass(class_name);
			var property:String = property;

			for (i in 1...seperated_path.length) {
				if (i < seperated_path.length - 1) {
					if (seperated_path[i].contains('[')) {
						var array = seperated_path[i].substr(0, seperated_path[i].indexOf('['));
						object = Reflect.getProperty(object, array)[Std.parseInt(seperated_path[i].split(']')[0].split('[')[1])];
					} else
						object = Reflect.getProperty(object, seperated_path[i]);
				} else
					property = seperated_path[i];
			}

			Reflect.setProperty(object != Type.resolveClass(class_name) ? object : Type.resolveClass(class_name), property, value);
		});

		setLuaFunction("getClass", function(class_name:String, property:Dynamic):Dynamic {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = Type.resolveClass(class_name);
			var property:String = property;

			if (seperated_path.length > 1) {
				for (i in 0...seperated_path.length) {
					if (i < seperated_path.length - 1)
						object = Reflect.getProperty(object, seperated_path[i]);
					else
						property = seperated_path[i];
				}
			}

			return Reflect.getProperty(object != Type.resolveClass(class_name) ? object : Type.resolveClass(class_name), property);
		});

		setLuaFunction("setProperty", function(object:String, property:String, value:Dynamic) {
			if (object != "") {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, object) != null)
					Reflect.setProperty(Reflect.getProperty(PlayState.instance, object), property, value);
				else
					Reflect.setProperty(Reflect.getProperty(PlayState, object), property, value);
			} else {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, property) != null)
					Reflect.setProperty(PlayState.instance, property, value);
				else
					Reflect.setProperty(PlayState, property, value);
			}
		});

		setLuaFunction("getProperty", function(object:String, property:String) {
			if (object != "") {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, object) != null)
					return Reflect.getProperty(Reflect.getProperty(PlayState.instance, object), property);
				else
					return Reflect.getProperty(Reflect.getProperty(PlayState, object), property);
			} else {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, property) != null)
					return Reflect.getProperty(PlayState.instance, property);
				else
					return Reflect.getProperty(PlayState, property);
			}
		});

		setLuaFunction("getPropertyFromClass", function(className:String, variable:String) {
			@:privateAccess
			{
				var variablePaths = variable.split(".");

				if (variablePaths.length > 1) {
					var selectedVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), variablePaths[0]);

					for (i in 1...variablePaths.length - 1) {
						selectedVariable = Reflect.getProperty(selectedVariable, variablePaths[i]);
					}

					return Reflect.getProperty(selectedVariable, variablePaths[variablePaths.length - 1]);
				}

				return Reflect.getProperty(Type.resolveClass(className), variable);
			}
		});

		setLuaFunction("setPropertyFromClass", function(className:String, variable:String, value:Dynamic) {
			@:privateAccess
			{
				var variablePaths:Array<String> = variable.split('.');

				if (variablePaths.length > 1) {
					var selectedVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), variablePaths[0]);

					for (i in 1...variablePaths.length - 1) {
						selectedVariable = Reflect.getProperty(selectedVariable, variablePaths[i]);
					}

					return Reflect.setProperty(selectedVariable, variablePaths[variablePaths.length - 1], value);
				}

				return Reflect.setProperty(Type.resolveClass(className), variable, value);
			}
		});

		// song stuff

		setLuaFunction("setSongPosition", function(position:Float) {
			Conductor.songPosition = position;
			setVar('songPos', Conductor.songPosition);
		});

		setLuaFunction("getSongPosition", function() {
			return Conductor.songPosition;
		});

		setLuaFunction("stopSong", function() {
			@:privateAccess
			{
				PlayState.instance.paused = true;

				FlxG.sound.music.volume = 0;
				PlayState.instance.vocals.volume = 0;

				PlayState.instance.notes.clear();
				PlayState.instance.remove(PlayState.instance.notes);

				FlxG.sound.music.time = 0;
				PlayState.instance.vocals.time = 0;

				Conductor.songPosition = 0;
				PlayState.songMultiplier = 0;

				Conductor.recalculateStuff(PlayState.songMultiplier);

				FlxG.sound.music.pitch = PlayState.songMultiplier;

				if (PlayState.instance.vocals.playing)
					PlayState.instance.vocals.pitch = PlayState.songMultiplier;

				PlayState.instance.stopSong = true;
			}

			return true;
		});

		setLuaFunction("endSong", function() {
			@:privateAccess
			{
				FlxG.sound.music.time = FlxG.sound.music.length;
				PlayState.instance.vocals.time = FlxG.sound.music.length;

				PlayState.instance.health = 500000;
				PlayState.instance.invincible = true;

				PlayState.instance.stopSong = false;

				PlayState.instance.resyncVocals();
			}

			return true;
		});

		setLuaFunction("getCharFromEvent", function(eventId:String) {
			switch (eventId.toLowerCase()) {
				case "girlfriend" | "gf" | "player3" | "2":
					return "girlfriend";
				case "dad" | "opponent" | "player2" | "1":
					return "dad";
				case "bf" | "boyfriend" | "player" | "player1" | "0":
					return "boyfriend";
			}

			return eventId;
		});

		setLuaFunction("charFromEvent", function(id:String) {
			switch (id.toLowerCase()) {
				case "girlfriend" | "gf" | "player3" | "2":
					return "girlfriend";
				case "dad" | "opponent" | "player2" | "1":
					return "dad";
				case "bf" | "boyfriend" | "player" | "player1" | "0":
					return "boyfriend";
			}

			return id;
		});

		setLuaFunction("tweenStageColorSwap", function(prop:String, value:Dynamic, time:Float, easeStr:String = "linear") {
			@:privateAccess
			var actor = PlayState.instance.stage.colorSwap;
			var ease = easeFromString(easeStr);

			if (actor != null) {
				var startVal = Reflect.getProperty(actor, prop);

				PlayState.instance.tweenManager.num(startVal, value, time, {
					onUpdate: function(tween:FlxTween) {
						var ting = FlxMath.lerp(startVal, value, ease(tween.percent));
						Reflect.setProperty(actor, prop, ting);
					},
					ease: ease,
					onComplete: function(tween:FlxTween) {
						Reflect.setProperty(actor, prop, value);
					}
				});
			}
		});

		setLuaFunction("setStageColorSwap", function(prop:String, value:Dynamic) {
			@:privateAccess
			var actor = PlayState.instance.stage.colorSwap;

			if (actor != null) {
				Reflect.setProperty(actor, prop, value);
			}
		});

		setLuaFunction("getStrumTimeFromStep", function(step:Float) {
			var beat = step * 0.25;
			var totalTime:Float = 0;
			var curBpm = Conductor.bpm;
			if (PlayState.SONG != null)
				curBpm = PlayState.SONG.bpm;
			for (i in 0...Math.floor(beat)) {
				if (Conductor.bpmChangeMap.length > 0) {
					for (j in 0...Conductor.bpmChangeMap.length) {
						if (totalTime >= Conductor.bpmChangeMap[j].songTime)
							curBpm = Conductor.bpmChangeMap[j].bpm;
					}
				}
				totalTime += (60 / curBpm) * 1000;
			}

			var leftOverBeat = beat - Math.floor(beat);
			totalTime += (60 / curBpm) * 1000 * leftOverBeat;

			return totalTime;
		});

		// shader bullshit

setLuaFunction("setActor3DShader", function(id:String, ?speed:Float = 3, ?frequency:Float = 10, ?amplitude:Float = 0.25) {
			var actor = getActorByName(id);

			if (actor != null) {
				var funnyShader:shaders.Shaders.ThreeDEffect = shaders.Shaders.newEffect("3d");
				funnyShader.waveSpeed = speed;
				funnyShader.waveFrequency = frequency;
				funnyShader.waveAmplitude = amplitude;
				lua_Shaders.set(id, funnyShader);

				actor.shader = funnyShader.shader;
			}
		});

		setLuaFunction("setActorNoShader", function(id:String) {
			var actor = getActorByName(id);

			if (actor != null) {
				lua_Shaders.remove(id);
				actor.shader = null;
			}
		});

		setLuaFunction("createCustomShader", function(id:String, file:String) {
			var funnyCustomShader:CustomShader = new CustomShader(Assets.getText(Paths.frag(file)), null);
			lua_Custom_Shaders.set(id, funnyCustomShader);
		});

		setLuaFunction("setActorCustomShader", function(id:String, actor:String) {
			if (!Options.getData("shaders"))
				return;

			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			if (getCharacterByName(actor) != null) {
				var character = getCharacterByName(actor);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					for (c in 0...character.otherCharacters.length) {
						character.otherCharacters[c].shader = funnyCustomShader;
					}
					return;
				}
			}
			var actor = getActorByName(actor);

			if (actor != null && funnyCustomShader != null)
				actor.shader = funnyCustomShader;
		});

		setLuaFunction("setActorNoCustomShader", function(actor:String) {
			getActorByName(actor).shader = null;
		});

		setLuaFunction("setCameraCustomShader", function(id:String, camera:String) {
			if (!Options.getData("shaders"))
				return;

			var cam = lua_Cameras.get(camera);
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			if (cam != null && funnyCustomShader != null) {
				cam.shaders.push(new ShaderFilter(funnyCustomShader));
				cam.shaderNames.push(id);
				cam.cam.filters = cam.shaders;
			}
		});

		setLuaFunction("pushShaderToCamera", function(id:String, camera:String) {
			if (!Options.getData("shaders"))
				return;

			var cam = lua_Cameras.get(camera);
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			if (cam != null && funnyCustomShader != null) {
				cam.shaders.push(new ShaderFilter(funnyCustomShader));
				cam.shaderNames.push(id);
				cam.cam.filters = cam.shaders;
			}
		});

		setLuaFunction("setCameraNoCustomShader", function(camera:String) {
			if (!Options.getData("shaders"))
				return;
			cameraFromString(camera).filters = null;
		});

		setLuaFunction("getCustomShaderBool", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getBool(property);
		});

		setLuaFunction("getCustomShaderInt", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getInt(property);
		});

		setLuaFunction("getCustomShaderFloat", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getFloat(property);
		});

		setLuaFunction("setCustomShaderBool", function(id:String, property:String, value:Bool) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setBool(property, value);
		});

		setLuaFunction("setCustomShaderInt", function(id:String, property:String, value:Int) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setInt(property, value);
		});

		setLuaFunction("setCustomShaderFloat", function(id:String, property:String, value:Float) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setFloat(property, value);
		});

		setLuaFunction("tweenShader",
			function(id:String, property:String, value:Float, duration:Float, ?ease:String = "linear", ?startDelay:Float = 0.0, ?onComplete:Dynamic) {
				var shader:CustomShader = lua_Custom_Shaders.get(id);
				if (shader != null) {
					shader.tween(property, value, duration, easeFromString(ease), startDelay, onComplete);
				} else {
					trace('Shader named $shader doesn\'t exist!', ERROR);
				}
			});

		// dumb vc functions
		setLuaFunction("initShader", function(id:String, file:String) {
			var funnyCustomShader:CustomShader = new CustomShader(Assets.getText(Paths.frag(file)), null);
			lua_Custom_Shaders.set(id, funnyCustomShader);
		});

		setLuaFunction("setActorShader", function(actorStr:String, shaderName:String) {
			if (!Options.getData("shaders"))
				return;

			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(shaderName);
			if (getCharacterByName(actorStr) != null) {
				var character = getCharacterByName(actorStr);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					for (c in 0...character.otherCharacters.length) {
						character.otherCharacters[c].shader = funnyCustomShader;
					}
					return;
				}
			}
			var actor = getActorByName(actorStr);

			if (actor != null && funnyCustomShader != null) {
				actor.shader = funnyCustomShader; // use reflect to workaround compiler errors

				// trace('added shader '+shaderName+" to " + actorStr);
			}
		});

		setLuaFunction("setCameraShader", function(camera:String, id:String) {
			if (!Options.getData("shaders"))
				return;

			var cam = lua_Cameras.get(camera);
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			if (cam != null && funnyCustomShader != null) {
				cam.shaders.push(new ShaderFilter(funnyCustomShader));
				cam.shaderNames.push(id);
				cam.cam.filters = cam.shaders;
			}
		});

		setLuaFunction("removeCameraShader", function(camStr:String, shaderName:String) {
			if (!Options.getData("shaders"))
				return;
			var cam = lua_Cameras.get(camStr);
			if (cam != null) {
				if (cam.shaderNames.contains(shaderName)) {
					var idx:Int = cam.shaderNames.indexOf(shaderName);
					if (idx != -1) {
						cam.shaderNames.remove(cam.shaderNames[idx]);
						cam.shaders.remove(cam.shaders[idx]);
						cam.cam.filters = cam.shaders;
					}
				}
			}
		});

		setLuaFunction("setShaderProperty", function(id:String, property:String, value:Dynamic) {
			if (!Options.getData("shaders"))
				return;
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			if (Std.isOfType(value, Float)) {
				funnyCustomShader.setFloat(property, Std.parseFloat(value));
			} else if (Std.isOfType(value, Bool)) {
				funnyCustomShader.setBool(property, value);
			} else {
				funnyCustomShader.setFloatArray(property, value);
			}
		});

		setLuaFunction("tweenShaderProperty",
			function(id:String, property:String, value:Float, duration:Float, ?ease:String = "linear", ?startDelay:Float = 0.0, ?onComplete:Dynamic) {
				if (!Options.getData("shaders"))
					return;
				var shader:CustomShader = lua_Custom_Shaders.get(id);
				if (shader != null) {
					shader.tween(property, value, duration, easeFromString(ease), startDelay, onComplete);
				} else {
					trace('Shader named $shader doesn\'t exist!', ERROR);
				}
			});

		setLuaFunction("updateRating", function() {
			PlayState.instance.updateRating();
		});

		// utilities
		setLuaFunction("printIP", function():Void {
			trace('${FlxG.random.int(100, 999)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}');
		});

		setLuaFunction("getIP", function():String {
			return '${FlxG.random.int(100, 999)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}';
		});

		setLuaFunction("getOption", function(saveStr:String) {
			return Options.getData(saveStr);
		});

		setLuaFunction("getCurrentMod", function(saveStr:String) {
			return Options.getData("curMod");
		});

		setLuaFunction("assetExists", function(path:String) {
			return Assets.exists(path);
		});

		setLuaFunction("fileSystemExists", function(path:String) {
			return sys.FileSystem.exists(path);
		});

		setLuaFunction("getText", function(path:String) {
			return Assets.getText(path);
		});

		setLuaFunction("getContent", function(path:String) {
			return sys.io.File.getContent(path);
		});

		setLuaFunction("loadScript", function(script:String) {
			var modchart:ModchartUtilities = null;

			if (Assets.exists(Paths.lua("modcharts/" + script)))
				modchart = new ModchartUtilities(#if MODDING_ALLOWED PolymodAssets #else Assets #end.getPath(Paths.lua("modcharts/" + script)));
			else if (Assets.exists(Paths.lua("scripts/" + script)))
				modchart = new ModchartUtilities(#if MODDING_ALLOWED PolymodAssets #else Assets #end.getPath(Paths.lua("scripts/" + script)));

			if (modchart == null) {
				trace('Couldn\'t find script at either ${Paths.lua("modcharts/" + script)} OR ${Paths.lua("scripts/" + script)}!', WARNING);
				return;
			}

			modchart.setupTheShitCuzPullRequestsSuck();

			if (functions_called.contains("create"))
				modchart.executeState("create", [PlayState.SONG.song.toLowerCase()]);
			if (functions_called.contains("createPost"))
				modchart.executeState("createPost", [PlayState.SONG.song.toLowerCase()]);
			if (functions_called.contains("start"))
				modchart.executeState("start", [PlayState.SONG.song.toLowerCase()]);

			extra_scripts.push(modchart);
		});

		// math
		setLuaFunction("bound", function(value:Float, ?Min:Float, ?Max:Float) {
			return FlxMath.bound(value, Min, Max);
		});

		setLuaFunction("boundTo", function(value:Float, Min:Float, Max:Float):Float {
			return CoolUtil.boundTo(value, Min, Max);
		});

		setLuaFunction("distanceBetween", function(SpriteA:String, SpriteB:String) {
			if (getActorByName(SpriteA) != null && getActorByName(SpriteB) != null)
				return FlxMath.distanceBetween(getActorByName(SpriteA), getActorByName(SpriteB));
			else
				return 0;
		});

		setLuaFunction("distanceToMouse", function(sprite:String) {
			if (getActorByName(sprite) != null)
				return FlxMath.distanceToMouse(getActorByName(sprite));
			else
				return 0;
		});

		setLuaFunction("distanceToPoint", function(sprite:String, x:Float, y:Float) {
			var point:FlxPoint = new FlxPoint(x, y);
			if (getActorByName(sprite) != null)
				return FlxMath.distanceToPoint(getActorByName(sprite), point);
			else
				return 0;
		});

		setLuaFunction("dotProduct", function(ax:Float, ay:Float, bx:Float, by:Float) {
			return FlxMath.dotProduct(ax, ay, bx, by);
		});

		setLuaFunction("equal", function(aValueA:Float, aValueB:Float, aDiff:Float = FlxMath.EPSILON) {
			return FlxMath.equal(aValueA, aValueB, aDiff);
		});

		setLuaFunction("fastCos", function(n:Float) {
			return FlxMath.fastCos(n);
		});

		setLuaFunction("fastSin", function(n:Float) {
			return FlxMath.fastSin(n);
		});

		setLuaFunction("fastTan", function(n:Float) {
			return FlxMath.fastSin(n) / FlxMath.fastCos(n);
		});

		setLuaFunction("fceil", function(n:Float) {
			return Math.fceil(n);
		});

		setLuaFunction("ffloor", function(n:Float) {
			return Math.ffloor(n);
		});

		setLuaFunction("fround", function(n:Float) {
			return Math.fround(n);
		});

		setLuaFunction("isFinite", function(n:Float) {
			return Math.isFinite(n);
		});

		setLuaFunction("isNaN", function(n:Float) {
			return Math.isNaN(n);
		});

		setLuaFunction("getDecimals", function(n:Float) {
			return FlxMath.getDecimals(n);
		});

		setLuaFunction("inBounds", function(value:Float, min:Null<Float>, max:Null<Float>) {
			return FlxMath.inBounds(value, min, max);
		});

		setLuaFunction("isDistanceToMouseWithin", function(sprite:String, distance:Float, includeEqual:Bool = false) {
			if (getActorByName(sprite) != null)
				return FlxMath.isDistanceToMouseWithin(getActorByName(sprite), distance, includeEqual);
			else
				return false;
		});

		setLuaFunction("isDistanceToPointWithin", function(sprite:String, x:Float, y:Float, distance:Float, includeEqual:Bool = false) {
			var point:FlxPoint = new FlxPoint(x, y);
			if (getActorByName(sprite) != null)
				return FlxMath.isDistanceToPointWithin(getActorByName(sprite), point, distance, includeEqual);
			else
				return false;
		});

		setLuaFunction("isDistanceWithin", function(SpriteA:String, SpriteB:String, distance:Float, includeEqual:Bool = false) {
			if (getActorByName(SpriteA) != null && getActorByName(SpriteB) != null)
				return FlxMath.isDistanceWithin(getActorByName(SpriteA), getActorByName(SpriteB), distance, includeEqual);
			else
				return false;
		});

		setLuaFunction("isEven", function(n:Float) {
			return FlxMath.isEven(n);
		});

		setLuaFunction("isOdd", function(n:Float) {
			return FlxMath.isOdd(n);
		});

		setLuaFunction("lerp", function(a:Float, b:Float, ratio:Float) {
			return FlxMath.lerp(a, b, ratio);
		});

		setLuaFunction("maxAdd", function(value:Int, amount:Int, max:Int, min:Int = 1) {
			return FlxMath.maxAdd(value, amount, max, min);
		});

		setLuaFunction("maxInt", function(a:Int, b:Int) {
			return FlxMath.maxInt(a, b);
		});

		setLuaFunction("minInt", function(a:Int, b:Int) {
			return FlxMath.minInt(a, b);
		});

		setLuaFunction("numericComparison", function(a:Float, b:Float) {
			return FlxMath.numericComparison(a, b);
		});

		setLuaFunction("perlin", function(x:Float, y:Float, z:Float) {
			return perlin.perlin(x, y, z);
		});

		setLuaFunction("pointInCoordinates", function(pointX:Float, pointY:Float, rectX:Float, rectY:Float, rectWidth:Float, rectHeight:Float) {
			return FlxMath.pointInCoordinates(pointX, pointX, rectX, rectY, rectWidth, rectHeight);
		});

		setLuaFunction("random", function() {
			return Math.random();
		});

		setLuaFunction("randomBool", function(chance:Float):Bool {
			return FlxG.random.bool(chance);
		});

		setLuaFunction("randomFloat", function(min:Float, max:Float):Float {
			return FlxG.random.float(min, max);
		});

		setLuaFunction("randomInt", function(min:Int, max:Int):Int {
			return FlxG.random.int(min, max);
		});

		setLuaFunction("remapToRange", function(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float) {
			return FlxMath.remapToRange(value, start1, stop1, start2, stop2);
		});

		setLuaFunction("round", function(v:Float) {
			return Math.round(v);
		});

		setLuaFunction("roundDecimal", function(value:Float, percision:Int) {
			return FlxMath.roundDecimal(value, percision);
		});

		setLuaFunction("sameSign", function(a:Float, b:Float) {
			return FlxMath.sameSign(a, b);
		});

		setLuaFunction("signOf", function(n:Float) {
			return FlxMath.signOf(n);
		});

		setLuaFunction("sinh", function(n:Float) {
			return FlxMath.sinh(n);
		});

		setLuaFunction("vectorLength", function(dx:Float, dy:Float) {
			return FlxMath.vectorLength(dx, dy);
		});

		setLuaFunction("wrap", function(value:Int, min:Int, max:Int) {
			return FlxMath.wrap(value, min, max);
		});

		#if MODCHARTING_TOOLS
		if (PlayState.SONG.modchartingTools) {
			setLuaFunction('startMod', function(name:String, modClass:String, type:String = '', pf:Int = -1) {
				ModchartFuncs.startMod(name, modClass, type, pf);

				PlayState.instance.playfieldRenderer.modifierTable.reconstructTable(); // needs to be reconstructed for lua modcharts
			});
			setLuaFunction('setMod', function(name:String, value:Float) {
				ModchartFuncs.setMod(name, value);
			});
			setLuaFunction('setSubMod', function(name:String, subValName:String, value:Float) {
				ModchartFuncs.setSubMod(name, subValName, value);
			});
			setLuaFunction('setModTargetLane', function(name:String, value:Int) {
				ModchartFuncs.setModTargetLane(name, value);
			});
			setLuaFunction('setModPlayfield', function(name:String, value:Int) {
				ModchartFuncs.setModPlayfield(name, value);
			});
			setLuaFunction('addPlayfield', function(?x:Float = 0, ?y:Float = 0, ?z:Float = 0) {
				ModchartFuncs.addPlayfield(x, y, z);
			});
			setLuaFunction('removePlayfield', function(idx:Int) {
				ModchartFuncs.removePlayfield(idx);
			});
			setLuaFunction('tweenModifier', function(modifier:String, val:Float, time:Float, ease:String) {
				ModchartFuncs.tweenModifier(modifier, val, time, ease);
			});
			setLuaFunction('tweenModifierSubValue', function(modifier:String, subValue:String, val:Float, time:Float, ease:String) {
				ModchartFuncs.tweenModifierSubValue(modifier, subValue, val, time, ease);
			});
			setLuaFunction('setModEaseFunc', function(name:String, ease:String) {
				ModchartFuncs.setModEaseFunc(name, ease);
			});
			setLuaFunction('setModifier', function(beat:Float, argsAsString:String) {
				ModchartFuncs.set(beat, argsAsString);
			});
			setLuaFunction('ease', function(beat:Float, time:Float, easeStr:String, argsAsString:String) {
				ModchartFuncs.ease(beat, time, easeStr, argsAsString);
			});
		}
		#end

		#if mobile
		setLuaFunction("vibrate", (duration:Null<Int>, ?period:Null<Int>) ->
		{
			if (duration == null)
				return trace('vibrate: No duration specified.');
			else if (period == null)
				period = 0;
			return lime.ui.Haptic.vibrate(period, duration);
		});
		#end

		#if android
		setVar("isDolbyAtmos", AndroidTools.isDolbyAtmos());
		setVar("isAndroidTV", AndroidTools.isAndroidTV());
		setVar("isTablet", AndroidTools.isTablet());
		setVar("isChromebook", AndroidTools.isChromebook());
		setVar("isDeXMode", AndroidTools.isDeXMode());

		setLuaFunction("backJustPressed", FlxG.android.justPressed.BACK);
		setLuaFunction("backPressed", FlxG.android.pressed.BACK);
		setLuaFunction("backJustReleased", FlxG.android.justReleased.BACK);

		setLuaFunction("menuJustPressed", FlxG.android.justPressed.MENU);
		setLuaFunction("menuPressed", FlxG.android.pressed.MENU);
		setLuaFunction("menuJustReleased", FlxG.android.justReleased.MENU);
		setLuaFunction("getCurrentOrientation", () -> LeatherJNI.getCurrentOrientationAsString());

		setLuaFunction("setOrientation", function(hint:Null<String>):Void
			{
				switch (hint.toLowerCase())
				{
					case 'portrait':
						hint = 'Portrait';
					case 'portraitupsidedown' | 'upsidedownportrait' | 'upsidedown':
						hint = 'PortraitUpsideDown';
					case 'landscapeleft' | 'leftlandscape':
						hint = 'LandscapeLeft';
					case 'landscaperight' | 'rightlandscape' | 'landscape':
						hint = 'LandscapeRight';
					default:
						hint = null;
				}
				if (hint == null)
					return trace('setOrientation: No orientation specified.');
				LeatherJNI.setOrientation(FlxG.stage.stageWidth, FlxG.stage.stageHeight, false, hint);
			});

		setLuaFunction("minimizeWindow", () -> AndroidTools.minimizeWindow());
		setLuaFunction("showToast", function(text:String, duration:Null<Int>, ?xOffset:Null<Int>, ?yOffset:Null<Int>) //, ?gravity:Null<Int>
		{
			if (text == null)
				return trace('showToast: No text specified.');
			else if (duration == null)
				return trace('showToast: No duration specified.');

			if (xOffset == null)
				xOffset = 0;
			if (yOffset == null)
				yOffset = 0;

			AndroidToast.makeText(text, duration, -1, xOffset, yOffset);
		});
		#end

		executeState("onCreate", []);
		executeState("createLua", []);
		executeState("new", []);
	}

	public function setupTheShitCuzPullRequestsSuck() {
		lua_Sprites.set("boyfriend", PlayState.boyfriend);
		lua_Sprites.set("girlfriend", PlayState.gf);
		lua_Sprites.set("dad", PlayState.dad);

		lua_Characters.set("boyfriend", PlayState.boyfriend);
		lua_Characters.set("girlfriend", PlayState.gf);
		lua_Characters.set("dad", PlayState.dad);

		lua_Sounds.set("Inst", FlxG.sound.music);
		@:privateAccess
		lua_Sounds.set("Voices", PlayState.instance.vocals);

		@:privateAccess
		for (object in PlayState.instance.stage.stage_Objects) {
			lua_Sprites.set(object[0], object[1]);
		}

		if (PlayState.dad.otherCharacters != null) {
			lua_Sprites.set('dad', PlayState.dad.otherCharacters[0]);
			lua_Characters.set('dad', PlayState.dad.otherCharacters[0]);
			for (char in 0...PlayState.dad.otherCharacters.length) {
				lua_Sprites.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
				lua_Characters.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
			}
		}

		if (PlayState.boyfriend.otherCharacters != null) {
			lua_Sprites.set('boyfriend', PlayState.boyfriend.otherCharacters[0]);
			lua_Characters.set('boyfriend', PlayState.boyfriend.otherCharacters[0]);
			for (char in 0...PlayState.boyfriend.otherCharacters.length) {
				lua_Sprites.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
				lua_Characters.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
			}
		}

		if (PlayState.gf.otherCharacters != null) {
			lua_Sprites.set('girlfriend', PlayState.gf.otherCharacters[0]);
			lua_Characters.set('girlfriend', PlayState.gf.otherCharacters[0]);
			for (char in 0...PlayState.gf.otherCharacters.length) {
				lua_Sprites.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
				lua_Characters.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
			}
		}

		if (PlayState.instance != null) {
			for (i in 0...PlayState.strumLineNotes.length) {
				lua_Sprites.set("defaultStrum" + i, PlayState.strumLineNotes.members[i]);

				if (PlayState.enemyStrums.members.contains(PlayState.strumLineNotes.members[i])) {
					lua_Sprites.set("enemyStrum" + i % PlayState.SONG.keyCount, PlayState.strumLineNotes.members[i]);
				} else {
					lua_Sprites.set("playerStrum" + i % PlayState.SONG.playerKeyCount, PlayState.strumLineNotes.members[i]);
				}
			}
		}

		lua_Sprites.set("iconP1", PlayState.instance.iconP1);
		lua_Sprites.set("iconP2", PlayState.instance.iconP2);

		setVar("player1", PlayState.boyfriend.curCharacter);
		setVar("player2", PlayState.dad.curCharacter);

		for (script in extra_scripts) {
			script.setupTheShitCuzPullRequestsSuck();
		}
	}

	private function convert(v:Any, type:String):Dynamic { // I didn't write this lol
		if (Std.isOfType(v, String) && type != null) {
			var v:String = v;

			if (type.substr(0, 4) == 'array') {
				if (type.substr(4) == 'float') {
					var array:Array<String> = v.split(',');
					var array2:Array<Float> = new Array();

					for (vars in array) {
						array2.push(Std.parseFloat(vars));
					}

					return array2;
				} else if (type.substr(4) == 'int') {
					var array:Array<String> = v.split(',');
					var array2:Array<Int> = new Array();

					for (vars in array) {
						array2.push(Std.parseInt(vars));
					}

					return array2;
				} else {
					var array:Array<String> = v.split(',');

					return array;
				}
			} else if (type == 'float') {
				return Std.parseFloat(v);
			} else if (type == 'int') {
				return Std.parseInt(v);
			} else if (type == 'bool') {
				if (v == 'true') {
					return true;
				} else {
					return false;
				}
			} else {
				return v;
			}
		} else {
			return v;
		}
	}

	public function getVar(var_name:String, type:String):Dynamic {
		var result:Any = null;

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
			return null;
		else {
			var new_result = convert(result, type);
			return new_result;
		}
	}

	public function executeState(name, args:Array<Dynamic>) {
		for (script in extra_scripts) {
			script.executeState(name, args);
		}

		return Lua.tostring(lua, callLua(name, args));
	}

	function cameraFromString(cam:String):FlxCamera {
		switch (cam.toLowerCase()) {
			case 'camhud' | 'hud':
				return PlayState.instance.camHUD;
		}

		return PlayState.instance.camGame;
	}

	@:access(openfl.display.BlendMode)
	inline function blendModeFromString(blend:String):BlendMode {
		return BlendMode.fromString(blend.toLowerCase());
	}

	public static function easeFromString(?ease:String = ''):Float->Float {
		switch (ease.toLowerCase().trim()) {
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}

		return FlxEase.linear;
	}
}
#end
