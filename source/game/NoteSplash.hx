package game;

import game.Note.JsonData;
import haxe.Json;
import openfl.Assets;
import shaders.NoteColors;
import shaders.ColorSwap;
import utilities.NoteVariables;
import flixel.FlxG;
import states.PlayState;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite {
	public var target:FlxSprite;
	
	public var colorSwap:ColorSwap;
	public var noteColor:Array<Int> = [255,0,0];
	public var affectedbycolor:Bool = false;
	public var jsonData:JsonData;

	public function setup_splash(noteData:Int, target:FlxSprite, ?isPlayer:Bool = false, ?ui_Skin:String) {
		this.target = target;

		var localKeyCount = isPlayer ? PlayState.SONG.playerKeyCount : PlayState.SONG.keyCount;

		alpha = 0.8;

		if (frames == null) {
			if (Std.parseInt(PlayState.instance.ui_settings[6]) == 1)
				frames = Paths.getSparrowAtlas('ui skins/' + PlayState.SONG.ui_Skin + "/arrows/Note_Splashes");
			else
				frames = Paths.getSparrowAtlas("ui skins/default/arrows/Note_Splashes");
		}

		graphic.destroyOnNoUse = false;

		animation.addByPrefix("default", "note splash " + NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + "0", FlxG.random.int(22, 26),
			false);
		animation.play("default", true);

		setGraphicSize(Std.int(target.width * 2.5));

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
		shader = affectedbycolor ? colorSwap.shader : null;

		noteColor = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[PlayState.SONG.keyCount - 1][noteData]);
		if(colorSwap != null){
			colorSwap.r = noteColor[0];
			colorSwap.g = noteColor[1];
			colorSwap.b = noteColor[2];
		}
		update(0);
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