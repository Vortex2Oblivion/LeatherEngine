package;

import sys.FileSystem;
import flxanimate.frames.FlxAnimateFrames;
import lime.utils.Assets;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

/**
 * Assets paths helper class
 */
class Paths {
	public static inline final SOUND_EXT:String = "ogg";

	private static var currentLevel:String = "preload";

	public static inline function setCurrentLevel(name:String):Void {
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>):String {
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null) {
			var levelPath = getLibraryPathForce(file, currentLevel);

			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");

			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload"):String
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String):String
		return '$library:assets/$library/$file';

	inline static public function getPreloadPath(file:String):String
		return 'assets/$file';

	inline static public function lua(key:String, ?library:String):String
		return getPath('data/$key.lua', TEXT, library);

	inline static public function hx(key:String, ?library:String):String
		return getPath('$key.hx', TEXT, library);

	inline static public function frag(key:String, ?library:String):String
		return getPath('shaders/$key.frag', TEXT, library);

	inline static public function vert(key:String, ?library:String):String
		return getPath('shaders/$key.vert', TEXT, library);

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String):String
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String):String
		return getPath('data/$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String):String
		return getPath('data/$key.xml', TEXT, library);

	inline static public function ui(key:String, ?library:String):String
		return getPath('ui/$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String):String
		return getPath('data/$key.json', TEXT, library);

	inline static public function video(key:String, ext:String = "mp4"):String
		return 'assets/videos/$key.$ext';

	inline static public function sound(key:String, ?library:String):String
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String):String
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String):String
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);

	inline static public function image(key:String, ?library:String):String
		return getPath('images/$key.png', IMAGE, library);

	inline static public function font(key:String):String
		return 'assets/fonts/$key';

	inline static public function ndll(key:String, ?library:String):String
		return getPath('ndlls/$key.ndll', TEXT, library);

	static public function voices(song:String, ?difficulty:String):String {
		if (difficulty != null) {
			if(difficulty.toLowerCase() == 'nightmare'){
				if (Assets.exists('songs:assets/songs/${song.toLowerCase()}/Voices-erect.$SOUND_EXT'))
					return 'songs:assets/songs/${song.toLowerCase()}/Voices-erect.$SOUND_EXT';
			}
			if (Assets.exists('songs:assets/songs/${song.toLowerCase()}/Voices-$difficulty.$SOUND_EXT'))
				return 'songs:assets/songs/${song.toLowerCase()}/Voices-$difficulty.$SOUND_EXT';
		}

		return 'songs:assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	static public function inst(song:String, ?difficulty:String):String {
		if (difficulty != null) {
			if(difficulty.toLowerCase() == 'nightmare'){
				if (Assets.exists('songs:assets/songs/${song.toLowerCase()}/Inst-erect.$SOUND_EXT'))
					return 'songs:assets/songs/${song.toLowerCase()}/Inst-erect.$SOUND_EXT';
			}
			if (Assets.exists('songs:assets/songs/${song.toLowerCase()}/Inst-$difficulty.$SOUND_EXT'))
				return 'songs:assets/songs/${song.toLowerCase()}/Inst-$difficulty.$SOUND_EXT';
		}

		return 'songs:assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	static public function songEvents(song:String, ?difficulty:String):String {
		if (difficulty != null) {
			if(difficulty.toLowerCase() == 'nightmare'){
				if (Assets.exists(Paths.json("song data/" + song.toLowerCase() + '/events-erect')))
					return Paths.json("song data/" + song.toLowerCase() + '/events-erect');
			}
			if (Assets.exists(Paths.json("song data/" + song.toLowerCase() + '/events-${difficulty.toLowerCase()}')))
				return Paths.json("song data/" + song.toLowerCase() + '/events-${difficulty.toLowerCase()}');
		}

		return Paths.json("song data/" + song.toLowerCase() + "/events");
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames {
		if (Assets.exists(file('images/$key.xml', library)))
			return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		else
			return FlxAtlasFrames.fromSparrow(image("Bind_Menu_Assets", "preload"), file('images/Bind_Menu_Assets.xml', "preload"));
	}

	inline static public function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames {
		if (Assets.exists(file('images/$key.txt', library)))
			return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		else
			return FlxAtlasFrames.fromSparrow(image("Bind_Menu_Assets", "preload"), file('images/Bind_Menu_Assets.xml', "preload"));
	}

	inline static public function getTextureAtlas(key:String, ?library:String):String {
		return getPath('images/$key', TEXT, library);
	}

	inline static public function getJsonAtlas(key:String, ?library:String):FlxAtlasFrames {
		return FlxAnimateFrames.fromJson(getPath('images/$key.json', TEXT, library));
	}
	
	inline static public function getEdgeAnimateAtlas(key:String, ?library:String):FlxAtlasFrames {
		return FlxAnimateFrames.fromEdgeAnimate(getPath('images/$key.eas', TEXT, library));
	}

	inline static public function getCocos2DAtlas(key:String, ?library:String):FlxAtlasFrames {
		return FlxAnimateFrames.fromCocos2D(getPath('images/$key.plist', TEXT, library));
	}

	inline static public function getEaselJSAtlas(key:String, ?library:String):FlxAtlasFrames {
		return FlxAnimateFrames.fromEaselJS(getPath('images/$key.js', TEXT, library));
	}

	inline static public function existsInMod(path:String, mod:String):Bool{
		return FileSystem.exists(path.replace('assets', 'mods/$mod'));
	}
}
