package modding.custom;

import openfl.utils.Assets;
import flixel.FlxG;
import modding.scripts.languages.HScript;
import states.MusicBeatState;
import flixel.FlxObject;
import states.TitleState;
import flixel.FlxObject;


class CustomState extends MusicBeatState{
    public var script:HScript;
    public static var instance:CustomState = null;
    override function new(script:String){
        if(Assets.exists(Paths.hx("classes/states/" + script))){
            instance = this;
            this.script = new HScript(Paths.hx("classes/states/" + script));
            this.script.start();
            this.script.interp.variables.set("add", function(obj:FlxObject)
            {
                add(obj);
            });
        }
        else{
            trace('Could not find script at path ${script}', ERROR);
            FlxG.switchState(new TitleState());
        }
        super();
    }
    override function create(){
        super.create();
        call("createPost");
    }
    override function update(elapsed:Float){
        call("update", [elapsed]);
		super.update(elapsed);
		call("updatePost", [elapsed]);
    }
    override function beatHit(){
        call("beatHit");
		super.beatHit();
		call("beatHitPost");
    }
    override function stepHit(){
        call("stepHit");
		super.stepHit();
		call("stepHitPost");
    }
    public inline function call(func:String, ?args:Array<Dynamic>) {
		script.call(func, args);
	}
}