package ui;

#if DISCORD_ALLOWED
import utilities.Discord.DiscordClient;
#end

#if MODDING_ALLOWED
import modding.PolymodHandler;
#end

import lime.app.Application;
import states.TitleState;
import modding.ModList;
import flixel.FlxSprite;
import flixel.FlxState;
import states.OptionsMenu;
import flixel.FlxG;
import flixel.group.FlxGroup;
import ui.ModIcon;

/**
 * The base option class that all options inherit from.
 */
class Option extends FlxTypedGroup<FlxSprite> {
	// variables //
	public var alphabetText:Alphabet;

	// options //
	public var optionName:String = "";
	public var optionValue:String = "downscroll";

	public function new(_optionName:String = "", _optionValue:String = "downscroll") {
		super();

		// SETTING VALUES //
		this.optionName = _optionName;
		this.optionValue = _optionValue;

		// CREATING OTHER OBJECTS //
		alphabetText = new Alphabet(20, 20, optionName, true);
		alphabetText.isMenuItem = true;
		add(alphabetText);
	}
}

/**
 * Simple Option with a checkbox that changes a bool value.
 */
class BoolOption extends Option {
	// variables //
	var checkbox:Checkbox;

	// options //
	public var optionChecked:Bool = false;

	override public function new(_optionName:String = "", _optionValue:String = "downscroll") {
		super(_optionName, _optionValue);

		// SETTING VALUES //
		this.optionChecked = getObjectValue();

		// CREATING OTHER OBJECTS //
		checkbox = new Checkbox(alphabetText);
		checkbox.checked = getObjectValue();
		add(checkbox);
	}

	public inline function getObjectValue():Bool {
		return Options.getData(optionValue);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (utilities.Controls.instance.ACCEPT && alphabetText.targetY == 0)
			changeValue();
	}

	public function changeValue() {
		Options.setData(!optionChecked, optionValue);

		optionChecked = !optionChecked;
		checkbox.checked = optionChecked;

		switch (optionValue) // extra special cases
		{
			case "fpsCounter":
				Main.toggleFPS(optionChecked);
			case "memoryCounter":
				Main.toggleMem(optionChecked);
			#if DISCORD_ALLOWED
			case "discordRPC":
				if (optionChecked && !DiscordClient.active)
					DiscordClient.initialize();
				else if (!optionChecked && DiscordClient.active)
					DiscordClient.shutdown();
			#end
			case "developer":
				Main.toggleLogs(optionChecked);
		}
	}
}

/**
 * Very simple option that transfers you to a different page when selecting it.
 */
class PageOption extends Option {
	// OPTIONS //
	public var pageName:String = "Categories";

	override public function new(_optionName:String = "", _pageName:String = "Categories", _Description:String = "Test Description") {
		super(_optionName, _pageName);

		// SETTING VALUES //
		this.pageName = _pageName;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (utilities.Controls.instance.ACCEPT && Std.int(alphabetText.targetY) == 0 && !OptionsMenu.instance.inMenu) {
			OptionsMenu.instance.loadPage(pageName);
		}
	}
}

class GameSubStateOption extends Option {
	public var gameSubState:Dynamic;

	public function new(_optionName:String = "", _gameSubState:Dynamic) {
		super(_optionName, null);

		// SETTING VALUES //
		this.gameSubState = _gameSubState;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (utilities.Controls.instance.ACCEPT && alphabetText.targetY == 0)
			OptionsMenu.instance.openSubState(Type.createInstance(this.gameSubState, []));
	}
}

/**
 * Very simple option that transfers you to a different game-state when selecting it.
 */
class GameStateOption extends Option {
	// OPTIONS //
	public var gameState:FlxState;

	public function new(_optionName:String = "", _gameState:Dynamic) {
		super(_optionName, null);

		// SETTING VALUES //
		this.gameState = _gameState;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (utilities.Controls.instance.ACCEPT && alphabetText.targetY == 0) {
			FlxG.switchState(gameState);
		}
	}
}

/**
 * Thing for Animation Debug.
 */
 class CharacterCreatorOption extends Option {
	// OPTIONS //

	public var gameState:FlxState;

	public function new(_optionName:String = "", _gameState:Dynamic) {
		super(_optionName, null);

		// SETTING VALUES //
		toolbox.CharacterCreator.lastState = "OptionsMenu";
		this.gameState = _gameState;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (utilities.Controls.instance.ACCEPT && alphabetText.targetY == 0)
			FlxG.switchState(gameState);
	}
}

#if sys
/**
 * Option for enabling and disabling mods.
 */
class ModOption extends FlxTypedGroup<FlxSprite> {
	// variables //
	public var alphabetText:Alphabet;
	public var modIcon:ModIcon;

	public var modEnabled:Bool = false;

	// options //
	public var optionName:String = "";
	public var optionValue:String = "Template Mod";

