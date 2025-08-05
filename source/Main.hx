package;

import lime.utils.LogLevel;
import haxe.PosInfos;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.system.debug.log.LogStyle;
import haxe.CallStack;
import haxe.Log;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.text.TextFormat;
import openfl.utils._internal.Log as OpenFLLog;
import states.TitleState;
import ui.SimpleInfoDisplay;
import ui.logs.Logs;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#if linux
import hxgamemode.GamemodeClient;
#end

class Main extends Sprite {
	public static var display:SimpleInfoDisplay;
	public static var logsOverlay:Logs;

	public static var previousState:FlxState;

	public static var onUncaughtError(default, null):FlxTypedSignal<UncaughtErrorEvent->Void> = new FlxTypedSignal<UncaughtErrorEvent->Void>();
	public static var onCriticalError(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	@:noCompletion
	private static function __init__():Void {
		#if linux
		// Request we start game mode
		if (GamemodeClient.request_start() != 0) {
			Sys.println('Failed to request gamemode start: ${GamemodeClient.error_string()}...');
			Sys.exit(1);
		} else
			Sys.println('Succesfully requested gamemode to start...');
		#end
	}

	public function new() {
		super();

		#if sys
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, _onUncaughtError);
		#end

		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(_onCriticalError); // this is important i guess?
		#end

		CoolUtil.haxe_trace = Log.trace;
		Log.trace = CoolUtil.haxe_print;
		OpenFLLog.throwErrors = false;

		FlxG.signals.preStateSwitch.add(() -> {
			Main.previousState = FlxG.state;
		});

		FlxG.signals.preStateCreate.add((state) -> {
			CoolUtil.clearMemory();
		});

		addChild(new FlxGame(1280, 720, TitleState, 60, 60, true));
		logsOverlay = new Logs();
		logsOverlay.visible = false;
		addChild(logsOverlay);

		LogStyle.WARNING.onLog.add((data:Any, ?pos:PosInfos) -> trace(data, WARNING, pos));
		LogStyle.ERROR.onLog.add((data:Any, ?pos:PosInfos) -> trace(data, ERROR, pos));
		LogStyle.NOTICE.onLog.add((data:Any, ?pos:PosInfos) -> trace(data, LOG, pos));

		OpenFLLog.debug = (message:Dynamic, ?info:PosInfos) -> {
			if (OpenFLLog.level >= LogLevel.DEBUG) {
				trace(message, DEBUG, info);
			}
		};

		OpenFLLog.error = (message:Dynamic, ?info:PosInfos) -> {
			if (OpenFLLog.level >= LogLevel.ERROR) {
				trace(message, ERROR, info);
			}
		};

		OpenFLLog.info = (message:Dynamic, ?info:PosInfos) -> {
			if (OpenFLLog.level >= LogLevel.INFO) {
				trace(message, LOG, info);
			}
		};

		OpenFLLog.warn = (message:Dynamic, ?info:PosInfos) -> {
			if (OpenFLLog.level >= LogLevel.WARN) {
				trace(message, WARNING, info);
			}
		};

		OpenFLLog.verbose = (message:Dynamic, ?info:PosInfos) -> {
			if (OpenFLLog.level >= LogLevel.VERBOSE) {
				trace(message, LOG, info);
			}
		};

		display = new SimpleInfoDisplay(8, 3, 0xFFFFFF, "_sans");
		addChild(display);

		// shader coords fix
		// stolen from psych engine lol
		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null) {
						resetSpriteCache(cam.flashSprite);
					}
				}
			}

			if (FlxG.game != null) {
				resetSpriteCache(FlxG.game);
			}
		});
	}

	public static inline function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static inline function toggleFPS(fpsEnabled:Bool):Void {
		display.infoDisplayed[0] = fpsEnabled;
	}

	public static inline function toggleMem(memEnabled:Bool):Void {
		display.infoDisplayed[1] = memEnabled;
	}

	public static inline function toggleVers(versEnabled:Bool):Void {
		display.infoDisplayed[2] = versEnabled;
	}

	public static inline function toggleLogs(logsEnabled:Bool):Void {
		display.infoDisplayed[3] = logsEnabled;
	}

	public static inline function toggleCommitHash(commitHashEnabled:Bool):Void {
		display.infoDisplayed[4] = commitHashEnabled;
	}

	public static inline function changeFont(font:String):Void {
		display.defaultTextFormat = new TextFormat(font, (font == "_sans" ? 12 : 14), display.textColor);
	}

	#if sys
	/**
	 * Shoutout to @gedehari for making the crash logging code
	 * They make some cool stuff check them out!
	 * @see https://github.com/gedehari/IzzyEngine/blob/master/source/Main.hx
	 * @param e
	 */
	private function _onUncaughtError(e:UncaughtErrorEvent):Void {
		onUncaughtError.dispatch(e);
		var error:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var date:String = Date.now().toString();

		date = StringTools.replace(date, " ", "_");
		date = StringTools.replace(date, ":", "'");

		for (stackItem in callStack) {
			switch (stackItem) {
				case FilePos(s, file, line, column):
					error += file + ":" + line + "\n";
				default:
					Sys.println(stackItem);
			}
		}

		// see the docs for e.error to see why we do this
		// since i guess it can sometimes be an issue???
		// /shrug - what-is-a-git 2024
		var errorData:String = "";
		if (e.error is Error) {
			errorData = cast(e.error, Error).message;
		} else if (e.error is ErrorEvent) {
			errorData = cast(e.error, ErrorEvent).text;
		} else {
			errorData = Std.string(e.error);
		}

		error += "\nUncaught Error: " + errorData;
		path = Sys.getCwd() + "crash/" + "crash-" + errorData + '-on-' + date + ".txt";

		if (!FileSystem.exists("./crash/")) {
			FileSystem.createDirectory("./crash/");
		}

		File.saveContent(path, error + "\n");

		Sys.println(error);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		var crashPath:String = "Crash" #if linux + '.x86_64' #end#if windows + ".exe" #end;

		if (FileSystem.exists("./" + crashPath)) {
			Sys.println("Found crash dialog: " + crashPath);

			#if linux
			crashPath = "./" + crashPath;
			new Process('chmod', ['+x', crashPath]); // make sure we can run the file lol
			#end
			FlxG.stage.window.visible = false;
			new Process(crashPath, ['--crash_path="' + path + '"']);
			// trace(process.exitCode());
		} else {
			Sys.println("No crash dialog found! Making a simple alert instead...");
			FlxG.stage.window.alert(error, "Error!");
		}

		Sys.exit(1);
	}
	#end

	private static function _onCriticalError(message:String):Void {
		try {
			onCriticalError.dispatch(message);
			var path:String;
			var error:String = "";
			var date:String = Date.now().toString();

			date = StringTools.replace(date, " ", "_");
			date = StringTools.replace(date, ":", "'");

			error = "Critical Error:\n" + message;
			path = Sys.getCwd() + "crash/" + "crash-critical" + '-on-' + date + ".txt";

			if (!FileSystem.exists("./crash/")) {
				FileSystem.createDirectory("./crash/");
			}

			File.saveContent(path, error + "\n");

			Sys.println(error);
			Sys.println("Crash dump saved in " + Path.normalize(path));

			var crashPath:String = "Crash" #if linux + '.x86_64' #end#if windows + ".exe" #end;

			if (FileSystem.exists("./" + crashPath)) {
				Sys.println("Found crash dialog: " + crashPath);

				#if linux
				crashPath = "./" + crashPath;
				new Process('chmod', ['+x', crashPath]); // make sure we can run the file lol
				#end
				FlxG.stage.window.visible = false;
				new Process(crashPath, ['--crash_path="' + path + '"']);
				// trace(process.exitCode());
			} else {
				Sys.println("No crash dialog found! Making a simple alert instead...");
				FlxG.stage.window.alert(message, "Critical Error!");
			}
		} catch (e:Dynamic) {
			Sys.println('Error while handling crash: $e');

			Sys.println('Message: $message');
		}
		#if sys
		Sys.sleep(1); // wait a few moments of margin to process.
		// Exit the game. Since it threw an error, we use a non-zero exit code.
		openfl.Lib.application.window.close();
		#end
	}
}
/*
																 .:^^.
															   .^~!777:
															  :~!!77?J~
															 ^!!!777?J~
														   .~!!!77???J!
														  .~7!!!77???J7
														  ~!!7777?????7
														 ^7777777????J?:
														:!77777??????JJ:
														^7?77777???JJJJ^
														~7777??JYYJJ?JY7
														~!7??JJJ???7???7.                                      .:::.
													  .^!!777777???7????7.                                   :~~!7?7
												   .:^~!!!!!!7777?J?????J7.                .^:.             ^~!!!7??.
											...::^~~~~~~!!!!!!!!!7777???77!^.             ^7?J!           .~!!!!7??J:
								   ..:::^^~~~~~~~~!!!!!!!!!!777!777777777777!^.          ~7????          .~7!!777?J7
						   ..::^^~~~~~~!!!!!!!!!!!!!!!!!!7777777777777?????777!~^:.    .~77777?^.        ~!!!777??J~
					 .::^^~~~~!!!!!!!!!!!!!!!!!!!777!!!777777777777777?????????777!~~^^~!!!!!!!7!~:.    ^!!!!7777?J~
				 .^~~~~~~~~~~~~!!!!!!!!!!7777777777777777777777777777???????????777?777!!!!!777!777!!~~~!!!!!777??J!
			  .^~~!!!!!!!!!!!!!7777777777777777777777?777????77?77????????????????77?????777777777???77??7!!777????7
		   .:^~~~~~~!!!!!!!!!7777777777777777777???????????????????????????????????????????????????J????????7?????JJ:
		.:^~~!7!!!!!!!!!!!7777777???????????????????????????????????????????????JJJ????JJJJ?????JJ?JJ???JJJJ???JJJJJ~
	   :~~!!!!!!!!7777777777777?????J???J???????????????????J?????????????????????JJJ??JJJJJ?????JJ??J???JJJJJJ?JJJJ!
	 .^!~77?777!77777777777????????JJJJJJJJJ?J????????????????JJJJ????????????JJJJJJJJ?JJJJJJJJJ?JJJ?JJJ?JJJJJ?JYJJJ?.
	.~~!???????????????J????JJ??JJJJJJYJJJJJJJJJ?JJJJ??J??JJ?JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??J?JJJJJJJYYJJJJ7
	.~~7YYYJJJ?JJJJ??JJJJ?J?JJJ?JJJJJJYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?????!7JY5555YYJJJ!
	:~7YYYYYYYYYYJJJYJJYJJJJYJJJYYYYYYYYYYYYYYYJYYJYYYJJJJJJJJYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?7~~:.   ~?5PP55YYJJJ7
	.~!?5YYYY5YYYYJYYYYYYYYYYYJYYY55YY5YYYYYYYYYYYYYYYYYYYJJJJJYJY5JJYJJJYYJJJJJJJJJJJJJJJJJJJJJJJ?!:         .!YP5555YJJJ7:
	.~!?55YYYYYYYYYYYY5YYYYY5YYY555555YYYYYYYY5YYYYYYYYYYYYJJJJYJYYJY5JYYYYJJJJJJJJYYYJJJJJJJJJJ7~.             :7Y555YYJJJ7
	.!7JP5555555YYY555YYYY5555555555YYYYYYYYYY55P5YYYYYYYJJJJYYJYYJ5YJY55YY5YJJJ???????JJJJJJ7^.                 :7Y55YYJJJ.
	.!?J5PPPP55555P555555555555555555YYYYYY5B#GG#PYJJYYYJJJJYJYYJY5YJ55555YJJJJ??????7~^^^^:                      .^?YYYY7.
	 .^7?YY5PP555PPP5555555555555555555YYYY5GBGGPYYYYYYYYJJYYY5YJ5YY5555YYJJJJJJJJJJ??!~:                             .::
	   .:~7?JY55YYYYYYYYYYYYY5YJJJJJJJJ???777777!!!!!!!!!!~~!!!!!!!~!55YYYJYYJJJJJJJJJ??7!:
		  ..:^^^^^^^^^^^^^^^^^^^::::^:::::::::::::::::::::::::::::::^J55YYYYYYYJJJJJJJJJJJ?!^.
			 ...:::::::::::::::::::^:::::::::::::^::^:::::::::::::::^!JY5YYYYYYJJYYJJJYYJJJ??7^
				 ..::.:::::^::^^^^^^^^^^^^^^^^^^^^^^:::::::::::::::^^^!?JYYYYYYJJYYYYYJJJJJJJJJ7^.
					  ....:^^^^^^^^^^~^^^^^^^::::::::::::::::::::::^^^~~!!7?YYYYY5YYYJJJJYYYJJJJJ?~.
						  ..::^^:^^:^^:::::::::::::::::::::::::::^^^^^^^:.. :~7J5YYYYJJJJYJJJYYYYJJ?7^.
								  ......:::::::::::::::::::::^^^::::..         .^7JYYYYYYYYYYYJJJJJJJJ?7~.
												...............                   .~7JYYY55YYYYYJYYYJJYYJJ7^.
																					 .:~7JYY5555YYYYYYYYJJYJ?:
																						 .::^~!?JYY555YYYJJ7!.
																								..:^~^^^~^.
 */
// :3
