package game;

import openfl.display.BlendMode;
import flixel.util.FlxDestroyUtil;
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

	public var player_1_Point:FlxPoint = FlxPoint.get(1000, 800);
	public var player_2_Point:FlxPoint = FlxPoint.get(300, 800);
	public var gf_Point:FlxPoint = FlxPoint.get(600, 750);

	public var p1_Scroll:Float = 1.0;
	public var p2_Scroll:Float = 1.0;
	public var gf_Scroll:Float = 0.95;

	public var p1ZIndex:Int = 0;
	public var p2ZIndex:Int = 0;
	public var gfZIndex:Int = 0;

	public var p1_Cam_Offset:FlxPoint = FlxPoint.get(0, 0);
	public var p2_Cam_Offset:FlxPoint = FlxPoint.get(0, 0);

	public var stageData:StageData;

	public var stageObjects:Array<Array<Dynamic>> = [];

	// other
	public var onBeatHit_Group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	public var foregroundSprites:FlxGroup = new FlxGroup();
	public var infrontOfGFSprites:FlxGroup = new FlxGroup();

	public var stageScript:Script = null;

	public var colorSwap:ColorSwapHSV;
	public var useAbsolutePositions:Null<Bool> = false;

	public function updateStage(?newStage:String) {
		if (newStage != null)
			stage = newStage;

		if (stage != "" && Assets.exists(Paths.json("stage data/" + stage))) {
			stageData = cast Json.parse(Assets.getText(Paths.json("stage data/" + stage)).trim());
		} else {
			stageData = cast Json.parse(Assets.getText(Paths.json("stage data/stage")).trim());
			stage = 'stage';
		}

		clear();

		switch (stage) {
			// incase you want to harcode your stage
			default:
				{
					if (stageData != null) {
						camZoom = stageData.camera_Zoom;
						useAbsolutePositions = (stageData?.useAbsolutePositions) ?? false;

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

						if (stageData.characterZIndices != null) {
							p1ZIndex = stageData.characterZIndices[0];
							p2ZIndex = stageData.characterZIndices[1];
							gfZIndex = stageData.characterZIndices[2];
						}

						var nullObjectNameLoop:Int = 0;

						for (object in stageData.objects) {
							var sprite:FlxSprite = object.dances ? new DancingSprite(object.position[0],
								object.position[1]) : new FlxSprite(object.position[0], object.position[1]);

							if (Options.getData("shaders"))
								sprite.shader = colorSwap.shader;

							if (object.color != null && object.color != [])
								sprite.color = FlxColor.fromRGB(object.color[0], object.color[1], object.color[2]);

							if (object.blend != null) {
								@:privateAccess
								sprite.blend = BlendMode.fromString(object.blend);
							}

							sprite.antialiasing = object.antialiased && Options.getData("antialiasing");
							sprite.scrollFactor.set(object.scroll_Factor[0], object.scroll_Factor[1]);

							if (object.object_Name != null && object.object_Name != "")
								stageObjects.push([object.object_Name, sprite, object]);
							else {
								stageObjects.push(["undefinedSprite" + nullObjectNameLoop, sprite, object]);
								nullObjectNameLoop++;
							}

							if (object.is_Animated) {
								sprite.frames = Paths.getSparrowAtlas((stageData.imageDirectory ?? stage) + "/" + object.file_Name, "stages");

								for (animation in object.animations) {
									var animName:String = animation.name;

									if (animation.name == "beatHit")
										onBeatHit_Group.add(sprite);

									if (animation.indices == null) {
										sprite.animation.addByPrefix(animName, animation.animation_name, animation.fps, animation.looped);
									} else if (animation.indices.length == 0) {
										sprite.animation.addByPrefix(animName, animation.animation_name, animation.fps, animation.looped);
									} else {
										sprite.animation.addByIndices(animName, animation.animation_name, animation.indices, "", animation.fps,
											animation.looped);
									}
								}

								if (object.start_Animation != "" && object.start_Animation != null && object.start_Animation != "null")
									sprite.animation.play(object.start_Animation);
							} else if (object.file_Name.startsWith('#')) {
								sprite.makeGraphic(Std.int(object.scale), Std.int(object.scale), FlxColor.fromString(object.file_Name));
							} else
								sprite.loadGraphic(Paths.gpuBitmap((stageData.imageDirectory ?? stage) + "/" + object.file_Name, "stages"));

							if (object.scaleY == null) {
								object.scaleY = object.scale;
							}


							sprite.scale.set(object.scale, object.scaleY);

							if (object.updateHitbox || object.updateHitbox == null)
								sprite.updateHitbox();

							if (object.flipX != null)
								sprite.flipX = object.flipX;

							if (object.flipY != null)
								sprite.flipY = object.flipY;

							if (object.alpha != null)
								sprite.alpha = object.alpha;

							if (object.zIndex != null)
								sprite.zIndex = object.zIndex;

							if (object.layer != null) {
								switch (object.layer.toLowerCase().trim()) {
									case "foreground":
										foregroundSprites.add(sprite);
									case "gf":
										infrontOfGFSprites.add(sprite);
									default:
										add(sprite);
								}
							} else
								add(sprite);
						}
					}
					if (stageData.scriptName == null) {
						stageData.scriptName = stage;
					}
					if (FlxG.state is PlayState) {
						#if HSCRIPT_ALLOWED
						if (Assets.exists(Paths.hx('data/stage data/${stageData.scriptName}'))) {
							stageScript = new HScript(Paths.hx('data/stage data/${stage}'), STAGE);
							for (object in stageObjects) {
								stageScript.set(object[0], object[1]);
							}
						}
						#end
						#if LUA_ALLOWED
						if (Assets.exists(Paths.lua("stage data/" + stageData.scriptName))) {
							stageScript = new LuaScript(#if MODDING_ALLOWED PolymodAssets #else Assets #end.getPath(Paths.lua("stage data/"
								+ stageData.scriptName)));
							stageScript.executeOn = STAGE;
						}
						#end
					}
				}
		}
	}

	public function setPosition(char:Character, point:FlxPoint, scroll:Float, zIndex:Int, useAbsolute:Bool) {
		if (char.isCharacterGroup) {
			for (other in char.otherCharacters) {
				setPosition(other, point, scroll, zIndex, useAbsolute);
			}
			return;
		}
		if (useAbsolute) {
			char.setPosition(point.x + char.positioningOffset[0], point.y + char.positioningOffset[1]);
		} else {
			char.setPosition((point.x - (char.width / 2)) + char.positioningOffset[0], (point.y - char.height) + char.positioningOffset[1]);
		}
		char.scrollFactor.set(scroll, scroll);
	}

	public function setCharOffsets(?p1:Character, ?gf:Character, ?p2:Character):Void {
		p1 ??= PlayState.boyfriend;

		gf ??= PlayState.gf;

		p2 ??= PlayState.dad;

		setPosition(p1, player_1_Point, p1_Scroll, p1ZIndex, useAbsolutePositions);
		setPosition(gf, gf_Point, gf_Scroll, gfZIndex, useAbsolutePositions);
		setPosition(p2, player_2_Point, p2_Scroll, p2ZIndex, useAbsolutePositions);
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

	override function destroy() {
		super.destroy();
		FlxDestroyUtil.destroy(infrontOfGFSprites);
		FlxDestroyUtil.destroy(foregroundSprites);
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
	var characterZIndices:Array<Int>;

	var camera_Zoom:Float;
	var camera_Offsets:Array<Array<Float>>;
	var objects:Array<StageObject>;
	var scriptName:Null<String>;
	var backgroundColor:Null<String>;
	var imageDirectory:Null<String>;
	var useAbsolutePositions:Null<Bool>;
}

typedef StageObject = {
	// General sprite object Data //
	var position:Array<Float>;
	var zIndex:Null<Int>;
	var scale:Float;
	var scaleY:Null<Float>;
	var antialiased:Bool;
	var scroll_Factor:Array<Float>;

	var color:Array<Int>;
	var object_Name:Null<String>;
	var layer:Null<String>; // default is bg, but fg is possible
	var alpha:Null<Float>;
	var updateHitbox:Null<Bool>;
	var blend:Null<String>;

	var flipX:Null<Bool>;
	var flipY:Null<Bool>;

	// Image Info //
	var file_Name:String;
	var is_Animated:Bool;
	// Animations //
	var animations:Array<CharacterAnimation>;
	var start_Animation:String;
	var dances:Null<Bool>;
}
