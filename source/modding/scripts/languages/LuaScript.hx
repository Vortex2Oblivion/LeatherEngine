package modding.scripts.languages;

#if LUA_ALLOWED
#if MODCHARTING_TOOLS
import modcharting.ModchartFuncs;
#end
import modding.helpers.FlxTweenUtil;
import flixel.addons.effects.FlxTrail;
import openfl.display.BlendMode;
import flixel.FlxCamera;
import game.DancingSprite;
import game.Boyfriend;
import ui.HealthIcon;
import hxnoise.Perlin;
import utilities.NoteVariables;
import game.Note;
import flixel.math.FlxMath;
import openfl.filters.BitmapFilter;
import flixel.math.FlxPoint;
import shaders.custom.CustomShader;
import openfl.filters.ShaderFilter;
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
import flixel.text.FlxText;
import haxe.Json;
import flixel.util.FlxStringUtil;
import openfl.display.ShaderParameter;

using StringTools;

typedef LuaCamera = {
	var cam:FlxCamera;
	var shaders:Array<BitmapFilter>;
	var shaderNames:Array<String>;
}

class LuaScript extends Script {
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
	public static var lua_Jsons:Map<String, Dynamic> = [];
	public static var lua_Tweens:Map<String, FlxTween> = [];

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
		else if (lua_Jsons.exists(id))
			return lua_Jsons.get(id);
		else if (lua_Tweens.exists(id))
			return lua_Tweens.get(id);

		if (Reflect.getProperty(PlayState.instance, id) != null)
			return Reflect.getProperty(PlayState.instance, id);
		else if (Reflect.getProperty(PlayState, id) != null)
			return Reflect.getProperty(PlayState, id);

		if (PlayState.strumLineNotes.length - 1 >= Std.parseInt(id))
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

	override public function destroy() {
		if (lua != null) {
			trails.clear();
			Lua.close(lua);
			lua = null;
		}
	}

