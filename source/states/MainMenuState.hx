package states;

#if DISCORD_ALLOWED
import utilities.Discord.DiscordClient;
#end

#if MODDING_ALLOWED
import modding.PolymodHandler;
#end

import modding.scripts.languages.HScript;
import flixel.system.debug.interaction.tools.Tool;
import utilities.Options;
import flixel.util.FlxTimer;
import utilities.MusicUtilities;
import lime.utils.Assets;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import modding.scripts.languages.HScript.IHScriptable;

class MainMenuState extends MusicBeatState implements IHScriptable {
	/**
		Current instance of `MainMenuState`.
	**/
	public static var instance:MainMenuState = null;

	static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	public var optionShit:Array<String> = ['story mode', 'freeplay', 'options'];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var ui_Skin:Null<String>;
	public var script:HScript;

	public inline function call(func:String, ?args:Array<Dynamic>) {
		if (script != null) {
			script.call(func, args);
		}
	}

	override function create() {
		instance = this;
		#if sys
		if (sys.FileSystem.exists("mods/" + Options.getData("curMod") + "/classes/states/MainMenuState.hx")){
			script = new HScript("mods/" + Options.getData("curMod") + "/classes/states/MainMenuState.hx", true);
			script.start();		
		}
		#end

		if (ui_Skin == null || ui_Skin == "default")
			ui_Skin = Options.getData("uiSkin");
		
		#if MODDING_ALLOWED
		if (PolymodHandler.metadataArrays.length > 0)
			optionShit.push('mods');
		#end

		if(Options.getData("developer"))
			optionShit.push('toolbox');

		call("buttonsAdded");
		
		MusicBeatState.windowNameSuffix = "";
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music == null || FlxG.sound.music.playing != true)
			TitleState.playTitleMusic();

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite;

		if(Options.getData("menuBGs"))
			if (!Assets.exists(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuBG')))
				bg = new FlxSprite(-80).loadGraphic(Paths.image('ui skins/default/backgrounds/menuBG'));
			else
				bg = new FlxSprite(-80).loadGraphic(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuBG'));
		else
			bg = new FlxSprite(-80).makeGraphic(1286, 730, FlxColor.fromString("#FDE871"), false, "optimizedMenuBG");

		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.3));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		if(Options.getData("menuBGs"))
			if (!Assets.exists(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuDesat')))
				magenta = new FlxSprite(-80).loadGraphic(Paths.image('ui skins/default/backgrounds/menuDesat'));
			else
				magenta = new FlxSprite(-80).loadGraphic(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuDesat'));
		else
			magenta = new FlxSprite(-80).makeGraphic(1286, 730, FlxColor.fromString("#E1E1E1"), false, "optimizedMenuDesat");

		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.3));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length) {
			var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
			if (!Assets.exists(Paths.image('ui skins/' + Options.getData("uiSkin") + '/' + 'buttons/'+ optionShit[i], 'preload')))
				menuItem.frames = Paths.getSparrowAtlas('ui skins/' + 'default' + '/' + 'buttons/'+ optionShit[i], 'preload');
			else
				menuItem.frames = Paths.getSparrowAtlas('ui skins/' + Options.getData("uiSkin") + '/' + 'buttons/'+ optionShit[i], 'preload');
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set(0.5, 0.5);
			menuItem.antialiasing = true;
		}

		FlxG.camera.follow(camFollow, null, 0.06);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, (Options.getData("watermarks") ? TitleState.version : "v0.3.3"), 16);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		#if MODDING_ALLOWED
		final buttonTab:String = controls.mobileC ? 'C' : 'TAB';
		var switchInfo:FlxText = new FlxText(5, versionShit.y - versionShit.height, 0, 'Hit $buttonTab to switch mods.', 16);
		switchInfo.scrollFactor.set();
		switchInfo.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(switchInfo);

		var modInfo:FlxText = new FlxText(5, switchInfo.y - switchInfo.height, 0, '${modding.PolymodHandler.metadataArrays.length} mods loaded, ${modding.ModList.getActiveMods(modding.PolymodHandler.metadataArrays).length} mods active.', 16);
		modInfo.scrollFactor.set();
		modInfo.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(modInfo);
		#end

		changeItem();

		super.create();

		addVirtualPad(UP_DOWN, #if MODDING_ALLOWED A_B_C #else A_B #end);

		call("createPost");
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		#if MODDING_ALLOWED
		if(virtualPad.buttonC.justPressed || FlxG.keys.justPressed.TAB){
			openSubState(new modding.SwitchModSubstate());
			persistentUpdate = false;
		}
		#end

		FlxG.camera.followLerp = elapsed * 3.6;

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!selectedSomethin) {
			if(-1 * Math.floor(FlxG.mouse.wheel) != 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1 * Math.floor(FlxG.mouse.wheel));
			}

			if (controls.UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				if(Options.getData("flashingLights")) {
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);
				}

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: (_) -> spr.kill()
						});
					} else {
						if(Options.getData("flashingLights")) {
							FlxFlicker.flicker(spr, 1, 0.06, false, false, (_) -> selectCurrent());
						} else {
							new FlxTimer().start(1, (_) -> selectCurrent(), 1);
						}
					}
				});
			}

			if (controls.BACK) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(new TitleState());
			}
		}

		call("update", [elapsed]);

		super.update(elapsed);

		call("updatePost", [elapsed]);

		menuItems.forEach((spr:FlxSprite) -> {
			spr.screenCenter(X);
		});
	}

	function selectCurrent() {
		var selectedButton:String = optionShit[curSelected];
		
		switch (selectedButton) {
			case 'story mode':
				FlxG.switchState(new StoryMenuState());
				trace("Story Menu Selected");

			case 'freeplay':
				FlxG.switchState(new FreeplayState());
				trace("Freeplay Menu Selected");

			case 'options':
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				FlxG.switchState(new OptionsMenu());

			#if MODDING_ALLOWED
			case 'mods':
				FlxG.switchState(new ModsMenu());
			#end

			case 'toolbox':
				FlxG.switchState(new toolbox.ToolboxPlaceholder());
		}
		call("changeState");
	}

	function changeItem(itemChange:Int = 0)
	{
		curSelected += itemChange;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				camFollow.setPosition(FlxG.width / 2, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});
		call("changeItem", [itemChange]);
	}
}
