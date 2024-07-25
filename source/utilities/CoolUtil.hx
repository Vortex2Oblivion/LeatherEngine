package utilities;

import game.SongLoader.FNFCMetadata;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.graphics.Image;
import lime.utils.Assets;
import openfl.utils.Function;
import states.PlayState;
import ui.logs.Logs;

using StringTools;

/**
 * Helper class with lots of utilitiy functions.
 */
class CoolUtil {
	public static function boundTo(value:Float, min:Float, max:Float):Float {
		var newValue:Float = value;

		if (newValue < min)
			newValue = min;
		else if (newValue > max)
			newValue = max;

		return newValue;
	}

	#if sys
	public static function coolTextFileSys(path:String):Array<String> {
		var daList:Array<String> = File.getContent(path).trim().split('\n');

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	#end

	public static function coolTextFile(path:String):Array<String> {
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolTextFileOfArrays(path:String, ?delimeter:String = " "):Array<Array<String>> {
		var daListOg = coolTextFile(path);

		var daList:Array<Array<String>> = [];

		for (line in daListOg) {
			daList.push(line.split(delimeter));
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int> {
		var dumbArray:Array<Int> = [];

		for (i in min...max)
			dumbArray.push(i);

		return dumbArray;
	}

	public static inline function openURL(url:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [url, "&"]);
		#else
		FlxG.openURL(url);
		#end
	}

	public static function coolTextCase(text:String):String {
		var returnText:String = "";

		var textArray:Array<String> = text.split(" ");

		for (text in textArray) {
			var textStuffs = text.split("");

			for (i in 0...textStuffs.length) {
				if (i != 0)
					returnText += textStuffs[i].toLowerCase();
				else
					returnText += textStuffs[i].toUpperCase();
			}

			returnText += " ";
		}

		return returnText;
	}

	// stolen from psych lmao cuz i'm lazy
	public static function dominantColor(sprite:flixel.FlxSprite):Int {
		var countByColor:Map<Int, Int> = [];

		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);

				if (colorOfThisPixel != 0) {
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color

		countByColor[FlxColor.BLACK] = 0;

		for (key in countByColor.keys()) {
			if (countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}

		return maxKey;
	}

	public static function dominantColorFrame(sprite:flixel.FlxSprite):Int {
		var countByColor:Map<Int, Int> = [];

		sprite.useFramePixels = true;
		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
				var colorOfThisPixel:Int = sprite.framePixels.getPixel32(col, row);

				if (colorOfThisPixel != 0) {
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color

		countByColor[FlxColor.BLACK] = 0;

		for (key in countByColor.keys()) {
			if (countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}

		return maxKey;
	}

	/**
	 * Sets the window icon
	 * @author Vortex
	 * @param path 
	 */
	public static inline function setWindowIcon(path:String) {
		#if desktop
		FlxG.stage.window.setIcon(Image.fromFile(path));
		#end
	}

	/**
	 * Gets the highest number from a list.
	 * Shoutout to @crinfarr on Discord.
	 * https://discord.com/channels/162395145352904705/162395145352904705/1157847259858354236
	 * @param ...nums 
	 * @return T
	 */
	public static function max<T:Float>(...nums:T):T {
		var max:Null<T> = null;
		for (n in nums) {
			if (max == null || n > max)
				max = n;
		}
		return max;
	}

	/**
	 * Gets the lowest number from a list.
	 * Shoutout to @crinfarr on Discord.
	 * https://discord.com/channels/162395145352904705/162395145352904705/1157847259858354236
	 * @param ...nums 
	 * @return T
	 */
	public static function min<T:Float>(...nums:T):T {
		var min:Null<T> = null;
		for (n in nums) {
			if (min == null || n < min)
				min = n;
		}
		return min;
	}

	/**
	 * Converts rgb values into hsv values.
	 * See: https://math.stackexchange.com/questions/556341/rgb-to-hsv-color-conversion-algorithm
	 * See: https://github.com/python/cpython/blob/3.9/Lib/colorsys.py
	 * @param r The red value
	 * @param g The green value
	 * @param b The blue value
	 * @return Array<Int>
	 */
	public static function rgbToHsv(r:Int, g:Int, b:Int):Array<Int> {
		r = Std.int(r / 255);
		b = Std.int(b / 255);
		g = Std.int(g / 255);

		var maxc = max(r, g, b);
		var minc = min(r, g, b);

		var h;

		var v = maxc;

		if (minc == maxc)
			return [Std.int(0), Std.int(0), Std.int(v)];

		var s = (maxc - minc) / maxc;
		var rc = (maxc - r) / (maxc - minc);
		var gc = (maxc - g) / (maxc - minc);
		var bc = (maxc - b) / (maxc - minc);

		if (r == maxc) {
			h = 0.0 + bc - gc;
		} else if (g == maxc) {
			h = 2.0 + rc - bc;
		} else {
			h = 4.0 + gc - rc;
		}

		h = (h / 6.0) % 1.0;

		return [Std.int(h * 360), Std.int(s * 100), Std.int(v * 100)];
	}

	/**
		Funny handler for `Application.current.window.alert` that *doesn't* crash on Linux and shit.

		@param message Message of the error.
		@param title Title of the error.

		@author Leather128
	**/
	public static function coolError(message:Null<String> = null, title:Null<String> = null):Void {
		trace(title + " /// " + message, ERROR);

		var text:FlxText = new FlxText(0, 0, 1280, title + "\n\n" + message, 32);
		text.font = Paths.font("vcr.ttf");
		text.color = 0xFF6183;
		text.alignment = CENTER;
		text.borderSize = 1.5;
		text.borderStyle = OUTLINE;
		text.borderColor = FlxColor.BLACK;
		text.scrollFactor.set();
		text.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		FlxTween.tween(text, {alpha: 0, y: 64}, 4, {
			onComplete: function(_) {
				if (text != null && text.exists) {
					FlxG.state.remove(text);
					text.destroy();
				}
			},
			startDelay: 1
		});

		FlxG.state.add(text);
	}

	/**
		Simple map that contains useful ansi color strings
		that can be used when printing to console for nice colors.

		@see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
	**/
	public static var ansi_colors:Map<String, String> = [
		'black' => '\033[40m',
		'red' => '\033[41m',
		'green' => '\033[42m',
		'yellow' => '\033[43m',
		'blue' => '\033[44m',
		'magenta' => '\033[45m',
		'cyan' => '\033[46m',
		'grey' => '\033[47m',
		'white' => '\033[101m',
		'default' => '\033[0m' // grey apparently
	];

	/**
		Used to replace haxe.Log.trace

		@param value Value to trace.
		@param pos_infos (Optional) Info about where the trace came from and parameters for it.

		@author Leather128
	**/
	public static function haxe_print(value:Dynamic, ?pos_infos:haxe.PosInfos):Void {
		if (pos_infos.customParams == null)
			print(value, LOG, pos_infos);
		else {
			var type:PrintType = pos_infos.customParams.copy()[0];
			pos_infos.customParams = null; // so no stupid shit in the end of prints :D
			print(Std.string(value), type, pos_infos);
		}
	}

	/**
		Prints the specified `message` with `type` and `pos_infos`.

		@param message The message to print as a `String`.
		@param type (Optional) The type of print (aka, `LOG`, `DEBUG`, `WARNING`, or `ERROR`) as a `PrintType`.
		@param pos_infos (Optional) Info about where the print came from.

		@author Leather128
	**/
	public static function print(message:String, ?type:PrintType = LOG, ?pos_infos:haxe.PosInfos):Void {
		switch (type) {
			case LOG:
				haxe_trace('${ansi_colors["cyan"]} LOG ${ansi_colors["default"]} $message', pos_infos);
				Logs.log(message);
			case DEBUG:
				haxe_trace('${ansi_colors["green"]} DEBUG ${ansi_colors["default"]} $message', pos_infos);
				Logs.debug(message);
			case WARNING:
				haxe_trace('${ansi_colors["yellow"]} WARNING ${ansi_colors["default"]} $message', pos_infos);
				Logs.warn(message);
			case ERROR:
				haxe_trace('${ansi_colors["red"]} ERROR ${ansi_colors["default"]} $message', pos_infos);
				Logs.error(message);
			// if you really want null, then here have it >:(
			default:
				haxe_trace(message, pos_infos);
		}
	}

	/**
		Access to the old `haxe.Log.trace` function.

		@author Leather128
	**/
	public static var haxe_trace:Function;

	/**
	 * List of formatting for different byte amounts
	 * in an array formatted like this:
	 * 
	 * [`Format`, `Divisor`]
	 */
	public static var byte_formats:Array<Array<Dynamic>> = [
		["$bytes b", 1.0],
		["$bytes kib", 1024.0],
		["$bytes mib", 1048576.0],
		["$bytes gib", 1073741824.0],
		["$bytes tib", 1099511627776.0]
	];

	/**
	 * Formats `bytes` into a `String`.
	 * 
	 * Examples (Input = Output)
	 * 
	 * ```
	 * 1024 = '1 kib'
	 * 1536 = '1.5 kib'
	 * 1048576 = '2 mib'
	 * ```
	 * 
	 * @param bytes Amount of bytes to format and return.
	 * @param onlyValue (Optional, Default = `false`) Whether or not to only format the value of bytes (ex: `'1.5 mib' -> '1.5'`).
	 * @param precision (Optional, Default = `2`) The precision of the decimal value of bytes. (ex: `1 -> 1.5, 2 -> 1.53, etc`).
	 * @return Formatted byte string.
	 */
	public static function formatBytes(bytes:Float, onlyValue:Bool = false, precision:Int = 2):String {
		var formatted_bytes:String = "?";

		for (i in 0...byte_formats.length) {
			// If the next byte format has a divisor smaller than the current amount of bytes,
			// and thus not the right format skip it.
			if (byte_formats.length > i + 1 && byte_formats[i + 1][1] < bytes)
				continue;

			var format:Array<Dynamic> = byte_formats[i];

			if (!onlyValue)
				formatted_bytes = StringTools.replace(format[0], "$bytes", Std.string(FlxMath.roundDecimal(bytes / format[1], precision)));
			else
				formatted_bytes = Std.string(FlxMath.roundDecimal(bytes / format[1], precision));

			break;
		}

		return formatted_bytes;
	}

	public static inline function getCurrentVersion():String {
		return 'v' + Application.current.meta.get('version');
	}

	public static function songExists(song:String, difficulty:String):Bool {
		song = song.toLowerCase();
		difficulty = difficulty.toLowerCase();
		var exists:Bool = false;
		var songPath:String = 'song data/$song';
		var difficultyExtension:String = difficulty == 'normal' ? '' : '-$difficulty';
		var difficultyExtensionMeta:String = (difficulty == 'nightmare' || difficulty == 'erect') ? '-erect' : '';

		// legacy charts
		if (Assets.exists(Paths.json('$songPath/$song$difficultyExtension'))) {
			return true;
		} else {
			// no meta or no chart
			if (!Assets.exists(Paths.json('$songPath/$song-metadata$difficultyExtensionMeta')) || !Assets.exists(Paths.json('$songPath/$song-chart$difficultyExtensionMeta'))) {
				return exists;
			}

			var meta:FNFCMetadata = cast haxe.Json.parse(Assets.getText(Paths.json('$songPath/$song-metadata$difficultyExtensionMeta')));
			if (meta.playData.difficulties.contains(difficulty)) {
				exists = true;
			}
		}

		return exists;
	}

	public static function last<T>(array:Array<T>):T
		return array[array.length - 1];
}

enum PrintType {
	LOG;
	DEBUG;
	WARNING;
	ERROR;
}
