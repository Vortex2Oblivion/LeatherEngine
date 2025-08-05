package utilities;

#if desktop
import sys.FileSystem;
import haxe.io.Path;

/**
 * A class that simply points the audio backend OpenALSoft to use a custom
 * configuration when the game starts up.
 *
 * The config file overrides a few global OpenALSoft settings to improve audio
 * quality on desktop targets.
 * 
 * @see https://github.com/FunkinCrew/Funkin/pull/3318/files#diff-7766222e461dc7f3b3a4409e20cf5889087593464aa99970599ebc39a588ebc4
 */
@:keep
@:nullSafety
class ALSoft {
	private static function __init__():Void {
        var configPath:String = Path.directory(Path.withoutExtension(#if hl Sys.getCwd() #else Sys.programPath() #end));
		#if windows
		configPath += "/plugins/alsoft.ini";
		#elseif mac
		configPath = '${Path.directory(configPath)}/Resources/plugins/alsoft.conf';
		#else
		configPath += "/plugins/alsoft.conf";
		#end
        
		Sys.putEnv("ALSOFT_CONF", FileSystem.fullPath(configPath));
		#if debug
        Sys.println("Successfully loaded alsoft config.");
		#end
	}
}
#end
