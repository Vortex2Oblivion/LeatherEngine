package game;

import openfl.utils.Assets;
import flixel.util.FlxColor;
import utilities.Options;
import shaders.NoteColors;
import shaders.ColorSwap;
import game.Song.SwagSong;
import utilities.NoteVariables;
import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;

using StringTools;

class Note extends FlxSkewedSprite {
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var prevNoteStrumtime:Float = 0;
	public var prevNoteIsSustainNote:Bool = false;

	public var singAnimPrefix:String = "sing"; //hopefully should make things easier
	public var singAnimSuffix:String = ""; //for alt anims lol

	public var sustains:Array<Note> = [];
	public var missesSustains:Bool = false;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;

	public var sustainScaleY:Float = 1;

	public var xOffset:Float = 0;
	public var yOffset:Float = 0;

	public var rawNoteData:Int = 0;

	public var modAngle:Float = 0;
	public var localAngle:Float = 0;

	public var character:Int = 0;

	public var characters:Array<Int> = [];

	public var arrow_Type:String;

	public var shouldHit:Bool = true;
	public var hitDamage:Float = 0.0;
	public var missDamage:Float = 0.07;
	public var heldMissDamage:Float = 0.035;
	public var playMissOnMiss:Bool = true;

	public var colorSwap:ColorSwap;
	public var affectedbycolor:Bool = false;

	public var inEditor:Bool = false;

	#if MODCHARTING_TOOLS
	/**
	 * The mesh used for sustains to make them stretchy
	 * Used only on modchart songs
	 */
	public var mesh:modcharting.SustainStrip = null;
	/**
	 * The Z value for the note.
	 * Used only on modchart songs
	 */
	public var z:Float = 0;
	#end

	/**
	 * @see https://discord.com/channels/929608653173051392/1034954605253107844/1163134784277590056
	 * @see https://step-mania.fandom.com/wiki/Notes
	 */
	public var quantColors:Array<Array<Int>> = [
		[255,35,15], 
		[19,75,255],
		[138,7,224],
		[71,250,22],
		[214,0,211],
		[246,121,4],
		[0,200,172],
		[38,168,41],
		[187,187,187],
		[167,199,231],
		[128,128,0],
	];


