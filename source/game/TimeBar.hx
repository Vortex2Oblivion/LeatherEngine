package game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import game.SongLoader;
import states.PlayState;

/**
 * Group that contains all the elemends of the time bar.
 */
class TimeBar extends FlxSpriteGroup{

    /**
     * The bg of the time bar
     */
    public var bg:FlxSprite = new FlxSprite();

    /**
     * The actual bar.
     */
    public var bar:FlxBar;

    /**
     * The text that displays over the time bar
     * Usually the time left or the song name or both.
     */
    public var text:FlxText;

    /**
     * The time of the bar in milliseconds.
     */
    public var time:Float = 0;


    // TODO: Make getters / setters for these variables that update the time bar when changed.

    /**
     * The left bar color.
     */
    public var barColorLeft:FlxColor = FlxColor.BLACK;

    /**
     * The right bar color.
     */
    public var barColorRight:FlxColor = FlxColor.WHITE;

    /**
     * The number of divisions of the time bar.
     */
    public var divisions:Int = 400;


    /**
     * Creates a new time bar instance.
     * @param song The song data used on the time bar
     * @param difficulty The difficulty to display for time bar styles that use it.
     */
    override public function new(song:SongData, difficulty:String = "NORMAL"){
        super();

        bg.screenCenter(X);
        bg.scrollFactor.set();

        text = new FlxText(0, 0, 0, '${song.song} - $difficulty${Options.getData('botplay') ? ' (BOT)' : ''}');
		text.setFormat(Paths.font("vcr.ttf"), Options.getData("biggerInfoText") ? 20 : 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.screenCenter(X);
		text.scrollFactor.set();
		text.antialiasing = Options.getData("antialiasing");

        // Sets up the time bar according to the style of the time bar.
        switch (Options.getData("timeBarStyle").toLowerCase()){
            default:
                bg.loadGraphic(Paths.image('ui skins/${song.ui_Skin}/other/healthBar'));
                text.y = bg.y = Options.getData("downscroll") ? FlxG.height - (bg.height + 1) : 1;

            case 'psych engine':
                bg.makeGraphic(400, 19, FlxColor.BLACK);
                bg.y = Options.getData("downscroll") ? FlxG.height - 36 : 10;
                divisions = 800;

                text.borderSize = Options.getData("biggerInfoText") ? 2 : 1.5;
				text.size = Options.getData("biggerInfoText") ? 32 : 20;
				text.y = bg.y - (text.height / 4);

            case 'old kade engine':
                bg.loadGraphic(Paths.image('ui skins/${song.ui_Skin}/other/healthBar'));
                barColorLeft = FlxColor.GRAY;
                barColorRight = FlxColor.LIME;
                text.y = bg.y = Options.getData("downscroll") ? FlxG.height * 0.9 + 45 : 10;
        }

        bar = new FlxBar(0, bg.y + 4, LEFT_TO_RIGHT, Std.int(bg.width - 8), Std.int(bg.height - 8), this,'time', 0, FlxG.sound.music.length);
        bar.numDivisions = divisions;
        bar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);

        bar.screenCenter(X);
        bar.scrollFactor.set();

        bar.createFilledBar(barColorLeft, barColorRight);

        add(bg);
        add(bar);
        add(text);
    }

}