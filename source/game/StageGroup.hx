package game;

import modding.scripts.Script;
#if MODDING_ALLOWED
import polymod.backends.PolymodAssets;
#end
#if LUA_ALLOWED
import modding.scripts.languages.LuaScript;
#end
import shaders.ColorSwapHSV;
import modding.scripts.languages.HScript;
import lime.utils.Assets;
import haxe.Json;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import modding.CharacterConfig;
import game.DancingSprite;

using StringTools;

class StageGroup extends FlxGroup {
	public var stage:String = "stage";
	public var camZoom:Float = 1.05;

	public var player_1_Point:FlxPoint = new FlxPoint(1000, 800);
	public var player_2_Point:FlxPoint = new FlxPoint(300, 800);
	public var gf_Point:FlxPoint = new FlxPoint(600, 750);

	public var p1_Scroll:Float = 1.0;
	public var p2_Scroll:Float = 1.0;
	public var gf_Scroll:Float = 0.95;

	public var p1_Cam_Offset:FlxPoint = new FlxPoint(0, 0);
	public var p2_Cam_Offset:FlxPoint = new FlxPoint(0, 0);

	public var stageData:StageData;

	public var stageObjects:Array<Array<Dynamic>> = [];

	// other
	public var onBeatHit_Group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	public var foregroundSprites:FlxGroup = new FlxGroup();
	public var infrontOfGFSprites:FlxGroup = new FlxGroup();

	public var stageScript:Script = null;

	public var colorSwap:ColorSwapHSV;

