package modding.custom;

#if HSCRIPT_ALLOWED
import modding.scripts.ExecuteOn;
import openfl.utils.Assets;
import flixel.FlxG;
import modding.scripts.languages.HScript;
import states.MusicBeatState;
import flixel.FlxObject;
import states.TitleState;
import flixel.FlxObject;

class CustomState extends MusicBeatState {
	public var script:HScript;
    public var scriptPath:String;

	public static var instance:CustomState = null;

	override public function new(scriptPath:String) {
		super();
        this.scriptPath = scriptPath;
	}

	override function create() {
		if (Assets.exists(Paths.hx("classes/states/" + scriptPath))) {
			instance = this;
			this.script = new HScript(Paths.hx("classes/states/" + scriptPath));
		} else {
			trace('Could not find script at path ${scriptPath}', ERROR);
			FlxG.switchState(() -> new TitleState());
		}
		super.create();
		call("createPost");
	}

	override function update(elapsed:Float) {
		call("update", [elapsed]);
		super.update(elapsed);
		call("updatePost", [elapsed]);
	}

	override function beatHit() {
		call("beatHit");
		super.beatHit();
		call("beatHitPost");
	}

	override function stepHit() {
		call("stepHit");
		super.stepHit();
		call("stepHitPost");
	}

	override public function call(func:String, ?args:Array<Any>, executeOn:ExecuteOn = BOTH) {
		super.call(func, args);
		script?.call(func, args);
	}
}
#end