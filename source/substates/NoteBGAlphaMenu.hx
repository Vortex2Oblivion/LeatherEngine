package substates;

import flixel.math.FlxMath;
import game.Conductor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

@:publicFields
class NoteBGAlphaMenu extends MusicBeatSubstate
{
    var alphaValue:Float = 0.0;
    var offsetText:FlxText = new FlxText(0,0,0,"Alpha: 0",64).setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

    public function new()
    {
        super();

        alphaValue = Options.getData("noteBGAlpha");
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        offsetText.text = "Alpha: " + alphaValue;
        offsetText.screenCenter();
        add(offsetText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;

        var back = controls.BACK;

        if(back)
        {
            Options.setData(alphaValue, "noteBGAlpha");
            FlxG.state.closeSubState();
        }

        if(leftP)
            alphaValue -= 0.1;
        if(rightP)
            alphaValue += 0.1;

        alphaValue = FlxMath.roundDecimal(alphaValue, 1);

        if(alphaValue > 1)
            alphaValue = 1;

        if(alphaValue < 0)
            alphaValue = 0;

        offsetText.text = "Alpha: " + alphaValue;
        offsetText.screenCenter();
    }
}