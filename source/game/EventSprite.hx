package game;

import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

class EventSprite extends FlxSprite {
	public var name(default, null):String;
	public var strumTime(default, null):Float;
	public var value1(default, null):String;
	public var value2(default, null):String;

	static var tooltipText:TooltipText;

	public function new(event:Array<Dynamic>, x:Float = 0.0, y:Float = 0.0) {
		super(x, y);
		loadGraphic(Paths.gpuBitmap("charter/eventSprite", "shared"));
		this.name = event[0];
		this.strumTime = event[1];
		this.value1 = event[2];
		this.value2 = event[3];

		if (tooltipText == null) {
			tooltipText = new TooltipText();
			tooltipText.color = FlxColor.WHITE;
			tooltipText.borderColor = FlxColor.BLACK;
			tooltipText.borderSize = 1;
			tooltipText.borderStyle = OUTLINE;
			tooltipText.size = 12;
			tooltipText.font = Paths.font("vcr.ttf");
			tooltipText.graphic.destroyOnNoUse = false;
		}
	}

	override function draw() {
		super.draw();
		if (!alive || !FlxG.mouse.overlaps(this)) {
			return;
		}
		tooltipText.text = 'Name: $name\nPosition: $strumTime\nValue 1: $value1\nValue 2: $value2';
		tooltipText.setPosition(FlxG.mouse.x + FlxG.mouse.cursor.width, FlxG.mouse.y);
		tooltipText.draw();
	}
}

private class TooltipText extends FlxText {
	override inline function destroy() {}
}
