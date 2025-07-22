package ui;

import flixel.FlxSubState;
import haxe.extern.EitherType;
import flixel.group.FlxSpriteContainer;
import flixel.system.debug.log.LogStyle;
#if DISCORD_ALLOWED
import utilities.DiscordClient;
#end
#if MODDING_ALLOWED
import modding.PolymodHandler;
#end
import utilities.NoteVariables;
import lime.app.Application;
import states.TitleState;
import states.MusicBeatState;
import modding.ModList;
import flixel.FlxSprite;
import flixel.FlxState;
import states.OptionsMenu;
import flixel.FlxG;
import ui.ModIcon;
import flixel.util.typeLimit.NextState;
import flixel.tweens.*;

/**
 * The base option class that all options inherit from.
 */
class Option extends FlxSpriteContainer {
	// variables //
	public var alphabetText(default, null):Alphabet;

	// options //
	public var optionName(default, null):String;
	public var optionValue(default, null):String;
	public var optionDescription(default, null):String;
	public var optionSaveKey(default, null):String;

	public function new(optionName:String, optionValue:String, optionDescription:String = "", optionSaveKey:String = "main") {
		super();

		// SETTING VALUES //
		this.optionName = optionName;
		this.optionValue = optionValue;
		this.optionDescription = optionDescription;
		this.optionSaveKey = optionSaveKey;

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
	public var checkbox(default, null):Checkbox;

	// options //
	public var optionChecked(default, null):Bool = false;

	override public function new(optionName:String, optionValue:String, optionDescription:String = "", optionSaveKey:String = "main") {
		super(optionName, optionValue, optionDescription, optionSaveKey);

		checkbox = new Checkbox(alphabetText);
		optionChecked = checkbox.checked = getObjectValue();
		add(checkbox);
	}

	public inline function getObjectValue():Bool {
		return Options.getData(optionValue, optionSaveKey);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && alphabetText.targetY == 0)
			changeValue();
	}

	public function changeValue() {
		Options.setData(!optionChecked, optionValue, optionSaveKey);

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
				if (optionChecked && !DiscordClient.active) {
					DiscordClient.startup();
					DiscordClient.loadModPresence();
				} else if (!optionChecked && DiscordClient.active)
					DiscordClient.shutdown();
			#end
			case "versionDisplay":
				Main.toggleVers(optionChecked);
			case "developer":
				Main.toggleLogs(optionChecked);
			case "showCommitHash":
				Main.toggleCommitHash(optionChecked);
			case "antialiasing":
				for (member in FlxG.state.members) {
					if (member is FlxSprite) {
						cast(member, FlxSprite).antialiasing = optionChecked;
					}
					FlxSprite.defaultAntialiasing = optionChecked;
				}
			case "vSync":
				FlxG.stage.window.vsync = optionChecked;
			case "throwExceptionOnError":
				LogStyle.ERROR.throwException = optionChecked;
		}
	}
}

/**
 * Very simple option that transfers you to a different page when selecting it.
 */
class PageOption extends Option {
	// OPTIONS //
	public var pageName:String = "Categories";

	override public function new(optionName:String, pageName:String = "Categories", optionDescription:String = "") {
		super(optionName, pageName, optionDescription);

		// SETTING VALUES //
		this.pageName = pageName;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && Std.int(alphabetText.targetY) == 0 && !OptionsMenu.instance.inMenu) {
			OptionsMenu?.instance?.loadPage(pageName ?? "Categories");
		}
	}
}

class GameSubStateOption extends Option {
	public var gameSubState:EitherType<NextState, Class<FlxSubState>>;

	public function new(optionName:String, gameSubState:EitherType<NextState, Class<FlxSubState>>, optionDescription:String = "") {
		super(optionName, null, optionDescription);

		// SETTING VALUES //
		this.gameSubState = gameSubState;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && alphabetText.targetY == 0)
			if (gameSubState is Class) {
				FlxG.state.openSubState(Type.createInstance(cast gameSubState, []));
			} else {
				FlxG.state.openSubState(cast gameSubState);
			}
	}
}

/**
 * Very simple option that transfers you to a different game-state when selecting it.
 */
