package modding.helpers;

import flixel.tweens.FlxTween;

class FlxTweenUtil
{
    static public function pauseTween(tween:FlxTween)
    {
       if (tween != null) {
         tween.active = false;
       }
    }
    static public function resumeTween(tween:FlxTween)
    {
       if (tween != null) {
        @:privateAccess
         tween.active = true;
       }
    }
    static public function pauseTweensOf(Object1, FieldPaths)
    {
        @:privateAccess
       FlxTween.globalManager.forEachTweensOf(Object1, FieldPaths, pauseTween);
    }
    static public function resumeTweensOf(Object1, FieldPaths)
    {
        @:privateAccess
       FlxTween.globalManager.forEachTweensOf(Object1, FieldPaths, resumeTween);
    }

}