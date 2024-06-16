package states;

#if MODDING_ALLOWED
import utilities.Options;
import ui.ModIcon;
import modding.ModList;
import modding.PolymodHandler;
import substates.UISkinSelect;
import substates.ControlMenuSubstate;
import utilities.MusicUtilities;
import ui.Option;
import ui.Checkbox;
import flixel.group.FlxGroup;
import toolbox.ChartingState;
import toolbox.StageMakingState;
import flixel.sound.FlxSound;
import toolbox.CharacterCreator;
import utilities.Controls.Control;
import openfl.text.TextField;
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
import toolbox.StageMakingState;
import game.Highscore;

class ModsMenu extends MusicBeatState {
	var curSelected:Int = 0;
	var ui_Skin:Null<String>;

	public var page:FlxTypedGroup<ModOption> = new FlxTypedGroup<ModOption>();

	public static var instance:ModsMenu;

	var descriptionText:FlxText;
	var descBg:FlxSprite;

	override function create() {
		if (ui_Skin == null || ui_Skin == "default")
			ui_Skin = Options.getData("uiSkin");

		MusicBeatState.windowNameSuffix = " Mods Menu";

		instance = this;

		var menuBG:FlxSprite;

		if(Options.getData("menuBGs"))
			if (!Assets.exists(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuDesat')))
				menuBG = new FlxSprite().loadGraphic(Paths.image('ui skins/default/backgrounds/menuDesat'));
			else
				menuBG = new FlxSprite().loadGraphic(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuDesat'));
		else
			menuBG = new FlxSprite().makeGraphic(1286, 730, FlxColor.fromString("#E1E1E1"), false, "optimizedMenuDesat");

		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		super.create();

		add(page);

		if(FlxG.sound.music == null)
			FlxG.sound.playMusic(MusicUtilities.GetOptionsMenuMusic(), 0.7, true);

		PolymodHandler.loadModMetadata();

		loadMods();

		descBg = new FlxSprite(0, FlxG.height - 90).makeGraphic(FlxG.width, 90, 0xFF000000);
		descBg.alpha = 0.6;
		add(descBg);

		descriptionText = new FlxText(descBg.x, descBg.y + 4, FlxG.width, "Template Description", 18);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		descriptionText.borderColor = FlxColor.BLACK;
		descriptionText.borderSize = 1;
		descriptionText.borderStyle = OUTLINE;
		descriptionText.scrollFactor.set();
		descriptionText.screenCenter(X);
		add(descriptionText);

		final buttonEnter:String = controls.mobileC ? 'A' : 'ENTER';

		var leText:String = 'Press $buttonEnter to enable / disable the currently selected mod.';

		var text:FlxText = new FlxText(0, FlxG.height - 22, FlxG.width, leText, 18);
		text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		text.borderColor = FlxColor.BLACK;
		text.borderSize = 1;
		text.borderStyle = OUTLINE;
		add(text);

		addVirtualPad(UP_DOWN, A_B);
	}

	function loadMods() {
		page.forEachExists(function(option:ModOption) {
			page.remove(option);
			option.kill();
			option.destroy();
		});

		var optionLoopNum:Int = 0;

		for(modId in PolymodHandler.metadataArrays) {
			if(ModList.modMetadatas.get(modId).metadata.get('canBeDisabled') != 'false') {
				var modOption = new ModOption(ModList.modMetadatas.get(modId).title, modId);
				page.add(modOption);
				optionLoopNum++;
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if(-1 * Math.floor(FlxG.mouse.wheel) != 0) {
			curSelected -= 1 * Math.floor(FlxG.mouse.wheel);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.UP_P) {
			curSelected --;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.DOWN_P) {
			curSelected ++;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.BACK) {
			PolymodHandler.loadMods();
			FlxG.switchState(new MainMenuState());
		}

		if (curSelected < 0)
			curSelected = page.length - 1;

		if (curSelected >= page.length)
			curSelected = 0;

		var bruh = 0;

		for (x in page.members) {
			x.alphabetText.targetY = bruh - curSelected;

			if(x.alphabetText.targetY == 0) {
				descriptionText.screenCenter(X);

				@:privateAccess
				descriptionText.text = 
					ModList.modMetadatas.get(x.optionValue).description 
					+ "\nAuthor: " + ModList.modMetadatas.get(x.optionValue)._author 
					+ "\nLeather Engine Version: " + ModList.modMetadatas.get(x.optionValue).apiVersion 
					+ "\nMod Version: " + ModList.modMetadatas.get(x.optionValue).modVersion 
					+ "\n";
			}

			bruh++;
		}
	}
}
#end
