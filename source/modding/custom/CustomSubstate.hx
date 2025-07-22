package modding.custom;

#if HSCRIPT_ALLOWED
import openfl.utils.Assets;
import modding.scripts.languages.HScript;
import substates.MusicBeatSubstate;
import flixel.FlxObject;

class CustomSubstate extends MusicBeatSubstate {
	public var script:HScript;

	public static var instance:CustomSubstate = null;
    public var scriptPath:String;

	override public function new(scriptPath:String) {
		super();
		this.scriptPath = scriptPath;
	}

	override public function create() {
		if (Assets.exists(Paths.hx("classes/substates/" + scriptPath))) {
			instance = this;
			this.script = new HScript(Paths.hx("classes/substates/" + scriptPath));
		} else {
			trace('Could not find script at path ${scriptPath}', ERROR);
		}
		super.create();
		call("createPost");
	}

	override public function update(elapsed:Float) {
		call("update", [elapsed]);
		super.update(elapsed);
		call("updatePost", [elapsed]);
	}

	override public function beatHit() {
		call("beatHit");
		super.beatHit();
		call("beatHitPost");
	}

	override function stepHit() {
		call("stepHit");
		super.stepHit();
		call("stepHitPost");
	}

	public inline function call(func:String, ?args:Array<Dynamic>) {
		script?.call(func, args);
	}
}
#end