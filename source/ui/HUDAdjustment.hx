package ui;

#if DISCORD_ALLOWED
import utilities.Discord.DiscordClient;
#end

import flixel.addons.ui.FlxUISlider;
import flixel.tweens.FlxTween;
import utilities.Ratings;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.math.FlxMath;
import flixel.FlxObject;
import states.MainMenuState;
import game.Boyfriend;
import flixel.FlxG;
import game.Character;
import flixel.FlxSprite;
import game.StageGroup;
import flixel.FlxCamera;
import states.MusicBeatState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

class HUDAdjustment extends MusicBeatState {
    /* OPTIONS */
    var ui_settings:Array<String>;
	var reset:FlxButton;

	/*STAGE*/
	var stage:StageGroup;
	var stages:Array<String>;

    /* CHARACTER*/  
    var bf:Boyfriend;
    var gf:Character;
    var characters:Map<String, Array<String>> = ["default" => ["bf", "gf"]];

    /* RATINGS */
    var ratingsGroup:FlxSpriteGroup = new FlxSpriteGroup();
    var rating:FlxSprite = new FlxSprite();
    var numbers:Array<FlxSprite> = [];
    var uiMap:Map<String, FlxGraphic> = [];
    var combo:Int = 123;

    var ratingPos:FlxSprite;
	var comboPos:FlxSprite;

    var selectedObject:Int = 0;
    var selectedThing:Bool = false;
	var selected:Dynamic;

    override function create() {
        FlxG.mouse.visible = true;

        #if DISCORD_ALLOWED
		DiscordClient.changePresence("Changing HUD Settings", null, null, true);
		#end

		FlxG.cameras.reset();

		if (FlxG.sound.music.active) {
			FlxG.sound.music.stop();
		}

        gf = new Character(400, 130, "gf");
        bf = new Boyfriend(770, 450, "bf");

		reloadStage();

		FlxG.sound.playMusic(Paths.music('breakfast'));
		add(ratingsGroup);

        ui_settings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + Options.getData("uiSkin") + "/config"));
        uiMap.set("marvelous", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + Options.getData("uiSkin") + "/ratings/marvelous")));

		uiMap.set('1', FlxGraphic.fromAssetKey(Paths.image("ui skins/" + Options.getData("uiSkin") + "/numbers/num1"), false, null, false));
		uiMap.set('2', FlxGraphic.fromAssetKey(Paths.image("ui skins/" + Options.getData("uiSkin") + "/numbers/num2"), false, null, false));
		uiMap.set('3', FlxGraphic.fromAssetKey(Paths.image("ui skins/" + Options.getData("uiSkin") + "/numbers/num3"), false, null, false));

		popUpScore();
		rating.loadGraphic(uiMap.get('marvelous'));

		ratingPos = new FlxSprite(Options.getData("ratingsSettings")[0], Options.getData("ratingsSettings")[1]);
		ratingPos.makeGraphic(32, 32, FlxColor.RED);
		ratingPos.updateHitbox();
		add(ratingPos);

		comboPos = new FlxSprite(Options.getData("comboSettings")[0], Options.getData("comboSettings")[1]);
		comboPos.makeGraphic(32, 32, FlxColor.BLUE);
		comboPos.updateHitbox();
		add(comboPos);

        reset = new FlxButton(0, FlxG.height, "RESET", () -> {
			comboPos.screenCenter();
			ratingPos.screenCenter();
			rating.screenCenter();
			trace(rating.x);
			trace(rating.y);
			Options.setData([comboPos.x, comboPos.y, 1, 1], "comboSettings");
			Options.setData([ratingPos.x, ratingPos.y, 1, 1], "ratingsSettings");
			trace("reset");
			popUpScore();
		});

		reset.y -= reset.height;
		add(reset);

		addVirtualPad(NONE, B);

		super.create();
    }

    override function update(elapsed:Float) {
        if (FlxG.mouse.overlaps(ratingPos) && FlxG.mouse.pressed && !selectedThing) {
			selectedThing = true;
			selected = ratingPos;

			selectedObject = 0;
		} else if (FlxG.mouse.overlaps(comboPos) && FlxG.mouse.pressed && !selectedThing) {
			selectedThing = true;
			selected = comboPos;

			selectedObject = 0;
		}
	 	else if (!FlxG.mouse.pressed)
			selectedThing = false;

        if (FlxG.mouse.pressed && selectedThing) {
			selected.x = FlxG.mouse.x - (selected.width / 2);
			selected.y = FlxG.mouse.y - (selected.height / 2);
			popUpScore();
        }

        if (virtualPad.buttonB.justPressed || FlxG.keys.anyJustPressed([ESCAPE, BACKSPACE])) {
            FlxG.switchState(new MainMenuState());
		}

        if (selected == ratingPos)
            Options.setData([ratingPos.x, ratingPos.y, 1, 1], "ratingsSettings");

		if (selected == comboPos)
            Options.setData([comboPos.x, comboPos.y, 1, 1], "comboSettings");

        super.update(elapsed);
    }

    function reloadStage() {
		clear();

		stage = new StageGroup('stage');
		add(stage);

		add(gf);
		add(stage.infrontOfGFSprites);

		add(bf);
		add(stage.foregroundSprites);
	}

    public function popUpScore():Void {
        rating.x = Options.getData("ratingsSettings")[0];
		rating.x -= Options.getData("middlescroll") ? 350 : 0;
		rating.y = Options.getData("ratingsSettings")[1];
		rating.y -= 60;
		rating.scale.y = rating.scale.x = Std.parseFloat(ui_settings[0]) * Std.parseFloat(ui_settings[4]);
		rating.updateHitbox();
		rating.antialiasing = ui_settings[3] == "true";
		var scoreStrings:Array<String> = Std.string(combo).split('');

		for (i in 0...scoreStrings.length) {
			if (numbers.length - 1 < i) {
				numbers.push(new FlxSprite());
			}

			var numScore = numbers[i];
			numScore.loadGraphic(uiMap.get(scoreStrings[i]));

			numScore.x = Options.getData("comboSettings")[0];
			numScore.y = Options.getData("comboSettings")[1];
			numScore.x -= Options.getData("middlescroll") ? 350 : 0;

			numScore.x += (43 * i) - 90;
			numScore.y += 80;

			numScore.scale.y = numScore.scale.x = Std.parseFloat(ui_settings[1]);
			numScore.updateHitbox();

			numScore.antialiasing = ui_settings[3] == "true";

			ratingsGroup.add(numScore);
		}
	}
}