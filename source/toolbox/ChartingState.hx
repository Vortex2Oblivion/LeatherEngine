package toolbox;

import sys.io.File;
import lime.ui.FileDialog;
import game.SoundGroup;
import flixel.util.FlxTimer;
import flixel.FlxObject;
import game.EventSprite;
import utilities.NoteVariables;
import modding.CharacterConfig;
import ui.FlxScrollableDropDownMenu;
import game.SongLoader;
import states.LoadingState;
import game.Conductor;
import states.PlayState;
import states.MusicBeatState;
import ui.HealthIcon;
import game.Note;
import game.Conductor.BPMChangeEvent;
import game.SongLoader.SongData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.text.FlxInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUISlider;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

using StringTools;
using utilities.BackgroundUtil;

@:publicFields
class ChartingState extends MusicBeatState {
	var fileDialogue:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;

	static inline final GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedIds:FlxTypedGroup<FlxSprite>;
	var curRenderedEvents:FlxTypedGroup<EventSprite>;

	var gridBG:FlxSprite;
	var gridBGNext:FlxSprite;

	var _song:SongData;

	var difficulty:String = 'normal';

	var typingShit:FlxInputText;
	var swagShit:FlxInputText;
	var modchart_Input:FlxInputText;
	var cutscene_Input:FlxInputText;
	var endCutscene_Input:FlxInputText;
	var characterGroup_Input:FlxInputText;

	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;
	var curSelectedEvent:Array<Dynamic>;

	var tempBpm:Float = 0;

	var vocals:SoundGroup;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var characters:Map<String, Array<String>> = new Map<String, Array<String>>();
	var gridBlackLine:FlxSprite;
	var gridEventBlackLine:FlxSprite;

	var selected_mod:String = "default";

	var stepperSusLength:FlxUINumericStepper;
	var stepperCharLength:FlxUINumericStepper;

	var current_Note_Character:Int = 0;

	static var playerHitsounds:Bool = false;
	static var enemyHitsounds:Bool = false;

	var eventList:Array<String> = [];
	var eventListData:Array<Array<String>> = [];

	var zoomLevel:Float = 1;

	var MIN_ZOOM:Float = 0.5;
	var MAX_ZOOM:Float = 16;

	var menuBG:FlxSprite;

	var colorQuantization:Bool;

	static var globalSecton:Int = 0;

