package substates;

import shaders.NoteColors;
import game.StrumNote;
import utilities.PlayerSettings;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import utilities.NoteVariables;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import lime.utils.Assets;

class NoteColorSubstate extends MusicBeatSubstate
{
    var key_Count:Int = 4;
    var arrow_Group:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();

    public var ui_settings:Array<String>;
    public var mania_size:Array<String>;
    public var mania_offset:Array<String>;

    public var arrow_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();

    var selectedControl:Int = 0;
    var selectingStuff:Bool = false;

    var coolText:FlxText = new FlxText(0,25,0,"Use UP and DOWN to change number of keys\nLEFT and RIGHT to change arrow selected\nRed: 0, Green: 0, Blue: 0\n", 32);

    var mania_gap:Array<String>;

    var selectedValue:Int = 0; // 0 = red, 1 = green, 2 = blue

    var current_ColorVals:Array<Int> = [255,0,0];

    final colorMins:Array<Int> = [0, 0, 0];
    final colorMaxs:Array<Int> = [255, 255, 255];

    public function new()
    {
        ui_settings = CoolUtil.coolTextFile(Paths.txt("ui skins/default/config"));
        mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniasize"));
        mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniaoffset"));
        mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

        arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("ui skins/default/default")));

        super();

        coolText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        coolText.screenCenter(X);
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        #if PRELOAD_ALL
        create_Arrows();
        add(arrow_Group);
        #else
        Assets.loadLibrary("shared").onComplete(function (_) {
            create_Arrows();
            add(arrow_Group);
        });
        #end
        
        add(coolText);

        updateColorValsBase();
        update_Text();

        addVirtualPad(LEFT_FULL, A_B_C);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
        var upP = controls.UP_P;
		var downP = controls.DOWN_P;
        var accept = controls.ACCEPT;
        var reset = virtualPad.buttonC.justPressed || controls.RESET;
        var back = controls.BACK;

        if(arrow_Group != null)
        {
            if(reset)
            {
                current_ColorVals = NoteColors.defaultColors.get(NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][selectedControl]);

                arrow_Group.members[selectedControl].colorSwap.r = current_ColorVals[0];
                arrow_Group.members[selectedControl].colorSwap.g = current_ColorVals[1];
                arrow_Group.members[selectedControl].colorSwap.b = current_ColorVals[2];

                NoteColors.setNoteColor(NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][selectedControl], current_ColorVals);
            }

            if(back && selectingStuff)
                selectingStuff = false;
            else if(back)
            {
                FlxG.mouse.visible = false;
                states.OptionsMenu.instance.closeSubState();
                removeVirtualPad();
            }
    
            for(x in arrow_Group)
            {
                if(x.ID == selectedControl && accept && !selectingStuff)
                {
                    selectedControl = x.ID;
                    selectingStuff = true;
                }
    
                if(x.ID == selectedControl)
                    x.alpha = 1;
                else
                    x.alpha = 0.6;
            }
    
            if(!selectingStuff && (upP || downP))
            {
                if(downP)
                    key_Count --;
    
                if(upP)
                    key_Count ++;
    
                if(key_Count < 1)
                    key_Count = 1;
    
                if(key_Count > NoteVariables.Note_Count_Directions.length)
                    key_Count = NoteVariables.Note_Count_Directions.length;
    
                create_Arrows();
            }

            if(selectingStuff && (upP || downP))
            {
                if(downP)
                    current_ColorVals[selectedValue] --;
    
                if(upP)
                    current_ColorVals[selectedValue] ++;
    
                if(current_ColorVals[selectedValue] < colorMins[selectedValue])
                    current_ColorVals[selectedValue] = colorMins[selectedValue];
    
                if(current_ColorVals[selectedValue] > colorMaxs[selectedValue])
                    current_ColorVals[selectedValue] = colorMaxs[selectedValue];
    
                switch(selectedValue)
                {
                    case 0:
                        arrow_Group.members[selectedControl].colorSwap.r = current_ColorVals[selectedValue];
                    case 1:
                        arrow_Group.members[selectedControl].colorSwap.g = current_ColorVals[selectedValue];
                    case 2:
                        arrow_Group.members[selectedControl].colorSwap.b = current_ColorVals[selectedValue];
                }

                NoteColors.setNoteColor(NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][selectedControl], current_ColorVals);
            }

            if(!selectingStuff && (leftP || rightP))
            {
                if(leftP)
                    selectedControl --;

                if(rightP)
                    selectedControl ++;

                if(selectedControl < 0)
                    selectedControl = key_Count - 1;

                if(selectedControl > key_Count - 1)
                    selectedControl = 0;

                updateColorValsBase();
            }

            if(selectingStuff && (leftP || rightP))
            {
                if(leftP)
                    selectedValue --;

                if(rightP)
                    selectedValue ++;

                if(selectedValue < 0)
                    selectedValue = 2;

                if(selectedValue > 2)
                    selectedValue = 0;
            }
    
            update_Text();
        }
    }

    function update_Text()
    {
        var red = Std.string(current_ColorVals[0]);
        var green = Std.string(current_ColorVals[1]);
        var blue = Std.string(current_ColorVals[2]);

        switch(selectedValue)
        {
            case 0:
                red = "> " + red + " <";
            case 1:
                green = "> " + green + " <";
            case 2:
                blue = "> " + blue + " <";
        }

        final buttonReset:String = controls.mobileC ? 'C' : 'R';
        final buttonEnter:String = controls.mobileC ? 'A' : 'ENTER';

        coolText.text = 'Use UP and DOWN to change number of keys or the selected color\nLEFT and RIGHT to change arrow selected or the color selected\n$buttonReset to Reset Note Colors\n$buttonEnter to select a note\nRed: ' + red + ", Green: " + green + ", Blue: " + blue + "\n";
        coolText.screenCenter(X);
    }

    inline function updateColorValsBase()
    {
        current_ColorVals = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][selectedControl]);
    }

    function create_Arrows(?new_Key_Count)
    {
        if(new_Key_Count != null)
            key_Count = new_Key_Count;

        arrow_Group.clear();

        var strumLine:FlxSprite = new FlxSprite(0, FlxG.height / 2);

		for (i in 0...key_Count)
        {
            var babyArrow:StrumNote = new StrumNote(0, strumLine.y, i, "default", ui_settings, mania_size, key_Count, null);

            babyArrow.frames = Paths.getSparrowAtlas("ui skins/default/arrows/default", 'shared');

			babyArrow.antialiasing = ui_settings[3] == "true";

			babyArrow.setGraphicSize(Std.int((babyArrow.width * Std.parseFloat(ui_settings[0])) * (Std.parseFloat(ui_settings[2]) - (Std.parseFloat(mania_size[key_Count-1])))));
			babyArrow.updateHitbox();

			babyArrow.animation.addByPrefix('default', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + "0");
			babyArrow.animation.addByPrefix('pressed', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' press', 24, false);
			babyArrow.animation.addByPrefix('confirm', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' confirm', 24, false);
			
			babyArrow.playAnim('default');

			babyArrow.x += (babyArrow.width + (2 + Std.parseFloat(mania_gap[key_Count - 1]))) * Math.abs(i) + Std.parseFloat(mania_offset[key_Count - 1]);
			babyArrow.y = strumLine.y - (babyArrow.height / 2);

            babyArrow.y -= 10;
            babyArrow.alpha = 0;
            FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			babyArrow.x += 100 - ((key_Count - 4) * 16) + (key_Count >= 10 ? 30 : 0);
			babyArrow.x += ((FlxG.width / 2) * 0.5);

            arrow_Group.add(babyArrow);
        }
    }
}