package ui;

import flixel.FlxG;
import openfl.utils.Assets;
import openfl.text.TextField;
import openfl.text.TextFormat;
import external.memory.Memory;

/**
 * Shows basic info about the game.
 */
class SimpleInfoDisplay extends TextField {
	//                                      fps    mem   version console info
	public var infoDisplayed:Array<Bool> = [false, false, false, false];

	public var framerate:Int = 0;
	private var framerateTimer:Float = 0.0;
    private var framesCounted:Int = 0;
	
	public var version:String = CoolUtil.getCurrentVersion();

	public function new(x:Float = 10.0, y:Float = 10.0, color:Int = 0x000000, ?font:String) {
		super();

		this.x = #if mobile FlxG.game.x + #end x;
		this.y = #if mobile FlxG.game.y + #end y;
		selectable = false;
		defaultTextFormat = new TextFormat(font != null ? font : Assets.getFont(Paths.font("vcr.ttf")).fontName, (font == "_sans" ? 12 : 14),
        color);

        FlxG.signals.postDraw.add(update);

		width = FlxG.width;
		height = FlxG.height;
	}

	private function update():Void {
		framerateTimer += FlxG.elapsed;
		
        if (framerateTimer >= 1) {
			framerateTimer = 0;
			
            framerate = framesCounted;
            framesCounted = 0;
        }
		
		framesCounted++;
		
		if (!visible) {
			return;
		}
		
		text = '';
		for (i in 0...infoDisplayed.length) {
			if (!infoDisplayed[i]) {
				continue;
			}
			
			switch (i) {
				case 0: // FPS
					text += '${framerate}fps';
				case 1: // Memory
					text += '${CoolUtil.formatBytes(Memory.getCurrentUsage())} / ${CoolUtil.formatBytes(Memory.getPeakUsage())}';
				case 2: // Version
					text += version;
				case 3: // Console
					text += '${Main.logsOverlay.logs.length} traced lines. F3 to view.';
			}

			text += '\n';
		}
	}
}