	override function create() {
		#if NO_PRELOAD_ALL
		// FOR WHEN COMING IN FROM THE TOOLS PAGE LOL
		if (Assets.getLibrary("shared") == null)
			Assets.loadLibrary("shared").onComplete(function(_) {});
		#end

		menuBG = new FlxSprite().makeBackground(0xFF3D3D3D);

		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set();
		add(menuBG);

		// preload hitsounds
		FlxG.sound.cache(Paths.sound('CLAP'));
		FlxG.sound.cache(Paths.sound('SNAP'));

		var characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));

		for (text in characterList) {
			var properties = text.split(":");

			var name = properties[0];
			var mod = properties[1];

			var base_array;

			if (characters.exists(mod))
				base_array = characters.get(mod);
			else
				base_array = [];

			base_array.push(name);
			characters.set(mod, base_array);
		}

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		gridBGNext = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		gridBGNext.y += gridBG.height;
		gridBGNext.color = FlxColor.GRAY;
		add(gridBGNext);

		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('bf');
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		leftIcon.updateHitbox();
		rightIcon.updateHitbox();

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -45);
		rightIcon.setPosition(gridBG.width / 2, -45);

		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height) * 2, FlxColor.BLACK);
		add(gridBlackLine);

		gridEventBlackLine = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height) * 2, FlxColor.BLACK);
		add(gridEventBlackLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedEvents = new FlxTypedGroup<EventSprite>();
		curRenderedIds = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = SongLoader.loadFromJson("normal", "tutorial");

		uiSettings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + _song.ui_Skin + "/config"));

		MusicBeatState.windowNameSuffix = " - " + (_song?.song ?? "Unknown Song") + " (Chart Editor)";

		for (event in (PlayState.instance.baseEvents) ?? []) {
			events.push(event);
		}

		_song.events = [];

		if (PlayState.songMultiplier != 1)
			_song.speed = PlayState.previousScrollSpeed;

		FlxG.mouse.visible = true;

		tempBpm = _song.bpm;

		addSection();

		updateGrid();

		difficulty = PlayState.storyDifficultyStr.toLowerCase();

		loadSong(_song.song);

		Conductor.timeScale = _song.timescale;
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(gridBG.width), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		add(curRenderedNotes);
		add(curRenderedIds);
		add(curRenderedEvents);

		var tabs = [
			{name: "Art", label: 'Art'},
			{name: "Chart", label: 'Chart'},
			{name: "Events", label: "Events"},
			{name: "Song", label: 'Song'}
		];

		for (event in CoolUtil.coolTextFile(Paths.txt("eventList"))) {
			var eventData = event.split("~");

			eventListData.push(eventData);
			eventList.push(eventData[0]);
		}

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = 0;
		UI_box.y = 100;
		add(UI_box);

		beatSnap = Conductor.stepsPerSection;

		if (NoteVariables.beats.indexOf(beatSnap) == -1) // error handling i guess
			beatSnap = 16;

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventUI();
		updateHeads();
		updateGrid();

		changeSection(globalSecton);

		new FlxTimer().start(Options.getData("backupDuration") * 60, _backup, 0);

		super.create();
	}

	private function _backup(_) {
		backupChart();
		backupEvents();
	}

	private function backupChart():Void {
		var json:Dynamic;
		var date:String = Date.now().toString();
		var path:String;
		date = StringTools.replace(date, " ", "_");
		date = StringTools.replace(date, ":", "'");
		json = {"song": _song};
		json.song.events = [];
		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0)) {
			var gamingName = _song.song.toLowerCase();

			if (difficulty.toLowerCase() != 'normal')
				gamingName = gamingName + '-' + difficulty.toLowerCase();

			#if sys
			path = "./backups/" + "backup-" + gamingName + '-on-' + date + ".json";
			if (!sys.FileSystem.exists("./backups/"))
				sys.FileSystem.createDirectory("./backups/");
			sys.io.File.saveContent(path, Std.string(data.trim()));
			#end
		}
	}

	private function backupEvents():Void {
		var json:Dynamic;
		var date:String = Date.now().toString();
		var path:String;
		date = StringTools.replace(date, " ", "_");
		date = StringTools.replace(date, ":", "'");

		json = {
			"song": {
				"events": []
			}
		};
		json.song.events = events;
		var data:String = Json.stringify(json);
		if ((data != null) && (data.length > 0)) {
			var gamingName = _song.song.toLowerCase();

			gamingName = "events-";

			gamingName += _song.song.toLowerCase();

			if (difficulty.toLowerCase() != 'normal')
				gamingName = gamingName + '-' + difficulty.toLowerCase();

			#if sys
			path = "./backups/" + "backup-" + gamingName + '-on-' + date + ".json";
			if (!sys.FileSystem.exists("./backups/"))
				sys.FileSystem.createDirectory("./backups/");
			sys.io.File.saveContent(path, Std.string(data.trim()));
			#end
		}
	}

	function addSongUI():Void {
		// base ui thingy :D
		var tab_group_song:FlxUI = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";

		// interactive

		// inputs
		var UI_songTitle:FlxInputText = new FlxInputText(10, 30, 70, _song.song, 8);
		typingShit = UI_songTitle;
		blockPressWhileTypingOn.push(typingShit);

		var UI_songDiff:FlxInputText = new FlxInputText(10, UI_songTitle.y + UI_songTitle.height + 2, 70, PlayState.storyDifficultyStr, 8);
		swagShit = UI_songDiff;
		blockPressWhileTypingOn.push(swagShit);

		var check_voices:FlxUICheckBox = new FlxUICheckBox(10, UI_songDiff.y + UI_songDiff.height + 1, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;

		check_voices.callback = function() {
			_song.needsVoices = check_voices.checked;
		};

		var playerHitsoundsBox:FlxUICheckBox = new FlxUICheckBox(check_voices.x + check_voices.width, check_voices.y, null, null, "Player\nHitsounds", 100);
		playerHitsoundsBox.checked = playerHitsounds;

		playerHitsoundsBox.callback = function() {
			playerHitsounds = playerHitsoundsBox.checked;
		};

		var enemyHitsoundsBox:FlxUICheckBox = new FlxUICheckBox(playerHitsoundsBox.x, playerHitsoundsBox.y + playerHitsoundsBox.height + 2, null, null,
			"Enemy\nHitsounds", 100);
		enemyHitsoundsBox.checked = enemyHitsounds;

		enemyHitsoundsBox.callback = function() {
			enemyHitsounds = enemyHitsoundsBox.checked;
		};

		var quantBox:FlxUICheckBox = new FlxUICheckBox(enemyHitsoundsBox.x + 25, enemyHitsoundsBox.y + enemyHitsoundsBox.height + 2, null, null,
			"Color Quants", 100);
		colorQuantization = quantBox.checked = Options.getData("colorQuantization");

		quantBox.callback = function() {
			colorQuantization = quantBox.checked;
			updateGrid();
		};

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, check_voices.y + check_voices.height + 5, 0.1, 1, 0.1, 1000, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + stepperBPM.height, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperKeyCount:FlxUINumericStepper = new FlxUINumericStepper(10, stepperSpeed.y + stepperSpeed.height, 1, 4, 1,
			NoteVariables.maniaDirections.length);
		stepperKeyCount.value = _song.keyCount;
		stepperKeyCount.name = 'song_keycount';

		var stepperPlayerKeyCount:FlxUINumericStepper = new FlxUINumericStepper(stepperKeyCount.x + (stepperKeyCount.width * 2) + 2, stepperKeyCount.y, 1, 4,
			1, NoteVariables.maniaDirections.length);
		stepperPlayerKeyCount.value = _song.playerKeyCount;
		stepperPlayerKeyCount.name = 'song_playerkeycount';

		blockPressWhileTypingOnStepper.push(stepperBPM);
		blockPressWhileTypingOnStepper.push(stepperSpeed);
		blockPressWhileTypingOnStepper.push(stepperKeyCount);
		blockPressWhileTypingOnStepper.push(stepperPlayerKeyCount);

		var check_mute_inst:FlxUICheckBox = new FlxUICheckBox(10, stepperKeyCount.y + stepperKeyCount.height + 10, null, null, "Mute Inst", 55);
		check_mute_inst.checked = muteInstShit;
		check_mute_inst.callback = function() {
			FlxG.sound.music.volume = check_mute_inst.checked ? 0 : 1;
			muteInstShit = check_mute_inst.checked;
		};
		check_mute_inst.callback();

		var check_mute_vocals:FlxUICheckBox = new FlxUICheckBox(check_mute_inst.x + check_mute_inst.width + 4, check_mute_inst.y, null, null, "Mute Vocals",
			65);
		check_mute_vocals.checked = muteVocalShit;
		check_mute_vocals.callback = function() {
			vocals.volume = check_mute_vocals.checked ? 0 : 1;
			muteVocalShit = check_mute_vocals.checked;
		};
		check_mute_vocals.callback();

		#if FLX_PITCH
		slider_playback_speed = new FlxUISlider(this, 'playbackSpeed', 150, 15, 0.1, 2);
		slider_playback_speed.nameLabel.text = 'Playback Speed';
		slider_playback_speed.valueLabel.color = FlxColor.BLACK;
		#end

		var check_char_ids:FlxUICheckBox = new FlxUICheckBox(check_mute_vocals.x + check_mute_vocals.width + 4, check_mute_vocals.y, null, null,
			"Character Ids On Notes", 100);
		check_char_ids.checked = doFunnyNumbers;
		check_char_ids.callback = function() {
			doFunnyNumbers = check_char_ids.checked;
			updateGrid();
		};

		modchart_Input = new FlxInputText(10, check_mute_inst.y + check_mute_inst.height + 2, 70, _song.modchartPath, 8);

		var check_modchart_tools:FlxUICheckBox = new FlxUICheckBox(modchart_Input.x + (modchart_Input.width * 2) + 20, modchart_Input.y, null, null,
			"Modcharting Tools", 100);
		check_modchart_tools.checked = _song.modchartingTools;

		check_modchart_tools.callback = function() {
			_song.modchartingTools = check_modchart_tools.checked;
		};

		cutscene_Input = new FlxInputText(modchart_Input.x, modchart_Input.y + modchart_Input.height + 2, 70, _song.cutscene, 8);
		endCutscene_Input = new FlxInputText(cutscene_Input.x, cutscene_Input.y + cutscene_Input.height + 2, 70, _song.endCutscene, 8);

		blockPressWhileTypingOn.push(modchart_Input);
		blockPressWhileTypingOn.push(cutscene_Input);
		blockPressWhileTypingOn.push(endCutscene_Input);

		var saveButton:FlxButton = new FlxButton(10, 240, "Save", function() {
			saveLevel();
		});

		var saveEventsButton:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Save Events", function() {
			saveLevel(true);
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x, saveButton.y + saveButton.height + 10, "Reload Audio", function() {
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x + reloadSong.width + 10, reloadSong.y, "Reload JSON", function() {
			loadJson(_song.song.toLowerCase(), difficulty.toLowerCase());
		});

		var loadChartBtn:FlxButton = new FlxButton(reloadSong.x, reloadSong.y + reloadSong.height + 10, 'Load Chart', loadChart);

		var restart = new FlxButton(loadChartBtn.x + loadChartBtn.width + 10, loadChartBtn.y, "Reset Chart", function() {
			for (ii in 0..._song.notes.length) {
				for (i in 0..._song.notes[ii].sectionNotes.length) {
					_song.notes[ii].sectionNotes = [];
				}
			}

			resetSection(true);
		});

		var resetEvents = new FlxButton(loadChartBtn.x, restart.y + restart.height + 10, "Reset Events", function() {
			events = [];

			updateGrid();
		});

		// labels

		var songNameLabel = new FlxText(UI_songTitle.x + UI_songTitle.width + 1, UI_songTitle.y, 0, "Song Name", 9);
		var diffLabel = new FlxText(UI_songDiff.x + UI_songDiff.width + 1, UI_songDiff.y, 0, "Difficulty", 9);

		var bpmLabel = new FlxText(stepperBPM.x + stepperBPM.width + 1, stepperBPM.y, 0, "BPM", 9);
		var speedLabel = new FlxText(stepperSpeed.x + stepperSpeed.width + 1, stepperSpeed.y, 0, "Scroll Speed", 9);
		var keyCountLabel = new FlxText(stepperKeyCount.x + stepperKeyCount.width + 1, stepperKeyCount.y, 0, "Key Count", 9);

		var modChartLabel = new FlxText(modchart_Input.x + modchart_Input.width + 1, modchart_Input.y, 0, "Modchart Path", 9);
		var cutsceneLabel = new FlxText(cutscene_Input.x + cutscene_Input.width + 1, cutscene_Input.y, 0, "Cutscene JSON Name", 9);
		var endCutsceneLabel = new FlxText(endCutscene_Input.x + endCutscene_Input.width + 1, endCutscene_Input.y, 0, "End Cutscene JSON Name", 9);

		var settingsLabel = new FlxText(10, 10, 0, "Setings", 9);
		var actionsLabel = new FlxText(10, 220, 0, "Actions", 9);

		// adding things
		tab_group_song.add(songNameLabel);
		tab_group_song.add(diffLabel);

		tab_group_song.add(bpmLabel);
		tab_group_song.add(speedLabel);
		tab_group_song.add(keyCountLabel);

		tab_group_song.add(modChartLabel);
		tab_group_song.add(cutsceneLabel);
		tab_group_song.add(endCutsceneLabel);

		tab_group_song.add(settingsLabel);
		tab_group_song.add(actionsLabel);

		tab_group_song.add(UI_songTitle);
		tab_group_song.add(UI_songDiff);
		tab_group_song.add(check_voices);
		tab_group_song.add(playerHitsoundsBox);
		tab_group_song.add(enemyHitsoundsBox);
		tab_group_song.add(quantBox);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(check_mute_vocals);
		tab_group_song.add(check_char_ids);
		tab_group_song.add(modchart_Input);
		tab_group_song.add(check_modchart_tools);
		tab_group_song.add(cutscene_Input);
		tab_group_song.add(endCutscene_Input);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEventsButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadChartBtn);
		tab_group_song.add(restart);
		tab_group_song.add(resetEvents);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stepperKeyCount);
		tab_group_song.add(stepperPlayerKeyCount);
		#if FLX_PITCH
		tab_group_song.add(slider_playback_speed);
		#end

		// final addings
		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		// also this, idk what it does but ehhhh who cares \_(:/)_/
		FlxG.camera.follow(cameraShitThing);
	}

	static var muteInstShit:Bool = false;
	static var muteVocalShit:Bool = false;

	var cameraShitThing:FlxObject = new FlxObject(0, 0, Std.int(FlxG.width / 2), 4);

	var value1:FlxInputText;
	var value2:FlxInputText;

	var valueDescriptions:FlxText;

	var curEvent:Int = 0;

	var eventDropDown:FlxScrollableDropDownMenu;

	function addEventUI():Void {
		// base ui thingy :D
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = "Events";

		// interactive

		// dropdown
		eventDropDown = new FlxScrollableDropDownMenu(10, 30, FlxScrollableDropDownMenu.makeStrIdLabelArray(eventList, true), function(event:String) {
			curEvent = Std.parseInt(event);
			eventName = eventList[Std.parseInt(event)];

			if (curSelectedEvent != null)
				curSelectedEvent[0] = eventName;

			valueDescriptions.text = "Value 1 - " + eventListData[curEvent][1] + "\nValue 2 - " + eventListData[curEvent][2] + "\n";
		});

		blockPressWhileScrolling.push(eventDropDown);

		// inputs
		value1 = new FlxInputText(10, 60, 70, eventValue1, 8);
		value2 = new FlxInputText(value1.x + value1.width + 2, value1.y, 70, eventValue2, 8);

		blockPressWhileTypingOn.push(value1);
		blockPressWhileTypingOn.push(value2);

		// labels

		var eventNameLabel = new FlxText(eventDropDown.x + eventDropDown.width + 1, eventDropDown.y, 0, "Event Name", 9);

		valueDescriptions = new FlxText(value1.x, value1.y
			+ value1.height
			+ 2, 290,
			"Value 1 - "
			+ eventListData[curEvent][1] + "\nValue 2 - " + eventListData[curEvent][2] + "\n", 9);

		// adding things
		tab_group_event.add(value1);
		tab_group_event.add(value2);
		tab_group_event.add(valueDescriptions);

		tab_group_event.add(eventDropDown);
		tab_group_event.add(eventNameLabel);

		// final addings
		UI_box.addGroup(tab_group_event);
		UI_box.scrollFactor.set();
	}

	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;
	var check_changeTimeScale:FlxUICheckBox;

	var cur_Note_Type:String = "default";

	var copiedSection:Int = 0;

	var arrowTypes:Array<String> = CoolUtil.coolTextFile(Paths.txt("arrowTypes"));

	function addSectionUI():Void {
		// SECTION CREATION
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Chart';

		// Section Titles
		var sectionText = new FlxText(10, 10, 0, "Section Options", 9);

		// Interactive Stuff

		// Section Section (lol) //

		// numbers
		stepperSectionBPM = new FlxUINumericStepper(10, 100, 0.1, Conductor.bpm, 0.1, 1000, 1);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var copySectionCount:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		blockPressWhileTypingOnStepper.push(stepperSectionBPM);
		blockPressWhileTypingOnStepper.push(copySectionCount);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last", function() {
			copySection(Std.int(copySectionCount.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var clearLeftSectionButton:FlxButton = new FlxButton(clearSectionButton.x + clearSectionButton.width + 2, 150, "Clear Left", function() {
			clearSectionSide(0);
		});

		var clearRightSectionButton:FlxButton = new FlxButton(clearSectionButton.x + clearSectionButton.width + 2, 170, "Clear Right", function() {
			clearSectionSide(1);
		});

		var swapSectionButton:FlxButton = new FlxButton(10, 170, "Swap section", function() {
			for (i in 0..._song.notes[curSection].sectionNotes.length) {
				_song.notes[curSection].sectionNotes[i][1] += _song.keyCount;
				_song.notes[curSection].sectionNotes[i][1] %= _song.keyCount + _song.playerKeyCount;

				updateGrid();
			}
		});

		// checkboxes
		check_mustHitSection = new FlxUICheckBox(10, 50, null, null, "Camera points at P1", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;

		check_altAnim = new FlxUICheckBox(10, 195, null, null, "Enemy Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 80, null, null, 'Change BPM?', 100);
		check_changeBPM.name = 'check_changeBPM';

		check_changeTimeScale = new FlxUICheckBox(check_mustHitSection.x + check_mustHitSection.width, 50, null, null, 'Change Time Signature?', 100);
		check_changeTimeScale.name = 'check_changeTimeScale';
		check_changeTimeScale.visible = false;
		check_changeTimeScale.alpha = 0;
		check_changeTimeScale.x = 5000000;
		check_changeTimeScale.y = 5000000;

		var stepperSectionTimeScale1 = new FlxUINumericStepper(10, 30, 1, Conductor.timeScale[0], 1, 1000);
		stepperSectionTimeScale1.value = Conductor.timeScale[0];
		stepperSectionTimeScale1.name = 'section_timescale1';

		var stepperSectionTimeScale2 = new FlxUINumericStepper(stepperSectionTimeScale1.x + stepperSectionTimeScale1.width + 2, stepperSectionTimeScale1.y, 1,
			Conductor.timeScale[1], 1, 1000);
		stepperSectionTimeScale2.value = Conductor.timeScale[1];
		stepperSectionTimeScale2.name = 'section_timescale2';

		blockPressWhileTypingOnStepper.push(stepperSectionTimeScale1);
		blockPressWhileTypingOnStepper.push(stepperSectionTimeScale2);

		var copySectionButton:FlxButton = new FlxButton(check_altAnim.x, check_altAnim.y + check_altAnim.height + 6, "Copy Section", function() {
			copiedSection = curSection;
			updateGrid();
		});

		var pasteSectionButton:FlxButton = new FlxButton(copySectionButton.x + copySectionButton.width + 2, copySectionButton.y, "Paste Section", function() {
			pasteSection();
		});

		var copyEventsButton:FlxButton = new FlxButton(copySectionButton.x, copySectionButton.y + copySectionButton.height + 2, "Copy Events", function() {
			copiedEventsSection = curSection;
			copyEvents(curSection);
		});

		var pasteEventsButton:FlxButton = new FlxButton(copyEventsButton.x + copyEventsButton.width + 2, copyEventsButton.y, "Paste Events", function() {
			pasteEvents();
		});

		// Labels for Interactive Stuff
		var noteText = new FlxText(10, 240 + copySectionButton.height + 2, 0, "Note Options", 9);
		var stepperText:FlxText = new FlxText(110 + copySectionCount.width, 130, 0, "Sections back", 9);
		var bpmText:FlxText = new FlxText(12 + stepperSectionBPM.width, 100, 0, "New BPM", 9);

		// end of section section //

		// NOTE SECTION //

		// numbers
		stepperSusLength = new FlxUINumericStepper(10, 260 + copySectionButton.height + 2, Conductor.stepCrochet / 2, 0, 0, 9999);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		stepperCharLength = new FlxUINumericStepper(stepperSusLength.x, stepperSusLength.y + stepperSusLength.height + 1, 1, 0, 0, 1000);
		stepperCharLength.value = 0;
		stepperCharLength.name = 'note_char';

		blockPressWhileTypingOnStepper.push(stepperSusLength);
		blockPressWhileTypingOnStepper.push(stepperCharLength);

		// Adding everything in

		var setCharacterLeftSide:FlxButton = new FlxButton(stepperCharLength.x, stepperCharLength.y + stepperCharLength.height + 1, "Char To Left",
			function() {
				characterSectionSide(0, Std.int(stepperCharLength.value));
			});

		var setCharacterRightSide:FlxButton = new FlxButton(setCharacterLeftSide.x + setCharacterLeftSide.width + 2, setCharacterLeftSide.y, "Char To Right",
			function() {
				characterSectionSide(1, Std.int(stepperCharLength.value));
			});

		// dropdown lmao
		var typeDropDown:FlxScrollableDropDownMenu = new FlxScrollableDropDownMenu(setCharacterLeftSide.x, setCharacterLeftSide.y + 40,
			FlxScrollableDropDownMenu.makeStrIdLabelArray(arrowTypes, true), function(type:String) {
				cur_Note_Type = arrowTypes[Std.parseInt(type)];
		});

		characterGroup_Input = new FlxInputText(typeDropDown.x, setCharacterLeftSide.y + 22, 70, "", 8);

		typeDropDown.selectedLabel = cur_Note_Type;

		blockPressWhileScrolling.push(typeDropDown);

		// funny input box

		blockPressWhileTypingOn.push(characterGroup_Input);

		// labels
		var susText = new FlxText(stepperSusLength.x + stepperSusLength.width + 1, stepperSusLength.y, 0, "Sustain note length", 9);
		var charText = new FlxText(stepperCharLength.x + stepperCharLength.width + 1, stepperCharLength.y, 0, "Character", 9);

		var charGroupText = new FlxText(characterGroup_Input.x + characterGroup_Input.width + 1, setCharacterLeftSide.y + setCharacterLeftSide.height, 0,
			"Character Group (seperated by ',')", 9);

		// note stuff
		tab_group_section.add(noteText);

		tab_group_section.add(stepperSusLength);
		tab_group_section.add(susText);

		tab_group_section.add(stepperCharLength);
		tab_group_section.add(charText);

		tab_group_section.add(typeDropDown);

		tab_group_section.add(setCharacterLeftSide);
		tab_group_section.add(setCharacterRightSide);

		tab_group_section.add(characterGroup_Input);
		tab_group_section.add(charGroupText);

		// section stuff
		tab_group_section.add(sectionText);

		tab_group_section.add(bpmText);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(copySectionCount);
		tab_group_section.add(stepperText);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(clearLeftSectionButton);
		tab_group_section.add(clearRightSectionButton);
		tab_group_section.add(swapSectionButton);
		tab_group_section.add(check_changeTimeScale);
		tab_group_section.add(stepperSectionTimeScale1);
		tab_group_section.add(stepperSectionTimeScale2);

		tab_group_section.add(copySectionButton);
		tab_group_section.add(pasteSectionButton);

		tab_group_section.add(copyEventsButton);
		tab_group_section.add(pasteEventsButton);

		// final addition
		UI_box.addGroup(tab_group_section);
	}

	function addNoteUI():Void {
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Art';

		var arrayCharacters = ["bf", "gf", ""];
		var tempCharacters = characters.get("default");

		if (tempCharacters != null) {
			for (Item in tempCharacters) {
				arrayCharacters.push(Item);
			}
		}

		// CHARS
		var player1DropDown = new FlxScrollableDropDownMenu(10, 30, FlxScrollableDropDownMenu.makeStrIdLabelArray(arrayCharacters, true),
			function(character:String) {
				_song.player1 = arrayCharacters[Std.parseInt(character)];
				updateHeads();
			});

		player1DropDown.selectedLabel = _song.player1;

		var gfDropDown = new FlxScrollableDropDownMenu(10, 50, FlxScrollableDropDownMenu.makeStrIdLabelArray(arrayCharacters, true),
			function(character:String) {
				_song.gf = arrayCharacters[Std.parseInt(character)];
			});

		gfDropDown.selectedLabel = _song.gf;

		var player2DropDown = new FlxScrollableDropDownMenu(10, 70, FlxScrollableDropDownMenu.makeStrIdLabelArray(arrayCharacters, true),
			function(character:String) {
				_song.player2 = arrayCharacters[Std.parseInt(character)];
				updateHeads();
			});

		player2DropDown.selectedLabel = _song.player2;

		blockPressWhileScrolling.push(player1DropDown);
		blockPressWhileScrolling.push(gfDropDown);
		blockPressWhileScrolling.push(player2DropDown);

		// OTHER
		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));

		var stageDropDown = new FlxScrollableDropDownMenu(10, 120, FlxScrollableDropDownMenu.makeStrIdLabelArray(stages, true), function(stage:String) {
			_song.stage = stages[Std.parseInt(stage)];
		});

		stageDropDown.selectedLabel = _song.stage;

		blockPressWhileScrolling.push(stageDropDown);

		var uiSkins:Array<String> = CoolUtil.coolTextFile(Paths.txt('uiSkinList'));

		var uiSkinDropDown = new FlxScrollableDropDownMenu(10, stageDropDown.y + 20, FlxScrollableDropDownMenu.makeStrIdLabelArray(uiSkins, true),
			function(uiSkin:String) {
				_song.ui_Skin = uiSkins[Std.parseInt(uiSkin)];
				uiSettings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + _song.ui_Skin + "/config"));
				while (curRenderedNotes.members.length > 0) {
					curRenderedNotes.remove(curRenderedNotes.members[0], true);
				}

				while (curRenderedEvents.members.length > 0) {
					curRenderedEvents.remove(curRenderedEvents.members[0], true);
				}

				updateGrid();
			});

		uiSkinDropDown.selectedLabel = _song.ui_Skin;

		blockPressWhileScrolling.push(uiSkinDropDown);

		var mods:Array<String> = [];

		var iterator = characters.keys();

		for (i in iterator) {
			mods.push(i);
		}

		var modDropDown = new FlxScrollableDropDownMenu(uiSkinDropDown.x, uiSkinDropDown.y + 20, FlxScrollableDropDownMenu.makeStrIdLabelArray(mods, true),
			function(mod:String) {
				selected_mod = mods[Std.parseInt(mod)];

				arrayCharacters = ["bf", "gf", ""];
				tempCharacters = characters.get(selected_mod);

				for (Item in tempCharacters) {
					arrayCharacters.push(Item);
				}

				var character_Data_List = FlxScrollableDropDownMenu.makeStrIdLabelArray(arrayCharacters, true);

				player1DropDown.setData(character_Data_List);
				gfDropDown.setData(character_Data_List);
				player2DropDown.setData(character_Data_List);

				player1DropDown.selectedLabel = _song.player1;
				gfDropDown.selectedLabel = _song.gf;
				player2DropDown.selectedLabel = _song.player2;
			});

		modDropDown.selectedLabel = selected_mod;

		blockPressWhileScrolling.push(modDropDown);

		// LABELS
		var characterLabel = new FlxText(10, 10, 0, "Characters", 9);
		var otherLabel = new FlxText(10, 100, 0, "Other", 9);

		var p1Label = new FlxText(12 + player1DropDown.width, player1DropDown.y, 0, "Player 1", 9);
		var gfLabel = new FlxText(12 + gfDropDown.width, gfDropDown.y, 0, "Girlfriend", 9);
		var p2Label = new FlxText(12 + player2DropDown.width, player2DropDown.y, 0, "Player 2", 9);
		var stageLabel = new FlxText(12 + stageDropDown.width, stageDropDown.y, 0, "Stage", 9);
		var uiSkinLabel = new FlxText(12 + uiSkinDropDown.width, uiSkinDropDown.y, 0, "UI Skin", 9);
		var modLabel = new FlxText(12 + modDropDown.width, modDropDown.y, 0, "Current Character Group", 9);

		// adding labels
		tab_group_note.add(characterLabel);
		tab_group_note.add(otherLabel);

		tab_group_note.add(p1Label);
		tab_group_note.add(gfLabel);
		tab_group_note.add(p2Label);
		tab_group_note.add(stageLabel);
		tab_group_note.add(uiSkinLabel);
		tab_group_note.add(modLabel);

		// adding main dropdowns
		tab_group_note.add(modDropDown);
		tab_group_note.add(uiSkinDropDown);
		tab_group_note.add(stageDropDown);
		tab_group_note.add(player2DropDown);
		tab_group_note.add(gfDropDown);
		tab_group_note.add(player1DropDown);

		// final add
		UI_box.addGroup(tab_group_note);
	}

	var addedVocals:Array<String> = [];

	function loadSong(daSong:String):Void {
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (vocals != null)
			vocals.stop();

		var difficulty_name:String = _song.specialAudioName == null ? difficulty.toLowerCase() : _song.specialAudioName;

		if (openfl.Assets.cache.hasSound(Paths.inst(daSong, difficulty_name)))
			openfl.Assets.cache.removeSound(Paths.inst(daSong, difficulty_name));

		if (openfl.Assets.cache.hasSound(Paths.voices(daSong, difficulty_name)))
			openfl.Assets.cache.removeSound(Paths.voices(daSong, difficulty_name));

		FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(daSong, _song.specialAudioName ?? difficulty_name, _song.player1));
		FlxG.sound.music.persist = true;

		vocals = new SoundGroup(2);
		if (_song.needsVoices) {
			for (character in ['bf', 'dad', 'player', 'opponent', _song.player1, _song.player2]) {
				var soundPath:String = Paths.voices(daSong, _song.specialAudioName ?? difficulty_name, character, _song.player1);
				if (!addedVocals.contains(soundPath)) {
					vocals.add(FlxG.sound.list.add(new FlxSound().loadEmbedded(soundPath)));
					addedVocals.push(soundPath);
				}
			}
		}

		// FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function() {
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	#if FLX_PITCH
	var slider_playback_speed:FlxUISlider;

	/**
	 * The playback speed of the current chart.
	 */
	var playbackSpeed:Float = 1;
	#end

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUICheckBox.CLICK_EVENT) {
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;

			switch (label) {
				case 'Camera points at P1':
					_song.notes[curSection].mustHitSection = check.checked;
					updateHeads();
					updateGrid();
				case 'Change BPM?':
					if (_song.notes[curSection].bpm < 0.1)
						_song.notes[curSection].bpm = 0.1;

					_song.notes[curSection].changeBPM = check.checked;

					Conductor.mapBPMChanges(_song);

					if (_song.notes[curSection].changeBPM)
						Conductor.changeBPM(_song.notes[curSection].bpm);

					updateGrid();
				case 'Change Time Signature?':
					if (_song.notes[curSection].timeScale == null)
						_song.notes[curSection].timeScale = Conductor.timeScale;

					if (_song.notes[curSection].timeScale[0] < 1)
						_song.notes[curSection].timeScale[0] = 1;

					if (_song.notes[curSection].timeScale[1] < 1)
						_song.notes[curSection].timeScale[1] = 1;

					_song.notes[curSection].changeTimeScale = check.checked;

					Conductor.mapBPMChanges(_song);

					if (_song.notes[curSection].changeTimeScale)
						Conductor.timeScale = _song.notes[curSection].timeScale;

					updateGrid();
				case "Enemy Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		} else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);

			switch (wname) {
				case 'section_length':
					_song.notes[curSection].lengthInSteps = Std.int(nums.value);
					updateGrid();
				case 'song_speed':
					_song.speed = nums.value;
				case 'song_keycount':
					_song.keyCount = Std.int(nums.value);
					updateGrid();
				case 'song_playerkeycount':
					_song.playerKeyCount = Std.int(nums.value);
					updateGrid();
				case 'song_bpm':
					if (nums.value < 0.1)
						nums.value = 0.1;

					tempBpm = nums.value;
					Conductor.mapBPMChanges(_song);
					Conductor.changeBPM(nums.value);
				case 'note_susLength':
					curSelectedNote[2] = nums.value;
					updateGrid();
				case 'note_char':
					current_Note_Character = Std.int(nums.value);
				case 'section_bpm':
					if (nums.value < 0.1)
						nums.value = 0.1;

					_song.notes[curSection].bpm = nums.value;

					Conductor.mapBPMChanges(_song);
					Conductor.changeBPM(nums.value);

					updateGrid();
				case 'section_timescale1':
					var val = Std.int(nums.value);

					if (val < 1)
						val = 1;

					// _song.notes[curSection].timeScale[0] = val;
					_song.timescale[0] = val;
					Conductor.timeScale = _song.timescale;

					Conductor.mapBPMChanges(_song);

					updateGrid();
				case 'section_timescale2':
					var val = Std.int(nums.value);

					if (val < 1)
						val = 1;

					// _song.notes[curSection].timeScale[1] = val;
					_song.timescale[1] = val;
					Conductor.timeScale = _song.timescale;

					Conductor.mapBPMChanges(_song);

					updateGrid();
			}
		} else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider)) {
			playbackSpeed = #if FLX_PITCH Std.int(slider_playback_speed.value) #else 1.0 #end;
		}
	}

	var updatedSection:Bool = false;

	function sectionStartTime(?section:Int):Float {
		if (section == null)
			section = curSection;

		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;

		for (i in 0...section) {
			if (_song.notes[i].changeBPM) {
				daBPM = _song.notes[i].bpm;
			}

			daPos += Conductor.timeScale[0] * (1000 * (60 / daBPM));
		}

		return daPos;
	}

	var beatSnap:Int = 16;

	private var blockPressWhileTypingOn:Array<FlxInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxScrollableDropDownMenu> = [];

	override function update(elapsed:Float) {
		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn) {
			if (inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if (!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				if (cast(stepper.text_field, flixel.addons.ui.FlxInputText).hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput) {
			FlxG.sound.muteKeys = [ZERO, NUMPADZERO];
			FlxG.sound.volumeDownKeys = [MINUS, NUMPADMINUS];
			FlxG.sound.volumeUpKeys = [PLUS, NUMPADPLUS];

			for (dropDownMenu in blockPressWhileScrolling) {
				if (dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		var oldValue1 = eventValue1;
		var oldValue2 = eventValue2;

		eventValue1 = value1.text;
		eventValue2 = value2.text;

		if (oldValue1 != eventValue1 && curSelectedEvent != null)
			curSelectedEvent[2] = eventValue1;

		if (oldValue2 != eventValue2 && curSelectedEvent != null)
			curSelectedEvent[3] = eventValue2;

		if (FlxMath.roundDecimal(tempBpm, 1) < 0.1)
			tempBpm = 0.1;

		if (FlxMath.roundDecimal(Conductor.bpm, 1) < 0.1)
			Conductor.bpm = 0.1;

		if (FlxMath.roundDecimal(_song.notes[curSection].bpm, 1) < 0.1) {
			_song.notes[curSection].bpm = 0.1;
			Conductor.mapBPMChanges(_song);
		}

		Conductor.timeScale = _song.timescale;

		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;
		difficulty = swagShit.text.toLowerCase();
		PlayState.storyDifficultyStr = difficulty.toUpperCase();
		_song.modchartPath = modchart_Input.text;
		_song.cutscene = cutscene_Input.text;
		_song.endCutscene = endCutscene_Input.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * Conductor.stepsPerSection));
		cameraShitThing.y = strumLine.y;

		if (playerHitsounds || enemyHitsounds) {
			curRenderedNotes.forEach(function(note:Note) {
				if (FlxG.sound.music.playing) {
					FlxG.overlap(strumLine, note, function(_, _) {
						if (note.isSustainNote)
							return;

						if (!note.playedHitSound) {
							note.playedHitSound = true;

							if (note.rawNoteData % (_song.keyCount + _song.playerKeyCount) < _song.keyCount
								&& _song.notes[curSection].mustHitSection
								|| note.rawNoteData % (_song.keyCount + _song.playerKeyCount) >= _song.keyCount && !_song.notes[curSection].mustHitSection) {
								if (playerHitsounds) {
									FlxG.sound.play(Paths.sound('CLAP'));
								}
							} else {
								if (enemyHitsounds) {
									FlxG.sound.play(Paths.sound('SNAP'));
								}
							}
						}
					});
				}
			});
		}
		if (curBeat % Std.int(Conductor.stepsPerSection / Conductor.timeScale[1]) == 0
			&& curStep >= (Conductor.stepsPerSection * (curSection + 1))) {
			if (_song.notes[curSection + 1] == null)
				addSection();

			changeSection(curSection + 1, false);
		}

		if (_song.notes[curSection] == null)
			addSection();

		if (FlxG.mouse.justPressed) {
			var coolNess = true;

			if (FlxG.mouse.overlaps(curRenderedNotes)) {
				curRenderedNotes.forEach(function(note:Note) {
					if (FlxG.mouse.overlaps(note) && (Math.floor(FlxG.mouse.x / GRID_SIZE) - 1) == note.rawNoteData && coolNess) {
						coolNess = false;

						if (FlxG.keys.pressed.CONTROL) {
							selectNote(note);
						} else {
							deleteNote(note);
						}
					}
				});
			}

			if (FlxG.mouse.overlaps(curRenderedEvents)) {
				curRenderedEvents.forEach(function(event:EventSprite) {
					if (FlxG.mouse.overlaps(event) && coolNess) {
						coolNess = false;

						if (FlxG.keys.pressed.CONTROL)
							selectEvent(event);
						else {
							deleteEvent(event);
						}
					}
				});
			}

			if (coolNess) {
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + gridBG.height) {
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * (Conductor.stepsPerSection * zoomLevel))) {
			var snappedGridSize = (GRID_SIZE / (beatSnap / Conductor.stepsPerSection));

			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;

			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / snappedGridSize) * snappedGridSize;
		}

		if (!blockInput) {
			if (FlxG.keys.justPressed.ENTER) {
				_song.events = events;
				globalSecton = curSection;
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				vocals.stop();
				PlayState.playCutscenes = true;
				PlayState.loadChartEvents = false;
				LoadingState.loadAndSwitchState(() -> new PlayState());
				PlayState.chartingMode = true;
				if (FlxG.keys.pressed.SHIFT) {
					PlayState.startOnTime = Conductor.songPosition;
				}
			}

			if (FlxG.keys.justPressed.E)
				changeNoteSustain(Conductor.stepCrochet);
			if (FlxG.keys.justPressed.Q)
				changeNoteSustain(-Conductor.stepCrochet);

			if (FlxG.keys.justPressed.X) {
				zoomLevel *= 2;
				zoomLevel = FlxMath.bound(zoomLevel, MIN_ZOOM, MAX_ZOOM);
				updateGrid();
			} else if (FlxG.keys.justPressed.Z) {
				zoomLevel /= 2;
				zoomLevel = FlxMath.bound(zoomLevel, MIN_ZOOM, MAX_ZOOM);
				updateGrid();
			}

			if (FlxG.keys.justPressed.TAB) {
				if (FlxG.keys.pressed.SHIFT) {
					UI_box.selected_tab--;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				} else {
					UI_box.selected_tab++;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}

			var control = FlxG.keys.pressed.CONTROL;

			if (FlxG.keys.justPressed.SPACE) {
				if (FlxG.sound.music.playing) {
					FlxG.sound.music.pause();
					vocals.pause();
				} else {
					var oldtime:Float = FlxG.sound.music.time;
					vocals.play();
					FlxG.sound.music.play();
					Conductor.songPosition = vocals.time = FlxG.sound.music.time = oldtime;
				}
			}

			if (FlxG.keys.justPressed.R) {
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0) {
				if (control) {
					cameraShitThing.x += FlxG.mouse.wheel * 5;

					/*if (cameraShitThing.x > gridBG.x + gridBG.width)
							cameraShitThing.x = gridBG.x + gridBG.width;

						if (cameraShitThing.x < 0)
							cameraShitThing.x = 0; */
				} else {
					FlxG.sound.music.pause();
					vocals.pause();

					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
					vocals.time = FlxG.sound.music.time;
				}
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S) {
				FlxG.sound.music.pause();
				vocals.pause();

				var daTime:Float = (FlxG.keys.pressed.SHIFT ? Conductor.stepCrochet : 700 * FlxG.elapsed);

				if (FlxG.keys.pressed.W) {
					FlxG.sound.music.time -= daTime;
				} else {
					FlxG.sound.music.time += daTime;
				}

				vocals.time = FlxG.sound.music.time;

				if (FlxG.sound.music.time < sectionStartTime()) {
					changeSection(curSection - 1);
				}

				if (FlxG.sound.music.time > FlxG.sound.music.length) {
					changeSection(0);
				}
			}

			var shiftThing:Int = 1;

			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;
			if ((controls.RIGHT_P) && !control) {
				if (sectionStartTime(curSection + shiftThing) >= (!_song.needsVoices ? FlxG.sound.music.length : Math.min(FlxG.sound.music.length,
					vocals.maxLength))) {
					changeSection(0);
				} else {
					changeSection(curSection + shiftThing);
				}
			}
			if ((controls.LEFT_P) && !control) {
				changeSection(curSection - shiftThing);
			}

			if (controls.RIGHT_P && control) {
				if (NoteVariables.beats.indexOf(beatSnap) + 1 <= NoteVariables.beats.length - 1)
					beatSnap = NoteVariables.beats[NoteVariables.beats.indexOf(beatSnap) + 1];
			}

			if (controls.LEFT_P && control) {
				if (NoteVariables.beats.indexOf(beatSnap) - 1 >= 0)
					beatSnap = NoteVariables.beats[NoteVariables.beats.indexOf(beatSnap) - 1];
			}
		}

		_song.bpm = tempBpm;

		if (_song.notes[curSection].bpm <= 0)
			_song.notes[curSection].bpm = 0.1;

		if (Conductor.songPosition < 0)
			Conductor.songPosition = 0;
		if (FlxG.sound.music.time < 0)
			FlxG.sound.music.time = 0;

		#if FLX_PITCH
		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		#end

		bpmTxt.text = ("Time: "
			+ Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSection
			+ "\nBPM: "
			+ Conductor.bpm
			+ "\nCurStep: "
			+ curStep
			+ "\nCurBeat: "
			+ curBeat
			+ "\nCurDecStep: "
			+ FlxMath.roundDecimal(curDecStep, 2)
			+ "\nCurDecBeat: "
			+ FlxMath.roundDecimal(curDecBeat, 2)
			+ "\nNote Snap: "
			+ beatSnap
			+ (FlxG.keys.pressed.SHIFT ? "\n(DISABLED)" : "\n(CONTROL + ARROWS)")
			+ "\nZoom Level: "
			+ zoomLevel
			+ "\n");
		bpmTxt.antialiasing = false;

		leftIcon.x = gridBG.x + GRID_SIZE;
		rightIcon.x = gridBlackLine.x;

		for (n in curRenderedNotes.members) {
			if (n?.animation?.curAnim != null) {
				if (n.isSustainNote && !StringTools.endsWith(n.animation.curAnim.name, "end")) {
					n.setGraphicSize(n.frameWidth * n.scale.x, Math.ceil(zoomLevel * GRID_SIZE));
					n.updateHitbox();
				}
			}
		}

		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void {
		if (curSelectedNote != null) {
			if (curSelectedNote[2] != null) {
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);

				// lol so one e press works as a held note lmao
				curSelectedNote[2] = Math.ceil(curSelectedNote[2]);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for (i in 0...Conductor.bpmChangeMap.length) {
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void {
		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning) {
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void {
		if (_song.notes[sec] != null) {
			curSection = sec;

			if (updateMusic) {
				FlxG.sound.music.pause();
				vocals.pause();

				Conductor.songPosition = FlxG.sound.music.time = vocals.time = sectionStartTime(sec);
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
		}
	}

	static var doFunnyNumbers:Bool = true;

	function copySection(?sectionNum:Int = 1) {
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		if (daSec - sectionNum != curSection) {
			for (note in _song.notes[daSec - sectionNum].sectionNotes) {
				var strum = note[0] + Conductor.stepCrochet * (Conductor.stepsPerSection * sectionNum);

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3], note[4]];
				_song.notes[curSection].sectionNotes.push(copiedNote);
			}
		}

		updateGrid();
	}

	var copiedEvents:Array<Array<Dynamic>> = [];
	var copiedEventsSection:Int = 0;

	function copyEvents(sectionNum:Int = 1) {
		copiedEvents = [];
		for (event in events) {
			if (event[1] >= sectionStartTime() && event[1] < sectionStartTime(sectionNum + 1)) {
				copiedEvents.push(event);
			}
		}
	}

	function pasteEvents() {
		for (event in copiedEvents) {
			var strumTime:Float = sectionStartTime() + (event[1] - sectionStartTime(copiedEventsSection));
			var pastedEvent:Array<Dynamic> = [event[0], strumTime, event[2], event[3]];
			if (!events.contains(pastedEvent)) {
				events.push(pastedEvent);
			}
		}
		updateGrid();
	}

	function pasteSection() {
		var daSec = copiedSection;

		if (daSec != curSection) {
			for (note in _song.notes[daSec].sectionNotes) {
				var strum = sectionStartTime() + (note[0] - sectionStartTime(daSec));

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3], note[4]];
				_song.notes[curSection].sectionNotes.push(copiedNote);
			}
		}

		updateGrid();
	}

	function updateSectionUI():Void {
		var sec = _song.notes[curSection];

		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		check_changeTimeScale.checked = sec.changeTimeScale;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void {
		var healthIconP1:String = _song.player1;
		var healthIconP2:String = _song.player2;

		if (_song.notes[curSection].mustHitSection) {
			leftIcon.setupIcon(healthIconP1);
			rightIcon.setupIcon(healthIconP2);
		} else {
			leftIcon.setupIcon(healthIconP2);
			rightIcon.setupIcon(healthIconP1);
		}

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		leftIcon.updateHitbox();
		rightIcon.updateHitbox();
	}

	function loadHealthIconFromCharacter(char:String) {
		var characterPath:String = 'character data/' + char + '/config';

		var path:String = Paths.json(characterPath);

		if (!Assets.exists(path) && !Assets.exists(Paths.image("icons/" + char, "preload")))
			path = Paths.json('character data/bf/config');
		else if (!Assets.exists(path) && Assets.exists(Paths.image("icons/" + char, "preload")))
			return char;

		var rawJson:String = Assets.getText(path).trim();

		var json:CharacterConfig = cast Json.parse(rawJson);

		return (json.healthIcon ?? char);
	}

	inline function updateNoteUI():Void {
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	var uiSettings:Array<String>;

	function updateGrid():Void {
		remove(gridBG);
		gridBG.kill();
		gridBG.destroy();

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * (_song.keyCount + _song.playerKeyCount + 1),
			Std.int((GRID_SIZE * Conductor.stepsPerSection) * zoomLevel));
		add(gridBG);

		remove(gridBGNext);
		gridBGNext.kill();
		gridBGNext.destroy();

		gridBGNext = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * (_song.keyCount + _song.playerKeyCount + 1),
			Std.int((GRID_SIZE * Conductor.stepsPerSection) * zoomLevel));
		gridBGNext.y += gridBG.height;
		gridBGNext.color = FlxColor.GRAY;
		add(gridBGNext);

		remove(gridBlackLine);
		gridBlackLine.kill();
		gridBlackLine.destroy();

		gridBlackLine = new FlxSprite(gridBG.x
			+ (GRID_SIZE * ((!_song.notes[curSection].mustHitSection ? _song.keyCount : _song.playerKeyCount)
				+ 1))).makeGraphic(2, Std.int(gridBG.height) * 2, FlxColor.BLACK);
		add(gridBlackLine);

		remove(gridEventBlackLine);
		gridEventBlackLine.kill();
		gridEventBlackLine.destroy();

		gridEventBlackLine = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height) * 2, FlxColor.BLACK);
		add(gridEventBlackLine);

		strumLine?.makeGraphic(Std.int(gridBG.width), 4);

		curRenderedNotes.clear();

		curRenderedEvents.clear();

		curRenderedIds.clear();

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song?.notes[curSection + 1]?.sectionNotes != null) {
			sectionInfo = sectionInfo.concat(_song.notes[curSection + 1].sectionNotes);
		}

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
			Conductor.changeBPM(_song.notes[curSection].bpm);
		else {
			// get last bpm
			var daBPM:Float = _song.bpm;

			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;

			Conductor.changeBPM(daBPM);
		}

		for (i in sectionInfo) {
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];

			var daType = i[4];

			if (daType == null)
				daType = "default";

			var mustPress = daNoteInfo >= _song.keyCount;

			if (_song.notes[curSection].mustHitSection)
				mustPress = !(daNoteInfo >= _song.playerKeyCount);

			var goodNoteInfo = daNoteInfo % (mustPress ? _song.playerKeyCount : _song.keyCount);

			if (!_song.notes[curSection].mustHitSection && mustPress)
				goodNoteInfo = daNoteInfo - _song.keyCount;

			if (_song.notes[curSection].mustHitSection && !mustPress)
				goodNoteInfo = daNoteInfo - _song.playerKeyCount;

			var note:Note = new Note(daStrumTime, goodNoteInfo, null, false, 0, daType, _song, [0], mustPress, true);
			note.sustainLength = daSus;

			note.setGraphicSize((Std.parseInt(PlayState.instance.arrow_Configs.get(daType)[4]) ?? Std.parseInt(PlayState.instance.arrow_Configs.get(daType)[4])),
				Std.parseInt(PlayState.instance.arrow_Configs.get(daType)[2]));
			note.updateHitbox();

			note.x = Math.floor((daNoteInfo + 1) * GRID_SIZE) + Std.parseFloat(PlayState.instance.arrow_Configs.get(daType)[1]);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime())) + Std.parseFloat(PlayState.instance.arrow_Configs.get(daType)[3]));
			note.antialiasing = uiSettings[3] == "true";

			note.rawNoteData = daNoteInfo;

			curRenderedNotes.add(note);

			if (doFunnyNumbers && !note.isSustainNote) {
				if (i[3] == null)
					i[3] = 0;

				var id:FlxText = new FlxText(Math.floor((daNoteInfo + 1) * GRID_SIZE), Math.floor(getYfromStrum((daStrumTime - sectionStartTime()))),
					GRID_SIZE, Std.string(i[3]).replace("[", "").replace("]", ""), 16);
				id.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
				id.font = Paths.font("vcr.ttf");

				var idIcon:FlxSprite = new FlxSprite(Math.floor((daNoteInfo + 1) * GRID_SIZE) - 16,
					Math.floor(getYfromStrum((daStrumTime - sectionStartTime()))) - 12);
				idIcon.loadGraphic(Paths.gpuBitmap("charter/idSprite", "shared"));
				idIcon.setGraphicSize(20, 20);
				idIcon.updateHitbox();
				idIcon.antialiasing = false;

				curRenderedIds.add(idIcon);
				curRenderedIds.add(id);
			}

			var sustainGroup:Array<Note> = [];
			for (susNote in 0...Math.floor(note.sustainLength / Std.int(Conductor.stepCrochet))) {
				var oldNote = curRenderedNotes.members[curRenderedNotes.members.length - 1];
				var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, goodNoteInfo, oldNote, true, 0,
					daType, _song, [0], mustPress, true);
				sustainNote.scale.set(note.scale.x, note.scale.y);
				sustainNote.antialiasing = uiSettings[3] == "true";
				sustainNote.updateHitbox();
				sustainNote.x = note.x + (GRID_SIZE / 2) - Std.parseFloat(PlayState.instance.arrow_Configs.get(daType)[1]) - sustainNote.width / 2;
				sustainNote.y = note.height
					+ Math.floor(getYfromStrum((oldNote.strumTime - sectionStartTime())) + Std.parseFloat(PlayState.instance.arrow_Configs.get(daType)[3]));
				curRenderedNotes.add(sustainNote);

				sustainGroup.push(sustainNote);
				sustainNote.sustains = sustainGroup;
			}
			note.sustains = sustainGroup;
		}

		if (colorQuantization) {
			Note.applyColorQuants(curRenderedNotes.members);
		}

		if (events.length >= 1) {
			for (event in events) {
				if (Std.int(event[1]) >= Std.int(sectionStartTime()) && Std.int(event[1]) < Std.int(sectionStartTime(curSection + 1))) {
					var eventSprite:EventSprite = new EventSprite(event);

					eventSprite.y = Math.floor(getYfromStrum((event[1] - sectionStartTime()) % (Conductor.stepCrochet * Conductor.stepsPerSection)));

					curRenderedEvents.add(eventSprite);
				}
			}
		}
	}

	var events:Array<Array<Dynamic>> = [];

	function addSection(?coolLength:Int = 0):Void {
		var col:Int = Conductor.stepsPerSection;

		if (coolLength == 0)
			col = Std.int(Conductor.timeScale[0] * Conductor.timeScale[1]);

		var sec:Section = {
			sectionNotes: [],
			lengthInSteps: col,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			altAnim: false,
			changeTimeScale: false,
			timeScale: Conductor.timeScale
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void {
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes) {
			if (i.strumTime == note.strumTime && i.noteData % _song.keyCount == note.noteData) {
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum++;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void {
		for (i in _song.notes[curSection].sectionNotes) {
			if (i[0] == note.strumTime && i[1] == note.rawNoteData)
				_song.notes[curSection].sectionNotes.remove(i);
		}

		updateGrid();
	}

	function selectEvent(event:EventSprite):Void {
		var swagNum:Int = 0;

		for (i in events) {
			if (i[1] == event.strumTime) {
				curSelectedEvent = events[swagNum];

				eventValue1 = Std.string(curSelectedEvent[2]);
				eventValue2 = Std.string(curSelectedEvent[3]);

				value1.text = eventValue1;
				value2.text = eventValue2;

				if (eventList.indexOf(curSelectedEvent[0]) == -1)
					eventDropDown.selectedLabel = eventList[0];
				else
					eventDropDown.selectedLabel = curSelectedEvent[0];

				if (eventList.indexOf(curSelectedEvent[0]) == -1)
					curEvent = 0;
				else
					curEvent = eventList.indexOf(curSelectedEvent[0]);

				valueDescriptions.text = "Value 1 - " + eventListData[curEvent][1] + "\nValue 2 - " + eventListData[curEvent][2] + "\n";

				eventName = curSelectedEvent[0];
			}

			swagNum++;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteEvent(event:EventSprite):Void {
		for (i in events) {
			if (i[1] == event.strumTime)
				events.remove(i);
		}

		updateGrid();
	}

	function clearSection():Void {
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSectionSide(side:Int = 0):Void {
		var removeThese = [];

		for (noteIndex in 0..._song.notes[curSection].sectionNotes.length) {
			if (side == 0) {
				if (_song.notes[curSection].sectionNotes[noteIndex][1] < _song.keyCount) {
					removeThese.push(_song.notes[curSection].sectionNotes[noteIndex]);
				}
			} else if (side == 1) {
				if (_song.notes[curSection].sectionNotes[noteIndex][1] >= _song.keyCount) {
					removeThese.push(_song.notes[curSection].sectionNotes[noteIndex]);
				}
			}
		}

		if (removeThese != []) {
			for (x in removeThese) {
				_song.notes[curSection].sectionNotes.remove(x);
			}

			updateGrid();
		}
	}

	function characterSectionSide(side:Int = 0, character:Int = 0):Void {
		var changeThese = [];

		var charactersArray:Array<Int> = [];

		if (characterGroup_Input.text != "" && characterGroup_Input.text != " ") {
			var yes = characterGroup_Input.text.split(",");

			for (char in yes) {
				charactersArray.push(Std.parseInt(char));
			}
		}

		for (noteIndex in 0..._song.notes[curSection].sectionNotes.length) {
			var noteData = _song.notes[curSection].sectionNotes[noteIndex][1];

			if (side == 0) {
				if (noteData < _song.keyCount) {
					changeThese.push(noteIndex);
				}
			} else if (side == 1) {
				if (noteData >= _song.keyCount) {
					changeThese.push(noteIndex);
				}
			}
		}

		if (changeThese != []) {
			for (x in changeThese) {
				if (charactersArray.length < 1)
					_song.notes[curSection].sectionNotes[x][3] = character;
				else
					_song.notes[curSection].sectionNotes[x][3] = charactersArray;
			}

			updateGrid();
		}
	}

	var eventName:String = "Change Character";
	var eventValue1:String = "Dad";
	var eventValue2:String = "spooky";

	private function addNote():Void {
		if (_song.notes[curSection] == null)
			addSection();

		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x / GRID_SIZE) - 1);
		var noteSus = 0;
		if (noteData > -1) {
			var characters:Array<Int> = [];

			if (characterGroup_Input.text != "" && characterGroup_Input.text != " ") {
				var yes = characterGroup_Input.text.split(",");

				for (char in yes) {
					characters.push(Std.parseInt(char));
				}
			}

			if (cur_Note_Type != "default" && cur_Note_Type != null)
				_song.notes[curSection].sectionNotes.push([
					noteStrum,
					noteData,
					noteSus,
					(characters.length <= 0 ? current_Note_Character : characters),
					cur_Note_Type
				]);
			else
				_song.notes[curSection].sectionNotes.push([
					noteStrum,
					noteData,
					noteSus,
					(characters.length <= 0 ? current_Note_Character : characters)
				]);

			curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

			if (FlxG.keys.pressed.CONTROL) {
				if (cur_Note_Type != "default")
					_song.notes[curSection].sectionNotes.push([
						noteStrum,
						(noteData + _song.keyCount) % (_song.keyCount + _song.playerKeyCount),
						noteSus,
						current_Note_Character,
						cur_Note_Type
					]);
				else
					_song.notes[curSection].sectionNotes.push([
						noteStrum,
						(noteData + _song.keyCount) % (_song.keyCount + _song.playerKeyCount),
						noteSus,
						current_Note_Character
					]);
			}
		} else {
			events.push([eventName, noteStrum, eventValue1, eventValue2]);

			curSelectedEvent = events[events.length - 1];
		}

		updateGrid();
		updateNoteUI();
	}

	inline function getStrumTime(yPos:Float):Float {
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, Conductor.stepsPerSection * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float {
		return FlxMath.remapToRange(strumTime * zoomLevel, 0, (Conductor.stepsPerSection * zoomLevel) * Conductor.stepCrochet, gridBG.y,
			gridBG.y + gridBG.height);
	}

	function loadJson(song:String, ?diff:String):Void {
		PlayState.storyDifficultyStr = diff;
		PlayState.SONG = SongLoader.loadFromJson(diff, song);

		#if NO_PRELOAD_ALL
		LoadingState.instance.checkLoadSong(LoadingState.getSongPath());

		if (PlayState.SONG.needsVoices)
			LoadingState.instance.checkLoadSong(LoadingState.getVocalPath());
		#end

		FlxG.sound.music.stop();
		vocals.stop();

		FlxG.resetState();
	}

	function loadChart():Void {
		var fileOpen:FileDialog = new FileDialog();
		fileOpen.browse(OPEN, "json", Sys.getCwd(), "Select A Chart File");
		fileOpen.onSelect.add((data) -> {
			try {
				var parsedJson:Dynamic = SongLoader.parseLegacy(Json.parse(File.getContent(data)));
				if (!Reflect.hasField(parsedJson, "song")) {
					CoolUtil.coolError('Leather Engine Chart Editor', 'Invalid chart at path $data');
				} else {
					if (Reflect.hasField(parsedJson.song, "events") && !Reflect.hasField(parsedJson.song, "notes")) {
						CoolUtil.coolError('Leather Engine Chart Editor', 'Invalid chart at path $data\nDid you try and load an events file?');
					} else {
						PlayState.SONG = parsedJson;
						FlxG.resetState();
					}
				}
			} catch (e) {
				CoolUtil.coolError('Leather Engine Chart Editor', 'Invalid chart at path $data');
			}
		});
	}

	private function saveLevel(saveEvents:Bool = false) {
		var json:Dynamic;

		if (saveEvents)
			json = {
				"song": {
					"events": []
				}
			};
		else
			json = {"song": _song};

		if (!saveEvents)
			json.song.events = [];
		else
			json.song.events = events;

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0)) {
			fileDialogue = new FileReference();
			fileDialogue.addEventListener(Event.COMPLETE, onSaveComplete);
			fileDialogue.addEventListener(Event.CANCEL, onSaveCancel);
			fileDialogue.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			var gamingName = _song.song.toLowerCase();

			if (difficulty.toLowerCase() != 'normal')
				gamingName = gamingName + '-' + difficulty.toLowerCase();

			if (saveEvents)
				gamingName = "events";

			fileDialogue.save(data.trim(), gamingName + ".json");
		}
	}

	function onSaveComplete(_):Void {
		fileDialogue.removeEventListener(Event.COMPLETE, onSaveComplete);
		fileDialogue.removeEventListener(Event.CANCEL, onSaveCancel);
		fileDialogue.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		fileDialogue = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		fileDialogue.removeEventListener(Event.COMPLETE, onSaveComplete);
		fileDialogue.removeEventListener(Event.CANCEL, onSaveCancel);
		fileDialogue.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		fileDialogue = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		fileDialogue.removeEventListener(Event.COMPLETE, onSaveComplete);
		fileDialogue.removeEventListener(Event.CANCEL, onSaveCancel);
		fileDialogue.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		fileDialogue = null;
		FlxG.log.error("Problem saving Level data");
	}
}