	function getLuaErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);

		return v;
	}

	override public function set(name:String, value:Any):Void {
		Convert.toLua(lua, value);
		Lua.setglobal(lua, name);
	}

	public var trails:Map<String, FlxTrail> = [];

	public var perlin:Perlin;

	/**
	 * Easy wrapper for `Lua_helper.add_callback`.
	 * @param name Function name
	 * @param func Function to use
	 */
	inline public function setFunction(name:String, func:Any):Void {
		Lua_helper.add_callback(lua, name, func);
	}

	public function new(path:String, executeOn:ExecuteOn = BOTH) {
		super(path, executeOn);
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

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

		lua_Sounds.set("Voices", PlayState.instance.vocals.members[0]);

		for (sound in 0...PlayState.instance.vocals.length) {
			lua_Sounds.set("Voices" + sound, PlayState.instance.vocals.members[sound]);
		}

		// trace("lua version: " + Lua.version());
		// trace("LuaJIT version: " + Lua.versionJIT());

		Lua.init_callbacks(lua);

		var result:Int = LuaL.dofile(lua, path); // execute le file

		if (result != 0) {
			CoolUtil.coolError("Lua ERROR:\n" + Lua.tostring(lua, result), "Leather Engine Modcharts");
			// return;
			// FlxG.switchState(new MainMenuState());
		}

		// get some fukin globals up in here bois
		set("songLower", PlayState.SONG.song.toLowerCase());
		set("difficulty", PlayState.storyDifficultyStr);
		set("bpm", Conductor.bpm);
		set("songBpm", PlayState.SONG.bpm);
		set("keyCount", PlayState.SONG.keyCount);
		set("playerKeyCount", PlayState.SONG.playerKeyCount);
		set("scrollspeed", PlayState.SONG.speed);
		set("fpsCap", Options.getData("maxFPS"));
		set("opponentPlay", PlayState.characterPlayingAs == 1);
		set("bot", Options.getData("botplay"));
		set("noDeath", Options.getData("noDeath"));
		set("downscroll", Options.getData("downscroll") == true ? 1 : 0); // fuck you compatibility
		set("downscrollBool", Options.getData("downscroll"));
		set("middlescroll", Options.getData("middlescroll"));
		set("flashingLights", Options.getData("flashingLights"));
		set("flashing", Options.getData("flashingLights"));
		set("distractions", true);
		set("cameraZooms", Options.getData("cameraZooms"));
		set("shaders", Options.getData("shaders"));

		set("animatedBackgrounds", Options.getData("animatedBGs"));
		set("charsAndBGs", Options.getData("charsAndBGs"));

		set("curStep", 0);
		set("curBeat", 0);
		set("stepCrochet", Conductor.stepCrochet);
		set("crochetUnscaled", Conductor.stepCrochet);
		set("crochet", Conductor.crochet);
		set("safeZoneOffset", Conductor.safeZoneOffset);

		set("hudZoom", PlayState.instance.camHUD.zoom);
		set("cameraZoom", FlxG.camera.zoom);

		set("cameraAngle", FlxG.camera.angle);
		set("camHudAngle", PlayState.instance.camHUD.angle);

		set("followXOffset", 0);
		set("followYOffset", 0);

		set("showOnlyStrums", false);
		set("strumLine1Visible", true);
		set("strumLine2Visible", true);

		// WHY DOES THIS OFFSET CURSTEP BY 500????????
		// WHAT THE FUCK????????????????
		// this is my fucking tf2 coconut
		/*set("screenWidth", FlxG.stage.window.display.currentMode.width);
			set("screenHeight", FlxG.stage.window.display.currentMode.height); */
		set("windowWidth", FlxG.width);
		set("windowHeight", FlxG.height);

		set("hudWidth", PlayState.instance.camHUD.width);
		set("hudHeight", PlayState.instance.camHUD.height);

		set("mustHit", false);
		set("strumLineX", PlayState.instance.strumLine.x);
		set("strumLineY", PlayState.instance.strumLine.y);

		set("characterPlayingAs", PlayState.characterPlayingAs);
		set("inReplay", false);

		set("player1", PlayState.SONG.player1);
		set("player2", PlayState.SONG.player2);

		set("curStage", PlayState.SONG.stage);

		set("mobile", FlxG.onMobile);

		set("curMod", Options.getData("curMod"));
		set("developer", Options.getData("developer"));

		// other globals

		set('flxColor', {
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
		});

		set("flxG", {
			width: FlxG.width,
			height: FlxG.height,
			elapsed: FlxG.elapsed,
		});

		set("flxMath", {
			EPSILON: FlxMath.EPSILON,
			MAX_VALUE_FLOAT: FlxMath.MAX_VALUE_FLOAT,
			MAX_VALUE_INT: FlxMath.MAX_VALUE_INT,
			MIN_VALUE_FLOAT: FlxMath.MIN_VALUE_FLOAT,
			MIN_VALUE_INT: FlxMath.MIN_VALUE_INT,
			SQUARE_ROOT_OF_TWO: FlxMath.SQUARE_ROOT_OF_TWO,
		});

		set("haxeMath", {
			NEGATIVE_INFINITY: Math.NEGATIVE_INFINITY,
			NaN: Math.NaN,
			POSITIVE_INFINITY: Math.NEGATIVE_INFINITY,
		});

		set("lua", {
			version: Lua.version(),
			versionJIT: Lua.versionJIT(),
		});

		set("SONG", PlayState.SONG);

		set("leatherEngine", {
			version: CoolUtil.getCurrentVersion().replace('v', ''),
			path: Sys.programPath(),
			cwd: Sys.getCwd(),
			systemName: Sys.systemName(),
		});

		// callbacks
		setFunction("trace", function(str:Dynamic, printType:String = "LOG") {
			trace('$path: $str', printType.toUpperCase());
		});

		setFunction("print", function(str:Dynamic, printType:String = "LOG") {
			trace('$path: $str', printType.toUpperCase());
		});

		setFunction("flashCamera", function(camera:String = "", color:String = "#FFFFFF", time:Float = 1, force:Bool = false) {
			if (Options.getData("flashingLights"))
				cameraFromString(camera).flash(FlxColor.fromString(color), time, null, force);
		});

		setFunction("fadeCamera", function(camera:String = "", color:String = "#FFFFFF", time:Float = 1, fadeIn:Bool = false, force:Bool = false) {
			if (Options.getData("flashingLights"))
				cameraFromString(camera).fade(FlxColor.fromString(color), time, fadeIn, null, force);
		});

		setFunction("triggerEvent", function(event_name:String, argument_1:Dynamic, argument_2:Dynamic) {
			var string_arg_1:String = Std.string(argument_1);
			var string_arg_2:String = Std.string(argument_2);

			if (!PlayState.instance.scripts.exists(event_name.toLowerCase())
				&& Assets.exists(Paths.lua("event data/" + event_name.toLowerCase()))) {
				var script = new LuaScript(Paths.getModPath(Paths.lua("event data/" + event_name.toLowerCase())));
				script.call("create", []);
				if (createPost) {
					script.call("createPost", []);
				}
				PlayState.instance.scripts.set(event_name.toLowerCase(), script);
			}

			PlayState.instance.processEvent([event_name, Conductor.songPosition, string_arg_1, string_arg_2]);
		});

		setFunction("addCharacterToMap", function(m:String, character:String) {
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

		setFunction("setCamera", function(id:String, camera:String = "") {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				Reflect.setProperty(actor, "cameras", [cameraFromString(camera)]);
		});

		setFunction("setObjectCamera", function(id:String, camera:String = "") {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				Reflect.setProperty(actor, "cameras", [cameraFromString(camera)]);
		});

		setFunction("justPressedDodgeKey", function() {
			return FlxG.keys.justPressed.SPACE;
		});

		setFunction("justPressed", function(key:String = "SPACE") {
			return Reflect.getProperty(FlxG.keys.justPressed, key);
		});

		setFunction("pressed", function(key:String = "SPACE") {
			return Reflect.getProperty(FlxG.keys.pressed, key);
		});

		setFunction("justReleased", function(key:String = "SPACE") {
			return Reflect.getProperty(FlxG.keys.justReleased, key);
		});

		setFunction("setGraphicSize", function(id:String, width:Float = 0, height:Float = 0) {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.setGraphicSize(width, height);
		});

		setFunction("updateHitbox", function(id:String) {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.updateHitbox();
		});

		setFunction("setBlendMode", function(id:String, blend:String = '') {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.blend = blendModeFromString(blend);
		});

		setFunction("getSingDirectionID", function(id:Int) {
			return
				['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'].indexOf(NoteVariables.characterAnimations[PlayState.SONG.playerKeyCount - 1][Std.int(Math.abs(id % PlayState.SONG.playerKeyCount))]);
		});

		// sprites

		// stage

		setFunction("makeStageSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.gpuBitmap(PlayState.instance.stage.stage + "/" + filename, "stages"));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.stage.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("makeStageAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

				Sprite.scale.set(size, sizeY == null ? size : sizeY);

				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.stage.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("makeStageDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

					Sprite.scale.set(size, sizeY == null ? size : sizeY);

					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);

					PlayState.instance.stage.add(Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		// regular

		setFunction("makeGraphic", function(id:String, width:Int, height:Int, color:String) {
			if (getActorByName(id) != null)
				getActorByName(id).makeGraphic(width, height, FlxColor.fromString(color));
		});

		setFunction("makeGraphicRGB", function(id:String, width:Int, height:Int, color:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).visible = true;
				var colors = color.split(',');
				var red = Std.parseInt(colors[0]);
				var green = Std.parseInt(colors[1]);
				var blue = Std.parseInt(colors[2]);
				getActorByName(id).makeGraphic(width, height, FlxColor.fromRGB(red, green, blue));
			}
		});

		setFunction("exists", function(id:String):Bool {
			if (getActorByName(id) != null)
				return Reflect.getProperty(getActorByName(id), 'exists') != true ? false : true;

			return false;
		});

		setFunction("color", function(r:Int, g:Int, b:Int, a:Int = 255):Int {
			return FlxColor.fromRGB(r, g, b, a);
		});

		setFunction("colorString", function(color:String):Int {
			return FlxColor.fromString(color);
		});

		setFunction("colorRGB", function(r:Int, g:Int, b:Int):Int {
			return FlxColor.fromRGB(r, g, b);
		});

		setFunction("colorRGBA", function(r:Int, g:Int, b:Int, a:Int):Int {
			return FlxColor.fromRGB(r, g, b, a);
		});

		setFunction("rgbToHsv", function(r:Int, g:Int, b:Int):Array<Int> {
			return CoolUtil.rgbToHsv(r, g, b);
		});

		setFunction("dominantColor", function(id:String):Int {
			if (getActorByName(id) != null)
				return CoolUtil.dominantColor(getActorByName(id));
			return 0;
		});

		setFunction("dominantColorFrame", function(id:String):Int {
			if (getActorByName(id) != null)
				return CoolUtil.dominantColorFrame(getActorByName(id));
			return 0;
		});

		// sprite functions

		setFunction("screenCenter", function(id:String, ?direction:String = "xy") {
			if (getActorByName(id) != null)
				getActorByName(id).screenCenter((direction.toLowerCase().contains('x') ? 0x01 : 0x00) + (direction.toLowerCase().contains('y') ? 0x10 : 0x00));
		});

		setFunction("center", function(id:String, ?direction:String = "xy") {
			if (getActorByName(id) != null)
				getActorByName(id).screenCenter((direction.toLowerCase().contains('x') ? 0x01 : 0x00) + (direction.toLowerCase().contains('y') ? 0x10 : 0x00));
		});

		setFunction("actorScreenCenter", function(id:String) {
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

		setFunction("add", function(id:String) {
			FlxG.state.add(getActorByName(id));
		});

		setFunction("remove", function(id:String, splice:Bool = true) {
			FlxG.state.remove(getActorByName(id), splice);
		});

		setFunction("kill", function(id:String) {
			getActorByName(id).kill();
		});

		setFunction("destroy", function(id:String) {
			getActorByName(id).destroy();
		});

		setFunction("insert", function(id:String, position:Int) {
			FlxG.state.insert(position, getActorByName(id));
		});

		// stage sprite functions

		setFunction("addStage", function(id:String) {
			PlayState.instance.stage.add(getActorByName(id));
		});

		setFunction("removeStage", function(id:String, splice:Bool = true) {
			PlayState.instance.stage.remove(getActorByName(id), splice);
		});

		setFunction("insertStage", function(id:String, position:Int) {
			PlayState.instance.stage.insert(position, getActorByName(id));
		});

		setFunction("setActorTextColor", function(id:String, color:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "color", FlxColor.fromString(color));
		});

		setFunction("setActorText", function(id:String, text:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "text", text);
		});

		setFunction("setActorFont", function(id:String, font:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "font", Paths.font(font));
		});

		setFunction("setActorOutlineColor", function(id:String, color:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "borderColor", FlxColor.fromString(color));
		});

		setFunction("setActorAlignment", function(id:String, align:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "alignment", align);
		});

		setFunction("makeText", function(id:String, text:String, x:Float, y:Float, size:Int = 32, font:String = "vcr.ttf", fieldWidth:Float = 0) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxText = new FlxText(x, y, fieldWidth, text, size);
				Sprite.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.TRANSPARENT);
				// Sprite.setFormat(Paths.font(font), size);
				Sprite.font = Paths.font(font);

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("newText", function(id:String, text:String, x:Float, y:Float, size:Int = 32, font:String = "vcr.ttf", fieldWidth:Float = 0) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxText = new FlxText(x, y, fieldWidth, text, size);
				Sprite.font = Paths.font(font);

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("newSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.gpuBitmap(filename));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);

				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("newSpriteCopy", function(id:String, targetID:String) {
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
				Sprite.shader = actor.shader;
				Sprite.color = actor.color;
				Sprite.antialiasing = actor.antialiasing;
				Sprite.cameras = actor.cameras;
				// trace('made sprite copy');
				lua_Sprites.set(id, Sprite);
			}
		});

		setFunction("newAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(filename);

				Sprite.scale.set(size, sizeY == null ? size : sizeY);

				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("newDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(filename);

					Sprite.scale.set(size, sizeY == null ? size : sizeY);

					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		setFunction("makeSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.gpuBitmap(filename));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);

				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("makeSpriteCopy", function(id:String, targetID:String) {
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
				Sprite.shader = actor.shader;
				Sprite.color = actor.color;
				Sprite.antialiasing = actor.antialiasing;
				Sprite.cameras = actor.cameras;
				// trace('made sprite copy');
				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			}
		});

		setFunction("makeAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(filename);

				Sprite.scale.set(size, sizeY == null ? size : sizeY);

				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setFunction("makeDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(filename);

					Sprite.scale.set(size, sizeY == null ? size : sizeY);

					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);

					PlayState.instance.add(Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		setFunction("destroySprite", function(id:String) {
			var sprite = lua_Sprites.get(id);

			if (sprite == null)
				return false;

			lua_Sprites.remove(id);

			PlayState.instance.remove(sprite);
			sprite.kill();
			sprite.destroy();

			return true;
		});

		setFunction("getIsColliding", function(sprite1Name:String, sprite2Name:String) {
			var sprite1 = getActorByName(sprite1Name);

			if (sprite1 != null) {
				var sprite2 = getActorByName(sprite2Name);

				if (sprite2 != null)
					return sprite1.overlaps(sprite2);
			}

			return false;
		});

		setFunction("addActorTrail", function(id:String, length:Int = 10, delay:Int = 3, alpha:Float = 0.4, diff:Float = 0.05) {
			if (!trails.exists(id) && getActorByName(id) != null) {
				var trail = new FlxTrail(getActorByName(id), null, length, delay, alpha, diff);

				PlayState.instance.insert(PlayState.instance.members.indexOf(getActorByName(id)) - 1, trail);

				trails.set(id, trail);
			} else
				trace("Trail " + id + " already exists (or actor is null)!!!");
		});

		setFunction("removeActorTrail", function(id:String) {
			if (trails.exists(id)) {
				PlayState.instance.remove(trails.get(id));

				trails.get(id).destroy();
				trails.remove(id);
			} else
				trace("Trail " + id + " doesn't exist!!!");
		});

		setFunction("getActorLayer", function(id:String) {
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

		setFunction("setActorLayer", function(id:String, layer:Int) {
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

		setFunction("getHealth", function() {
			return PlayState.instance.health;
		});

		setFunction("setHealth", function(heal:Float) {
			PlayState.instance.health = heal;
		});

		setFunction("getMinHealth", function() {
			return PlayState.instance.minHealth;
		});

		setFunction("getMaxHealth", function() {
			return PlayState.instance.maxHealth;
		});

		set('changeHealthRange', function(minHealth:Float, maxHealth:Float) {
			{
				var bar = PlayState.instance.healthBar;
				PlayState.instance.minHealth = minHealth;
				PlayState.instance.maxHealth = maxHealth;
				bar.setRange(minHealth, maxHealth);
			}
		});

		// hud/camera

		setFunction("setHudAngle", function(angle:Float) {
			PlayState.instance.camHUD.angle = angle;
		});

		setFunction("setHudPosition", function(x:Int, y:Int) {
			PlayState.instance.camHUD.x = x;
			PlayState.instance.camHUD.y = y;
		});

		setFunction("getHudX", function() {
			return PlayState.instance.camHUD.x;
		});

		setFunction("getHudY", function() {
			return PlayState.instance.camHUD.y;
		});

		setFunction("makeCamera", function(camStr:String) {
			var newCam:FlxCamera = new FlxCamera();
			newCam.bgColor.alpha = 0;
			PlayState.instance.reorderCameras(newCam);
			lua_Cameras.set(camStr, {cam: newCam, shaders: [], shaderNames: []});
			PlayState.instance.usedLuaCameras = true;
		});

		setFunction("setNoteCameras", function(camStr:String) {
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
				PlayState.instance.noteBG.camera = camList[0];
			}
		});

		setFunction("setObjectCameras", function(id:String, camStr:String) {
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

		setFunction("getCameraScrollX", function(camStr:String) {
			var cam = getCameraByName(camStr);
			if (cam != null) {
				return cam.cam.scroll.x;
			}
			return 0.0;
		});

		setFunction("getCameraScrollY", function(camStr:String) {
			var cam = getCameraByName(camStr);
			if (cam != null) {
				return cam.cam.scroll.y;
			}
			return 0.0;
		});

		setFunction("setCamPosition", function(x:Int, y:Int) {
			{
				PlayState.instance.camFollow.x = x;
				PlayState.instance.camFollow.y = y;
			}
		});

		setFunction("getCameraX", function() {
			return PlayState.instance.camFollow.x;
		});

		setFunction("getCameraY", function() {
			return PlayState.instance.camFollow.y;
		});

		setFunction("getCamZoom", function() {
			return FlxG.camera.zoom;
		});

		setFunction("getHudZoom", function() {
			return PlayState.instance.camHUD.zoom;
		});

		setFunction("setCamZoom", function(zoomAmount:Float) {
			FlxG.camera.zoom = zoomAmount;
		});

		setFunction("setHudZoom", function(zoomAmount:Float) {
			PlayState.instance.camHUD.zoom = zoomAmount;
		});

		// strumline

		setFunction("setStrumlineX", function(x:Float, ?dontMove:Bool = false) {
			PlayState.instance.strumLine.x = x;

			if (!dontMove) {
				for (note in PlayState.strumLineNotes) {
					note.x = x;
				}
			}
		});

		setFunction("setStrumlineY", function(y:Float, ?dontMove:Bool = false) {
			PlayState.instance.strumLine.y = y;

			if (!dontMove) {
				for (note in PlayState.strumLineNotes) {
					note.y = y;
				}
			}
		});

		// actors

		setFunction("getNoteProperty", function(note:Note, property:String):Dynamic {
			return Reflect.getProperty(note, property);
		});

		setFunction("makeNoteCopy", function(id:String, noteIdx:Int) {
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

		setFunction("getUnspawnNotes", function() {
			return PlayState.instance.unspawnNotes.length;
		});

		setFunction("getUnspawnedNoteType", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].arrow_Type;
		});

		setFunction("getUnspawnedNoteNoteType", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].arrow_Type;
		});

		setFunction("getUnspawnedNoteArrowType", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].arrow_Type;
		});

		setFunction("getUnspawnedNoteStrumtime", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].strumTime;
		});

		setFunction("getUnspawnedNoteMustPress", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].mustPress;
		});

		setFunction("getUnspawnedNoteSustainNote", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].isSustainNote;
		});

		setFunction("getUnspawnedNoteNoteData", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].noteData;
		});

		setFunction("getUnspawnedNoteData", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].noteData;
		});

		setFunction("getUnspawnedNoteScaleX", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].scale.x;
		});

		setFunction("getUnspawnedNoteScaleY", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].scale.y;
		});

		setFunction("getUnspawnedNoteSingAnimPrefix", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].singAnimPrefix;
		});

		setFunction("getUnspawnedNoteSingAnimSuffix", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].singAnimSuffix;
		});

		setFunction("setUnspawnedNoteSingAnimPrefix", function(id:Int, prefix:String) {
			PlayState.instance.unspawnNotes[id].singAnimPrefix = prefix;
		});

		setFunction("setUnspawnedNoteSingAnimSuffix", function(id:Int, suffix:String) {
			PlayState.instance.unspawnNotes[id].singAnimSuffix = suffix;
		});

		setFunction("setUnspawnedNoteXOffset", function(id:Int, offset:Float) {
			PlayState.instance.unspawnNotes[id].xOffset = offset;
		});

		setFunction("setUnspawnedNoteYOffset", function(id:Int, offset:Float) {
			PlayState.instance.unspawnNotes[id].yOffset = offset;
		});

		setFunction("setUnspawnedNoteAngle", function(id:Int, offset:Float) {
			PlayState.instance.unspawnNotes[id].localAngle = offset;
		});

		setFunction("getRenderedNotes", function() {
			return PlayState.instance.notes.length;
		});

		setFunction("getRenderedNoteX", function(id:Int) {
			return PlayState.instance.notes.members[id].x;
		});

		setFunction("getRenderedNoteY", function(id:Int) {
			return PlayState.instance.notes.members[id].y;
		});

		setFunction("getRenderedNoteType", function(id:Int) {
			return PlayState.instance.notes.members[id].arrow_Type;
		});

		setFunction("getRenderedNoteData", function(id:Int) {
			return PlayState.instance.notes.members[id].noteData;
		});

		setFunction("getRenderedNoteArrowType", function(id:Int) {
			return PlayState.instance.notes.members[id].arrow_Type;
		});

		setFunction("getRenderedNoteParentX", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.x;
		});

		setFunction("getRenderedNoteParentY", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.y;
		});

		setFunction("getRenderedNoteHit", function(id:Int) {
			return PlayState.instance.notes.members[id].mustPress;
		});

		setFunction("getRenderedNoteCalcX", function(id:Int) {
			if (PlayState.instance.notes.members[id].mustPress)
				return PlayState.playerStrums.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;

			return PlayState.strumLineNotes.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
		});

		setFunction("getRenderedNoteStrumtime", function(id:Int) {
			return PlayState.instance.notes.members[id].strumTime;
		});

		setFunction("getRenderedNoteScaleX", function(id:Int) {
			return PlayState.instance.notes.members[id].scale.x;
		});

		setFunction("getRenderedNoteScaleY", function(id:Int) {
			return PlayState.instance.notes.members[id].scale.y;
		});

		setFunction("setRenderedNotePos", function(x:Float, y:Float, id:Int) {
			if (PlayState.instance.notes.members[id] == null)
				throw('error! you cannot set a rendered notes position when it doesnt exist! ID: ' + id);
			else {
				PlayState.instance.notes.members[id].x = x;
				PlayState.instance.notes.members[id].y = y;
			}
		});

		setFunction("setRenderedNoteAlpha", function(alpha:Float, id:Int) {
			PlayState.instance.notes.members[id].alpha = alpha;
		});

		setFunction("setRenderedNoteScale", function(scale:Float, id:Int) {
			PlayState.instance.notes.members[id].setGraphicSize(PlayState.instance.notes.members[id].width * scale);
		});

		setFunction("setRenderedNoteScale", function(scaleX:Int, scaleY:Int, id:Int) {
			PlayState.instance.notes.members[id].setGraphicSize(scaleX, scaleY);
		});

		setFunction("setRenderedNoteScaleX", function(scale:Float, id:Int) {
			PlayState.instance.notes.members[id].scale.x = scale;
		});

		setFunction("setRenderedNoteScaleY", function(scale:Float, id:Int) {
			PlayState.instance.notes.members[id].scale.y = scale;
		});

		setFunction("setRenderedNoteScaleXY", function(scaleX:Int, scaleY:Int, id:Int) {
			PlayState.instance.notes.members[id].scale.set(scaleX, scaleY);
		});

		setFunction("isRenderedNoteSustainEnd", function(id:Int) {
			if (PlayState.instance.notes.members[id].animation.curAnim != null)
				return PlayState.instance.notes.members[id].animation.curAnim.name.endsWith('end');
			return false;
		});

		setFunction("getRenderedNoteSustainScaleY", function(id:Int) {
			return PlayState.instance.notes.members[id].sustainScaleY;
		});

		setFunction("getRenderedNoteOffsetX", function(id:Int) {
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

		setFunction("getRenderedNoteOffsetY", function(id:Int) {
			return PlayState.instance.notes.members[id].yOffset;
		});

		setFunction("getRenderedNoteWidth", function(id:Int) {
			return PlayState.instance.notes.members[id].width;
		});

		setFunction("getRenderedNoteHeight", function(id:Int) {
			return PlayState.instance.notes.members[id].height;
		});

		setFunction("getRenderedNotePrevNoteStrumtime", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNoteStrumtime;
		});

		setFunction("setRenderedNoteAngle", function(angle:Float, id:Int) {
			PlayState.instance.notes.members[id].modAngle = angle;
		});

		setFunction("setRenderedNoteSkewX", function(skew:Float, id:Int) {
			PlayState.instance.notes.members[id].skew.x = skew;
		});

		setFunction("setRenderedNoteSkewY", function(skew:Float, id:Int) {
			PlayState.instance.notes.members[id].skew.y = skew;
		});

		setFunction("getRenderedNoteSkewX", function(id:Int) {
			return PlayState.instance.notes.members[id].skew.x;
		});

		setFunction("getRenderedNoteSkewY", function(id:Int) {
			return PlayState.instance.notes.members[id].skew.y;
		});

		setFunction("isSustain", function(id:Int) {
			return PlayState.instance.notes.members[id].isSustainNote;
		});

		setFunction("isParentSustain", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.isSustainNote;
		});

		setFunction("setRenderedNoteColor", function(r:Float, g:Float, b:Float, id:Int) {
			var note:Note = PlayState.instance.notes.members[id];
			note.colorSwap.r = r;
			note.colorSwap.g = g;
			note.colorSwap.b = b;
		});

		setFunction("setUnspawnedNoteColor", function(r:Float, g:Float, b:Float, id:Int) {
			var note:Note = PlayState.instance.unspawnNotes[id];
			note.colorSwap.r = r;
			note.colorSwap.g = g;
			note.colorSwap.b = b;
		});

		setFunction("setRenderedNoteColorForce", function(r:Float, g:Float, b:Float, id:Int) {
			var note:Note = PlayState.instance.notes.members[id];
			note.shader = note.colorSwap.shader;
			note.colorSwap.r = r;
			note.colorSwap.g = g;
			note.colorSwap.b = b;
		});

		setFunction("setUnspawnedNoteColorForce", function(r:Float, g:Float, b:Float, id:Int) {
			var note:Note = PlayState.instance.unspawnNotes[id];
			note.shader = note.colorSwap.shader;
			note.colorSwap.r = r;
			note.colorSwap.g = g;
			note.colorSwap.b = b;
		});

		setFunction("getRenderedNoteColor", function(id:Int):Dynamic {
			var note:Note = PlayState.instance.notes.members[id];
			return {r: note.colorSwap.r, g: note.colorSwap.g, b: note.colorSwap.b};
		});

		setFunction("getUnspawnedNoteColor", function(id:Int):Dynamic {
			var note:Note = PlayState.instance.unspawnNotes[id];
			return {r: note.colorSwap.r, g: note.colorSwap.g, b: note.colorSwap.b};
		});

		setFunction("getRenderedNoteAffectedByColor", function(id:Int):Bool {
			return PlayState.instance.notes.members[id].affectedbycolor;
		});

		setFunction("getUnspawnedNoteAffectedByColor", function(id:Int):Bool {
			return PlayState.instance.notes.members[id].affectedbycolor;
		});

		setFunction("setRenderedNoteSpeed", function(speed:Float, id:Int) {
			PlayState.instance.notes.members[id].speed = speed;
		});

		setFunction("getRenderedNoteSpeed", function(id:Int) {
			return PlayState.instance.notes.members[id].speed;
		});

		setFunction("setUnspawnNoteSpeed", function(speed:Float, id:Int) {
			PlayState.instance.unspawnNotes[id].speed = speed;
		});

		setFunction("getUnspawnNoteSpeed", function(id:Int) {
			return PlayState.instance.unspawnNotes[id].speed;
		});

		setFunction("anyNotes", function() {
			return PlayState.instance.notes.members.length != 0;
		});

		setFunction("setActorPos", function(x:Float, y:Float, id:String) {
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

		setFunction("setActorScroll", function(x:Float, y:Float, id:String) {
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

		setFunction("setActorX", function(x:Float, id:String) {
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

		setFunction("getOriginalCharX", function(character:Int) {
			return PlayState.instance.stage.getCharacterPos(character)[0];
		});

		setFunction("getOriginalCharY", function(character:Int) {
			return PlayState.instance.stage.getCharacterPos(character)[1];
		});

		setFunction("setActorAccelerationX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).acceleration.x = x;
			}
		});

		setFunction("setActorDragX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).drag.x = x;
			}
		});

		setFunction("setActorVelocityX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).velocity.x = x;
			}
		});

		setFunction("setActorOriginX", function(x:Float, id:String) {
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

		setFunction("setActorOriginY", function(x:Float, id:String) {
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

		setFunction("setActorAntialiasing", function(antialiasing:Bool, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).antialiasing = antialiasing && Options.getData("antialiasing");
			}
		});

		setFunction("addActorAnimation", function(id:String, prefix:String, anim:String, fps:Int = 30, looped:Bool = true) {
			if (getActorByName(id) != null) {
				getActorByName(id).animation.addByPrefix(prefix, anim, fps, looped);
			}
		});

		setFunction("addActorAnimationIndices", function(id:String, prefix:String, indiceString:String, anim:String, fps:Int = 30, looped:Bool = true) {
			if (getActorByName(id) != null) {
				var indices:Array<Dynamic> = indiceString.split(",");

				for (indiceIndex in 0...indices.length) {
					indices[indiceIndex] = Std.parseInt(indices[indiceIndex]);
				}

				getActorByName(id).animation.addByIndices(anim, prefix, indices, "", fps, looped);
			}
		});

		setFunction("playCharAnim", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).playAnim(anim, force, reverse, frame);
			}
		});

		setFunction("playAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			var obj:FlxSprite = getActorByName(id);
			if (obj != null) {
				if (obj is Character)
					cast(obj, Character).playAnim(anim, force, reverse, frame);
				else
					obj.animation.play(anim, force, reverse, frame);
			}
		});

		setFunction("dance", function(id:String, ?altAnim:String = '') {
			if (getActorByName(id) != null) {
				getActorByName(id).dance(altAnim);
			}
		});

		setFunction("playActorAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
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

		setFunction("playActorDance", function(id:String, ?altAnim:String = '') {
			if (getActorByName(id) != null) {
				getActorByName(id).dance(altAnim);
			}
		});

		setFunction("playCharacterAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).playAnim(anim, force, reverse, frame);
			}
		});

		setFunction("setCharacterShouldDance", function(id:String, shouldDance:Bool = true) {
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
		setFunction("setCharacterPlayFullAnim", function(id:String, playFullAnim:Bool = true) {
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

		setFunction("setCharacterSingPrefix", function(id:String, prefix:String) {
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

		setFunction("setCharacterPreventDanceForAnim", function(id:String, preventDanceForAnim:Bool = true) {
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

		setFunction("playCharacterDance", function(id:String, ?altAnim:String) {
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

		setFunction("getPlayingActorAnimation", function(id:String) {
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

		setFunction("getPlayingActorAnimationFrame", function(id:String) {
			if (getActorByName(id) != null) {
				if (Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim") != null)
					return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim"), "curFrame");
			}

			return 0;
		});

		setFunction("setActorAlpha", function(alpha:Float, id:String) {
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

		setFunction("setActorVisible", function(visible:Bool, id:String) {
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

		setFunction("setActorColor", function(id:String, r:Int, g:Int, b:Int, alpha:Int = 255) {
			if (getActorByName(id) != null) {
				Reflect.setProperty(getActorByName(id), "color", FlxColor.fromRGB(r, g, b, alpha));
			}
		});

		setFunction("setActorColorRGB", function(id:String, color:String) {
			var actor:FlxSprite = getActorByName(id);

			var colors = color.split(',');
			var red = Std.parseInt(colors[0]);
			var green = Std.parseInt(colors[1]);
			var blue = Std.parseInt(colors[2]);

			if (actor != null)
				Reflect.setProperty(actor, "color", FlxColor.fromRGB(red, green, blue));
		});

		setFunction("setActorY", function(y:Float, id:String) {
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

		setFunction("setActorAccelerationY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).acceleration.y = y;
			}
		});

		setFunction("setActorDragY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).drag.y = y;
			}
		});

		setFunction("setActorVelocityY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).velocity.y = y;
			}
		});

		setFunction("setActorAngle", function(angle:Float, id:String) {
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

		setFunction("setActorModAngle", function(angle:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).modAngle = angle;
		});

		setFunction("setActorScale", function(scale:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).setGraphicSize(getActorByName(id).width * scale);
		});

		setFunction("setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).setGraphicSize(getActorByName(id).width * scaleX, getActorByName(id).height * scaleY);
		});

		setFunction("setActorFlipX", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).flipX = flip;
		});

		setFunction("setActorFlipY", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).flipY = flip;
		});

		setFunction("getActorFlipX", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).flipX;
			return false;
		});

		setFunction("getActorFlipY", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).flipY;
			return false;
		});

		setFunction("setActorTrailVisible", function(id:String, visibleVal:Bool) {
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

		setFunction("getActorTrailVisible", function(id:String) {
			var char = getCharacterByName(id);

			if (char != null) {
				if (char.coolTrail != null)
					return char.coolTrail.visible;
				else
					return false;
			} else
				return false;
		});

		setFunction("getActorWidth", function(id:String) {
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

		setFunction("getActorHeight", function(id:String) {
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

		setFunction("getActorAlpha", function(id:String) {
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

		setFunction("getActorAngle", function(id:String) {
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

		setFunction("getActorX", function(id:String) {
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

		setFunction("getActorY", function(id:String) {
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

		setFunction("setActorReflection", function(id:String, r:Bool) {
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

		setFunction("setActorReflectionYOffset", function(id:String, y:Float) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "reflectionYOffset", y);
					return;
				}
			}
			Reflect.setProperty(getActorByName(id), "reflectionYOffset", y);
		});

		setFunction("setActorReflectionAlpha", function(id:String, a:Float) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "reflectionAlpha", a);
					return;
				}
			}
			Reflect.setProperty(getActorByName(id), "reflectionAlpha", a);
		});

		setFunction("setActorReflectionColor", function(id:String, color:String) {
			if (getCharacterByName(id) != null) {
				var character = getCharacterByName(id);
				if (character.otherCharacters != null && character.otherCharacters.length > 0) {
					Reflect.setProperty(character.otherCharacters[0], "reflectionColor", FlxColor.fromString(color));
					return;
				}
			}
			Reflect.setProperty(getActorByName(id), "reflectionColor", FlxColor.fromString(color));
		});

		setFunction("setWindowPos", function(x:Int, y:Int) {
			Application.current.window.move(x, y);
		});

		setFunction("getWindowX", function() {
			return Application.current.window.x;
		});

		setFunction("getWindowY", function() {
			return Application.current.window.y;
		});

		setFunction("getCenteredWindowX", function() {
			return (Application.current.window.display.currentMode.width / 2) - (Application.current.window.width / 2);
		});

		setFunction("getCenteredWindowY", function() {
			return (Application.current.window.display.currentMode.height / 2) - (Application.current.window.height / 2);
		});

		setFunction("resizeWindow", function(Width:Int, Height:Int) {
			Application.current.window.resize(Width, Height);
		});

		setFunction("getScreenWidth", function() {
			return Application.current.window.display.currentMode.width;
		});

		setFunction("getScreenHeight", function() {
			return Application.current.window.display.currentMode.height;
		});

		setFunction("getWindowWidth", function() {
			return Application.current.window.width;
		});

		setFunction("getWindowHeight", function() {
			return Application.current.window.height;
		});

		setFunction("setCanFullscreen", function(can_Fullscreen:Bool) {
			PlayState.instance.canFullscreen = can_Fullscreen;
		});

		setFunction("changeDadCharacter", function(character:String) {
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
		});

		setFunction("changeBoyfriendCharacter", function(character:String) {
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

		setFunction("getBaseScrollSpeed", function() {
			return original_Scroll_Speed;
		});

		setFunction("getScrollSpeed", function() {
			return PlayState.SONG.speed;
		});

		setFunction("setScrollSpeed", function(speed:Float) {
			PlayState.SONG.speed = speed;
		});

		// sounds

		setFunction("createSound", function(id:String, file_Path:String, library:String, ?looped:Bool = false) {
			if (lua_Sounds.get(id) == null) {
				lua_Sounds.set(id, new FlxSound().loadEmbedded(Paths.sound(file_Path, library), looped));
				FlxG.sound.list.add(lua_Sounds.get(id));
			} else
				trace("Error! Sound " + id + " already exists! Try another sound name!");
		});

		setFunction("removeSound", function(id:String) {
			if (lua_Sounds.get(id) != null) {
				FlxG.sound.list.remove(lua_Sounds.get(id));

				var sound = lua_Sounds.get(id);
				sound.stop();
				sound.kill();
				sound.destroy();

				lua_Sounds.set(id, null);
			}
		});

		setFunction("playSound", function(id:String, ?forceRestart:Bool = false) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).play(forceRestart);
		});

		setFunction("stopSound", function(id:String) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).stop();
		});

		setFunction("pauseSound", function(id:String) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).pause();
		});

		setFunction("resumeSound", function(id:String) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).resume();
		});

		setFunction("setSoundVolume", function(id:String, volume:Float) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).volume = volume;
		});

		setFunction("getSoundTime", function(id:String) {
			if (lua_Sounds.get(id) != null)
				return lua_Sounds.get(id).time;

			return 0;
		});

		// tweens

		setFunction("tween", function(obj:String, properties:Dynamic, duration:Float, ease:String, ?startDelay:Float = 0.0, ?onComplete:Dynamic) {
			var spr:Dynamic = getActorByName(obj);
			if (spr != null) {
				lua_Tweens.set('$obj.$properties', FlxTween.tween(spr, properties, duration, {
					ease: easeFromString(ease),
					onComplete: function(twn) {
						lua_Tweens.remove('$obj.$properties');
						if (onComplete != null){
							onComplete();
						}
					},
					startDelay: startDelay,
				}));
			} else {
				trace('Object named $obj doesn\'t exist!', ERROR);
			}
		});

		setFunction("tweenCancel", function(tween:String) {
			var twn:FlxTween = lua_Tweens.get(tween);
			if (twn != null) {
				twn.cancel();
				lua_Tweens.remove(tween);
			} else {
				trace('Tween $tween doesn\'t exist!', ERROR);
			}
		});

		setFunction("tweenPause", function(tween:String) {
			var twn:FlxTween = lua_Tweens.get(tween);
			if (twn != null) {
				FlxTweenUtil.pauseTween(twn);
			} else {
				trace('Tween $tween doesn\'t exist!', ERROR);
			}
		});

		setFunction("tweenResume", function(tween:String) {
			var twn:FlxTween = lua_Tweens.get(tween);
			if (twn != null) {
				FlxTweenUtil.resumeTween(twn);
			} else {
				trace('Tween $tween doesn\'t exist!', ERROR);
			}
		});

		setFunction("cancelTweensOf", function(object:String, ?fieldPaths:Array<String>) {
			var obj:Dynamic = getActorByName(object);
			if (obj != null) {
				FlxTween.cancelTweensOf(obj, fieldPaths);
			} else {
				trace('Object $object doesn\'t exist!', ERROR);
			}
		});

		setFunction("pauseTweensOf", function(object:String, ?fieldPaths:Array<String>) {
			var obj:Dynamic = getActorByName(object);
			if (obj != null) {
				FlxTweenUtil.pauseTweensOf(obj, fieldPaths);
			} else {
				trace('Object $object doesn\'t exist!', ERROR);
			}
		});

		setFunction("resumeTweensOf", function(object:String, ?fieldPaths:Array<String>) {
			var obj:Dynamic = getActorByName(object);
			if (obj != null) {
				FlxTweenUtil.resumeTweensOf(obj, fieldPaths);
			} else {
				trace('Object $object doesn\'t exist!', ERROR);
			}
		});


		setFunction("tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenPos", function(id:String, toX:Int, toY:Int, time:Float, ?onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.quintInOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenCameraZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenCameraZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.quintInOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
			PlayState.instance.tweenManager.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						call(onComplete, ["camera"]);
					}
				}
			});
		});

		setFunction("tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenFadeOut", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.circOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenFadeCubeInOut", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.cubeInOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenActorColor", function(id:String, r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int, time:Float, onComplete:String = "") {
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				FlxTween.color(actor, time, FlxColor.fromRGB(r1, g1, b1, 255), FlxColor.fromRGB(r2, g2, b2, 255), {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
			}
		});

		setFunction("tweenScaleX", function(id:String, toScale:Float, time:Float, easeStr:String = "", onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id).scale, {x: toScale}, time, {
					ease: easeFromString(easeStr),
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});
		setFunction("tweenScaleY", function(id:String, toScale:Float, time:Float, easeStr:String = "", onComplete:String = "") {
			if (getActorByName(id) != null)
				PlayState.instance.tweenManager.tween(getActorByName(id).scale, {y: toScale}, time, {
					ease: easeFromString(easeStr),
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
		});

		setFunction("tweenActorProperty", function(id:String, prop:String, value:Dynamic, time:Float, easeStr:String = "linear") {
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

		setFunction("setActorProperty", function(id:String, prop:String, value:Dynamic) {
			var actor = getActorByName(id);
			if (actor != null && Reflect.getProperty(actor, prop) != null) {
				Reflect.setProperty(actor, prop, value);
			}
		});

		setFunction("tweenActorColor", function(id:String, r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int, time:Float, onComplete:String = "") {
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				FlxTween.color(actor, time, FlxColor.fromRGB(r1, g1, b1, 255), FlxColor.fromRGB(r2, g2, b2, 255), {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							call(onComplete, [id]);
						}
					}
				});
			}
		});

		// properties

		setFunction("set", function(property:Dynamic, value:Dynamic):Void {
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

		setFunction("get", function(property:Dynamic):Dynamic {
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

		setFunction("setClass", function(class_name:String, property:Dynamic, value:Dynamic):Void {
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

		setFunction("getClass", function(class_name:String, property:Dynamic):Dynamic {
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

		setFunction("setProperty", function(object:String, property:String, value:Dynamic) {
			if (object != "") {
				if (Reflect.getProperty(PlayState.instance, object) != null)
					Reflect.setProperty(Reflect.getProperty(PlayState.instance, object), property, value);
				else
					Reflect.setProperty(Reflect.getProperty(PlayState, object), property, value);
			} else {
				if (Reflect.getProperty(PlayState.instance, property) != null)
					Reflect.setProperty(PlayState.instance, property, value);
				else
					Reflect.setProperty(PlayState, property, value);
			}
		});

		setFunction("getProperty", function(object:String, property:String) {
			if (object != "") {
				if (Reflect.getProperty(PlayState.instance, object) != null)
					return Reflect.getProperty(Reflect.getProperty(PlayState.instance, object), property);
				else
					return Reflect.getProperty(Reflect.getProperty(PlayState, object), property);
			} else {
				if (Reflect.getProperty(PlayState.instance, property) != null)
					return Reflect.getProperty(PlayState.instance, property);
				else
					return Reflect.getProperty(PlayState, property);
			}
		});

		setFunction("getPropertyFromClass", function(className:String, variable:String) {
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

		setFunction("setPropertyFromClass", function(className:String, variable:String, value:Dynamic) {
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

		setFunction("setSongPosition", function(position:Float) {
			Conductor.songPosition = position;
			set('songPos', Conductor.songPosition);
		});

		setFunction("getSongPosition", function() {
			return Conductor.songPosition;
		});

		setFunction("stopSong", function() {
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

		setFunction("endSong", function() {
			FlxG.sound.music.time = FlxG.sound.music.length;
			PlayState.instance.vocals.time = FlxG.sound.music.length;

			PlayState.instance.health = 500000;
			PlayState.instance.invincible = true;

			PlayState.instance.stopSong = false;
			PlayState.instance.resyncVocals();
		});

		setFunction("getCharFromEvent", function(eventId:String) {
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

		setFunction("charFromEvent", function(id:String) {
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

		setFunction("tweenStageColorSwap", function(prop:String, value:Dynamic, time:Float, easeStr:String = "linear") {
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

		setFunction("setStageColorSwap", function(prop:String, value:Dynamic) {
			var actor = PlayState.instance.stage.colorSwap;

			if (actor != null) {
				Reflect.setProperty(actor, prop, value);
			}
		});

		setFunction("getStrumTimeFromStep", function(step:Float) {
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

		setFunction("setActor3DShader", function(id:String, ?speed:Float = 3, ?frequency:Float = 10, ?amplitude:Float = 0.25) {
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

		setFunction("setActorNoShader", function(id:String) {
			var actor = getActorByName(id);

			if (actor != null) {
				lua_Shaders.remove(id);
				actor.shader = null;
			}
		});

		setFunction("createCustomShader", function(id:String, frag:String, ?vert:String) {
			var _vert:String = Assets.exists(Paths.vert(vert)) ? Assets.getText(Paths.vert(vert)) : null;
			lua_Custom_Shaders.set(id, new CustomShader(Assets.getText(Paths.frag(frag)), _vert));
		});

		setFunction("setActorCustomShader", function(id:String, actor:String) {
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

		setFunction("setActorNoCustomShader", function(actor:String) {
			getActorByName(actor).shader = null;
		});

		setFunction("setCameraCustomShader", function(id:String, camera:String) {
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

		setFunction("pushShaderToCamera", function(id:String, camera:String) {
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

		setFunction("setCameraNoCustomShader", function(camera:String) {
			if (!Options.getData("shaders"))
				return;
			cameraFromString(camera).filters = null;
		});

		setFunction("getCustomShaderBool", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getBool(property);
		});

		setFunction("getCustomShaderInt", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getInt(property);
		});

		setFunction("getCustomShaderFloat", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getFloat(property);
		});

		setFunction("setCustomShaderBool", function(id:String, property:String, value:Bool) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setBool(property, value);
		});

		setFunction("setCustomShaderInt", function(id:String, property:String, value:Int) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setInt(property, value);
		});

		setFunction("setCustomShaderFloat", function(id:String, property:String, value:Float) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setFloat(property, value);
		});

		setFunction("tweenShader",
			function(id:String, property:String, value:Float, duration:Float, ease:String = "linear", startDelay:Float = 0.0, ?onComplete:Dynamic) {
				var shader:CustomShader = lua_Custom_Shaders.get(id);
				if (shader != null) {
					shader.tween(property, value, duration, easeFromString(ease), startDelay, onComplete);
				} else {
					trace('Shader named $id doesn\'t exist!', ERROR);
				}
			});

		// dumb vc functions
		setFunction("initShader", function(id:String, frag:String, ?vert:String) {
			var _vert:String = Assets.exists(Paths.vert(vert)) ? Assets.getText(Paths.vert(vert)) : null;
			lua_Custom_Shaders.set(id, new CustomShader(Assets.getText(Paths.frag(frag)), _vert));
		});

		setFunction("setActorShader", function(actorStr:String, shaderName:String) {
			if (!Options.getData("shaders"))
				return;

			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(shaderName);
			if (funnyCustomShader != null) {
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
					actor.shader = funnyCustomShader;
				}
			} else
				trace('Shader named $shaderName doesn\'t exist!', ERROR);
		});

		setFunction("setCameraShader", function(camera:String, id:String) {
			if (!Options.getData("shaders"))
				return;

			var cam = lua_Cameras.get(camera);
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			if (funnyCustomShader != null) {
				if (cam != null) {
					cam.shaders.push(new ShaderFilter(funnyCustomShader));
					cam.shaderNames.push(id);
					cam.cam.filters = cam.shaders;
				} else {
					trace('Camera named $camera doesn\'t exist!', ERROR);
				}
			} else {
				trace('Shader named $id doesn\'t exist!', ERROR);
			}
		});

		setFunction("removeCameraShader", function(camStr:String, shaderName:String) {
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
				} else {
					trace('Camera named $camStr doesn\'t contain the shader $shaderName!', ERROR);
				}
			} else {
				trace('Camera named $camStr doesn\'t exist!', ERROR);
			}
		});

		setFunction("setShaderProperty", function(id:String, property:String, value:Dynamic) {
			if (!Options.getData("shaders"))
				return;
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			if (funnyCustomShader != null) {
				var intParam:ShaderParameter<Int> = Reflect.field(funnyCustomShader.data, property);
				if (intParam != null) {
					funnyCustomShader.setInt(property, Std.parseInt(value));
				} else if (value is Float) {
					funnyCustomShader.setFloat(property, Std.parseFloat(value));
				} else if (value is Bool) {
					funnyCustomShader.setBool(property, value);
				} else if (value is Array) {
					if (value[0] is Float) {
						funnyCustomShader.setFloatArray(property, value);
					} else if (value[0] is Bool) {
						funnyCustomShader.setBoolArray(property, value);
					} else {
						funnyCustomShader.setIntArray(property, value);
					}
				} else {
					FlxG.log.warn('Shader parameter "$property" not found on shader $id.');
				}
			} else {
				trace('Shader named $id doesn\'t exist!', ERROR);
			}
		});

		setFunction("tweenShaderProperty",
			function(id:String, property:String, value:Float, duration:Float, ease:String = "linear", startDelay:Float = 0.0, ?onComplete:Dynamic) {
				if (!Options.getData("shaders"))
					return;
				var shader:CustomShader = lua_Custom_Shaders.get(id);
				if (shader != null) {
					shader.tween(property, value, duration, easeFromString(ease), startDelay, onComplete);
				} else {
					trace('Shader named $id doesn\'t exist!', ERROR);
				}
			});

		setFunction("updateRating", function() {
			PlayState.instance.updateRating();
		});

		// utilities
		setFunction("arrayToCSV", function(data:Array<Int>, width:Int, invert:Bool):String {
			return FlxStringUtil.arrayToCSV(data, width, invert);
		});

		setFunction("filterDigits", function(input:String):String {
			return FlxStringUtil.filterDigits(input);
		});

		setFunction("formatArray", function(anyArray:Array<Dynamic>):String {
			return FlxStringUtil.formatArray(anyArray);
		});

		setFunction("formatBytes", function(bytes:Float, precision:Int = 2):String {
			return FlxStringUtil.formatBytes(bytes, precision);
		});

		setFunction("formatTime", function(seconds:Float, showMS:Bool = false):String {
			return FlxStringUtil.formatTime(seconds, showMS);
		});

		setFunction("getClassName", function(object:Dynamic, simple:Bool = false):String {
			return FlxStringUtil.getClassName(object, simple);
		});

		setFunction("printIP", function():Void {
			trace('${FlxG.random.int(100, 999)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}');
		});

		setFunction("getIP", function():String {
			return '${FlxG.random.int(100, 999)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}';
		});

		setFunction("getOption", function(saveStr:String) {
			return Options.getData(saveStr);
		});

		setFunction("getCurrentMod", function(saveStr:String) {
			return Options.getData("curMod");
		});

		setFunction("assetExists", function(path:String) {
			return Assets.exists(path);
		});

		setFunction("fileSystemExists", function(path:String) {
			return sys.FileSystem.exists(path);
		});

		setFunction("existsInMod", function(path:String, mod:String) {
			return Paths.existsInMod(path, mod);
		});

		setFunction("getText", function(path:String) {
			return Assets.getText(path);
		});

		setFunction("getContent", function(path:String) {
			return sys.io.File.getContent(path);
		});

		setFunction("parseJson", function(tag:String, content:String) {
			lua_Jsons.set(tag, Json.parse(Assets.getText(Paths.json(content))));
		});

		setFunction("loadScript", function(script:String) {
			var modchart:LuaScript = null;

			if (Assets.exists(Paths.lua("modcharts/" + script)))
				modchart = new LuaScript(Paths.getModPath(Paths.lua("modcharts/" + script)));
			else if (Assets.exists(Paths.lua("scripts/" + script)))
				modchart = new LuaScript(Paths.getModPath(Paths.lua("scripts/" + script)));

			if (modchart == null) {
				trace('Couldn\'t find script at either ${Paths.lua("modcharts/" + script)} OR ${Paths.lua("scripts/" + script)}!', WARNING);
				return;
			}

			modchart.setup();

			if (createPost)
				modchart.call("createPost", [PlayState.SONG.song.toLowerCase()]);

			otherScripts.push(modchart);
		});

		// math
		setFunction("bound", function(value:Float, ?Min:Float, ?Max:Float) {
			return FlxMath.bound(value, Min, Max);
		});

		setFunction("boundTo", function(value:Float, Min:Float, Max:Float):Float {
			return CoolUtil.boundTo(value, Min, Max);
		});

		setFunction("distanceBetween", function(SpriteA:String, SpriteB:String) {
			if (getActorByName(SpriteA) != null && getActorByName(SpriteB) != null)
				return FlxMath.distanceBetween(getActorByName(SpriteA), getActorByName(SpriteB));
			else
				return 0;
		});

		setFunction("distanceToMouse", function(sprite:String) {
			if (getActorByName(sprite) != null)
				return FlxMath.distanceToMouse(getActorByName(sprite));
			else
				return 0;
		});

		setFunction("distanceToPoint", function(sprite:String, x:Float, y:Float) {
			var point:FlxPoint = new FlxPoint(x, y);
			if (getActorByName(sprite) != null)
				return FlxMath.distanceToPoint(getActorByName(sprite), point);
			else
				return 0;
		});

		setFunction("dotProduct", function(ax:Float, ay:Float, bx:Float, by:Float) {
			return FlxMath.dotProduct(ax, ay, bx, by);
		});

		setFunction("equal", function(aValueA:Float, aValueB:Float, aDiff:Float = FlxMath.EPSILON) {
			return FlxMath.equal(aValueA, aValueB, aDiff);
		});

		setFunction("fastCos", function(n:Float) {
			return FlxMath.fastCos(n);
		});

		setFunction("fastSin", function(n:Float) {
			return FlxMath.fastSin(n);
		});

		setFunction("fastTan", function(n:Float) {
			return FlxMath.fastSin(n) / FlxMath.fastCos(n);
		});

		setFunction("fceil", function(n:Float) {
			return Math.fceil(n);
		});

		setFunction("ffloor", function(n:Float) {
			return Math.ffloor(n);
		});

		setFunction("fround", function(n:Float) {
			return Math.fround(n);
		});

		setFunction("isFinite", function(n:Float) {
			return Math.isFinite(n);
		});

		setFunction("isNaN", function(n:Float) {
			return Math.isNaN(n);
		});

		setFunction("getDecimals", function(n:Float) {
			return FlxMath.getDecimals(n);
		});

		setFunction("inBounds", function(value:Float, min:Null<Float>, max:Null<Float>) {
			return FlxMath.inBounds(value, min, max);
		});

		setFunction("isDistanceToMouseWithin", function(sprite:String, distance:Float, includeEqual:Bool = false) {
			if (getActorByName(sprite) != null)
				return FlxMath.isDistanceToMouseWithin(getActorByName(sprite), distance, includeEqual);
			else
				return false;
		});

		setFunction("isDistanceToPointWithin", function(sprite:String, x:Float, y:Float, distance:Float, includeEqual:Bool = false) {
			var point:FlxPoint = new FlxPoint(x, y);
			if (getActorByName(sprite) != null)
				return FlxMath.isDistanceToPointWithin(getActorByName(sprite), point, distance, includeEqual);
			else
				return false;
		});

		setFunction("isDistanceWithin", function(SpriteA:String, SpriteB:String, distance:Float, includeEqual:Bool = false) {
			if (getActorByName(SpriteA) != null && getActorByName(SpriteB) != null)
				return FlxMath.isDistanceWithin(getActorByName(SpriteA), getActorByName(SpriteB), distance, includeEqual);
			else
				return false;
		});

		setFunction("isEven", function(n:Float) {
			return FlxMath.isEven(n);
		});

		setFunction("isOdd", function(n:Float) {
			return FlxMath.isOdd(n);
		});

		setFunction("lerp", function(a:Float, b:Float, ratio:Float) {
			return FlxMath.lerp(a, b, ratio);
		});

		setFunction("maxAdd", function(value:Int, amount:Int, max:Int, min:Int = 1) {
			return FlxMath.maxAdd(value, amount, max, min);
		});

		setFunction("maxInt", function(a:Int, b:Int) {
			return FlxMath.maxInt(a, b);
		});

		setFunction("minInt", function(a:Int, b:Int) {
			return FlxMath.minInt(a, b);
		});

		setFunction("numericComparison", function(a:Float, b:Float) {
			return FlxMath.numericComparison(a, b);
		});

		setFunction("perlin", function(x:Float, y:Float, z:Float) {
			return perlin.perlin(x, y, z);
		});

		setFunction("pointInCoordinates", function(pointX:Float, pointY:Float, rectX:Float, rectY:Float, rectWidth:Float, rectHeight:Float) {
			return FlxMath.pointInCoordinates(pointX, pointX, rectX, rectY, rectWidth, rectHeight);
		});

		setFunction("random", function() {
			return Math.random();
		});

		setFunction("randomBool", function(chance:Float):Bool {
			return FlxG.random.bool(chance);
		});

		setFunction("randomFloat", function(min:Float, max:Float):Float {
			return FlxG.random.float(min, max);
		});

		setFunction("randomInt", function(min:Int, max:Int):Int {
			return FlxG.random.int(min, max);
		});

		setFunction("remapToRange", function(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float) {
			return FlxMath.remapToRange(value, start1, stop1, start2, stop2);
		});

		setFunction("round", function(v:Float) {
			return Math.round(v);
		});

		setFunction("roundDecimal", function(value:Float, percision:Int) {
			return FlxMath.roundDecimal(value, percision);
		});

		setFunction("sameSign", function(a:Float, b:Float) {
			return FlxMath.sameSign(a, b);
		});

		setFunction("signOf", function(n:Float) {
			return FlxMath.signOf(n);
		});

		setFunction("sinh", function(n:Float) {
			return FlxMath.sinh(n);
		});

		setFunction("vectorLength", function(dx:Float, dy:Float) {
			return FlxMath.vectorLength(dx, dy);
		});

		setFunction("wrap", function(value:Int, min:Int, max:Int) {
			return FlxMath.wrap(value, min, max);
		});

		#if MODCHARTING_TOOLS
		if (PlayState.SONG.modchartingTools) {
			set('startMod', function(name:String, modClass:String, type:String = '', pf:Int = -1) {
				ModchartFuncs.startMod(name, modClass, type, pf);

				PlayState.instance.playfieldRenderer.modifierTable.reconstructTable(); // needs to be reconstructed for lua modcharts
			});
			set('setMod', function(name:String, value:Float) {
				ModchartFuncs.setMod(name, value);
			});
			set('setSubMod', function(name:String, subValName:String, value:Float) {
				ModchartFuncs.setSubMod(name, subValName, value);
			});
			set('setModTargetLane', function(name:String, value:Int) {
				ModchartFuncs.setModTargetLane(name, value);
			});
			set('setModPlayfield', function(name:String, value:Int) {
				ModchartFuncs.setModPlayfield(name, value);
			});
			set('addPlayfield', function(?x:Float = 0, ?y:Float = 0, ?z:Float = 0) {
				ModchartFuncs.addPlayfield(x, y, z);
			});
			set('removePlayfield', function(idx:Int) {
				ModchartFuncs.removePlayfield(idx);
			});
			set('tweenModifier', function(modifier:String, val:Float, time:Float, ease:String) {
				ModchartFuncs.tweenModifier(modifier, val, time, ease);
			});
			set('tweenModifierSubValue', function(modifier:String, subValue:String, val:Float, time:Float, ease:String) {
				ModchartFuncs.tweenModifierSubValue(modifier, subValue, val, time, ease);
			});
			set('setModEaseFunc', function(name:String, ease:String) {
				ModchartFuncs.setModEaseFunc(name, ease);
			});
			set('setModifier', function(beat:Float, argsAsString:String) {
				ModchartFuncs.set(beat, argsAsString);
			});
			set('easeModifier', function(beat:Float, time:Float, easeStr:String, argsAsString:String) {
				ModchartFuncs.ease(beat, time, easeStr, argsAsString);
			});
			set('ease', function(beat:Float, time:Float, easeStr:String, argsAsString:String) {
				ModchartFuncs.ease(beat, time, easeStr, argsAsString);
			});
		}
		#end

		setup();

		call("onCreate", []);
		call("createLua", []);
		call("new", []);
	}

	override public function setup() {
		lua_Sprites.set("boyfriend", PlayState.boyfriend);
		lua_Sprites.set("girlfriend", PlayState.gf);
		lua_Sprites.set("dad", PlayState.dad);

		lua_Characters.set("boyfriend", PlayState.boyfriend);
		lua_Characters.set("girlfriend", PlayState.gf);
		lua_Characters.set("dad", PlayState.dad);

		lua_Sounds.set("Inst", FlxG.sound.music);
		lua_Sounds.set("Voices", PlayState.instance.vocals.members[0]);

		for (sound in 0...PlayState.instance.vocals.length) {
			lua_Sounds.set("Voices" + sound, PlayState.instance.vocals.members[sound]);
		}

		if (PlayState.instance.stage != null) {
			for (object in PlayState.instance.stage.stageObjects) {
				lua_Sprites.set(object[0], object[1]);
			}
		}

		if (PlayState.dad.otherCharacters != null) {
			lua_Sprites.set('dad', PlayState.dad.otherCharacters[PlayState.dad.mainCharacterID]);
			lua_Characters.set('dad', PlayState.dad.otherCharacters[PlayState.dad.mainCharacterID]);
			for (char in 0...PlayState.dad.otherCharacters.length) {
				lua_Sprites.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
				lua_Characters.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
			}
		}

		if (PlayState.boyfriend.otherCharacters != null) {
			lua_Sprites.set('boyfriend', PlayState.boyfriend.otherCharacters[PlayState.boyfriend.mainCharacterID]);
			lua_Characters.set('boyfriend', PlayState.boyfriend.otherCharacters[PlayState.boyfriend.mainCharacterID]);
			for (char in 0...PlayState.boyfriend.otherCharacters.length) {
				lua_Sprites.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
				lua_Characters.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
			}
		}

		if (PlayState.gf.otherCharacters != null) {
			lua_Sprites.set('girlfriend', PlayState.gf.otherCharacters[PlayState.gf.mainCharacterID]);
			lua_Characters.set('girlfriend', PlayState.gf.otherCharacters[PlayState.gf.mainCharacterID]);
			for (char in 0...PlayState.gf.otherCharacters.length) {
				lua_Sprites.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
				lua_Characters.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
			}
		}

		if (PlayState?.strumLineNotes?.members != null) {
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

		set("player1", PlayState.boyfriend.curCharacter);
		set("player2", PlayState.dad.curCharacter);

		for (script in otherScripts) {
			cast(script, LuaScript).setup();
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

	public function getVar(var_name:String, type:String):Any {
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

	public override function call(func:String, ?arguments:Array<Any>):Bool {
		if (arguments == null)
			arguments = [];

		for (script in otherScripts) {
			cast(script, LuaScript).call(func, arguments);
		}

		Lua.getglobal(lua, func);

		for (arg in arguments) {
			Convert.toLua(lua, arg);
		}

		if (Lua.pcall(lua, arguments.length, 1, 0) != Lua.LUA_OK) {
			Lua.pop(lua, 1);
			return false;
		} else {
			Lua.pop(lua, 1);
			return true;
		}
	}

	function cameraFromString(cam:String):FlxCamera {
		var camera:LuaCamera = getCameraByName(cam);
		if (camera == null) {
			switch (cam.toLowerCase()) {
				case 'camhud' | 'hud':
					return PlayState.instance.camHUD;
			}
			return PlayState.instance.camGame;
		}
		return camera.cam;
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
