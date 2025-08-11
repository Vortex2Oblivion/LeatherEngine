package ui;

import ui.logs.Logs;
import openfl.events.Event;
import flixel.math.FlxMath;
import lime.system.System;
import macros.GithubCommitHash;
import flixel.util.FlxStringUtil;
import flixel.FlxG;
import openfl.utils.Assets;
import openfl.text.TextField;
import openfl.text.TextFormat;
import external.memory.Memory;
import macros.GithubCommitHash;
import haxe.macro.Compiler;

/**
 * Shows basic info about the game.
 */
class SimpleInfoDisplay extends TextField {
	public var framerate(default, null):Int = 0;

	private var framerateTimer(default, null):Float = 0.0;
	private var framesCounted(default, null):Int = 0;

	public var version:String = CoolUtil.getCurrentVersion();

	public var showFPS:Bool = false;
	public var showMemory:Bool = false;
	public var showVersion:Bool = false;
	public var showTracedLines:Bool = false;
	public var showCommitHash:Bool = false;

	private var canLie:Bool = true;

	public function new(x:Float = 10.0, y:Float = 10.0, color:Int = 0x000000, ?font:String) {
		super();

		this.x = x;
		this.y = y;
		selectable = false;
		defaultTextFormat = new TextFormat(font ?? Assets.getFont(Paths.font("vcr.ttf")).fontName, (font == "_sans" ? 12 : 14), color);

		width = FlxG.width;
		height = FlxG.height;

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private var _framesPassed:Int = 0;
	private var _previousTime:Float = 0;
	private var _updateClock:Float = 999999;

	/**
	 * @see https://github.com/swordcube/friday-again-garfie-baby/blob/main/source/funkin/backend/StatsDisplay.hx#L46
	 */
	private function onEnterFrame(e:Event):Void {
		_framesPassed++;

		final deltaTime:Float = Math.max(System.getTimerPrecise() - _previousTime, 0);
		_updateClock += deltaTime;

		if (_updateClock >= 1000) {
			framerate = (FlxG.drawFramerate > 0) ? FlxMath.minInt(_framesPassed, FlxG.drawFramerate) : _framesPassed;
			if (canLie) {
				framerate = FlxMath.boundInt(framerate, 0, Options.getData("maxFPS")); // make sure the counter doesn't go above your max fps
			}

			_framesPassed = 0;
			_updateClock = 0;
		}
		_previousTime = System.getTimerPrecise();

		if (!visible) {
			return;
		}

		text = '';
		if (showFPS) {
			text += '${framerate}fps\n';
		}
		if (showMemory) {
			text += '${FlxStringUtil.formatBytes(Memory.getCurrentUsage())} / ${FlxStringUtil.formatBytes(Memory.getPeakUsage())}\n';
		}
		if (showVersion) {
			text += '$version\n';
		}
		if (showTracedLines && Options.getData("developer")) {
			var textToAppend:String = '';
			var showLogs:Bool = Main.logsOverlay.logs.length > 0;
			if (showLogs) {
				textToAppend += '${Main.logsOverlay.logs.length} traced lines';
			}
			if (Logs.errors > 0) {
				textToAppend += ' | ${Logs.errors} errors';
			}
			if (showLogs) {
				textToAppend += '. Press F3 to view.\n';
			}
			text += textToAppend;
		}
		if (showCommitHash) {
			text += 'Commit ${GithubCommitHash.getGitCommitHash().substring(0, 7)}';
		}
	}
}