	public function updateStage(?newStage:String) {
		if (newStage != null)
			stage = newStage;

		if (stage != "" && Assets.exists(Paths.json("stage data/" + stage))) {
			stageData = cast Json.parse(Assets.getText(Paths.json("stage data/" + stage)).trim());
		} else {
			stageData = cast Json.parse(Assets.getText(Paths.json("stage data/stage")).trim());
		}

		clear();

		switch (stage) {
			// incase you want to harcode your stage
			default:
				{
					if (stageData != null) {
						camZoom = stageData.camera_Zoom;

						if (stageData.camera_Offsets != null) {
							p1_Cam_Offset.set(stageData.camera_Offsets[0][0], stageData.camera_Offsets[0][1]);
							p2_Cam_Offset.set(stageData.camera_Offsets[1][0], stageData.camera_Offsets[1][1]);
						}

						player_1_Point.set(stageData.character_Positions[0][0], stageData.character_Positions[0][1]);
						player_2_Point.set(stageData.character_Positions[1][0], stageData.character_Positions[1][1]);
						gf_Point.set(stageData.character_Positions[2][0], stageData.character_Positions[2][1]);

						if (stageData.character_Scrolls != null) {
							p1_Scroll = stageData.character_Scrolls[0];
							p2_Scroll = stageData.character_Scrolls[1];
							gf_Scroll = stageData.character_Scrolls[2];
						}

						var null_Object_Name_Loop:Int = 0;

						for (Object in stageData.objects) {
							var Sprite:FlxSprite = Object.dances ? new DancingSprite(Object.position[0],
								Object.position[1]) : new FlxSprite(Object.position[0], Object.position[1]);

							if (Options.getData("shaders"))
								Sprite.shader = colorSwap.shader;

							if (Object.color != null && Object.color != [])
								Sprite.color = FlxColor.fromRGB(Object.color[0], Object.color[1], Object.color[2]);

							Sprite.antialiasing = Object.antialiased;
							Sprite.scrollFactor.set(Object.scroll_Factor[0], Object.scroll_Factor[1]);

							if (Object.object_Name != null && Object.object_Name != "")
								stageObjects.push([Object.object_Name, Sprite, Object]);
							else {
								stageObjects.push(["undefinedSprite" + null_Object_Name_Loop, Sprite, Object]);
								null_Object_Name_Loop++;
							}

							if (Object.is_Animated) {
								Sprite.frames = Paths.getSparrowAtlas((stageData.imageDirectory ?? stage) + "/" + Object.file_Name, "stages");

								for (Animation in Object.animations) {
									var Anim_Name = Animation.name;

									if (Animation.name == "beatHit")
										onBeatHit_Group.add(Sprite);

									if (Animation.indices == null) {
										Sprite.animation.addByPrefix(Anim_Name, Animation.animation_name, Animation.fps, Animation.looped);
									} else if (Animation.indices.length == 0) {
										Sprite.animation.addByPrefix(Anim_Name, Animation.animation_name, Animation.fps, Animation.looped);
									} else {
										Sprite.animation.addByIndices(Anim_Name, Animation.animation_name, Animation.indices, "", Animation.fps,
											Animation.looped);
									}
								}

								if (Object.start_Animation != "" && Object.start_Animation != null && Object.start_Animation != "null")
									Sprite.animation.play(Object.start_Animation);
							} else if (Object.file_Name.startsWith('#')) {
								Sprite.makeGraphic(Std.int(Object.scale), Std.int(Object.scale), FlxColor.fromString(Object.file_Name));
							} else
								Sprite.loadGraphic(Paths.gpuBitmap((stageData.imageDirectory ?? stage) + "/" + Object.file_Name, "stages"));

							if (Object.uses_Frame_Width)
								Sprite.setGraphicSize(Sprite.frameWidth * Object.scale);
							else
								Sprite.setGraphicSize(Sprite.width * Object.scale);

							if (Object.updateHitbox || Object.updateHitbox == null)
								Sprite.updateHitbox();

							if (Object.alpha != null)
								Sprite.alpha = Object.alpha;

							if (Object.layer != null) {
								switch (Object.layer.toLowerCase()) {
									case "foreground":
										foregroundSprites.add(Sprite);
									case "gf":
										infrontOfGFSprites.add(Sprite);
									default:
										add(Sprite);
								}
							} else
								add(Sprite);
						}
					}
					if (stageData.scriptName == null) {
						stageData.scriptName = stage;
					}
					if (Assets.exists(Paths.hx('data/stage data/${stageData.scriptName}'))) {
						stageScript = new HScript(Paths.hx('data/stage data/${stage}'));
						for (object in stageObjects) {
							stageScript.set(object[0], object[1]);
						}
					} else if (Assets.exists(Paths.lua("data/stage data/" + stageData.scriptName))) { // Fixed
						stageScript = new LuaScript(#if MODDING_ALLOWED PolymodAssets #else Assets #end
							.getPath(Paths.lua("data/stage data/" + stageData.scriptName)));
					}
				}
		}
	}

	public function setCharOffsets(?p1:Character, ?gf:Character, ?p2:Character):Void {
		if (p1 == null)
			p1 = PlayState.boyfriend;

		if (gf == null)
			gf = PlayState.gf;

		if (p2 == null)
			p2 = PlayState.dad;

		p1.setPosition((player_1_Point.x - (p1.width / 2)) + p1.positioningOffset[0], (player_1_Point.y - p1.height) + p1.positioningOffset[1]);
		gf.setPosition((gf_Point.x - (gf.width / 2)) + gf.positioningOffset[0], (gf_Point.y - gf.height) + gf.positioningOffset[1]);
		p2.setPosition((player_2_Point.x - (p2.width / 2)) + p2.positioningOffset[0], (player_2_Point.y - p2.height) + p2.positioningOffset[1]);

		p1.scrollFactor.set(p1_Scroll, p1_Scroll);
		p2.scrollFactor.set(p2_Scroll, p2_Scroll);
		gf.scrollFactor.set(gf_Scroll, gf_Scroll);

		if (p2.curCharacter.startsWith("gf") && gf.curCharacter.startsWith("gf")) {
			p2.setPosition(gf.x, gf.y);
			p2.scrollFactor.set(gf_Scroll, gf_Scroll);

			if (p2.visible)
				gf.visible = false;
		}

		if (p1.otherCharacters != null) {
			for (character in p1.otherCharacters) {
				character.setPosition((player_1_Point.x - (character.width / 2)) + character.positioningOffset[0],
					(player_1_Point.y - character.height) + character.positioningOffset[1]);
				character.scrollFactor.set(p1_Scroll, p1_Scroll);
			}
		}

		if (gf.otherCharacters != null) {
			for (character in gf.otherCharacters) {
				character.setPosition((gf_Point.x - (character.width / 2)) + character.positioningOffset[0],
					(gf_Point.y - character.height) + character.positioningOffset[1]);
				character.scrollFactor.set(gf_Scroll, gf_Scroll);
			}
		}

		if (p2.otherCharacters != null) {
			for (character in p2.otherCharacters) {
				character.setPosition((player_2_Point.x - (character.width / 2)) + character.positioningOffset[0],
					(player_2_Point.y - character.height) + character.positioningOffset[1]);
				character.scrollFactor.set(p2_Scroll, p2_Scroll);
			}
		}
	}