	/**
	 * @see https://discord.com/channels/929608653173051392/1034954605253107844/1163134784277590056
	 * @see https://step-mania.fandom.com/wiki/Notes
	 */
	public var beats:Array<Int> = [4, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192];

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?character:Int = 0, ?arrowType:String = "default",
			?song:SwagSong, ?characters:Array<Int>, ?mustPress:Bool = false, ?inEditor:Bool = false) {
		super();
		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.inEditor = inEditor;
		this.character = character;
		this.strumTime = strumTime;
		this.arrow_Type = arrowType;
		this.characters = characters;
		this.mustPress = mustPress;

		isSustainNote = sustainNote;

		if (song == null)
			song = PlayState.SONG;

		var localKeyCount = mustPress ? song.playerKeyCount : song.keyCount;

		this.noteData = noteData;

		x += 100;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y = -2000;

		if (PlayState.instance.types.contains(arrow_Type)) {
			if (Assets.exists(Paths.image('ui skins/' + song.ui_Skin + "/arrows/" + arrow_Type, 'shared'))) {
				frames = Paths.getSparrowAtlas('ui skins/' + song.ui_Skin + "/arrows/" + arrow_Type, 'shared');
			} else {
				frames = Paths.getSparrowAtlas('ui skins/default/arrows/default', 'shared');
			}
		} else {
			frames = Paths.getSparrowAtlas("ui skins/default/arrows/" + arrow_Type, 'shared');
		}

		animation.addByPrefix("default", NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + "0", 24);
		animation.addByPrefix("hold", NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + " hold0", 24);
		animation.addByPrefix("holdend", NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + " hold end0", 24);
		animation.addByPrefix("glow", NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + " glow0", 24);

		var lmaoStuff = Std.parseFloat(PlayState.instance.ui_settings[0]) * (Std.parseFloat(PlayState.instance.ui_settings[2])
			- (Std.parseFloat(PlayState.instance.mania_size[localKeyCount - 1])));

		if (isSustainNote)
			scale.set(lmaoStuff,
				Std.parseFloat(PlayState.instance.ui_settings[0]) * (Std.parseFloat(PlayState.instance.ui_settings[2])
					- (Std.parseFloat(PlayState.instance.mania_size[3]))));
		else
			scale.set(lmaoStuff, lmaoStuff);

		updateHitbox();

		antialiasing = PlayState.instance.ui_settings[3] == "true";

		x += swagWidth * noteData;
		animation.play("default");

		if (!PlayState.instance.arrow_Configs.exists(arrow_Type)) {
			if (PlayState.instance.types.contains(arrow_Type))
				PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/" + song.ui_Skin + "/" + arrow_Type)));
			else
				PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/default/" + arrow_Type)));

			PlayState.instance.type_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("arrow types/" + arrow_Type)));
			PlayState.instance.setupNoteTypeScript(arrow_Type);
		}

		offset.y += Std.parseFloat(PlayState.instance.arrow_Configs.get(arrow_Type)[0]) * lmaoStuff;

		shouldHit = PlayState.instance.type_Configs.get(arrow_Type)[0] == "true";
		hitDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[1]);
		missDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[2]);

		if (PlayState.instance.type_Configs.get(arrow_Type)[4] != null)
			playMissOnMiss = PlayState.instance.type_Configs.get(arrow_Type)[4] == "true";
		else {
			if (shouldHit)
				playMissOnMiss = true;
			else
				playMissOnMiss = false;
		}

		if (PlayState.instance.type_Configs.get(arrow_Type)[3] != null)
			heldMissDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[3]);

		if (Options.getData("downscroll") && sustainNote)
			flipY = true;

		if (isSustainNote && prevNote != null) {
			alpha = 0.6;

			prevNoteStrumtime = prevNote.strumTime;
			prevNoteIsSustainNote = prevNote.isSustainNote;

			if (!song.ui_Skin.contains("pixel"))
				x += width / 2;

			animation.play("holdend");
			updateHitbox();

			if (!song.ui_Skin.contains("pixel"))
				x -= width / 2;

			if (song.ui_Skin.contains("pixel"))
				x += 30;

			if (prevNote.isSustainNote) {
				if (prevNote.animation != null)
					prevNote.animation.play("hold");

				var speed = song.speed;

				if (Options.getData("useCustomScrollSpeed"))
					speed = Options.getData("customScrollSpeed") / PlayState.songMultiplier;

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * speed;
				prevNote.updateHitbox();
				prevNote.sustainScaleY = prevNote.scale.y;
			}

			centerOffsets();
			centerOrigin();

			sustainScaleY = scale.y;
		}


		if (PlayState.instance.arrow_Configs.get(arrow_Type)[5] != null) {
			if (PlayState.instance.arrow_Configs.get(arrow_Type)[5] == "true")
				affectedbycolor = true;
		}

		colorSwap = new ColorSwap();
		shader = affectedbycolor ? colorSwap.shader : null;

		var noteColor = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[song.keyCount - 1][noteData]);

		if(noteColor!= null && colorSwap != null){
			colorSwap.r = noteColor[0];
			colorSwap.g = noteColor[1];
			colorSwap.b = noteColor[2];
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		angle = modAngle + localAngle;

		calculateCanBeHit();

		if (!inEditor) {
			if (tooLate) {
				if (alpha > 0.3)
					alpha = 0.3;
			}
		}
	}


	public function calculateCanBeHit() {
		if (this != null) {
			if (mustPress) {
				/**
					TODO: make this shit use something from the arrow config .txt file
				**/
				if (shouldHit) {
					if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
						&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset)
						canBeHit = true;
					else
						canBeHit = false;
				} else {
					if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset * 0.3
						&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset * 0.2)
						canBeHit = true;
					else
						canBeHit = false;
				}

				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
					tooLate = true;
			} else {
				canBeHit = false;

				if (strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}
	}
}

typedef NoteType = {
	var shouldHit:Bool;

	var hitDamage:Float;
	var missDamage:Float;
}
typedef StrumJson = {
	var affectedbycolor:Bool;
}
typedef JsonData = {
	var values:Array<StrumJson>;
}

