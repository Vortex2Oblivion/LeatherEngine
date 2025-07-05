package toolbox;

import flixel.input.FlxInput;
import ui.HealthIcon;
import flixel.ui.FlxBar;
import openfl.utils.Assets;
import flixel.text.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import modding.CharacterConfig;
import haxe.Json;
#if DISCORD_ALLOWED
import utilities.DiscordClient;
#end
import game.StageGroup;
import flixel.ui.FlxButton;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
import ui.FlxScrollableDropDownMenu;
import states.MusicBeatState;
import states.MainMenuState;
import states.PlayState;
import game.Character;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUITabMenu;

using StringTools;

/**
	*DEBUG MODE
 */
@:publicFields
class CharacterCreator extends MusicBeatState {
	var char:Character;
	var ghost:Character;
	var animText:FlxText;
	var moveText:FlxText;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;
	var _file:FileReference;

	var tabs:FlxUITabMenu;

	function new(daAnim:String = 'spooky', selectedStage:String) {
		super();
		this.daAnim = daAnim;
		stages = CoolUtil.coolTextFile(Paths.txt('stageList'));

		if (selectedStage != null)
			stageName = selectedStage;
	}

	var characters:Map<String, Array<String>> = ["default" => ["bf", "gf"]];

	var modList:Array<String> = ["default"];
	var curCharList:Array<String>;

	var offsetButton:FlxButton;
	var configButton:FlxButton;
	var charDropDown:FlxScrollableDropDownMenu;
	var modDropDown:FlxScrollableDropDownMenu;
	var ghostAnimDropDown:FlxScrollableDropDownMenu;

	var gridBG:FlxSprite;

	/* CAMERA */
	var gridCam:FlxCamera;
	var charCam:FlxCamera;
	var camHUD:FlxCamera;

	/*STAGE*/
	var stage:StageGroup;

	var stages:Array<String>;
	var stageName:String = 'stage';
	var stageData:StageData;

	var stageDropdown:FlxScrollableDropDownMenu;
	var objects:Array<Array<Dynamic>> = [];

	static var lastState:String = "OptionsMenu";

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Creating A Character", null, null, true);
		#end
		FlxG.mouse.visible = true;

		gridCam = new FlxCamera();
		charCam = new FlxCamera();
		charCam.bgColor.alpha = 0;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset();
		FlxG.cameras.add(gridCam, false);
		FlxG.cameras.add(charCam, true);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(charCam, true);

		FlxG.camera = charCam;

		if (FlxG.sound.music != null && FlxG.sound.music.active)
			FlxG.sound.music.stop();

