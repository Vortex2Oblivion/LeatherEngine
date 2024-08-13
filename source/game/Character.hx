package game;

import flxanimate.frames.FlxAnimateFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.FlxTrail;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flxanimate.FlxAnimate;
import haxe.Json;
import lime.utils.Assets;
import modding.CharacterConfig;
import modding.scripts.languages.HScript;
import states.PlayState;


/**
 * The base character class.
 */
class Character extends FlxSprite {
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

	public var animationNotes:Array<Dynamic> = [];

	public var dancesLeftAndRight:Bool = false;

	public var barColor:FlxColor = FlxColor.GREEN;
	public var positioningOffset:Array<Float> = [0, 0];
	public var cameraOffset:Array<Float> = [0, 0];

	public var otherCharacters:Array<Character>;
	public var mainCharacterID:Int = 0;

	public var offsetsFlipWhenPlayer:Bool = true;
	public var offsetsFlipWhenEnemy:Bool = false;

	public var coolTrail:FlxTrail;

	public var deathCharacter:String = "bf-dead";

	public var swapLeftAndRightSingPlayer:Bool = true;

	public var icon:String;

	public var isDeathCharacter:Bool = false;

	public var config:CharacterConfig;

	public var singDuration:Float = 4.0;

	public var script:HScript;

	public var singAnimPrefix:String = 'sing';

