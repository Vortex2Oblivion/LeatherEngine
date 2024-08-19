package ui;

import flixel.FlxG;
import openfl.utils.Assets;
import openfl.text.TextField;
import openfl.text.TextFormat;
import external.memory.Memory;
import lime.system.System as LimeSystem;

/**
 * Shows basic info about the game.
 */
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class SimpleInfoDisplay extends TextField {
	//                                      fps    mem   version console info
	public var infoDisplayed:Array<Bool> = [false, false, false, false];

	public var framerate:Int = 0;
	private var framerateTimer:Float = 0.0;
    private var framesCounted:Int = 0;
	
	public var version:String = CoolUtil.getCurrentVersion();
	public final os:String = '${LimeSystem.platformName} ${getArch() != 'Unknown' ? getArch() : ''} ${(LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null) ? '' : '- ' + LimeSystem.platformVersion}';

	public function new(x:Float = 10.0, y:Float = 10.0, color:Int = 0x000000, ?font:String) {
		super();

		os = os.toLowerCase();

		positionFPS(x, y);
		selectable = false;
		defaultTextFormat = new TextFormat(font != null ? font : Assets.getFont(Paths.font("vcr.ttf")).fontName, (font == "_sans" ? 12 : 14),
        color);

        FlxG.signals.postDraw.add(update);

		width = FlxG.width;
		height = FlxG.height;
	}

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
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
					text += os;
				case 3: // Console
					text += '${Main.logsOverlay.logs.length} traced lines. F3 to view.';
			}

			text += '\n';
		}
	}

	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#elseif cpp
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private static function getArch():String
	{
		return "Unknown";
	}
}