		gridBG = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0, 0);
		gridBG.cameras = [gridCam];
		add(gridBG);


		ghost = new Character(0, 0, daAnim);
		ghost.debugMode = true;
		ghost.color = FlxColor.BLACK;
		ghost.alpha = 0.5;

		char = new Character(0, 0, daAnim);
		char.debugMode = true;

		reloadStage();
		add(ghost);
		add(char);
		animText = new FlxText(4, 4, 0, "BRUH BRUH BRUH: [0,0]", 20);
		animText.font = Paths.font("vcr.ttf");
		animText.scrollFactor.set();
		animText.color = FlxColor.WHITE;
		animText.borderColor = FlxColor.BLACK;
		animText.borderStyle = OUTLINE_FAST;
		animText.borderSize = 2;
		animText.cameras = [camHUD];
		add(animText);

		moveText = new FlxText(4, 4, 0, "", 20);
		moveText.font = Paths.font("vcr.ttf");
		moveText.x = FlxG.width - moveText.width - 4;
		moveText.scrollFactor.set();
		moveText.color = FlxColor.WHITE;
		moveText.borderColor = FlxColor.BLACK;
		moveText.borderStyle = OUTLINE_FAST;
		moveText.borderSize = 2;
		moveText.alignment = RIGHT;
		moveText.cameras = [camHUD];
		add(moveText);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.sound.playMusic(Paths.music('breakfast'));

		charCam.follow(camFollow);

		var characterData:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
		char.setPosition(position[0], position[1]);
		ghost.setPosition(position[0], position[1]);

		for (item in characterData) {
			var characterDataVal:Array<String> = item.split(":");

			var charName:String = characterDataVal[0];
			var charMod:String = characterDataVal[1];

			var charsLmao:Array<String> = [];

			if (characters.exists(charMod))
				charsLmao = characters.get(charMod);
			else
				modList.push(charMod);

			charsLmao.push(charName);
			characters.set(charMod, charsLmao);
		}

		curCharList = characters.get("default");

		charDropDown = new FlxScrollableDropDownMenu(10, 500, FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true), function(character:String) {
			remove(char);
			char.kill();
			char.destroy();

			remove(ghost);
			ghost.kill();
			ghost.destroy();

			daAnim = curCharList[Std.parseInt(character)];

			ghost = new Character(0, 0, daAnim);
			ghost.debugMode = true;
			ghost.color = FlxColor.BLACK;
			ghost.alpha = 0.5;
			add(ghost);

			char = new Character(0, 0, daAnim);
			char.debugMode = true;
			add(char);

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);
			ghost.setPosition(position[0], position[1]);

			animList = [];
			genBoyOffsets(true);
			remove(ghostAnimDropDown);
			ghostAnimDropDown.kill();
			ghostAnimDropDown.destroy();
			ghostAnimDropDown = new FlxScrollableDropDownMenu(stageDropdown.x + stageDropdown.width + 1, stageDropdown.y,
				FlxUIDropDownMenu.makeStrIdLabelArray(animList, true), function(animName:String) {
					ghost.playAnim(animList[Std.parseInt(animName)], true);

					var position = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
					ghost.setPosition(position[0], position[1]);

					genBoyOffsets(false);
			});

			ghostAnimDropDown.scrollFactor.set();
			ghostAnimDropDown.cameras = [camHUD];
			add(ghostAnimDropDown);
		});

		charDropDown.selectedLabel = daAnim;
		charDropDown.scrollFactor.set();
		charDropDown.cameras = [camHUD];
		add(charDropDown);

		modDropDown = new FlxScrollableDropDownMenu(charDropDown.x + charDropDown.width + 1, charDropDown.y,
			FlxUIDropDownMenu.makeStrIdLabelArray(modList, true), function(modID:String) {
				var mod:String = modList[Std.parseInt(modID)];

				if (characters.exists(mod)) {
					curCharList = characters.get(mod);
					charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true));
					charDropDown.selectedLabel = curCharList[0];

					remove(char);
					char.kill();
					char.destroy();

					remove(ghost);
					ghost.kill();
					ghost.destroy();

					daAnim = curCharList[0];
					ghost = new Character(0, 0, daAnim);
					ghost.debugMode = true;
					ghost.alpha = 0.5;
					ghost.color = FlxColor.BLACK;
					add(ghost);

					char = new Character(0, 0, daAnim);
					char.debugMode = true;
					add(char);

					var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
					char.setPosition(position[0], position[1]);

					animList = [];
					genBoyOffsets(true);
				}
		});

		modDropDown.selectedLabel = "default";
		modDropDown.scrollFactor.set();
		modDropDown.cameras = [camHUD];
		add(modDropDown);

		stageDropdown = new FlxScrollableDropDownMenu(modDropDown.x + modDropDown.width + 1, modDropDown.y,
			FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stageName:String) {
				stageName = stages[Std.parseInt(stageName)];
				reloadStage();
				remove(ghost);
				ghost.kill();
				ghost.destroy();
				remove(char);
				char.kill();
				char.destroy();
				daAnim = curCharList[0];

				ghost = new Character(0, 0, daAnim);
				ghost.debugMode = true;
				ghost.color = FlxColor.BLACK;
				ghost.alpha = 0.5;
				add(ghost);

				char = new Character(0, 0, daAnim);
				char.debugMode = true;
				add(char);

				var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
				char.setPosition(position[0], position[1]);

				animList = [];
				genBoyOffsets(true);
		});

		stageDropdown.selectedLabel = stageName;
		stageDropdown.scrollFactor.set();
		stageDropdown.cameras = [camHUD];
		add(stageDropdown);

		ghostAnimDropDown = new FlxScrollableDropDownMenu(stageDropdown.x + stageDropdown.width + 1, stageDropdown.y,
			FlxUIDropDownMenu.makeStrIdLabelArray(animList, true), function(animName:String) {
				ghost.playAnim(animList[Std.parseInt(animName)], true);

				var position = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
				ghost.setPosition(position[0], position[1]);

				genBoyOffsets(false);
		});

		ghostAnimDropDown.scrollFactor.set();
		ghostAnimDropDown.cameras = [camHUD];
		add(ghostAnimDropDown);

		offsetButton = new FlxButton(charDropDown.x, charDropDown.y - 30, "Save Offsets", function() {
			saveOffsets();
		});
		offsetButton.scrollFactor.set();
		offsetButton.cameras = [camHUD];
		add(offsetButton);

		configButton = new FlxButton(offsetButton.x, offsetButton.y - 30, "Save Character", function() {
			saveConfig();
		});
		configButton.scrollFactor.set();
		configButton.cameras = [camHUD];
		add(configButton);
		

		tabs = new FlxUITabMenu(null, [
			{name: 'Character', label: 'Character'}
		], true);
		tabs.resize(300, 400);
		tabs.x = 900;
		tabs.screenCenter(Y);
		tabs.scrollFactor.set();
		tabs.cameras = [camHUD];
		add(tabs);

		var tabCharacter:FlxUI = new FlxUI(null, tabs);
		tabCharacter.name = "Character";


		var checkAntialiasing:FlxUICheckBox = new FlxUICheckBox(10, 250, null, null, "Antialasing");
		checkAntialiasing.checked = char.antialiasing;
		checkAntialiasing.callback = () -> {
			char.config.antialiasing = ghost.config.antialiasing = char.antialiasing = ghost.antialiasing = checkAntialiasing.checked;
		}

		tabCharacter.add(checkAntialiasing);

		var checkFlipX:FlxUICheckBox = new FlxUICheckBox(checkAntialiasing.x, checkAntialiasing.y + 25, null, null, "Flip X");
		checkFlipX.checked = char.config.defaultFlipX;
		checkFlipX.callback = () -> {
			char.config.defaultFlipX = checkFlipX.checked;
			ghost.config.defaultFlipX = checkFlipX.checked;
			char.flipX = !char.flipX;
			ghost.flipX = !ghost.flipX;
		}

		tabCharacter.add(checkFlipX);

		var spriteSheetTextInput:FlxInputText = new FlxInputText(10, 10, 100, char.config.imagePath);
		spriteSheetTextInput.onTextChange.add((text, change) -> {
			char.config.imagePath = text;
			char.config.defaultFlipX = checkFlipX.checked;
			char.loadCharacterConfiguration(char.config);
			char.playAnim("idle", true);
		});
		tabCharacter.add(spriteSheetTextInput);

		var healthBar:FlxSprite = new FlxSprite(10, 350).makeGraphic(280, 9, char.barColor);
		healthBar.antialiasing = false;
		tabCharacter.add(healthBar);

		var icon:HealthIcon = new HealthIcon(char.curCharacter);
		icon.scale.set(icon.scale.x * 0.47, icon.scale.y * 0.47);
		icon.updateHitbox();	
		icon.x = 10 - icon.width / 2;
		icon.y = 350 - (icon.height / 2);
		tabCharacter.add(icon);

		var r:FlxInputText = new FlxInputText(healthBar.x, healthBar.y - 50, 30, Std.string(char.config.barColor[0]));
		r.onTextChange.add((text, change) -> {
			var num:Int = Math.floor(Math.max(0, Math.min(Std.parseInt(text), 255)));
			char.config.barColor[0] = num;
			healthBar.color.red = num;
			trace(num, DEBUG);
		});
		tabCharacter.add(r);
		
		tabs.addGroup(tabCharacter);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void {
		animText.text = "";

		for (anim => offsets in char.animOffsets) {
			if (pushList)
				animList.push(anim);

			animText.text += anim + (anim == animList[curAnim] ? " (current) " : "") + ": " + offsets + "\n";
		}

		if ((char.offsetsFlipWhenPlayer && char.isPlayer) || (char.offsetsFlipWhenEnemy && !char.isPlayer))
			animText.text += "(offsets flipped)";
	}

	override function update(elapsed:Float) {
		if (FlxG.keys.pressed.E && charCam.zoom < 2)
			charCam.zoom += elapsed * charCam.zoom * (FlxG.keys.pressed.SHIFT ? 0.1 : 1);
		if (FlxG.keys.pressed.Q && charCam.zoom >= 0.1)
			charCam.zoom -= elapsed * charCam.zoom * (FlxG.keys.pressed.SHIFT ? 0.1 : 1);
		if (FlxG.mouse.wheel != 0 && charCam.zoom >= 0.1 && charCam.zoom < 2)
			charCam.zoom += FlxG.keys.pressed.SHIFT ? FlxG.mouse.wheel / 100.0 : FlxG.mouse.wheel / 10.0;

		if (charCam.zoom > 2)
			charCam.zoom = 2;
		if (charCam.zoom < 0.1)
			charCam.zoom = 0.1;
		if (FlxG.keys.justPressed.Z)
			stage.foregroundSprites.visible = stage.infrontOfGFSprites.visible = stage.visible = !stage.visible;
		if (FlxG.keys.justPressed.X) {
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;

			ghost.isPlayer = !ghost.isPlayer;
			ghost.flipX = !ghost.flipX;

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);
			ghost.setPosition(position[0], position[1]);

			char.loadOffsetFile(char.curCharacter);
			char.playAnim(animList[curAnim], true);
			animList = [];
			genBoyOffsets(true);
		}

		var shiftThing:Int = FlxG.keys.pressed.SHIFT ? 5 : 1;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L) {
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90 * shiftThing;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90 * shiftThing;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90 * shiftThing;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90 * shiftThing;
			else
				camFollow.velocity.x = 0;
		} else {
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W) {
			curAnim--;
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			if (lastState == "OptionsMenu") {
				FlxG.switchState(() -> new MainMenuState());
			} else {
				FlxG.switchState(() -> new PlayState());
			}
		}

		if (FlxG.keys.justPressed.S) {
			curAnim++;
		}

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE) {
			char.playAnim(animList[curAnim], true);

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);

			genBoyOffsets(false);
		}

		var upP = FlxG.keys.justPressed.UP;
		var rightP = FlxG.keys.justPressed.RIGHT;
		var downP = FlxG.keys.justPressed.DOWN;
		var leftP = FlxG.keys.justPressed.LEFT;

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		if (upP || rightP || downP || leftP) {
			if (upP) {
				char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
				ghost.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			}
			if (downP) {
				char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
				ghost.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			}
			if (leftP) {
				char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
				ghost.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			}
			if (rightP) {
				char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;
				ghost.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;
			}

			genBoyOffsets(false);
			char.playAnim(animList[curAnim], true);
		}

		charCam.zoom = flixel.math.FlxMath.roundDecimal(charCam.zoom, 2) <= 0 ? 1 : charCam.zoom;
		moveText.text = 'Use IJKL to move the camera\nE and Q to zoom the camera\nSHIFT for faster moving offset or camera\nZ to toggle the stage\nX to toggle playing side\nCamera Zoom: ${flixel.math.FlxMath.roundDecimal(charCam.zoom, 2)}\n';
		moveText.x = FlxG.width - moveText.width - 4;

		super.update(elapsed);
	}

	function saveOffsets() {
		var offsetsText:String = "";
		var flipped = (char.offsetsFlipWhenPlayer && char.isPlayer) || (char.offsetsFlipWhenEnemy && !char.isPlayer);

		for (anim => offsets in char.animOffsets) {
			offsetsText += anim + " " + (flipped ? -offsets[0] : offsets[0]) + " " + offsets[1] + "\n";
		}

		if ((offsetsText != "") && (offsetsText.length > 0)) {
			if (offsetsText.endsWith("\n"))
				offsetsText = offsetsText.substr(0, offsetsText.length - 1);

			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			_file.save(offsetsText, "offsets.txt");
		}
	}

	function saveConfig(){
		var config:CharacterConfig = cast {
			imagePath: "",
			animations: [],
			defaultFlipX: char.config.defaultFlipX,
			dancesLeftAndRight: false,
			barColor: [0, 0, 0],
			positionOffset: [0, 0],
			cameraOffset: [0, 0],
			singDuration: 4
		}
		_file = new FileReference();
		_file.addEventListener(Event.COMPLETE, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file.save(Json.stringify(config, "\t"), "config.json");
	}

	function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved OFFSETS FILE.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		trace("Problem saving offsets file", ERROR);
	}

	function reloadStage() {
		objects = [];

		if (stage != null) {
			remove(stage);
		}
		add(camFollow);

		stage = new StageGroup(stageName);
		add(stage);

		stageData = stage.stageData;

		var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
		char.setPosition(position[0], position[1]);
		ghost.setPosition(position[0], position[1]);

		remove(stage.infrontOfGFSprites);
		add(stage.infrontOfGFSprites);

		if (ghost.otherCharacters == null) {
			remove(ghost);
			add(ghost);
		} else {
			for (character in ghost.otherCharacters) {
				remove(character);
				add(character);
			}
		}

		if (char.otherCharacters == null) {
			remove(char);
			add(char);
		} else {
			for (character in char.otherCharacters) {
				remove(character);
				add(character);
			}
		}

		remove(stage.foregroundSprites);
		add(stage.foregroundSprites);
	}
}