class GameStateOption extends Option {
	// OPTIONS //
	public var gameState:NextState;

	public function new(optionName:String = "", gameState:EitherType<NextState, Class<FlxState>>, optionDescription:String = "") {
		super(optionName, null, optionDescription);

		// SETTING VALUES //
		this.gameState = gameState;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && alphabetText.targetY == 0) {
			if (gameState is Class) {
				FlxG.switchState(Type.createInstance(cast this.gameState, []));
			} else {
				FlxG.switchState(cast gameState);
			}
		}
	}
}

class CharacterCreatorOption extends GameStateOption {

	public function new(optionName:String = "", gameState:EitherType<NextState, Class<FlxState>>, optionDescription:String = "") {
		super(optionName, gameState, optionDescription);
		toolbox.CharacterCreator.lastState = "OptionsMenu";
	}
}

#if MODDING_ALLOWED
/**
 * Option for enabling and disabling mods.
 */
class ModOption extends FlxSpriteContainer {
	// variables //
	public var alphabetText:Alphabet;
	public var modIcon:ModIcon;

	public var modEnabled:Bool = false;

	// options //
	public var optionName:String = "";
	public var optionValue:String = "Unknown Mod";

	public function new(_optionName:String = "", _optionValue:String = "Unknown Mod") {
		super();

		// SETTING VALUES //
		this.optionName = _optionName;
		this.optionValue = _optionValue;

		// CREATING OTHER OBJECTS //
		alphabetText = new Alphabet(20, 20, optionName, true);
		alphabetText.isMenuItem = true;
		add(alphabetText);

		modIcon = new ModIcon(optionValue, alphabetText);
		modIcon.sprTracker = alphabetText;
		add(modIcon);

		modEnabled = ModList.modList.get(optionValue);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && alphabetText.targetY == 0) {
			if (optionValue == Options.getData("curMod")) {
				CoolUtil.coolError("Leather Engine Mods", "The mod " + optionValue + " is your current mod\nPlease switch to a different mod to disable it!");
				for (member in members) {
					FlxTween.color(member, 1, 0xFF0000, 0xFFFFFF, {ease: FlxEase.quartOut});
				}
			} else {
				modEnabled = !modEnabled;
				ModList.setModEnabled(optionValue, modEnabled);
			}
		}

		if (modEnabled) {
			alpha = 1;
		} else {
			alpha = 0.6;
		}
	}
}

class ChangeModOption extends FlxSpriteContainer {
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

		if (alphabetText.targetY == 0) {
			alpha = 1;
			if (FlxG.keys.justPressed.ENTER) {
				Options.setData(optionValue, "curMod");
				modEnabled = !modEnabled;
				if (FlxG.state is TitleState)
					TitleState.initialized = false;
				if (FlxG.sound.music != null) {
					FlxG.sound.music.fadeOut(0.25, 0);
					FlxG.sound.music.persist = false;
				}
				FlxG.sound.play(Paths.sound('confirmMenu'), 1);
				CoolUtil.setWindowIcon("mods/" + Options.getData("curMod") + "/_polymod_icon.png");
				MusicBeatState.windowNamePrefix = Options.getData("curMod");
				PolymodHandler.loadMods();
				NoteVariables.init();
				Options.fixBinds();
				#if DISCORD_ALLOWED
				DiscordClient.loadModPresence();
				#end
				if (FlxG.state is modding.custom.CustomState) {
					FlxG.switchState(() -> new TitleState());
				} else {
					FlxG.resetState();
				}
				if (FlxG.sound.music == null || FlxG.sound.music.playing != true)
					TitleState.playTitleMusic();
			}
		} else {
			alpha = 0.6;
		}
	}
}
#end

/**
 * A Option for save data that is saved a string with multiple pre-defined states (aka like accuracy option or cutscene option)
 */
class StringSaveOption extends Option {
	// VARIABLES //
	public var currentMode(default, null):String;
	public var modes(default, null):Array<String>;
	public var displayName(default, null):String;
	public var saveDataName(default, null):String;

