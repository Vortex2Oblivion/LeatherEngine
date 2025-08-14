package utilities;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import sys.FileSystem;
import game.SongLoader.FNFCMetadata;
import game.FreeplaySong;
import sys.io.File;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.graphics.Image;
import lime.utils.Assets;
import ui.logs.Logs;
import haxe.EntryPoint;
import haxe.Log;
import haxe.Json;
import haxe.PosInfos;

/**
 * Helper class with lots of utilitiy functions.
 */
@:cppFileCode('
	#include <iostream>
')
class CoolUtil {
	public static function boundTo(value:Float, min:Float, max:Float):Float {
		var newValue:Float = value;

		if (newValue < min)
			newValue = min;
		else if (newValue > max)
			newValue = max;

		return newValue;
	}

	public static function coolTextFileSys(path:String):Array<String> {
		#if sys
		var daList:Array<String> = File.getContent(path).trim().split('\n');

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
		#else
		return coolTextFile(path);
		#end
	}

	public static function coolTextFile(path:String):Array<String> {
		if (!Assets.exists(path)) {
			return [];
		}
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolTextFileOfArrays(path:String, ?delimeter:String = " "):Array<Array<String>> {
		if (!Assets.exists(path)) {
			return [[]];
		}
		var daListOg:Array<String> = coolTextFile(path);

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
	 * @see https://discord.com/channels/162395145352904705/162395145352904705/1157847259858354236
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
	 * @see https://discord.com/channels/162395145352904705/162395145352904705/1157847259858354236
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
	 * @see https://math.stackexchange.com/questions/556341/rgb-to-hsv-color-conversion-algorithm
	 * @see https://github.com/python/cpython/blob/3.9/Lib/colorsys.py
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

	public static var errors(default, never):Map<String, FlxText> = new Map<String, FlxText>();

	/**
		Funny handler for `Application.current.window.alert` that *doesn't* crash on Linux and shit.

		@param message Message of the error.
		@param title Title of the error.

		@author Leather128
	**/
	public static function coolError(message:String, title:String, ?pos:PosInfos):Void {
		if (errors.exists(title + "\n\n" + message) || #if haxe5 errors.size() #else Lambda.count(errors) #end >= 10) {
			return;
		}

		print(title + "-" + message, ERROR, pos);

		var text:FlxText = new FlxText(0, 0, 1280, title + "\n\n" + message, 32);
		text.font = Paths.font("vcr.ttf");
		text.color = 0xFF0000;
		text.alignment = CENTER;
		text.borderSize = 1.5;
		text.borderStyle = OUTLINE_FAST;
		text.borderColor = FlxColor.BLACK;
		text.scrollFactor.set();
		text.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		text.zIndex = FlxMath.MAX_VALUE_INT;
		errors.set(title + "\n\n" + message, text);

		FlxTween.tween(text, {alpha: 0, y: 64}, 4, {
			onComplete: function(_) {
				if (text != null && text.exists) {
					errors.remove(title + "\n\n" + message);
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
	public static function haxe_print(value:Dynamic, ?pos_infos:PosInfos):Void {
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
	public static function print(message:String, ?type:PrintType = LOG, ?infos:PosInfos):Void {
		untyped __cpp__("std::cout << {0}", '${Log.formatOutput('${messageFromPrintType(type)} $message', infos)}\n');
		final formattedMessage:String = Log.formatOutput(message, infos);
		EntryPoint.runInMainThread(() -> {
			switch (type) {
				case DEBUG:
					Logs.debug(formattedMessage);
				case WARNING:
					Logs.warn(formattedMessage);
				case ERROR:
					Logs.error(formattedMessage);
				default:
					Logs.log(formattedMessage);
			}
		});
	}

	public static function messageFromPrintType(?type:PrintType = LOG):String {
		var messagePrefix:String;
		switch (type) {
			case DEBUG:
				messagePrefix = '${ansi_colors["green"]} DEBUG';
			case WARNING:
				messagePrefix = '${ansi_colors["yellow"]} WARNING';
			case ERROR:
				messagePrefix = '${ansi_colors["red"]} ERROR';
			default:
				messagePrefix = '${ansi_colors["cyan"]} LOG';
		}
		return '$messagePrefix ${ansi_colors["default"]}';
	}

	/**
		Access to the old `haxe.Log.trace` function.

		@author Leather128
	**/
	public dynamic static function haxe_trace(v:Dynamic, ?infos:Null<PosInfos>) {}

	public static inline function getCurrentVersion():String {
		return 'v' + Application.current.meta.get('version');
	}

	public static function songExists(song:String, difficulty:String, ?mix:String):Bool {
		song = song.toLowerCase();
		difficulty = difficulty.toLowerCase();
		var exists:Bool = false;
		var songPath:String = 'song data/$song';
		var difficultyExtension:String = difficulty == 'normal' ? '' : '-$difficulty';
		var difficultyExtensionMeta:String = (difficulty == 'nightmare' || difficulty == 'erect') ? '-erect' : '';

		if (mix != null && Assets.exists('$difficultyExtensionMeta-$mix')) {
			difficultyExtensionMeta += '-$mix';
		}

		// legacy charts
		if (Assets.exists(Paths.json('$songPath/$song$difficultyExtension'))) {
			return true;
		} else {
			// no meta or no chart
			if (!Assets.exists(Paths.json('$songPath/$song-metadata$difficultyExtensionMeta'))
				|| !Assets.exists(Paths.json('$songPath/$song-chart$difficultyExtensionMeta'))) {
				return exists;
			}

			var meta:FNFCMetadata = cast Json.parse(Assets.getText(Paths.json('$songPath/$song-metadata$difficultyExtensionMeta')));
			if (meta.playData.difficulties.contains(difficulty)) {
				exists = true;
			}
		}

		return exists;
	}

	/**
	 * Clears all assets and other objects from the game's memory.
	 */
	public static function clearMemory():Void {
		if (Options.getData('memoryLeaks')) {
			return;
		}
		// Remove cached assets (prevents memory leaks that i can prevent)
		lime.utils.Assets.cache.clear();
		openfl.utils.Assets.cache.clear();
		#if MODDING_ALLOWED
		polymod.Polymod.clearCache();
		#end

		// Remove lingering sounds from the sound list
		FlxG.sound.list.forEachAlive(function(sound:flixel.sound.FlxSound):Void {
			FlxG.sound.list.remove(sound, true);
			sound.stop();
			sound.destroy();
		});
		FlxG.sound.list.clear();

		FlxG.bitmap.clearCache();

		// Clear actual assets from OpenFL and Lime itself
		var cache:openfl.utils.AssetCache = cast openfl.utils.Assets.cache;
		var lime_cache:lime.utils.AssetCache = cast lime.utils.Assets.cache;

		// this totally isn't copied from polymod/backends/OpenFLBackend.hx trust me
		for (key in cache.bitmapData.keys())
			cache.bitmapData.remove(key);
		for (key in cache.font.keys())
			cache.font.remove(key);

		for (key in cache.sound.keys()) {
			cache.sound.get(key).close();
			cache.sound.remove(key);
		}

		// this totally isn't copied from polymod/backends/LimeBackend.hx trust me
		for (key in lime_cache.image.keys())
			lime_cache.image.remove(key);
		for (key in lime_cache.font.keys())
			lime_cache.font.remove(key);
		for (key in lime_cache.audio.keys()) {
			lime_cache.audio.get(key).dispose();
			lime_cache.audio.remove(key);
		};

		Paths.graphics.clear();

		// Run built-in garbage collector
		#if cpp
		cpp.vm.Gc.compact();
		#end
		#if sys
		openfl.system.System.gc();
		#end
	}

	public static function convertFromFreeplaySongList() {
		final possibleLocations:Array<String> = [
			"data/freeplaySonglist.txt",
			"data/freeplaySongList.txt",
			"_append/data/freeplaySongList.txt",
			"_append/data/freeplaySonglist.txt"
		];

		inline function parseFreeplaySongList(list:Array<String>):Array<FreeplaySong> {
			var songs:Array<FreeplaySong> = [];
			for (i in 0...list.length) {
				if (list[i].trim() != "") {
					var listArray:Array<String> = list[i].split(":");

					var week:Int = Std.parseInt(listArray[2]);
					var icon:String = listArray[1];
					var song:String = listArray[0];

					var diffsStr:String = listArray[3];
					var diffs:Array<String> = ["easy", "normal", "hard"];

					var color:String = listArray[4] ?? "#00FF00";

					if (diffsStr != null)
						diffs = diffsStr.split(",");

					songs.push({
						name: song,
						week: week,
						icon: icon,
						difficulties: diffs,
						color: color,
						metadata: {
							composer: "",
							charter: "",
							modcharter: ""
						},
						menuConfig: {
							canBeEntered: true,
							showStats: true
						},
						extraData: {}
					});
				}
			}
			return songs;
		}

		var curMod:String = Options.getData("curMod");

		if (FileSystem.exists('./mods/$curMod/data/freeplay.json')) {
			return;
		}

		for (location in possibleLocations) {
			var pathToCheck:String = './mods/$curMod/$location';
			if (FileSystem.exists(pathToCheck)) {
				if (!FileSystem.exists('./mods/$curMod/data/')) {
					FileSystem.createDirectory('./mods/$curMod/data');
				}
				File.saveContent('./mods/$curMod/data/freeplay.json', Json.stringify({
					songs: parseFreeplaySongList(coolTextFileSys(pathToCheck)),
				}, "\t"));
				break;
			}
		}
	}

	public static function easeFromString(ease:String = 'linear'):EaseFunction {
		switch (ease.toLowerCase().trim()) {
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}

		return FlxEase.linear;
	}
}

enum abstract PrintType(String) to String from String {
	var LOG = "LOG";
	var DEBUG = "DEBUG";
	var WARNING = "WARNING";
	var ERROR = "ERROR";
}
