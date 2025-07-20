package game;

import openfl.utils.Assets;
import utilities.Options;
import shaders.NoteColors;
import shaders.ColorSwap;
import game.SongLoader.SongData;
import utilities.NoteVariables;
import states.PlayState;
import flixel.FlxG;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

using StringTools;

class Note extends #if MODCHARTING_TOOLS modcharting.FlxSprite3D #else FlxSkewedSprite #end {
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var prevNoteStrumtime:Float = 0;
	public var prevNoteIsSustainNote:Bool = false;

	public var singAnimPrefix:String = "sing"; // hopefully should make things easier
	public var singAnimSuffix:String = ""; // for alt anims lol

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

	public var song:SongData;

	public var speed(default, set):Float = 1;

	public var originalSpeed(default, null):Float;

	public var playedHitSound:Bool = false;

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
	public static var quantColors:Array<Array<Int>> = [
		[255, 35, 15],
		[19, 75, 255],
		[138, 7, 224],
		[71, 250, 22],
		[214, 0, 211],
		[246, 121, 4],
		[0, 200, 172],
		[38, 168, 41],
		[187, 187, 187],
		[167, 199, 231],
		[128, 128, 0],
	];

	/**
	 * @see https://discord.com/channels/929608653173051392/1034954605253107844/1163134784277590056
	 * @see https://step-mania.fandom.com/wiki/Notes
	 */
	public static var beats:Array<Int> = [4, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192];

	public static function applyColorQuants(notes:Array<Note>) {
		if (!Options.getData('colorQuantization')) {
			return;
		}
		var col:Array<Int> = [255, 0, 0];
		for (note in notes) {
			if (!note.isSustainNote && note.affectedbycolor) {
				var noteBeat:Int = Math.floor(((note.strumTime / (Conductor.getBPMFromSeconds(note.strumTime).stepCrochet * 4)) * 48) + 0.5);
				for (beat in 0...beats.length - 1) {
					if ((noteBeat % (192 / beats[beat]) == 0)) {
						col = quantColors[beat];
						break;
					}
				}
				note.colorSwap.r = col[0];
				note.colorSwap.g = col[1];
				note.colorSwap.b = col[2];
				for (sustain in note.sustains) {
					sustain.colorSwap.r = note.colorSwap.r;
					sustain.colorSwap.g = note.colorSwap.g;
					sustain.colorSwap.b = note.colorSwap.b;
				}
			}
		}
	}

	public static function getFrames(note:Note):FlxAtlasFrames {
		var disallowGPU:Bool = #if MODCHARTING_TOOLS note.song.modchartingTools
			|| FlxG.state is modcharting.ModchartEditorState #else false #end;

		var skin:String = Assets.exists('assets/shared/images/ui skins/${note.song.ui_Skin}') ? note.song.ui_Skin : 'default';
		var uiSkinPathBase:String ='ui skins/$skin/arrows/';
		var uiSkinPathNote:String = '$uiSkinPathBase${note.arrow_Type}';
		if (Assets.exists(Paths.image(uiSkinPathNote, 'shared'))) {
			return Paths.getSparrowAtlas(uiSkinPathNote, 'shared', disallowGPU);
		}
		return Paths.getSparrowAtlas('ui skins/${skin}/arrows/default', 'shared', disallowGPU);
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?character:Int = 0, ?arrowType:String = "default",
			?song:SongData, ?characters:Array<Int>, ?mustPress:Bool = false, ?inEditor:Bool = false) {
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

		var localKeyCount:Int = mustPress ? song.playerKeyCount : song.keyCount;

		this.noteData = noteData;

		this.song = song;
		speed = song.speed;
		originalSpeed = speed;

		x += 100;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y = -2000;

		frames = Note.getFrames(this);

		animation.addByPrefix("default", NoteVariables.animationDirections[localKeyCount - 1][noteData] + "0", 24);
		animation.addByPrefix("hold", NoteVariables.animationDirections[localKeyCount - 1][noteData] + " hold0", 24);
		animation.addByPrefix("holdend", NoteVariables.animationDirections[localKeyCount - 1][noteData] + " hold end0", 24);

		var lmaoStuff:Float = Std.parseFloat(PlayState.instance.ui_settings[0]) * (Std.parseFloat(PlayState.instance.ui_settings[2])
			- (Std.parseFloat(PlayState.instance.mania_size[localKeyCount - 1])));

		if (isSustainNote)
			scale.set(lmaoStuff,
				Std.parseFloat(PlayState.instance.ui_settings[0]) * (Std.parseFloat(PlayState.instance.ui_settings[2])
					- (Std.parseFloat(PlayState.instance.mania_size[3]))));
		else
			scale.set(lmaoStuff, lmaoStuff);

		updateHitbox();

		antialiasing = PlayState.instance.ui_settings[3] == "true" && Options.getData("antialiasing");

		x += swagWidth * noteData;
		animation.play("default");

		if (!PlayState.instance.arrow_Configs.exists(arrow_Type)) {
			if (PlayState.instance.types.contains(arrow_Type)) {
				if (Assets.exists(Paths.txt("ui skins/" + song.ui_Skin + "/" + arrow_Type))) {
					PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/" + song.ui_Skin + "/" + arrow_Type)));
				} else {
					PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/" + song.ui_Skin + "/default")));
				}
			} else {
				if (Assets.exists(Paths.txt("ui skins/default/" + arrow_Type))) {
					PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/default/" + arrow_Type)));
				} else {
					PlayState.instance.arrow_Configs.set(arrow_Type, CoolUtil.coolTextFile(Paths.txt("ui skins/default/default")));
				}
			}

			PlayState.instance.type_Configs.set(arrow_Type,
				Assets.exists(Paths.txt("arrow types/" + arrow_Type)) ? CoolUtil.coolTextFile(Paths.txt("arrow types/" +
					arrow_Type)) : CoolUtil.coolTextFile(Paths.txt("arrow types/default")));
			PlayState.instance.setupNoteTypeScript(arrow_Type);
		}

		offset.y += Std.parseFloat(PlayState.instance.arrow_Configs.get(arrow_Type)[0]) * lmaoStuff;

		shouldHit = PlayState.instance.type_Configs.get(arrow_Type)[0] == "true";
		hitDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[1]);
		missDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[2]);

		if (PlayState.instance.type_Configs.get(arrow_Type)[4] != null)
			playMissOnMiss = PlayState.instance.type_Configs.get(arrow_Type)[4] == "true";
		else {
			playMissOnMiss = shouldHit;
		}

		if (PlayState.instance.type_Configs.get(arrow_Type)[3] != null)
			heldMissDamage = Std.parseFloat(PlayState.instance.type_Configs.get(arrow_Type)[3]);

		if (Options.getData("downscroll") && sustainNote && !inEditor)
			flipY = true;

		if (isSustainNote && prevNote != null) {
			alpha = 0.6;

			prevNoteStrumtime = prevNote.strumTime;
			prevNoteIsSustainNote = prevNote.isSustainNote;

			animation.play("holdend");
			updateHitbox();

			if (prevNote.isSustainNote) {
				if (prevNote.animation != null)
					prevNote.animation.play("hold");

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * speed;
				prevNote.updateHitbox();
				prevNote.sustainScaleY = prevNote.scale.y;
			}

			centerOffsets();

			sustainScaleY = scale.y;
		}

		if (Options.getData("downscroll") && animation.curAnim.name.endsWith("end")) {
			offset.y -= height * 1.7;
		}

		if (PlayState.instance.arrow_Configs.get(arrow_Type)[5] != null) {
			if (PlayState.instance.arrow_Configs.get(arrow_Type)[5] == "true")
				affectedbycolor = true;
		}

		colorSwap = new ColorSwap();
		shader = affectedbycolor ? colorSwap.shader : null;

		var realKeyCount:Int = mustPress ? song.playerKeyCount : song.keyCount;

		var noteColor = NoteColors.getNoteColor(NoteVariables.animationDirections[realKeyCount - 1][noteData]);

		if (colorSwap != null && noteColor != null) {
			colorSwap.r = noteColor[0];
			colorSwap.g = noteColor[1];
			colorSwap.b = noteColor[2];
		}
	}

	/**
	 * Calculates the Y value of a note.
	 * @param note the note to calculate
	 * @return The Y value. NOTE: Will return the negative value if downscroll is enabled.
	 */
	public static inline function calculateY(note:Note):Float {
		return (Options.getData("downscroll") ? 1 : -1) * (0.45 * (Conductor.songPosition - note.strumTime) * FlxMath.roundDecimal(note.speed, 2));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		#if MODCHARTING_TOOLS angle3D.z #else angle #end = modAngle + localAngle;

		calculateCanBeHit();

		if (!inEditor) {
			if (tooLate) {
				if (alpha > 0.3)
					alpha = 0.3;
			}
		}
	}

	public function calculateCanBeHit() {
		if (mustPress) {
			/**
				// TODO: make this shit use something from the arrow config .txt file
			**/
			if (shouldHit) {
				canBeHit = (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
					&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset);
			} else {
				canBeHit = (strumTime > Conductor.songPosition - Conductor.safeZoneOffset / 3
					&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset * 0.2);
			}

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		} else {
			canBeHit = strumTime <= Conductor.songPosition;
		}
	}

	/**
	 * Override the setter to disable rounding on clipRect
	 * @author CCobaltDev
	 */
	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;
		if (frames != null)
			frame = frames.frames[animation.frameIndex];
		return rect;
	}

	@:noCompletion
	function set_speed(speed:Float):Float {
		if (Options.getData("useCustomScrollSpeed")) {
			speed = Options.getData("customScrollSpeed") / PlayState.songMultiplier;
		}
		if (isSustainNote && !inEditor && animation != null && !animation?.curAnim?.name?.endsWith('end')) {
			scale.y = Std.parseFloat(PlayState.instance.ui_settings[0]) * (Std.parseFloat(PlayState.instance.ui_settings[2])
				- (Std.parseFloat(PlayState.instance.mania_size[3])));
			scale.y *= Conductor.stepCrochet / 100 * 1.5 * speed;
			updateHitbox();
			centerOffsets();
		}
		return this.speed = speed;
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
