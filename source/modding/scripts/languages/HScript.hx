package modding.scripts.languages;

#if HSCRIPT_ALLOWED
import haxe.PosInfos;
import states.PlayState;
import openfl.utils.Assets;
import sys.io.File;
import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxBasic;
import hscript.*;

/**
	Handles HScript for you.
**/
class HScript extends Script {
	/**
		Parses the HScript.
	**/
	public var parser:Parser = new Parser();

	/**
		Current Expression.
	**/
	public var program:Expr;

	/**
		Interprets the HScript.
	**/
	public var interp:Interp = new Interp();


	public function new(path:String, executeOn:ExecuteOn = BOTH) {
		super(path, executeOn);
		// parser settings
		parser.allowJSON = true;
		parser.allowTypes = true;
		parser.allowMetadata = true;
		// parser.resumeErrors = true;

		// load text
		program = parser.parseString(FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path));

		setup();

		interp.printCallStack = true;
		interp.execute(program);
		if(this.executeOn != STAGE)
			call("create", [path]);
	}

	public inline function update(elapsed:Float)
		call("update", [elapsed]);

	public override function call(func:String, ?args:Array<Any>):Bool {
		if (interp.variables.exists(func)) {
			var real_func = interp.variables.get(func);

			try {
				if (args == null)
					real_func();
				else
					Reflect.callMethod(null, real_func, args);
			} catch (e) {
				trace('$name.$extension' + ": " + e.details(), ERROR);
				trace("ERROR Caused in " + func + " with " + Std.string(args) + " args", ERROR);
				return false;
			}
		}

		for (script in otherScripts) {
			script.call(func, args);
		}
		return true;
	}

	override public function set(variable:String, value:Any){
		interp.variables.set(variable, value);
		for(script in otherScripts) {
			script.set(variable, value);
		}
	}

	override public function destroy(){}

	override public function setup() {
		// global class shit
		//setDefaults();

		// haxeflixel classes
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxCamera', flixel.FlxCamera);
		set("FlxMath", flixel.math.FlxMath);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set("FlxTweenUtil", modding.helpers.FlxTweenUtil);
		set("FlxText", flixel.text.FlxText);
		set('FlxColor', modding.helpers.FlxColorHelper);
		set('FlxEase', flixel.tweens.FlxEase);
		set("Assets", openfl.utils.Assets);
		set("LimeAssets", lime.utils.Assets);
		set("Math", Math);
		set("Std", Std);
		set("StringTools", StringTools);
		set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
		set("CustomShader", shaders.custom.CustomShader);
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('Json', haxe.Json);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxEmitter", flixel.effects.particles.FlxEmitter);
		set("FlxAnimate", flxanimate.FlxAnimate);
		set("FlxAtlasSprite", game.FlxAtlasSprite);
		set("Map", haxe.ds.StringMap);
		set("StringMap", haxe.ds.StringMap);
		set("IntMap", haxe.ds.IntMap);
		set("EnumValueMap", haxe.ds.EnumValueMap);
		set("ObjectMap", haxe.ds.ObjectMap);


		// game classes
		set("PlayState", states.PlayState);
		set("Conductor", game.Conductor);
		set("Paths", Paths);
		set("CoolUtil", utilities.CoolUtil);
		set('Options', utilities.Options);
		set('Character', game.Character);
		set('Alphabet', ui.Alphabet);
		set('CustomState', modding.custom.CustomState);
		set('CustomSubstate', modding.custom.CustomSubstate);

		#if DISCORD_ALLOWED
		set('DiscordClient', utilities.DiscordClient);
		#end

		#if MODDING_ALLOWED
		set("Polymod", polymod.Polymod);
		set("PolymodAssets", polymod.backends.PolymodAssets);
		set('ModList', modding.ModList);
		#end

		// modchart tools stuff
		#if MODCHARTING_TOOLS
		if (FlxG.state == PlayState.instance) {
			set('PlayfieldRenderer', modcharting.PlayfieldRenderer);
			set('ModchartUtil', modcharting.ModchartUtil);
			set('Modifier', modcharting.Modifier);
			set('NoteMovement', modcharting.NoteMovement);
			set('NotePositionData', modcharting.NotePositionData);
			set('ModchartFile', modcharting.ModchartFile);
		}
		#end

		set("NdllLoader", utilities.NdllLoader);
		// function shits

		set("import", function(class_name:String) {
			var classes = class_name.split(".");

			if (Type.resolveClass(class_name) != null)
				set(classes[classes.length - 1], Type.resolveClass(class_name));
			else if (Type.resolveEnum(class_name) != null) {
				var enum_new = {};
				var good_enum = Type.resolveEnum(class_name);

				for (constructor in good_enum.getConstructors()) {
					Reflect.setField(enum_new, constructor, good_enum.createByName(constructor));
				}

				set(classes[classes.length - 1], enum_new);
			} else
				trace(class_name + " isn't a valid class or enum!", WARNING);
		});


		set("trace", Reflect.makeVarArgs(function(el) {
			@:privateAccess
			var inf = cast {fileName: path, lineNumber: interp.curExpr.line};
			var v = el.shift();
			if (el.length > 0)
				inf.customParams = el;
			
			haxe.Log.trace(Std.string(v), inf);
		}));

		set("load", function(path:String) {
			var newScript:HScript = new HScript(path);
			if (createPost)
				newScript.call("createPost", [path]);

			otherScripts.push(newScript);

			return otherScripts.length - 1;
		});

		set("unload", function(script_index:Int) {
			if (otherScripts.length - 1 >= script_index)
				otherScripts.remove(otherScripts[script_index]);
		});

		set("otherScripts", otherScripts);

		// playstate local shit
		set("bf", states.PlayState.boyfriend);
		set("gf", states.PlayState.gf);
		set("dad", states.PlayState.dad);

		set("removeStage", function() {
			states.PlayState.instance.stage.stageObjects = [];

			states.PlayState.instance.stage.infrontOfGFSprites.clear();
			states.PlayState.instance.stage.foregroundSprites.clear();
			states.PlayState.instance.stage.clear();
		});

		set("add", function(object:FlxBasic) {
			FlxG.state.add(object);
		});

		set("remove", function(object:FlxBasic) {
			FlxG.state.remove(object);
		});
	}
}
#end