	public function new(_optionName:String = "", _optionValue:String = "Template Mod") {
		super();

		// SETTING VALUES //
		this.optionName = _optionName;
		this.optionValue = _optionValue;

		// CREATING OTHER OBJECTS //
		alphabetText = new Alphabet(20, 20 , optionName, true);
		alphabetText.isMenuItem = true;
		add(alphabetText);

		modIcon = new ModIcon(optionValue);
		modIcon.sprTracker = alphabetText;
		add(modIcon);

		modEnabled = ModList.modList.get(optionValue);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (utilities.Controls.instance.ACCEPT && alphabetText.targetY == 0) {
			modEnabled = !modEnabled;
			ModList.setModEnabled(optionValue, modEnabled);
		}

		if (modEnabled) {
			alphabetText.alpha = 1;
			modIcon.alpha = 1;
		} else {
			alphabetText.alpha = 0.6;
			modIcon.alpha = 0.6;
		}
	}
}

class ChangeModOption extends FlxTypedGroup<FlxSprite> {
	// variables //
	public var alphabetText:Alphabet;
	public var modIcon:ModIcon;

	public var modEnabled:Bool = false;

	// options //
	public var optionName:String = "";
	public var optionValue:String = "Template Mod";

	public function new(_optionName:String = "", _optionValue:String = "Friday Night Funkin'") {
		super();

		// SETTING VALUES //
		this.optionName = _optionName;
		this.optionValue = _optionValue;

		// CREATING OTHER OBJECTS //
		alphabetText = new Alphabet(20, 20, optionName, true);
		alphabetText.isMenuItem = true;
		alphabetText.scrollFactor.set();
		add(alphabetText);

		modIcon = new ModIcon(optionValue);
		modIcon.sprTracker = alphabetText;
		modIcon.scrollFactor.set();
		add(modIcon);

		modEnabled = ModList.modList.get(optionValue);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if(alphabetText.targetY == 0){
			alphabetText.alpha = 1;
			modIcon.alpha = 1;
			if (utilities.Controls.instance.ACCEPT) {
				Options.setData(optionValue, "curMod");
				modEnabled = !modEnabled;
				@:privateAccess
				if (FlxG.state is TitleState) TitleState.initialized = false;
				if (FlxG.sound.music != null) {
					FlxG.sound.music.fadeOut(0.25, 0);
					FlxG.sound.music.persist = false;
				}
				FlxG.sound.play(Paths.sound('confirmMenu'), 1);
				FlxG.resetState();
				lime.utils.Assets.cache.clear();
            	openfl.utils.Assets.cache.clear();
				CoolUtil.setWindowIcon("mods/"+Options.getData("curMod")+"/_polymod_icon.png");
				PolymodHandler.loadMods();
				if (FlxG.sound.music == null || FlxG.sound.music.playing != true)
					TitleState.playTitleMusic();
			}
		}else {
			alphabetText.alpha = 0.6;
			modIcon.alpha = 0.6;
		}
	}
}
#end

/**
 * A Option for save data that is saved a string with multiple pre-defined states (aka like accuracy option or cutscene option)
 */
class StringSaveOption extends Option {
	// VARIABLES //
	var Current_Mode:String = "option 2";
	var Modes:Array<String> = ["option 1", "option 2", "option 3"];
	var Cool_Name:String;
	var Save_Data_Name:String;

	override public function new(_optionName:String = "String Switcher", _Modes:Array<String>, _Save_Data_Name:String = "hitsound") {
		super(_optionName, null);

		// SETTING VALUES //
		this.Modes = _Modes;
		this.Save_Data_Name = _Save_Data_Name;
		this.Current_Mode = Options.getData(Save_Data_Name);
		this.Cool_Name = _optionName;
		this.optionName = Cool_Name + " " + Current_Mode;

		// CREATING OTHER OBJECTS //
		remove(alphabetText);
		alphabetText.kill();
		alphabetText.destroy();

		alphabetText = new Alphabet(20, 20, optionName, true);
		alphabetText.isMenuItem = true;
		add(alphabetText);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (utilities.Controls.instance.ACCEPT && Std.int(alphabetText.targetY) == 0 && !OptionsMenu.instance.inMenu) {
			var prevIndex = Modes.indexOf(Current_Mode);

			if (prevIndex != -1) {
				if (prevIndex + 1 > Modes.length - 1)
					prevIndex = 0;
				else
					prevIndex++;
			} else
				prevIndex = 0;

			Current_Mode = Modes[prevIndex];

			this.optionName = Cool_Name + " " + Current_Mode;

			remove(alphabetText);
			alphabetText.kill();
			alphabetText.destroy();

			alphabetText = new Alphabet(20, 20, optionName, true);
			alphabetText.isMenuItem = true;
			add(alphabetText);

			SetDataIGuess();
		}
	}

	function SetDataIGuess() {
		Options.setData(Current_Mode, Save_Data_Name);
	}
}

class DisplayFontOption extends StringSaveOption {
	override function SetDataIGuess() {
		super.SetDataIGuess();
		Main.changeFont(Options.getData("infoDisplayFont"));
	}
}

/**
 * Very simple option that opens a webpage when selected
 */
 class OpenUrlOption extends Option {
	// OPTIONS //
	public var Title:String;
	public var Url:String;

	public function new(_optionName:String = "", Title:String, Url:String) {
		super(_optionName, null);

		// SETTING VALUES //
		this.Url = Url;
		this.Title = Title;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (utilities.Controls.instance.ACCEPT && alphabetText.targetY == 0) {
			CoolUtil.openURL(Url);
		}
	}
}