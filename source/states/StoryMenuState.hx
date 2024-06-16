package states;

#if DISCORD_ALLOWED
import utilities.Discord.DiscordClient;
#end

import substates.ResetScoreSubstate;
import lime.app.Application;
import lime.utils.Assets;
import haxe.Json;
import ui.MenuCharacter;
import ui.MenuItem;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import game.Song;
import game.Highscore;

using StringTools;

class StoryMenuState extends MusicBeatState {
	/* WEEK GROUPS */
	static var groupIndex:Int = 0;

	var groups:Array<StoryGroup> = [];

	var currentGroup:StoryGroup;

	/* WEEK VARIABLES */
	static var curWeek:Int = 0;
	static var curDifficulty:Int = 1;

	var curDifficulties:Array<Array<String>> = [["easy", "default/easy"], ["normal", "default/normal"], ["hard", "default/hard"]];
	var defaultDifficulties:Array<Array<String>> = [["easy", "default/easy"], ["normal", "default/normal"], ["hard", "default/hard"]];

	/* TEXTS */
	var weekScoreText:FlxText;
	var weekTitleText:FlxText;
	var weekSongListText:FlxText;

	var groupSwitchText:FlxText;

	/* UI */
	var yellowBG:FlxSprite;
	var bgSprite:FlxSprite;

	var weekGraphics:FlxTypedGroup<MenuItem>;
	var menuCharacters:FlxTypedGroup<MenuCharacter>;

	/* DIFFICULTY UI */
	var difficultySelectorGroup:FlxGroup;

	var difficultySprite:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	override function create():Void {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			TitleState.playTitleMusic();

		// UPDATE TITLE WINDOW JUST IN CASE LOL //
		MusicBeatState.windowNameSuffix = " Story Menu";

		// SETUP THE GROUPS //
		loadGroups();

		// CREATE THE UI //
		createStoryUI();

		addVirtualPad(LEFT_FULL, A_B_X_Y);

		super.create();
	}

