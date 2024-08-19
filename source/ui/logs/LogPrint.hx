package ui.logs;

import flixel.util.FlxColor;

class LogPrint {
	public var text:String = "[LOG]";
	public var color:FlxColor = FlxColor.WHITE;

	public function new(text:String, color:FlxColor){
		this.text = text;
		this.color = color;
	}
}