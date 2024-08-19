package;

import openfl.errors.Error;
import openfl.events.ErrorEvent;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.system.debug.log.LogStyle;
import haxe.CallStack;
import haxe.Log;
import haxe.io.Path;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import openfl.text.TextFormat;
import states.TitleState;
import ui.SimpleInfoDisplay;
import ui.logs.Logs;
#if mobile
import mobile.states.CopyState;
#end

class Main extends Sprite {
	public static var game:FlxGame;
	public static var display:SimpleInfoDisplay;
	public static var logsOverlay:Logs;
	
	public function new() {
		#if mobile
		#if android
		SUtil.doPermissionsShit();
		#end
		Sys.setCwd(SUtil.getStorageDirectory());
		#end

		super();

		#if sys
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		CoolUtil.haxe_trace = Log.trace;
		Log.trace = CoolUtil.haxe_print;

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init();
		#end

		game = new FlxGame(1280, 720, #if (mobile && MODDING_ALLOWED) !CopyState.checkExistingFiles() ? CopyState : #end TitleState, 60, 60, true);

		// FlxG.game._customSoundTray wants just the class, it calls new from
		// create() in there, which gets called when it's added to stage
		// which is why it needs to be added before addChild(game) here
		@:privateAccess
		game._customSoundTray = ui.FunkinSoundTray;

		addChild(game);
		#if mobile
		FlxG.scaleMode = new mobile.MobileScaleMode();
		#end
		logsOverlay = new Logs();
		logsOverlay.visible = false;
		addChild(logsOverlay);

		display = new SimpleInfoDisplay(8, 3, 0xFFFFFF, "_sans");
		addChild(display);

		// shader coords fix
		// stolen from psych engine lol
		FlxG.signals.gameResized.add(function (w, h) {
			if(display != null)
				display.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));
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

		#if mobile
		lime.system.System.allowScreenTimeout = Options.getData("screenSaver");
		#if android FlxG.android.preventDefaultKeys = [BACK]; #end
		#end
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
	function onCrash(e:UncaughtErrorEvent):Void {
		var error:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var date:String = Date.now().toString();

		date = StringTools.replace(date, " ", "_");
		date = StringTools.replace(date, ":", "'");

		for (stackItem in callStack){
			switch (stackItem) {
				case FilePos(s, file, line, column):
					error += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		// see the docs for e.error to see why we do this
		// since i guess it can sometimes be an issue???
		// /shrug - what-is-a-git 2024
		var errorData:String = "";
		if (Std.isOfType(e.error, Error)) {
			errorData = cast(e.error, Error).message;
		} else if (Std.isOfType(e.error, ErrorEvent)) {
			errorData = cast(e.error, ErrorEvent).text;
		} else {
			errorData = Std.string(e.error);
		}
		
		error += "\nUncaught Error: " + errorData;
		path = Sys.getCwd() + "logs/" + "crash-" + errorData + '-on-' + date + ".txt";

		if (!sys.FileSystem.exists("./logs/")) {
			sys.FileSystem.createDirectory("./logs/");
		}

		sys.io.File.saveContent(path, error + "\n");

		Sys.println(error);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		#if desktop
		var crashPath:String = "Crash" #if linux + '.x86_64' #end #if windows + ".exe" #end;

		if (sys.FileSystem.exists("./" + crashPath)){
				Sys.println("Found crash dialog: " + crashPath);
	
				#if linux
				crashPath = "./" + crashPath;
				new sys.io.Process('chmod', ['+x', crashPath]); // make sure we can run the file lol
				#end
				FlxG.stage.window.visible = false;
				new sys.io.Process(crashPath, ['--crash_path="' + path + '"']);
				//trace(process.exitCode());
		} else {
			Sys.println("No crash dialog found! Making a simple alert instead...");
			SUtil.showPopUp(error, "Error!");
		}
		#else
		SUtil.showPopUp(error, "Error!");
		#end

		Sys.exit(1);
	}
	#end
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