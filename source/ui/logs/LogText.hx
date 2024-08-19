package ui.logs;

import flixel.util.FlxColor;
import openfl.text.TextFormatAlign;
import openfl.text.TextFormat;
import openfl.text.TextField;

class LogText extends TextField{
    override public function new(x:Float, y:Float, sizeData:Dynamic, text:String, size:Int, textAlign:TextFormatAlign = CENTER, ?color:FlxColor = FlxColor.WHITE){
        super();
		width = sizeData.width;
		height = sizeData.height;
		multiline = true;
		wordWrap = true;
		selectable = false;

		var dtf:TextFormat = new TextFormat("VCR OSD Mono", size, color);
		dtf.align = textAlign;
		defaultTextFormat = dtf;
		this.text = text;

		this.x = x;
		this.y = y;
    }
}