	public var playFullAnim:Bool = false;
	public var preventDanceForAnim:Bool = false;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?isDeathCharacter:Bool = false) {
		
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();

		curCharacter = character;
		this.isPlayer = isPlayer;
		this.isDeathCharacter = isDeathCharacter;

		antialiasing = true;

		dancesLeftAndRight = false;

		var ilikeyacutg:Bool = false;

		switch (curCharacter) {
			case '':
				trace("NO VALUE THINGY LOL DONT LOAD SHIT");
				deathCharacter = "bf-dead";

			default:
				if (isPlayer)
					flipX = !flipX;

				ilikeyacutg = true;

				loadNamedConfiguration(curCharacter);
		}

		if (isPlayer && !ilikeyacutg)
			flipX = !flipX;

		if (icon == null)
			icon = curCharacter;

		// YOOOOOOOOOO POG MODDING STUFF
		if (character != '')
			loadOffsetFile(curCharacter);

		if (curCharacter != '' && otherCharacters == null && hasAnims()) {
			if (atlasMode) {
				atlas.updateHitbox();
				width = atlas.width;
				height = atlas.height;
				offset = atlas.offset;
				origin = atlas.origin;
			} else {
				updateHitbox();
			}

			if (!debugMode) {
				dance('');

				if (isPlayer) {
					// Doesn't flip for BF, since his are already in the right place???
					if (swapLeftAndRightSingPlayer && !isDeathCharacter) {
						try{

							var oldOffRight = animOffsets.get("singRIGHT");
							var oldOffLeft = animOffsets.get("singLEFT");
							var oldRight:Array<Int> = animation.getByName('singRIGHT').frames;
							animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
							animation.getByName('singLEFT').frames = oldRight;

							animOffsets.set("singRIGHT", oldOffLeft);
							animOffsets.set("singLEFT", oldOffRight);

							// IF THEY HAVE MISS ANIMATIONS??
							if (animation.getByName('singRIGHTmiss') != null) {
								var oldOffRightMiss = animOffsets.get("singRIGHTmiss");
								var oldOffLeftMiss = animOffsets.get("singLEFTmiss");

								var oldMiss = animation.getByName('singRIGHTmiss').frames;
								animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
								animation.getByName('singLEFTmiss').frames = oldMiss;

								animOffsets.set("singRIGHTmiss", oldOffLeftMiss);
								animOffsets.set("singLEFTmiss", oldOffRightMiss);
							}
						}	
						catch(e){
							//trace(e, ERROR);
						}
					}
				}
			}
		} else {
			visible = false;
		}
		if (Assets.exists(Paths.hx("data/character data/" + curCharacter + "/script"))) {
			script.call("createCharacterPost", [curCharacter]);
		}
	}

	public function loadNamedConfiguration(characterName:String) {
		if (!Assets.exists(Paths.json("character data/" + characterName + "/config"))) {
			characterName = "bf";
			curCharacter = characterName;
		}
		if(Assets.exists(Paths.hx("data/character data/" + characterName + "/script")))
			{
				script = new HScript(Paths.hx("data/character data/" + characterName + "/script"));
	
				script.interp.variables.set("character", this);
				PlayState.instance.scripts.push(script);
				script.call("createCharacter", [curCharacter]);
			}

		if (Options.getData("optimizedChars") && Assets.exists(Paths.json("character data/optimized_" + characterName + "/config")))
			characterName = "optimized_" + characterName;

		var rawJson = Assets.getText(Paths.json("character data/" + characterName + "/config")).trim();
		this.config = cast Json.parse(rawJson);
		loadCharacterConfiguration(this.config);
	}

	public var atlasMode:Bool = false;
	public var atlas:FlxAnimate;

	override public function draw():Void {
		if (atlasMode && atlas != null && visible) {
			// thanks cne for this shits lol
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.color = color;
			atlas.colorTransform = colorTransform;
			atlas.draw();
		} else {
			super.draw();
		}
	}


	private function getAtlas(path:String):FlxAtlasFrames{
		if (Assets.exists(Paths.file("images/characters/" + path + ".txt", TEXT))) {
			return Paths.getPackerAtlas('characters/' + path);
		}
		else if (Assets.exists(Paths.file("images/characters/" + path + ".json", TEXT))){
			return Paths.getJsonAtlas('characters/' + path);
		}
		else if (Assets.exists(Paths.file("images/characters/" + path + ".plist", TEXT))){
			return Paths.getCocos2DAtlas('characters/' + path);
		} 
		else if (Assets.exists(Paths.file("images/characters/" + path + ".eas", TEXT))){
			return Paths.getEdgeAnimateAtlas('characters/' + path);
		} 
		else if (Assets.exists(Paths.file("images/characters/" + path + ".js", TEXT))){
			return Paths.getEaselJSAtlas('characters/' + path);
		} 
		return Paths.getSparrowAtlas('characters/' + path);
	}

	public function loadCharacterConfiguration(config:CharacterConfig) {
		if (config.characters == null || config.characters.length <= 1) {
			if (!isPlayer)
				flipX = config.defaultFlipX;
			else
				flipX = !config.defaultFlipX;
			if (Options.getData("dinnerbone")){
				flipY = !config.defaultFlipY;
			}

			if (config.offsetsFlipWhenPlayer == null) {
				if (curCharacter.contains("bf"))
					offsetsFlipWhenPlayer = false;
				else
					offsetsFlipWhenPlayer = true;
			} else
				offsetsFlipWhenPlayer = config.offsetsFlipWhenPlayer;

			if (config.offsetsFlipWhenEnemy == null) {
				if (curCharacter.contains("bf"))
					offsetsFlipWhenEnemy = true;
				else
					offsetsFlipWhenEnemy = false;
			} else
				offsetsFlipWhenEnemy = config.offsetsFlipWhenEnemy;

			dancesLeftAndRight = config.dancesLeftAndRight;

			if (Assets.exists(Paths.file("images/characters/" + config.imagePath + "/Animation.json", TEXT))){
				atlasMode = true;
				atlas = new FlxAnimate(0.0, 0.0, Paths.getTextureAtlas("characters/" + config.imagePath, "shared"));
				atlas.showPivot = false;
			}
			else{
				frames = getAtlas(config.imagePath);
			}

			if(config.extraSheets != null){
				for (sheet in config.extraSheets){
					cast(frames, FlxAtlasFrames).addAtlas(getAtlas(sheet)); //multiatlas support.
				}
			}

			var size:Null<Float> = config.graphicSize;

			if (size == null)
				size = config.graphicsSize;

			if (size != null)
				scale.set(size, size);

			if (!atlasMode) {
				for (selected_animation in config.animations) {
					if (selected_animation.indices != null && selected_animation.indices.length > 0) {
						animation.addByIndices(selected_animation.name, selected_animation.animation_name, selected_animation.indices, "", selected_animation.fps, selected_animation.looped);
					} else {
						animation.addByPrefix(selected_animation.name, selected_animation.animation_name, selected_animation.fps, selected_animation.looped);
					}
				}
			} else {
				for (selected_animation in config.animations) {
					if (selected_animation.indices != null && selected_animation.indices.length > 0) {
						atlas.anim.addBySymbolIndices(selected_animation.name, selected_animation.animation_name, selected_animation.indices, selected_animation.fps, selected_animation.looped);
					} else {
						atlas.anim.addBySymbol(selected_animation.name, selected_animation.animation_name, selected_animation.fps, selected_animation.looped);
					}
				}
			}

			if (isDeathCharacter)
				playAnim("firstDeath");
			else {
				if (dancesLeftAndRight)
					playAnim("danceRight");
				else{
					playAnim("idle");

				}
			}

			if (debugMode)
				flipX = config.defaultFlipX;

			if (config.antialiasing != null)
				antialiasing = config.antialiasing;
			else if (config.antialiased != null)
				antialiasing = config.antialiased;

			if (atlasMode) {
				atlas.updateHitbox();
				width = atlas.width;
				height = atlas.height;
				offset = atlas.offset;
				origin = atlas.origin;
			} else {
				updateHitbox();
			}

			if (config.positionOffset != null)
				positioningOffset = config.positionOffset;

			if (config.trail == true)
				coolTrail = new FlxTrail(this, null, config.trailLength, config.trailDelay, config.trailStalpha, config.trailDiff);

			if (config.swapDirectionSingWhenPlayer != null)
				swapLeftAndRightSingPlayer = config.swapDirectionSingWhenPlayer;
			else if (curCharacter.contains("bf"))
				swapLeftAndRightSingPlayer = false;

			if (config.singDuration != null)
				singDuration = config.singDuration;
		} else {
			otherCharacters = [];
			mainCharacterID = config.mainCharacterID;

			for (characterData in config.characters) {
				var character:Character;

				if (!isPlayer)
					character = new Character(x, y, characterData.name, isPlayer, isDeathCharacter);
				else
					character = new Boyfriend(x, y, characterData.name, isDeathCharacter);

				if (flipX)
					characterData.positionOffset[0] = 0 - characterData.positionOffset[0];

				character.positioningOffset[0] += characterData.positionOffset[0];
				character.positioningOffset[1] += characterData.positionOffset[1];

				otherCharacters.push(character);
			}
		}

		if (config.barColor == null)
			config.barColor = [255, 0, 0];

		barColor = FlxColor.fromRGB(config.barColor[0], config.barColor[1], config.barColor[2]);

		var localKeyCount;
		if(FlxG.state == PlayState.instance){
			localKeyCount = isPlayer ? PlayState.SONG.playerKeyCount : PlayState.SONG.keyCount;
		}
		else{
			localKeyCount = 4;
		}


		if (config.cameraOffset != null) {
			if (flipX)
				config.cameraOffset[0] = 0 - config.cameraOffset[0];

			cameraOffset = config.cameraOffset;
		}

		if (config.deathCharacter != null)
			deathCharacter = config.deathCharacter;
		else if (config.deathCharacterName != null)
			deathCharacter = config.deathCharacterName;
		else
			deathCharacter = "bf-dead";

		if (config.healthIcon != null)
			icon = config.healthIcon;
	}

	public function loadOffsetFile(characterName:String) {
		animOffsets = new Map<String, Array<Dynamic>>();

		if (!Assets.exists(Paths.txt("character data/" + characterName + "/" + "offsets"))) {
			return;
		}

		var offsets:Array<String> = CoolUtil.coolTextFile(Paths.txt("character data/" + characterName + "/" + "offsets"));

		for (x in 0...offsets.length) {
			var selectedOffset = offsets[x];
			var arrayOffset:Array<String>;
			arrayOffset = selectedOffset.split(" ");

			addOffset(arrayOffset[0], Std.parseInt(arrayOffset[1]), Std.parseInt(arrayOffset[2]));
		}
	}

	public var shouldDance:Bool = true;

	override function update(elapsed:Float) {
		if (!debugMode && curCharacter != '' && hasAnims()) {
			if(curAnimFinished() && hasAnim(curAnimName() + '-loop'))
				{
					playAnim(curAnimName() + '-loop');
				}
				else if (playFullAnim && curAnimFinished())
				{
					playFullAnim = false;
					dance('');
				}
				else if (preventDanceForAnim && curAnimFinished())
				{
					preventDanceForAnim = false;
					dance('');
				}
			if (!isPlayer) {
				if (curAnimName().startsWith('sing'))
					holdTimer += elapsed * (FlxG.state == PlayState.instance ? PlayState.songMultiplier : 1);

				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001) {
					dance(mostRecentAlt);
					holdTimer = 0;
				}
			}

			// fix for multi character stuff lmao
			if (hasAnims()) {
				if (curAnimName() == 'hairFall' && curAnimFinished())
					playAnim('danceRight');
			}
		}
		
		if (atlasMode && atlas != null) {
			atlas.update(elapsed);
		}

		super.update(elapsed);

	}

	private var danced:Bool = false;

	public var lastAnim:String = '';
	var mostRecentAlt:String = "";

	public inline function curAnimLooped():Bool {
		@:privateAccess
		return (!atlasMode && animation.curAnim != null && animation.curAnim.looped) || 
				(atlasMode && atlas.anim.loopType == flxanimate.data.AnimationData.Loop.Loop);
	}

	public inline function curAnimFinished():Bool {
		return (!atlasMode && animation.curAnim != null && animation.curAnim.finished) || 
				(atlasMode && atlas.anim.finished);
	}

	public function curAnimName():String {
		if (!atlasMode && animation.curAnim != null) {
			return animation.curAnim.name;
		}

		if (atlasMode) {
			return lastAnim;
		}

		return '';
	}

	public inline function hasAnim(name:String):Bool {
		return (!atlasMode && animation.exists(name)) || (atlasMode && atlas.anim.existsByName(name));
	}

	public inline function hasAnims():Bool {
		return (!atlasMode && animation.curAnim != null) || (atlasMode && atlas != null && atlas.anim != null);
	}

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?altAnim:String = '', force:Bool = false) {
		if (shouldDance) {
			if (!debugMode && curCharacter != '' && hasAnims() && (force || (!playFullAnim && !preventDanceForAnim))) {
				var alt = "";

				if ((!dancesLeftAndRight && hasAnim("idle" + altAnim))
					|| (dancesLeftAndRight
						&& hasAnim("danceLeft" + altAnim)
						&& hasAnim("danceRight" + altAnim)))
					alt = altAnim;

				mostRecentAlt = alt;

				var special_animation = !(curAnimName().startsWith('idle')
					|| curAnimName().startsWith('danceLeft')
					|| curAnimName().startsWith('danceRight')
					|| curAnimName().startsWith('sing'));

				if (!special_animation || curAnimFinished() || curAnimLooped()) {
					if (!dancesLeftAndRight)
						playAnim('idle' + alt);
					else {
						danced = !danced;

						if (danced)
							playAnim('danceRight' + alt);
						else
							playAnim('danceLeft' + alt);
					}
				}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		if (playFullAnim)
			return;
		if (!hasAnim(AnimName))
			return;
		
		if (singAnimPrefix != 'sing' && AnimName.contains('sing')){
			var anim = AnimName;
			anim = anim.replace('sing', singAnimPrefix);
			if (animation.getByName(anim) != null) //check if it exists so no broken anims
				AnimName = anim;
		}

		preventDanceForAnim = false; //reset it

		if (atlasMode && atlas != null) {
			atlas.anim.play(AnimName, Force, Reversed, Frame);
		} else {
			animation.play(AnimName, Force, Reversed, Frame);
		}

		lastAnim = AnimName;

		if (AnimName.contains('dodge'))
			preventDanceForAnim = true;

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName)) {
			offset.set((daOffset[0] * _cosAngle) - (daOffset[1] *_sinAngle), (daOffset[1] * _cosAngle) + (daOffset[0] * _sinAngle));
		}
		else{
			offset.set(0, 0);
		}
	}

	public inline function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets.set(name, [(isPlayer && offsetsFlipWhenPlayer) || (!isPlayer && offsetsFlipWhenEnemy) ? -x : x, y]);
	}

	public var followMainCharacter:Bool = false;

	public function getMainCharacter():Character
	{
		if (otherCharacters != null && otherCharacters.length > 0)
		{
			if (followMainCharacter)
				return otherCharacters[mainCharacterID];
		}
		return this;
	}
}