	override function update(elapsed:Float) {

		#if MODDING_ALLOWED
		if(virtualPad.buttonY.justPressed || FlxG.keys.justPressed.TAB){
			openSubState(new modding.SwitchModSubstate());
			persistentUpdate = false;
		}
		#end
		
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		weekScoreText.text = "WEEK SCORE:" + lerpScore;

		weekTitleText.x = FlxG.width - (weekTitleText.width + 10);

		if (!movedBack) {
			if (!selectedWeek) {
				if (-1 * Math.floor(FlxG.mouse.wheel) != 0)
					changeWeek(-1 * Math.floor(FlxG.mouse.wheel));

				if (controls.UP_P)
					changeWeek(-1);
				if (controls.DOWN_P)
					changeWeek(1);

				if (controls.RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P)
					changeDifficulty(1);
				if (controls.LEFT_P)
					changeDifficulty(-1);

				if (FlxG.keys.justPressed.E)
					changeGroup(1);
				if (FlxG.keys.justPressed.Q)
					changeGroup(-1);

				if (virtualPad.buttonX.justPressed || controls.RESET) {
					persistentUpdate = false;
					openSubState(new ResetScoreSubstate("nonelolthisisweekslmao", curDifficulties[curDifficulty][0], curWeek, currentGroup.pathName + "Week",
						true));
					changeWeek();
				}
			}

			if (controls.ACCEPT)
				selectWeek();
		}

		if (controls.BACK && !movedBack && !selectedWeek) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	override function closeSubState() {
		changeWeek();
		persistentUpdate = true;
		removeVirtualPad();
		addVirtualPad(LEFT_FULL, A_B_X_Y);
		FlxG.mouse.visible = false;
		super.closeSubState();
	}

	function createStoryUI() {
		weekScoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		weekScoreText.setFormat("VCR OSD Mono", 32);

		weekTitleText = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		weekTitleText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		weekTitleText.alpha = 0.7;

		yellowBG = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, FlxColor.WHITE);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.visible = false;

		menuCharacters = new FlxTypedGroup<MenuCharacter>();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Story Menus", null);
		#end

		addWeekCharacters();

		var coverUp:FlxSprite = new FlxSprite(0, 456).makeGraphic(400, 1280, FlxColor.BLACK);
		weekGraphics = new FlxTypedGroup<MenuItem>();

		add(weekGraphics);
		add(yellowBG);
		add(bgSprite);

		add(menuCharacters);
		add(coverUp);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		createWeekGraphics();

		difficultySelectorGroup = new FlxGroup();
		add(difficultySelectorGroup);

		var arrow_Tex = Paths.getSparrowAtlas('campaign menu/ui_arrow');

		leftArrow = new FlxSprite(weekGraphics.members[0].x + weekGraphics.members[0].width + 10, weekGraphics.members[0].y + 10);
		leftArrow.frames = arrow_Tex;
		leftArrow.animation.addByPrefix('idle', "arrow0");
		leftArrow.animation.addByPrefix('press', "arrow push", 24, false);
		leftArrow.animation.play('idle');

		difficultySprite = new FlxSprite(leftArrow.x + leftArrow.width + 4, leftArrow.y);
		difficultySprite.loadGraphic(Paths.image("campaign menu/difficulties/default/normal"));
		difficultySprite.updateHitbox();
		changeDifficulty();

		rightArrow = new FlxSprite(difficultySprite.x + difficultySprite.width + 4, leftArrow.y);
		rightArrow.frames = arrow_Tex;
		rightArrow.animation.addByPrefix('idle', 'arrow0');
		rightArrow.animation.addByPrefix('press', "arrow push", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.flipX = true;

		difficultySelectorGroup.add(leftArrow);
		difficultySelectorGroup.add(difficultySprite);
		difficultySelectorGroup.add(rightArrow);

		weekSongListText = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		weekSongListText.alignment = CENTER;
		weekSongListText.font = weekTitleText.font;
		weekSongListText.color = 0xFFe55777;
		add(weekSongListText);
		add(weekScoreText);
		add(weekTitleText);

		groupSwitchText = new FlxText(leftArrow.x, difficultySprite.y + difficultySprite.height + 48, 0, "< DEFAULT >", 32);
		groupSwitchText.alignment = CENTER;
		groupSwitchText.font = weekSongListText.font;
		groupSwitchText.color = FlxColor.WHITE;
		groupSwitchText.borderStyle = OUTLINE;
		groupSwitchText.borderColor = FlxColor.BLACK;
		groupSwitchText.borderSize = 1;
		add(groupSwitchText);

		var groupInfoText = new FlxText(leftArrow.x, difficultySprite.y + difficultySprite.height + 96, 0,
			"Q + E to change groups\nRESET to reset week score\n", 24);
		groupInfoText.alignment = LEFT;
		groupInfoText.font = weekSongListText.font;
		groupInfoText.color = FlxColor.WHITE;
		groupInfoText.borderStyle = OUTLINE;
		groupInfoText.borderColor = FlxColor.BLACK;
		groupInfoText.borderSize = 1;
		add(groupInfoText);

		changeWeek();
		changeGroup();
	}

	function addWeekCharacters() {
		for (char in 0...3) {
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, currentGroup.weeks[curWeek].characters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.antialiasing = true;
			menuCharacters.add(weekCharacterThing);
		}
	}

	function createWeekGraphics() {
		weekGraphics.forEachAlive(function(item:MenuItem) {
			item.kill();
			item.destroy();
		});

		weekGraphics.clear();

		for (i in 0...groups[groupIndex].weeks.length) {
			var selectedGroup = groups[groupIndex];

			var weekGraphic:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, selectedGroup.weeks[i].imagePath, selectedGroup.pathName);
			weekGraphic.y += ((weekGraphic.height + 20) * i);
			weekGraphic.targetY = i;

			weekGraphics.add(weekGraphic);

			weekGraphic.screenCenter(X);
			weekGraphic.antialiasing = true;
		}

		if (leftArrow != null) {
			leftArrow.x = weekGraphics.members[0].x + weekGraphics.members[0].width + 10;
			difficultySprite.x = leftArrow.x + leftArrow.width + 4;
			rightArrow.x = difficultySprite.x + difficultySprite.width + 4;
		}
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek() {
		PlayState.storyPlaylist = currentGroup.weeks[curWeek].songs;
		var dif:String = curDifficulties[curDifficulty][0].toLowerCase();

		var song_name:String = PlayState.storyPlaylist[0].toLowerCase();
		var song_file:String = song_name + (dif == "normal" ? "" : "-" + dif);

		if (!stopspamming && Assets.exists(Paths.json('song data/${song_name}/${song_file}'))) {
			FlxG.sound.play(Paths.sound('confirmMenu'));

			if (Options.getData("flashingLights"))
				weekGraphics.members[curWeek].startFlashing();

			menuCharacters.members[1].character = menuCharacters.members[1].character + 'Confirm';
			menuCharacters.members[1].loadCharacter();

			stopspamming = true;

			PlayState.isStoryMode = true;
			selectedWeek = true;

			PlayState.SONG = Song.loadFromJson(song_file, song_name);
			PlayState.storyWeek = curWeek;
			PlayState.storyDifficultyStr = dif.toUpperCase();
			PlayState.campaignScore = 0;
			PlayState.groupWeek = currentGroup.pathName;
			PlayState.songMultiplier = 1;

			new FlxTimer().start(1, function(tmr:FlxTimer) {
				PlayState.loadChartEvents = true;
				LoadingState.loadAndSwitchState(new PlayState());
			});
		} else if (!Assets.exists(Paths.json('song data/${song_name}/${song_file}')))
			CoolUtil.coolError('Error: ${Paths.json('song data/${song_name}/${song_file}')} not found!', "Leather Engine Crash Prevention");
	}

	function changeDifficulty(change:Int = 0):Void {
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, curDifficulties.length - 1);

		difficultySprite.loadGraphic(Paths.image("campaign menu/difficulties/" + curDifficulties[curDifficulty][1]));
		difficultySprite.updateHitbox();
		difficultySprite.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		difficultySprite.x = leftArrow.x + leftArrow.width + 4;
		difficultySprite.y = leftArrow.y - (difficultySprite.height - leftArrow.height) - 40;

		if (rightArrow != null)
			rightArrow.x = difficultySprite.x + difficultySprite.width + 4;

		if (currentGroup != null) {
			if (currentGroup.weeks.length - 1 >= curWeek) {
				var offsets = currentGroup.weeks[curWeek].difficultyOffsets;

				if (offsets != null) {
					var difficulty = curDifficulties[curDifficulty][0];

					if (offsets.exists(difficulty)) {
						difficultySprite.x += offsets.get(difficulty)[0];
						difficultySprite.y += offsets.get(difficulty)[1];
					}
				}
			}
		}

		intendedScore = Highscore.getWeekScore(curWeek, curDifficulties[curDifficulty][0], currentGroup.pathName + "Week");

		FlxTween.tween(difficultySprite, {y: difficultySprite.y + 30, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void {
		curWeek = FlxMath.wrap(curWeek + change, 0, currentGroup.weeks.length - 1);

		var bullShit:Int = 0;

		for (item in weekGraphics.members) {
			item.targetY = bullShit - curWeek;
			item.alpha = item.targetY == 0 ? 1.0 : 0.6;
			bullShit++;
		}

		if (currentGroup.weeks[curWeek].difficulties == null)
			curDifficulties = defaultDifficulties;
		else
			curDifficulties = currentGroup.weeks[curWeek].difficulties;

		changeDifficulty();

		FlxG.sound.play(Paths.sound('scrollMenu'));
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulties[curDifficulty][0], currentGroup.pathName + "Week");

		if (currentGroup.weeks[curWeek].backgroundImage != null) {
			bgSprite.loadGraphic(Paths.image('campaign menu/backgrounds/${currentGroup.weeks[curWeek].backgroundImage}'));
			bgSprite.setGraphicSize(0, 400);
			bgSprite.visible = true;
		} else
			bgSprite.visible = false;

		updateText();
	}

	function changeGroup(change:Int = 0) {
		groupIndex += change;

		if (groupIndex >= groups.length)
			groupIndex = 0;
		if (groupIndex < 0)
			groupIndex = groups.length - 1;

		if (change != 0)
			curWeek = 0;

		currentGroup = groups[groupIndex];

		createWeekGraphics();
		changeWeek();
	}

	function updateText():Void {
		groupSwitchText.text = "<  " + currentGroup.groupName + "  >";
		var curGroupWeek:StoryWeek = currentGroup.weeks[curWeek];

		// Reloads menu characters
		for (characterIndex in 0...menuCharacters.members.length) {
			var character = menuCharacters.members[characterIndex];

			// performance or something i guess
			if (character.character != curGroupWeek.characters[characterIndex]) {
				character.character = curGroupWeek.characters[characterIndex];
				character.loadCharacter();
			}
		}

		weekSongListText.text = "Tracks\n\n";
		weekTitleText.text = curGroupWeek.weekTitle;

		for (i in curGroupWeek.songs) {
			weekSongListText.text += i + "\n";
		}

		weekSongListText.screenCenter(X);
		weekSongListText.x -= FlxG.width * 0.35;
		weekSongListText.text = weekSongListText.text.toUpperCase();

		var bgColor:FlxColor = FlxColor.WHITE;

		if (curGroupWeek.backgroundColor != null) {
			var arrayColor = curGroupWeek.backgroundColor;
			bgColor = FlxColor.fromRGB(arrayColor[0], arrayColor[1], arrayColor[2]);
		} else
			bgColor = FlxColor.fromRGB(249, 207, 81);

		yellowBG.color = bgColor;
	}

	function loadJSON(name:String):Void {
		if (Assets.exists(Paths.json("week data/" + name))) {
			var group:StoryGroup = cast Json.parse(Assets.getText(Paths.json("week data/" + name)));

			for (week in group.weeks) {
				var offsets:Map<String, Array<Float>> = [];

				if (week.difficultyOffsets != null) {
					var week_offsets:Array<Array<Dynamic>> = week.difficultyOffsets;

					for (offset in week_offsets) {
						offsets.set(offset[0], offset[1]);
					}
				}

				week.difficultyOffsets = offsets;
			}

			groups.push(group);
		} else
			trace('Tried to load json ${Paths.json("week data/" + name)} that doesn\'t exist!', ERROR);
	}

	function loadGroups():Void {
		for (week in CoolUtil.coolTextFile(Paths.txt("storyWeekList")))
			loadJSON(week);

		currentGroup = groups[0];
	}
}

typedef StoryGroup = {
	var groupName:String;
	var pathName:String;
	var weeks:Array<StoryWeek>;
}

typedef StoryWeek = {
	var imagePath:String;
	var songs:Array<String>;
	var characters:Array<String>;
	var weekTitle:String;

	var backgroundColor:Array<Int>;
	var ?backgroundImage:Null<String>;
	var difficulties:Null<Array<Array<String>>>;
	var difficultyOffsets:Null<Dynamic>;
}
