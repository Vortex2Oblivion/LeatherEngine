package states;

#if DISCORD_ALLOWED
import utilities.DiscordClient;
#end
#if MODDING_ALLOWED
import modding.PolymodHandler;
#end
import utilities.Options;
import flixel.util.FlxTimer;
import lime.utils.Assets;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using utilities.BackgroundUtil;

class MainMenuState extends MusicBeatState {
	/**
		Current instance of `MainMenuState`.
	**/
	public static var instance:MainMenuState = null;

	static var curSelected:Int = 0;

	public var menuItems:FlxTypedGroup<FlxSprite>;

	public var optionShit:Array<String> = ['story mode', 'freeplay', 'options'];

	public var magenta:FlxSprite;
	public var camFollow:FlxObject;
	public var bg:FlxSprite;

	public function addButton(buttonName:String, i:Int) {
		var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
		if (!Assets.exists(Paths.image('ui skins/' + Options.getData("uiSkin") + '/' + 'buttons/' + buttonName, 'preload')))
			menuItem.frames = Paths.getSparrowAtlas('ui skins/' + 'default' + '/' + 'buttons/' + buttonName, 'preload');
		else
			menuItem.frames = Paths.getSparrowAtlas('ui skins/' + Options.getData("uiSkin") + '/' + 'buttons/' + buttonName, 'preload');
		menuItem.animation.addByPrefix('idle', buttonName + " basic", 24);
		menuItem.animation.addByPrefix('selected', buttonName + " white", 24);
		menuItem.animation.play('idle');
		menuItem.ID = i;
		menuItem.screenCenter(X);
		menuItems.add(menuItem);
		menuItem.scrollFactor.set(0.5, 0.5);
	}

	public override function create() {
		instance = this;

		#if MODDING_ALLOWED
		if (PolymodHandler.metadataArrays.length > 0)
			optionShit.push('mods');
		#end

		if (Options.getData("developer"))
			optionShit.push('toolbox');

		call("buttonsAdded");

		MusicBeatState.windowNameSuffix = "";

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music == null || !FlxG.sound.music.playing || OptionsMenu.playing) {
			OptionsMenu.playing = false;
			TitleState.playTitleMusic();
		}

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).makeBackground(0xFFFDE871);
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.scale.set(1.3, 1.3);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).makeBackground(0xFFfd719b);
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.scale.set(1.3, 1.3);
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length) {
			addButton(optionShit[i], i);
		}

		FlxG.camera.follow(camFollow, null, 0.06);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, TitleState.version, 16);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(versionShit);

		#if MODDING_ALLOWED
		var switchInfo:FlxText = new FlxText(5, versionShit.y - versionShit.height, 0, 'Hit TAB to switch mods.', 16);
		switchInfo.scrollFactor.set();
		switchInfo.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(switchInfo);

		var modInfo:FlxText = new FlxText(5, switchInfo.y - switchInfo.height, 0,
			'${modding.PolymodHandler.metadataArrays.length} mods loaded, ${modding.ModList.getActiveMods(modding.PolymodHandler.metadataArrays).length} mods active.',
			16);
		modInfo.scrollFactor.set();
		modInfo.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(modInfo);
		#end

		changeItem();

		super.create();

		call("createPost");
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		#if MODDING_ALLOWED
		if (!selectedSomethin && FlxG.keys.justPressed.TAB) {
			openSubState(new modding.SwitchModSubstate());
			persistentUpdate = false;
		}
		#end

		#if (flixel < "6.0.0")
		FlxG.camera.followLerp = elapsed * 3.6;
		#end

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!selectedSomethin) {
			if (-1 * Math.floor(FlxG.mouse.wheel) != 0) {
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

				if (Options.getData("flashingLights")) {
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);
				}

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: (_) -> spr.kill()
						});
					} else {
						if (Options.getData("flashingLights")) {
							FlxFlicker.flicker(spr, 1, 0.06, false, false, (_) -> selectCurrent());
						} else {
							new FlxTimer().start(1, (_) -> selectCurrent(), 1);
						}
					}
				});
			}

			if (controls.BACK) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new TitleState());
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

		call("buttonSelected", [selectedButton]);
		switch (selectedButton) {
			case 'story mode':
				FlxG.switchState(() -> new StoryMenuState());

			case 'freeplay':
				FlxG.switchState(() -> new FreeplayState());

			case 'options':
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				FlxG.switchState(() -> new OptionsMenu());

			#if MODDING_ALLOWED
			case 'mods':
				FlxG.switchState(() -> new ModsMenu());
			#end

			case 'toolbox':
				FlxG.switchState(() -> new toolbox.ToolboxState("Categories", 0xFF00FF6A));
		}
		call("buttonSelectedPost", [selectedButton]);
	}

	function changeItem(itemChange:Int = 0) {
		curSelected += itemChange;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');

			if (spr.ID == curSelected) {
				spr.animation.play('selected');
				camFollow.setPosition(FlxG.width / 2, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
			spr.centerOffsets();
		});
		call("changeItem", [itemChange]);
	}
}
