package modding;

import states.MusicBeatState;
import substates.MusicBeatSubstate;
#if sys
import utilities.Options;
import ui.ModIcon;
import modding.ModList;
import modding.PolymodHandler;
import substates.UISkinSelect;
import substates.ControlMenuSubstate;
import modding.CharacterCreationState;
import utilities.MusicUtilities;
import ui.Option;
import ui.Checkbox;
import flixel.group.FlxGroup;
import tools.ChartingState;
import tools.StageMakingState;
import flixel.sound.FlxSound;
import tools.CharacterCreator;
import utilities.Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import ui.Alphabet;
import game.Song;
import tools.StageMakingState;
import game.Highscore;

class SwitchModSubstate extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var ui_Skin:Null<String>;

	public var page:FlxTypedGroup<ChangeModOption> = new FlxTypedGroup<ChangeModOption>();

	public static var instance:SwitchModSubstate;

	var descriptionText:FlxText;
	var descBg:FlxSprite;

	override function create()
	{
		if (ui_Skin == null || ui_Skin == "default")
			ui_Skin = Options.getData("uiSkin");

		instance = this;

		var menuBG:FlxSprite;

		menuBG = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK, false, "optimizedMenuDesat");
        menuBG.alpha = 0.5;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
        menuBG.scrollFactor.set();
		add(menuBG);

		super.create();
		add(page);

		PolymodHandler.loadModMetadata();

		loadMods();

		descBg = new FlxSprite(0, FlxG.height - 90).makeGraphic(FlxG.width, 90, 0xFF000000);
		descBg.alpha = 0.6;
        descBg.scrollFactor.set();
		add(descBg);

		descriptionText = new FlxText(descBg.x, descBg.y + 4, FlxG.width, "Template Description", 18);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		descriptionText.borderColor = FlxColor.BLACK;
		descriptionText.borderSize = 1;
		descriptionText.borderStyle = OUTLINE;
		descriptionText.scrollFactor.set();
		descriptionText.screenCenter(X);
		add(descriptionText);

		var leText:String = "Press ENTER to switch to the currently selected mod.";

		var text:FlxText = new FlxText(0, FlxG.height - 22, FlxG.width, leText, 18);
		text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		text.borderColor = FlxColor.BLACK;
		text.borderSize = 1;
		text.borderStyle = OUTLINE;
		add(text);
	}

	function loadMods()
	{
		page.forEachExists(function(option:ChangeModOption)
		{
			page.remove(option);
			option.kill();
			option.destroy();
		});

		var optionLoopNum:Int = 0;

		for(modId in PolymodHandler.metadataArrays)
		{
			if (ModList.modList.get(modId)){
				var modOption = new ChangeModOption(ModList.modMetadatas.get(modId).title, modId, optionLoopNum);
				page.add(modOption);
				optionLoopNum++;
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(-1 * Math.floor(FlxG.mouse.wheel) != 0)
		{
			curSelected -= 1 * Math.floor(FlxG.mouse.wheel);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.UP_P)
		{
			curSelected -= 1;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.DOWN_P)
		{
			curSelected += 1;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.BACK)
		{
			close();
		}

		if (curSelected < 0)
			curSelected = page.length - 1;

		if (curSelected >= page.length)
			curSelected = 0;

		var bruh = 0;

		for (x in page.members)
		{
			x.Alphabet_Text.targetY = bruh - curSelected;
			
			if(x.Alphabet_Text.targetY == 0)
			{
				descriptionText.screenCenter(X);

				@:privateAccess
				descriptionText.text = 
				ModList.modMetadatas.get(x.Option_Value).description 
				+ "\nAuthor: " + ModList.modMetadatas.get(x.Option_Value)._author 
				+ "\nLeather Engine Version: " + ModList.modMetadatas.get(x.Option_Value).apiVersion 
				+ "\nMod Version: " + ModList.modMetadatas.get(x.Option_Value).modVersion 
				+ "\n";
			}

			bruh++;
		}
	}
}
#end
