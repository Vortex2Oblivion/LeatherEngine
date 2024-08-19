package ui.logs;

import flixel.util.FlxColor;
import openfl.text.TextFormat;

class LogTextFormat extends TextFormat{
    override public function new(_color:FlxColor = FlxColor.WHITE, _size:Int = 10){
        super(Options.getData("infoDisplayFont"), _size, _color);
    }
}