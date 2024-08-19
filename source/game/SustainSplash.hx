package game;

import shaders.NoteColors;
import haxe.Json;
import openfl.utils.Assets;
import flixel.FlxG;
import utilities.NoteVariables;
import states.PlayState;
import game.Note.JsonData;
import shaders.ColorSwap;
import flixel.FlxSprite;

class SustainSplash extends FlxSprite {
    public var colorSwap:ColorSwap;
	public var noteColor:Array<Int> = [255,0,0];

    public var affectedbycolor:Bool = false;
	public var jsonData:JsonData;

    public var target:FlxSprite;

    public function setup_splash(noteData:Int, target:FlxSprite, ?isPlayer:Bool = false, ?ui_Skin:String) {
		this.target = target;

		var localKeyCount = isPlayer ? PlayState.SONG.playerKeyCount : PlayState.SONG.keyCount;

		alpha = 0.8;

		if (frames == null) {
			if (Assets.exists(Paths.image('ui skins/' + PlayState.SONG.ui_Skin + "/arrows/Sustain_Splashes")))
				frames = Paths.getSparrowAtlas('ui skins/' + PlayState.SONG.ui_Skin + "/arrows/Sustain_Splashes");
			else
				frames = Paths.getSparrowAtlas("ui skins/default/arrows/Sustain_Splashes");
		}

		graphic.destroyOnNoUse = false;

		animation.addByPrefix("start", "sustain cover pre", 24, false, false, false);
        animation.addByPrefix("hold", "sustain splash " + NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + "0", 24, false, false, false);
        animation.addByPrefix("end", "sustain splash end " + NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + "0", 24, false, false, false);
        animation.finishCallback = this.onAnimationFinished;
        animation.play("start", false);



		//setGraphicSize(Std.int(target.width * 2.5));

		updateHitbox();
		centerOffsets();

		if (ui_Skin == null)
			ui_Skin = PlayState.SONG.ui_Skin;

		if(Assets.exists(Paths.json("ui skins/" + ui_Skin + "/config"))){
			jsonData = Json.parse(Assets.getText(Paths.json("ui skins/" + ui_Skin + "/config")));	
			for (value in jsonData.values) {
				this.affectedbycolor = value.affectedbycolor;
			}
		}

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		if(affectedbycolor) {
			noteColor = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[PlayState.SONG.keyCount - 1][noteData]);
		}
		else {
			noteColor = [255,0,0];
		}
		colorSwap.r = noteColor[0];
		colorSwap.g = noteColor[1];
		colorSwap.b = noteColor[2];
		update(0);
	}

    public function onAnimationFinished(animationName:String):Void {
        if (animationName.startsWith('start')){
            animation.play('hold', true);
        }
        if (animationName.startsWith('hold')){
            animation.play('end', true);
        }
        if (animationName.startsWith('end')){
            this.visible = false;
        }
    }

	override function update(elapsed:Float) {
		if (target != null) {
			x = target.x - (target.width / 1.5);
			y = target.y - (target.height / 1.5);

			color = target.color;

			flipX = target.flipX;
			flipY = target.flipY;

			angle = target.angle;
		}

		super.update(elapsed);
	}
}