	public function getCharacterPos(character:Int, char:Character = null):Array<Float> {
		switch (character) {
			case 0: // bf
				if (char == null)
					char = PlayState.boyfriend;

				return [
					(player_1_Point.x - (char.width / 2)) + char.positioningOffset[0],
					(player_1_Point.y - char.height) + char.positioningOffset[1]
				];
			case 1: // dad
				if (char == null)
					char = PlayState.dad;

				return [
					(player_2_Point.x - (char.width / 2)) + char.positioningOffset[0],
					(player_2_Point.y - char.height) + char.positioningOffset[1]
				];
			case 2: // gf
				if (char == null)
					char = PlayState.gf;

				return [
					(gf_Point.x - (char.width / 2)) + char.positioningOffset[0],
					(gf_Point.y - char.height) + char.positioningOffset[1]
				];
		}

		return [0, 0];
	}

	override public function new(?stageName:String) {
		super();
		colorSwap = new ColorSwapHSV();
		stage = stageName;
		updateStage();
	}

	public function beatHit() {
		if (Options.getData("animatedBGs")) {
			for (sprite in onBeatHit_Group) {
				sprite.animation.play("beatHit");
			}

			for (member in members) {
				if (member is DancingSprite) {
					cast(member, DancingSprite).dance();
				}
			}
		}
	}

	// LUA SHIT LOL

	override public function destroy() {
		#if linc_luajit
		if (stageScript != null) {
			stageScript.destroy();
			stageScript = null;
		}
		#end

		super.destroy();
	}

	/**
	 * Returns a named sprite from a string, if it exists. 
	 * Otherwise, returns `null`.
	 * @param prop 
	 * @return FlxSprite
	 */
	public function getNamedProp(prop:String):FlxSprite {
		for (object in stageObjects) {
			if (object[0] == prop) {
				return object[1];
			}
		}
		return null;
	}
}

typedef StageData = {
	var character_Positions:Array<Array<Float>>;
	var character_Scrolls:Array<Float>;

	var camera_Zoom:Float;
	var camera_Offsets:Array<Array<Float>>;
	var objects:Array<StageObject>;
	var scriptName:Null<String>;
	var backgroundColor:Null<String>;
	var imageDirectory:Null<String>;
}

typedef StageObject = {
	// General Sprite Object Data //
	var position:Array<Float>;
	var scale:Float;
	var antialiased:Bool;
	var scroll_Factor:Array<Float>;

	var color:Array<Int>;
	var uses_Frame_Width:Bool;
	var object_Name:Null<String>;
	var layer:Null<String>; // default is bg, but fg is possible
	var alpha:Null<Float>;
	var updateHitbox:Null<Bool>;
	// Image Info //
	var file_Name:String;
	var is_Animated:Bool;
	// Animations //
	var animations:Array<CharacterAnimation>;
	var start_Animation:String;
	var dances:Null<Bool>;
}