	override public function new(optionName:String, modes:Array<String>, saveDataName:String, optionDescription:String = "", optionSaveKey:String = "main") {
		super(optionName, null, optionDescription, optionSaveKey);

		// SETTING VALUES //
		this.modes = modes;
		this.saveDataName = saveDataName;
		this.currentMode = Options.getData(saveDataName, optionSaveKey);
		this.displayName = optionName;
		this.optionName = displayName + " " + currentMode;

		// CREATING OTHER OBJECTS //
		remove(alphabetText);
		alphabetText.kill();
		alphabetText.destroy();

		alphabetText = new Alphabet(20, 20, this.optionName, true);
		alphabetText.isMenuItem = true;
		add(alphabetText);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && Std.int(alphabetText.targetY) == 0 && !OptionsMenu.instance.inMenu) {
			var prevIndex = modes.indexOf(currentMode);

			if (prevIndex != -1) {
				if (prevIndex + 1 > modes.length - 1)
					prevIndex = 0;
				else
					prevIndex++;
			} else
				prevIndex = 0;

			currentMode = modes[prevIndex];

			this.optionName = displayName + " " + currentMode;

			remove(alphabetText);
			alphabetText.kill();
			alphabetText.destroy();

			alphabetText = new Alphabet(20, 20, optionName, true);
			alphabetText.isMenuItem = true;
			add(alphabetText);

			setData();
		}
	}

	function setData() {
		Options.setData(currentMode, saveDataName, optionSaveKey);
	}
}

class StepperSaveDeveloperOption extends StepperSaveOption {
	override function setData() {
		if (!Options.getData("developer")) {
			return;
		}
		super.setData();
	}
}

class StepperSaveOption extends Option {
	public var min(default, null):Float;
	public var max(default, null):Float;

	public var step(default, null):Float;
	public var currentValue(default, null):Float;

	override public function new(displayName:String, min:Float, max:Float, saveString:String, step:Float = 1, optionDescription:String = "") {
		super(displayName, saveString, optionDescription);
		if (max < min) {
			throw "Max value must not be less than min value.";
		}
		if (max == min) {
			throw "Min value must not equal max value.";
		}
		if (step <= 0) {
			throw "Step must be greater than 0.";
		}
		this.min = min;
		this.max = max;
		this.step = step;
		currentValue = Options.getData(saveString);

		remove(alphabetText);
		alphabetText.kill();
		alphabetText.destroy();

		alphabetText = new Alphabet(20, 20, '$optionName: $currentValue', true);
		alphabetText.isMenuItem = true;
		add(alphabetText);
	}

	private var prevValue:Float;

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (Std.int(alphabetText.targetY) == 0 && !OptionsMenu.instance.inMenu) {
			prevValue = currentValue;
			if (FlxG.keys.anyJustPressed([LEFT, A])) {
				currentValue = Math.max(min, currentValue - step);
				setData();
			} else if (FlxG.keys.anyJustPressed([RIGHT, D])) {
				currentValue = Math.min(max, currentValue + step);
				setData();
			}
		}
	}

	function setData() {
		if (prevValue == currentValue) {
			return;
		}
		Options.setData(currentValue, optionValue);
		remove(alphabetText);
		alphabetText.kill();
		alphabetText.destroy();

		alphabetText = new Alphabet(20, 20, '$optionName: $currentValue', true);
		alphabetText.isMenuItem = true;
		add(alphabetText);
	}
}

class DisplayFontOption extends StringSaveOption {
	override function setData() {
		super.setData();
		Main.changeFont(Options.getData("infoDisplayFont"));
	}
}

class DeveloperOption extends BoolOption {
	override function changeValue() {
		if (!Options.getData("developer")) {
			return;
		}
		super.changeValue();
	}
}

/**
 * Very simple option that opens a webpage when selected
 */
class OpenUrlOption extends Option {
	// OPTIONS //
	public var title:String;
	public var url:String;

	public function new(optionName:String, title:String, url:String, optionDescription:String = "") {
		super(optionName, null, optionDescription);

		// SETTING VALUES //
		this.url = url;
		this.title = title;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.keys.justPressed.ENTER && alphabetText.targetY == 0) {
			FlxG.openURL(url);
		}
	}
}
