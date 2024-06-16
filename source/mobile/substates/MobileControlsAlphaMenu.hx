package mobile.substates;

import flixel.math.FlxMath;
import game.Conductor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class MobileControlsAlphaMenu extends substates.MusicBeatSubstate
{
    var opacityValue:Float = 0.0;
    var offsetText:FlxText = new FlxText(0,0,0,"Alpha: 0",64).setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

    public function new()
    {
        super();

        opacityValue = Options.getData("mobileCAlpha");
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        offsetText.text = "Opacity: " + opacityValue;
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
            Options.setData(opacityValue, "mobileCAlpha");
            FlxG.state.closeSubState();
        }

        if(leftP)
            opacityValue -= 0.1;
        if(rightP)
            opacityValue += 0.1;

        opacityValue = FlxMath.roundDecimal(opacityValue, 1);

        if(opacityValue > 1)
            opacityValue = 1;

        if(opacityValue < 0)
            opacityValue = 0;

        offsetText.text = "Opacity: " + opacityValue;
        offsetText.screenCenter();
    }
}