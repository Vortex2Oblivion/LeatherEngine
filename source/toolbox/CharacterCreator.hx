package toolbox;

import openfl.display.BlendMode;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.effects.FlxTrail;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.addons.ui.FlxUINumericStepper;
import ui.HealthIcon;
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
	var ghostAnimList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;
	var _file:FileReference;

	var tabs:FlxUITabMenu;

	var editor:FlxUITabMenu;

	var cross:FlxSprite;
	var scaleStepper:FlxUINumericStepper;

	var animationFramerateStepper:FlxUINumericStepper;
	var animationLoopedCheckbox:FlxUICheckBox;
	var removeAnimation:FlxUIButton;

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

	var offsetButton:FlxUIButton;
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

	var globalOffsetXStepper:FlxUINumericStepper;
	var globalOffsetYStepper:FlxUINumericStepper;

	var cameraOffsetXStepper:FlxUINumericStepper;
	var cameraOffsetYStepper:FlxUINumericStepper;

	var ghostAlphaSlider:FlxUISlider;
	var ghostBlendCheck:FlxUICheckBox;

	var trail:FlxUICheckBox;
	var trailLength:FlxUINumericStepper;
	var trailDelay:FlxUINumericStepper;
	var trailAlpha:FlxUINumericStepper;
	var trailDiff:FlxUINumericStepper;

	var singDurationStepper:FlxUINumericStepper;

	var icon:HealthIcon;

	var iconName:FlxInputText;

	var healthBar:FlxSprite;

	var r:FlxInputText;
	var g:FlxInputText;
	var b:FlxInputText;

	var spriteSheetTextInput:FlxInputText;

	var checkFlipX:FlxUICheckBox;

	var checkAntialiasing:FlxUICheckBox;

	var offsetsFlipWhenPlayer:FlxUICheckBox;
	var offsetsFlipWhenEnemy:FlxUICheckBox;

	var addAnimation:FlxUIButton;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Creating A Character", null, null, true);
		#end
		Main.display.visible = false;
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
		// ghost.color = FlxColor.BLACK;
		ghost.alpha = 0.5;

		char = new Character(0, 0, daAnim);
		char.debugMode = true;

		reloadStage();
		add(ghost);
		add(char.coolTrail);
		add(char);

		var midPos:FlxPoint = char.getMidpoint();
		midPos.x += stage.p2_Cam_Offset.x;
		midPos.y += stage.p2_Cam_Offset.y;

		/*cross = new FlxShapeCross(midPos.x + 150 + char.cameraOffset[0], midPos.y - 100 + char.cameraOffset[1], 10, 10, 10, 10, 10, 10, {
				thickness: 1,
				color: FlxColor.TRANSPARENT,
				capsStyle: CapsStyle.SQUARE,
				jointStyle: JointStyle.MITER
			}, FlxColor.WHITE);
			add(cross); */

		cross = new FlxSprite(midPos.x + 150 + char.cameraOffset[0], midPos.y - 100 + char.cameraOffset[1]).loadGraphic(new ui.Cross(11, 11));
		cross.antialiasing = false;
		cross.scale.set(3, 3);
		cross.updateHitbox();
		cross.pixelPerfectRender = true;
		add(cross);

		animText = new FlxText(4, 4, 0, "BRUH BRUH BRUH: [0,0]", 20);
		animText.font = Paths.font("vcr.ttf");
		animText.scrollFactor.set();
		animText.color = FlxColor.WHITE;
		animText.borderColor = FlxColor.BLACK;
		animText.borderStyle = OUTLINE;
		animText.borderSize = 2;
		animText.cameras = [camHUD];
		add(animText);

		moveText = new FlxText(4, 4, 0, "", 20);
		moveText.font = Paths.font("vcr.ttf");
		moveText.x = FlxG.width - moveText.width - 4;
		moveText.scrollFactor.set();
		moveText.color = FlxColor.WHITE;
		moveText.borderColor = FlxColor.BLACK;
		moveText.borderStyle = OUTLINE;
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

		charDropDown = new FlxScrollableDropDownMenu(10, 10, FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true), function(character:String) {
			remove(char);
			char.kill();
			char.destroy();

			daAnim = curCharList[Std.parseInt(character)];

			char = new Character(0, 0, daAnim);
			// char.coolTrail = new FlxTrail(char, null, char.config.trailLength, char.config.trailDelay, char.config.trailStalpha, char.config.trailDiff);
			char.debugMode = true;
			// char.coolTrail.visible = trail.checked = char.config.trail;
			add(char);

			animList = [];
			genBoyOffsets(true);
			char.playAnim(animList[curAnim], true);

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);

			genBoyOffsets(false);

			char.playAnim(animList[curAnim], true);

			iconName.text = char.icon ?? char.curCharacter;
			iconName.onTextChange.dispatch(iconName.text, INPUT_ACTION);

			healthBar.color = char.barColor;

			var healthColorArray:Array<Int> = char.config.barColor ?? [0, 128, 0];
			r.text = Std.string(healthColorArray[0]);
			g.text = Std.string(healthColorArray[1]);
			b.text = Std.string(healthColorArray[2]);
			r.onTextChange.dispatch(r.text, INPUT_ACTION);
			g.onTextChange.dispatch(g.text, INPUT_ACTION);
			b.onTextChange.dispatch(b.text, INPUT_ACTION);

			spriteSheetTextInput.text = char.config.imagePath ?? "";
			spriteSheetTextInput.onTextChange.dispatch(spriteSheetTextInput.text, INPUT_ACTION);

			checkFlipX.checked = char.config.defaultFlipX;
			checkAntialiasing.checked = char.antialiasing;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.scale.x;

			globalOffsetXStepper.value = char.positioningOffset[0];
			globalOffsetYStepper.value = char.positioningOffset[1];

			cameraOffsetXStepper.value = char.cameraOffset[0];
			cameraOffsetYStepper.value = char.cameraOffset[1];

			offsetsFlipWhenPlayer.checked = char.offsetsFlipWhenPlayer;
			offsetsFlipWhenEnemy.checked = char.offsetsFlipWhenEnemy;

			trail.checked = char.config.trail ?? false;
			trailLength.value = char.config.trailLength ?? 10;
			trailDelay.value = char.config.trailDelay ?? 3;
			trailAlpha.value = char.config.trailStalpha ?? 0.4;
			trailDiff.value = char.config.trailDiff ?? 0.05;
		});

		charDropDown.selectedLabel = daAnim;
		charDropDown.scrollFactor.set();
		charDropDown.cameras = [camHUD];

		modDropDown = new FlxScrollableDropDownMenu(charDropDown.x, charDropDown.y + 30 + 1, FlxUIDropDownMenu.makeStrIdLabelArray(modList, true),
			function(modID:String) {
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
					ghost.alpha = ghostAlphaSlider.value;
					ghost.blend = ghostBlendCheck.checked ? BlendMode.ADD : BlendMode.NORMAL;
					@:privateAccess
					ghostAlphaSlider._object = ghost;
					// ghost.color = FlxColor.BLACK;
					add(ghost);

					char = new Character(0, 0, daAnim);
					char.debugMode = true;
					add(char.coolTrail);
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
		stageDropdown = new FlxScrollableDropDownMenu(modDropDown.x, modDropDown.y + 30 + 1, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true),
			function(stageName:String) {
				stageName = stages[Std.parseInt(stageName)];
				stage.clear();
				stage.infrontOfGFSprites.clear();
				stage.foregroundSprites.clear();
				stage = new StageGroup(stageName);
				addBehind(stage, ghost);
				add(stage.infrontOfGFSprites);
				add(stage.foregroundSprites);

				//reloadStage();
				daAnim = curCharList[0];

				var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
				char.setPosition(position[0], position[1]);

				var positionGhost = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
				ghost.setPosition(positionGhost[0], positionGhost[1]);

				animList = [];
				genBoyOffsets(true);
				ghostAnimList = [];
				genGhostOffsets(true);
			});

		stageDropdown.selectedLabel = stageName;
		stageDropdown.scrollFactor.set();
		stageDropdown.cameras = [camHUD];

		for (anim => offsets in ghost.animOffsets) {
			ghostAnimList.push(anim);
		}
		ghostAnimDropDown = new FlxScrollableDropDownMenu(10, 35, FlxUIDropDownMenu.makeStrIdLabelArray(ghostAnimList, true), function(animName:String) {
			ghost.playAnim(ghostAnimList[Std.parseInt(animName)], true);

			var position = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
			ghost.setPosition(position[0], position[1]);
		});

		ghostAnimDropDown.scrollFactor.set();
		ghostAnimDropDown.cameras = [camHUD];

		offsetButton = new FlxUIButton(10, 100, "Save Offsets", function() {
			saveOffsets();
		});
		offsetButton.scrollFactor.set();
		offsetButton.cameras = [camHUD];
		offsetButton.resize(280, offsetButton.height);
		offsetButton.autoCenterLabel();
		offsetButton.updateHitbox();
		offsetButton.antialiasing = false;
		configButton = new FlxButton(180, 10, "Save Character", function() {
			saveConfig();
		});
		configButton.scrollFactor.set();
		configButton.cameras = [camHUD];

		tabs = new FlxUITabMenu(null, [
			{name: 'Character', label: 'Character'},
			{name: "Trail", label: "Trail"},
			{name: 'Animations', label: 'Animations'},
			{name: 'Offsets', label: 'Offsets'},
		], true);
		tabs.resize(300, 400);
		tabs.x = 900;
		tabs.screenCenter(Y);
		tabs.y += 150;
		tabs.scrollFactor.set();
		tabs.cameras = [camHUD];
		add(tabs);

		editor = new FlxUITabMenu(null, [{name: "Editor", label: "Editor"}, {name: "Ghost", label: "Ghost"}], true);
		editor.resize(300, 125);
		editor.x = 900;
		editor.y = tabs.y - 115 - 25;
		editor.cameras = [camHUD];
		add(editor);

		var tabEditor:FlxUI = new FlxUI(null, editor);
		tabEditor.name = "Editor";
		editor.addGroup(tabEditor);

		var tabGhost:FlxUI = new FlxUI(null, editor);
		tabGhost.name = "Ghost";
		editor.addGroup(tabGhost);

		tabEditor.add(stageDropdown);
		tabEditor.add(modDropDown);
		tabEditor.add(charDropDown);

		var stageDropdownLabel:FlxText = new FlxText(135, stageDropdown.y - 185, 0, "Stage");
		tabEditor.add(stageDropdownLabel);

		var modDropDownLabel:FlxText = new FlxText(135, modDropDown.y - 185, 0, "Mod Group");
		tabEditor.add(modDropDownLabel);

		var charDropDownLabel:FlxText = new FlxText(135, charDropDown.y - 185, 0, "Current Character");
		tabEditor.add(charDropDownLabel);

		ghostAlphaSlider = new FlxUISlider(ghost, "alpha", 10, 50, 0, 1, 130);
		ghostAlphaSlider.nameLabel.text = "Ghost Alpha";
		ghostAlphaSlider.nameLabel.offset.y = -8;
		ghostAlphaSlider.valueLabel.color = FlxColor.BLACK;
		tabGhost.add(ghostAlphaSlider);

		var ghostDropDown:FlxScrollableDropDownMenu = new FlxScrollableDropDownMenu(10, 10, FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true),
			function(character:String) {
				remove(ghost);
				ghost.kill();
				ghost.destroy();

				daAnim = curCharList[Std.parseInt(character)];

				ghost = new Character(0, 0, daAnim);
				ghost.debugMode = true;
				// ghost.color = FlxColor.BLACK;
				ghost.alpha = ghostAlphaSlider.value;
				ghost.blend = ghostBlendCheck.checked ? BlendMode.ADD : BlendMode.NORMAL;
				@:privateAccess
				ghostAlphaSlider._object = ghost;
				add(ghost);

				var position = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
				ghost.setPosition(position[0], position[1]);

				ghost.animOffsets.clear();
				ghost.loadOffsetFile(ghost.curCharacter);
				ghostAnimList = [];
				for (anim => offsets in ghost.animOffsets) {
					ghostAnimList.push(anim);
				}
				genBoyOffsets(true);
				tabGhost.remove(ghostAnimDropDown);
				ghostAnimDropDown.kill();
				ghostAnimDropDown.destroy();
				ghostAnimDropDown = new FlxScrollableDropDownMenu(10, 35, FlxUIDropDownMenu.makeStrIdLabelArray(ghostAnimList, true),
					function(animName:String) {
						ghost.playAnim(ghostAnimList[Std.parseInt(animName)], true);

						var position = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
						ghost.setPosition(position[0], position[1]);
					});

				tabGhost.add(ghostAnimDropDown);
				ghost.playAnim(ghostAnimList[0], true);

				var position = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
				ghost.setPosition(position[0], position[1]);
			});
		ghostDropDown.selectedLabel = char.curCharacter;

		var ghostDropdownLabel:FlxText = new FlxText(135, 10, 0, "Ghost Character");
		tabGhost.add(ghostDropdownLabel);

		var ghostAnimDropdownLabel:FlxText = new FlxText(135, 35, 0, "Ghost Animation");
		tabGhost.add(ghostAnimDropdownLabel);

		tabGhost.add(ghostAnimDropDown);
		tabGhost.add(ghostDropDown);

		ghostBlendCheck = new FlxUICheckBox(155, 65, null, null, "Highlight Ghost");
		ghostBlendCheck.callback = () -> {
			ghost.blend = ghostBlendCheck.checked ? BlendMode.ADD : BlendMode.NORMAL;
		}
		tabGhost.add(ghostBlendCheck);

		var ghostCopyButton:FlxUIButton = new FlxUIButton(220, 15, "Copy\nCharacter", () -> {
			ghostAnimList = [];
			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			ghost.setPosition(position[0], position[1]);
			ghost.animation.destroyAnimations();
			ghost.loadCharacterConfiguration(char.config);
			ghost.flipX = char.flipX;
			for (anim => offsets in char.animOffsets) {
				ghostAnimList.push(anim);
			}
			ghostAnimList = animList;
			try {
				ghost.playAnim(ghost.animation.curAnim.name, true);
			} catch (e) {}
		});
		ghostCopyButton.resize(75, ghostCopyButton.height + 5);
		tabGhost.add(ghostCopyButton);

		var tabCharacter:FlxUI = new FlxUI(null, tabs);
		tabCharacter.name = "Character";

		var tabOffsets:FlxUI = new FlxUI(null, tabs);
		tabOffsets.name = "Offsets";

		var tabTrail:FlxUI = new FlxUI(null, tabs);
		tabTrail.name = "Trail";

		var tabAnimations:FlxUI = new FlxUI(null, tabs);
		tabAnimations.name = "Animations";

		globalOffsetXStepper = new FlxUINumericStepper(10, 50, 1, char.positioningOffset[0], -9999, 9999);

		globalOffsetXStepper.value = char.positioningOffset[0];
		globalOffsetXStepper.name = "globalOffsetX";

		globalOffsetYStepper = new FlxUINumericStepper(globalOffsetXStepper.x, globalOffsetXStepper.y + 20, 1, char.positioningOffset[1], -9999, 9999);

		globalOffsetYStepper.value = char.positioningOffset[1];
		globalOffsetYStepper.name = "globalOffsetY";

		tabCharacter.add(globalOffsetXStepper);
		tabCharacter.add(globalOffsetYStepper);

		cameraOffsetXStepper = new FlxUINumericStepper(globalOffsetXStepper.x + 80, globalOffsetXStepper.y, 1, char.cameraOffset[0], -9999, 9999);

		cameraOffsetXStepper.value = char.cameraOffset[0];
		cameraOffsetXStepper.name = "cameraOffsetX";

		cameraOffsetYStepper = new FlxUINumericStepper(cameraOffsetXStepper.x, globalOffsetYStepper.y, 1, char.cameraOffset[1], -9999, 9999);

		cameraOffsetYStepper.value = char.cameraOffset[1];
		cameraOffsetYStepper.name = "cameraOffsetY";

		tabCharacter.add(cameraOffsetXStepper);
		tabCharacter.add(cameraOffsetYStepper);

		var infoPos:FlxText = new FlxText(globalOffsetXStepper.x, globalOffsetXStepper.y - 20, 0, "Position");
		infoPos.alignment = CENTER;
		tabCharacter.add(infoPos);

		var infoCamera:FlxText = new FlxText(cameraOffsetXStepper.x, cameraOffsetXStepper.y - 20, 0, "Camera");
		infoCamera.alignment = CENTER;
		tabCharacter.add(infoCamera);

		checkAntialiasing = new FlxUICheckBox(10, 100, null, null, "Antialasing");
		checkAntialiasing.checked = char.antialiasing;
		checkAntialiasing.callback = () -> {
			char.config.antialiasing = char.antialiasing = checkAntialiasing.checked;
		}

		tabCharacter.add(checkAntialiasing);

		checkFlipX = new FlxUICheckBox(checkAntialiasing.x, checkAntialiasing.y + 25, null, null, "Flip X");
		checkFlipX.checked = char.config.defaultFlipX;
		checkFlipX.callback = () -> {
			char.config.defaultFlipX = checkFlipX.checked;
			char.flipX = !char.flipX;
		}

		tabCharacter.add(checkFlipX);

		var dances:FlxUICheckBox = new FlxUICheckBox(checkFlipX.x, checkFlipX.y + 25, null, null, "Dances Left/Right");
		dances.checked = char.config.dancesLeftAndRight;
		dances.callback = () -> {
			char.config.dancesLeftAndRight = dances.checked;
		}

		tabCharacter.add(dances);

		scaleStepper = new FlxUINumericStepper(dances.x, dances.y + 35, 0.1, (char.config.graphicSize) ?? 1, 0.1, 10, 1);

		scaleStepper.value = (char.config.graphicSize) ?? 1;
		scaleStepper.name = "scale";
		tabCharacter.add(scaleStepper);

		var scaleLabel:FlxText = new FlxText(scaleStepper.x + scaleStepper.width + 2, scaleStepper.y);
		scaleLabel.text = "Scale";
		tabCharacter.add(scaleLabel);

		singDurationStepper = new FlxUINumericStepper(scaleStepper.x, scaleStepper.y + 20, 0.1, (char.config.singDuration) ?? 4, 0.1, 10, 1);

		singDurationStepper.value = (char.config.singDuration) ?? 4;
		singDurationStepper.name = "singDuration";
		tabCharacter.add(singDurationStepper);

		var singDurationLabel:FlxText = new FlxText(singDurationStepper.x + singDurationStepper.width + 2, singDurationStepper.y);
		singDurationLabel.text = "Sing Duration";
		tabCharacter.add(singDurationLabel);

		spriteSheetTextInput = new FlxInputText(10, 10, 100, char.config.imagePath);
		spriteSheetTextInput.onTextChange.add((text, change) -> {
			char.config.imagePath = text;
			char.loadCharacterConfiguration(char.config);
			char.playAnim("idle", true);
			char.updateHitbox();
			char.centerOrigin();
			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);
		});
		tabCharacter.add(spriteSheetTextInput);

		var spriteSheetTextInputLabel:FlxText = new FlxText(spriteSheetTextInput.x + spriteSheetTextInput.fieldWidth + 2, spriteSheetTextInput.y);
		spriteSheetTextInputLabel.text = "Image Path";
		tabCharacter.add(spriteSheetTextInputLabel);

		healthBar = new FlxSprite(10, 350).makeGraphic(280, 9, FlxColor.WHITE);
		healthBar.antialiasing = false;
		healthBar.color = char.barColor;
		tabCharacter.add(healthBar);

		icon = new HealthIcon(char.icon);
		icon.scale.set(icon.scale.x * 0.47, icon.scale.y * 0.47);
		icon.updateHitbox();
		icon.x = 10 - icon.width / 2;
		icon.y = 350 - (icon.height / 2);
		tabCharacter.add(icon);

		r = new FlxInputText(healthBar.x, healthBar.y - 50, 22, Std.string(char.config.barColor[0]));
		r.onTextChange.add((text, change) -> {
			var num:Int = Math.floor(Math.max(0, Math.min(Std.parseInt(text), 255)));
			char.config.barColor[0] = num;
			healthBar.color = FlxColor.fromRGB(char.config.barColor[0], char.config.barColor[1], char.config.barColor[2]);
		});
		r.onFocusChange.add((focused) -> {
			if (!focused) {
				r.text = Std.string(Math.floor(Math.max(0, Math.min(Std.parseInt(r.text), 255))));
			}
		});
		tabCharacter.add(r);

		g = new FlxInputText(r.x + 25, r.y, 22, Std.string(char.config.barColor[1]));
		g.onTextChange.add((text, change) -> {
			var num:Int = Math.floor(Math.max(0, Math.min(Std.parseInt(text), 255)));
			char.config.barColor[1] = num;
			healthBar.color = FlxColor.fromRGB(char.config.barColor[0], char.config.barColor[1], char.config.barColor[2]);
		});
		g.onFocusChange.add((focused) -> {
			if (!focused) {
				g.text = Std.string(Math.floor(Math.max(0, Math.min(Std.parseInt(g.text), 255))));
			}
		});
		tabCharacter.add(g);

		b = new FlxInputText(g.x + 25, g.y, 22, Std.string(char.config.barColor[2]));
		b.onTextChange.add((text, change) -> {
			var num:Int = Math.floor(Math.max(0, Math.min(Std.parseInt(text), 255)));
			char.config.barColor[2] = num;
			healthBar.color = FlxColor.fromRGB(char.config.barColor[0], char.config.barColor[1], char.config.barColor[2]);
		});
		b.onFocusChange.add((focused) -> {
			if (!focused) {
				b.text = Std.string(Math.floor(Math.max(0, Math.min(Std.parseInt(b.text), 255))));
			}
		});
		tabCharacter.add(b);

		var rgbInfo:FlxText = new FlxText(b.x + 25, b.y, 0, "Health Bar Color (RGB)");
		tabCharacter.add(rgbInfo);

		var match:FlxButton = new FlxButton(rgbInfo.x + rgbInfo.width, rgbInfo.y, "Get Dominant Color", () -> {
			var color:FlxColor = CoolUtil.dominantColor(icon);
			var red:String = Std.string(color.red);
			var green:String = Std.string(color.green);
			var blue:String = Std.string(color.blue);
			r.onTextChange.dispatch(red, INPUT_ACTION);
			g.onTextChange.dispatch(green, INPUT_ACTION);
			b.onTextChange.dispatch(blue, INPUT_ACTION);
			r.text = red;
			g.text = green;
			b.text = blue;
		});
		match.scale.y = 1.667;
		match.label.offset.y += 5;
		tabCharacter.add(match);

		iconName = new FlxInputText(r.x, r.y - 25, 100, icon.char);
		iconName.onTextChange.add((text, change) -> {
			char.icon = text;
			icon.setupIcon(text);
			icon.scale.set(icon.scale.x * 0.47, icon.scale.y * 0.47);
			icon.updateHitbox();
		});
		tabCharacter.add(iconName);

		var iconNameLabel:FlxText = new FlxText(iconName.x + iconName.fieldWidth + 2, iconName.y);
		iconNameLabel.text = "Icon Name";
		tabCharacter.add(iconNameLabel);

		tabCharacter.add(configButton);

		tabs.addGroup(tabCharacter);

		trail = new FlxUICheckBox(10, 10, null, null, "Has Trail");
		char.coolTrail.visible = trail.checked = char.config.trail;
		trail.callback = () -> {
			char.coolTrail.visible = char.config.trail = trail.checked;
		}
		tabTrail.add(trail);

		trailLength = new FlxUINumericStepper(trail.x, trail.y + 25, 1, (char.config.trailLength ?? 10), 1, 100);
		trailLength.value = (char.config.trailLength) ?? 1;
		trailLength.name = "trailLength";
		tabTrail.add(trailLength);

		trailDelay = new FlxUINumericStepper(trailLength.x, trailLength.y + 25, 1, (char.config.trailDelay ?? 3), 0, 100);
		trailDelay.value = (char.config.trailDelay) ?? 3;
		trailDelay.name = "trailDelay";
		tabTrail.add(trailDelay);

		trailAlpha = new FlxUINumericStepper(trailDelay.x, trailDelay.y + 25, 0.1, (char.config.trailStalpha ?? 0.4), 0.1, 1, 1);
		trailAlpha.value = (char.config.trailStalpha) ?? 0.4;
		trailAlpha.name = "trailAlpha";
		tabTrail.add(trailAlpha);

		trailDiff = new FlxUINumericStepper(trailAlpha.x, trailAlpha.y + 25, 0.01, (char.config.trailDiff ?? 0.05), 0.01, 100, 2);
		trailDiff.value = (char.config.trailDiff) ?? 0.05;
		trailDiff.name = "trailDiff";
		tabTrail.add(trailDiff);

		var trailLengthLabel:FlxText = new FlxText(trailLength.x + trailLength.width, trailLength.y, 0, "Trail Length");
		tabTrail.add(trailLengthLabel);

		var trailDelayLabel:FlxText = new FlxText(trailDelay.x + trailDelay.width, trailDelay.y, 0, "Trail Delay");
		tabTrail.add(trailDelayLabel);

		var trailAlphaLabel:FlxText = new FlxText(trailAlpha.x + trailAlpha.width, trailAlpha.y, 0, "Trail Alpha");
		tabTrail.add(trailAlphaLabel);

		var trailDiffLabel:FlxText = new FlxText(trailDiff.x + trailDiff.width, trailDiff.y, 0, "Trail Difference");
		tabTrail.add(trailDiffLabel);

		tabs.addGroup(tabTrail);

		var animationInputName:FlxInputText = new FlxInputText(10, 25, 100);
		tabAnimations.add(animationInputName);

		var animationInputNameLabel:FlxText = new FlxText(animationInputName.x, animationInputName.y - 15, 100, "Name");
		animationInputNameLabel.alignment = CENTER;
		tabAnimations.add(animationInputNameLabel);

		var animationInputAnimationName:FlxInputText = new FlxInputText(animationInputName.x + 105, 25, 100);
		tabAnimations.add(animationInputAnimationName);

		var animationInputAnimationNameLabel:FlxText = new FlxText(animationInputAnimationName.x, animationInputAnimationName.y - 15, 100, "Animation Name");
		animationInputAnimationNameLabel.alignment = CENTER;
		tabAnimations.add(animationInputAnimationNameLabel);

		animationFramerateStepper = new FlxUINumericStepper(animationInputName.x, animationInputName.y + 25, 1, 24, 1, 60);
		animationFramerateStepper.value = 24;
		animationFramerateStepper.name = "animationFramerate";
		tabAnimations.add(animationFramerateStepper);

		var animationFramerateStepperLabel:FlxText = new FlxText(animationFramerateStepper.x + animationFramerateStepper.width, animationFramerateStepper.y,
			0, "Animation Framerate");
		tabAnimations.add(animationFramerateStepperLabel);

		animationLoopedCheckbox = new FlxUICheckBox(animationInputName.x, animationFramerateStepper.y + 25, null, null, "Animation Looped");
		tabAnimations.add(animationLoopedCheckbox);

		addAnimation = new FlxUIButton(10, animationLoopedCheckbox.y + 25, "Add / Update Animation", () -> {
			if (animationInputName.text != "" && animationInputAnimationName.text != "") {
				char.animation.addByPrefix(animationInputName.text, animationInputAnimationName.text, animationFramerateStepper.value,
					animationLoopedCheckbox.checked);
				char.config.animations.push({
					name: animationInputName.text,
					animation_name: animationInputAnimationName.text,
					fps: Std.int(animationFramerateStepper.value),
					looped: animationLoopedCheckbox.checked
				});
				char.addOffset(animationInputName.text, 0, 0);
				animList = [];
				genBoyOffsets(true);
				fixOffsets();
			}
		});
		addAnimation.resize(280, addAnimation.height);
		addAnimation.antialiasing = false;
		addAnimation.updateHitbox();
		addAnimation.autoCenterLabel();
		tabAnimations.add(addAnimation);

		removeAnimation = new FlxUIButton(addAnimation.x, addAnimation.y + addAnimation.height + 2, "Remove Animation", () -> {
			if (animationInputName.text != "") {
				char.animation.remove(animationInputName.text);

				for(animation in char.config.animations){
					if(animation.name == animationInputName.text){
						char.config.animations.remove(animation);
						break;
					}
				}
				char.animOffsets.remove(animationInputName.text);
				animList = [];
				genBoyOffsets(true);
				fixOffsets();
			}
		});
		removeAnimation.resize(280, removeAnimation.height);
		removeAnimation.antialiasing = false;
		removeAnimation.updateHitbox();
		removeAnimation.autoCenterLabel();
		tabAnimations.add(removeAnimation);

		tabs.addGroup(tabAnimations);

		offsetsFlipWhenPlayer = new FlxUICheckBox(10, 10, null, null, "Offsets Flip When Player");
		offsetsFlipWhenPlayer.checked = char.offsetsFlipWhenPlayer;
		offsetsFlipWhenPlayer.callback = () -> {
			char.offsetsFlipWhenPlayer = char.config.offsetsFlipWhenPlayer = offsetsFlipWhenPlayer.checked;
			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);
			char.loadOffsetFile(char.curCharacter);
			char.playAnim(animList[curAnim], true);
			animList = [];
			genBoyOffsets(true);
		}
		tabOffsets.add(offsetsFlipWhenPlayer);

		offsetsFlipWhenEnemy = new FlxUICheckBox(offsetsFlipWhenPlayer.x, offsetsFlipWhenPlayer.y + 25, null, null, "Offsets Flip When Enemy");
		offsetsFlipWhenEnemy.checked = char.offsetsFlipWhenEnemy;
		offsetsFlipWhenEnemy.callback = () -> {
			char.offsetsFlipWhenEnemy = char.config.offsetsFlipWhenEnemy = offsetsFlipWhenEnemy.checked;
			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);
			char.loadOffsetFile(char.curCharacter);
			char.playAnim(animList[curAnim], true);
			animList = [];
			genBoyOffsets(true);
		}
		tabOffsets.add(offsetsFlipWhenEnemy);

		tabOffsets.add(offsetButton);

		tabs.addGroup(tabOffsets);

		super.create();
	}

	override function destroy() {
		Main.display.visible = true;
		super.destroy();
	}

	inline function fixOffsets() {
		char.playAnim(animList[curAnim], true);
		var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
		char.setPosition(position[0], position[1]);
		genBoyOffsets(false);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			var stepper:FlxUINumericStepper = cast sender;
			var name:String = stepper.name;
			switch (name) {
				case "globalOffsetX":
					char.positioningOffset[0] = data;
					fixOffsets();
				case "globalOffsetY":
					char.positioningOffset[1] = data;
					fixOffsets();
				case "cameraOffsetX":
					char.cameraOffset[0] = data;
				case "cameraOffsetY":
					char.cameraOffset[1] = data;
				case "scale":
					char.config.graphicsSize = char.scale.x = char.scale.y = data;
				case "singDuration":
					char.config.singDuration = data;
				case "trailLength":
					char.config.trailLength = data;
					char.coolTrail = new FlxTrail(char, null, char.config.trailLength, char.config.trailDelay, char.config.trailStalpha, char.config.trailDiff);
				case "trailDelay":
					char.coolTrail.delay = char.config.trailDelay = data;
				case "trailAlpha":
					@:privateAccess
					char.coolTrail._transp = char.config.trailStalpha = data;
				case "trailDiff":
					@:privateAccess
					char.coolTrail._difference = char.config.trailDiff = data;
			}
		}
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

	function genGhostOffsets(pushList:Bool = true):Void {
		for (anim => offsets in ghost.animOffsets) {
			if (pushList)
				ghostAnimList.push(anim);
		}
	}

	override function update(elapsed:Float) {
		if (char.isPlayer) {
			cross.setPosition(char.getMidpoint().x - 100 + char.cameraOffset[0], char.getMidpoint().y - 100 + char.cameraOffset[1]);
		} else {
			cross.setPosition(char.getMidpoint().x + 150 + char.cameraOffset[0], char.getMidpoint().y - 100 + char.cameraOffset[1]);
		}
		if (FlxG.keys.pressed.E && charCam.zoom < 2)
			charCam.zoom += elapsed * charCam.zoom * (FlxG.keys.pressed.SHIFT ? 0.1 : 1);
		if (FlxG.keys.pressed.Q && charCam.zoom >= 0.1)
			charCam.zoom -= elapsed * charCam.zoom * (FlxG.keys.pressed.SHIFT ? 0.1 : 1);
		if (FlxG.mouse.wheel != 0 && charCam.zoom >= 0.1 && charCam.zoom <= 2)
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

			/*ghost.isPlayer = char.isPlayer;
				ghost.flipX = char.flipX; */

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			// var positionGhost = stage.getCharacterPos(ghost.isPlayer ? 0 : 1, ghost);
			char.setPosition(position[0], position[1]);
			/*ghost.setPosition(positionGhost[0], positionGhost[1]);*/

			char.loadOffsetFile(char.curCharacter);
			char.playAnim(animList[curAnim], true);

			/*ghost.loadOffsetFile(ghost.curCharacter);
				ghost.playAnim(ghost.animation.curAnim.name, true); */
			animList = [];
			// ghostAnimList = [];
			genBoyOffsets(true);
			// genGhostOffsets(true);
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
				// ghost.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			}
			if (downP) {
				char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
				// ghost.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			}
			if (leftP) {
				char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
				// ghost.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			}
			if (rightP) {
				char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;
				// ghost.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;
			}

			genBoyOffsets(false);
			char.playAnim(animList[curAnim], true);
		}

		charCam.zoom = FlxMath.roundDecimal(charCam.zoom, 2) <= 0 ? 1 : charCam.zoom;
		moveText.text = 'Use IJKL to move the camera\nE and Q to zoom the camera\nSHIFT for faster moving offset or camera\nZ to toggle the stage\nX to toggle playing side\nCamera Zoom: ${FlxMath.roundDecimal(charCam.zoom, 2)}\n';
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

	function saveConfig() {
		var config:CharacterConfig = cast {
			imagePath: char.config.imagePath,
			graphicsSize: char.config.graphicsSize,
			extraSheets: char.config.extraSheets,
			healthIcon: char.icon,
			barColor: char.config.barColor,
			defaultFlipX: char.config.defaultFlipX,
			dancesLeftAndRight: char.config.dancesLeftAndRight,
			positionOffset: char.positioningOffset,
			cameraOffset: char.cameraOffset,
			singDuration: char.config.singDuration,
			antialiasing: char.antialiasing,
			offsetsFlipWhenPlayer: char.offsetsFlipWhenPlayer,
			offsetsFlipWhenEnemy: char.offsetsFlipWhenEnemy,
			trail: char.config.trail,
			trailLength: char.config.trailLength,
			trailDelay: char.config.trailLength,
			trailStalpha: char.config.trailStalpha,
			trailDiff: char.config.trailDiff,
			animations: char.config.animations,
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
			remove(char.coolTrail);
			add(char.coolTrail);
			remove(char);
			add(char);
		} else {
			for (character in char.otherCharacters) {
				remove(character.coolTrail);
				add(character.coolTrail);
				remove(character);
				add(character);
			}
		}

		remove(stage.foregroundSprites);
		add(stage.foregroundSprites);
	}
}
