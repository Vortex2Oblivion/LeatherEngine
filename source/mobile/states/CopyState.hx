package mobile.states;

import states.TitleState;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets as OpenFLAssets;
import flixel.addons.util.FlxAsyncLoop;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.utils.ByteArray;
import haxe.io.Path;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

/**
 * The CopyState class handles the copying of missing game assets from internal storage
 * to the appropriate directories on the file system.
 */
class CopyState extends states.MusicBeatState {
	/**
	 * Static variables to store located files, maximum loop times, and the name of the ignore file.
	 */
	public static var locatedFiles:Array<String> = [];

	/**
	 * The maximum number of iterations the copy loop will perform.
	 * This value is determined by the number of files that need to be copied.
	 */
	public static var maxLoopTimes:Int = 0;

	/**
	 * The name of the file that contains a list of folders to ignore during the copy process.
	 */
	public static final IGNORE_FOLDER_FILE_NAME:String = "ignore.txt";

	@:dox(hide) public var loadingImage:FlxSprite;
	@:dox(hide) public var bottomBG:FlxSprite;
	@:dox(hide) public var loadedText:FlxText;

	/**
	 * An asynchronous loop that handles the file copying process.
	 * It will iterate through the files to be copied and handle each file asynchronously.
	 */
	public var copyLoop:FlxAsyncLoop;

	var loopTimes:Int = 0;
	var failedFiles:Array<String> = [];
	var failedFilesStack:Array<String> = [];
	var canUpdate:Bool = true;
	var shouldCopy:Bool = false;

	/**
	 * A list of file extensions that are considered text files.
	 * These file types will be handled appropriately during the copy process.
	 */
	private static final textFilesExtensions:Array<String> = ['ini', 'txt', 'xml', 'hxs', 'hx', 'lua', 'json', 'frag', 'vert'];

	override function create() {
		locatedFiles = [];
		maxLoopTimes = 0;
		checkExistingFiles();
		if (maxLoopTimes <= 0) {
			FlxG.switchState(new TitleState());
			return;
		}

		SUtil.showPopUp("Seems like you have some missing files that are necessary to run the game\nPress OK to begin the copy process", "Notice!");

		shouldCopy = true;

		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d));

		loadingImage = new FlxSprite(0, 0, Paths.image('funkay'));
		loadingImage.setGraphicSize(0, FlxG.height);
		loadingImage.updateHitbox();
		loadingImage.screenCenter();
		add(loadingImage);

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		loadedText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, '', 16);
		loadedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(loadedText);

		var ticks:Int = 15;
		if (maxLoopTimes <= 15)
			ticks = 1;

		copyLoop = new FlxAsyncLoop(maxLoopTimes, copyAsset, ticks);
		add(copyLoop);
		copyLoop.start();

		super.create();
	}

	override function update(elapsed:Float) {
		if (shouldCopy && copyLoop != null) {
			if (copyLoop.finished && canUpdate) {
				if (failedFiles.length > 0) {
					SUtil.showPopUp(failedFiles.join('\n'), 'Failed To Copy ${failedFiles.length} File.');
					if (!FileSystem.exists('logs'))
						FileSystem.createDirectory('logs');
					File.saveContent('logs/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '-CopyState' + '.txt', failedFilesStack.join('\n'));
				}
				canUpdate = false;
				FlxG.sound.play(Paths.sound('confirmMenu')).onComplete = () -> {
					FlxG.switchState(new TitleState());
				};
			}

			if (maxLoopTimes == 0)
				loadedText.text = "Completed!";
			else
				loadedText.text = '$loopTimes/$maxLoopTimes';
		}
		super.update(elapsed);
	}

	/**
	 * Function to copy an asset from internal storage to the file system.
	 */
	public function copyAsset() {
		var file = locatedFiles[loopTimes];
		loopTimes++;
		if (!FileSystem.exists(file)) {
			var directory = Path.directory(file);
			if (!FileSystem.exists(directory))
				SUtil.mkDirs(directory);
			try {
				if (OpenFLAssets.exists(getFile(file))) {
					if (textFilesExtensions.contains(Path.extension(file)))
						createContentFromInternal(file);
					else
						File.saveBytes(file, getFileBytes(getFile(file)));
				} else {
					failedFiles.push(getFile(file) + " (File Dosen't Exist)");
					failedFilesStack.push('Asset ${getFile(file)} does not exist.');
				}
			} catch (e:haxe.Exception) {
				failedFiles.push('${getFile(file)} (${e.message})');
				failedFilesStack.push('${getFile(file)} (${e.stack})');
			}
		}
	}

	/**
	 * Function to create content from internal storage for text files.
	 * @param file The file path to copy.
	 */
	public function createContentFromInternal(file:String) {
		var fileName = Path.withoutDirectory(file);
		var directory = Path.directory(file);
		try {
			var fileData:String = OpenFLAssets.getText(getFile(file));
			if (fileData == null)
				fileData = '';
			if (!FileSystem.exists(directory))
				SUtil.mkDirs(directory);
			File.saveContent(Path.join([directory, fileName]), fileData);
		} catch (e:haxe.Exception) {
			failedFiles.push('${getFile(file)} (${e.message})');
			failedFilesStack.push('${getFile(file)} (${e.stack})');
		}
	}

	/**
	 * Function to get the byte content of a file.
	 * @param file The file path to get bytes from.
	 * @return The byte array of the file.
	 */
	public function getFileBytes(file:String):ByteArray {
		switch (Path.extension(file)) {
			case 'otf' | 'ttf':
				return ByteArray.fromFile(file);
			default:
				return OpenFLAssets.getBytes(file);
		}
	}

	/**
	 * Function to get the file path from assets.
	 * @param file The file path to check.
	 * @return The actual file path in the assets.
	 */
	public static function getFile(file:String):String {
		if (OpenFLAssets.exists(file))
			return file;

		@:privateAccess
		for (library in LimeAssets.libraries.keys()) {
			if (OpenFLAssets.exists('$library:$file') && library != 'default')
				return '$library:$file';
		}

		return file;
	}

	/**
	 * Function to check for existing files and update the list of files to be copied.
	 * @return Whether there are files to copy.
	 */
	public static function checkExistingFiles():Bool {
		locatedFiles = OpenFLAssets.list();

		// removes unwanted assets
		var assets = locatedFiles.filter(folder -> folder.startsWith('assets/'));
		var mods = locatedFiles.filter(folder -> folder.startsWith('mods/'));
		locatedFiles = assets.concat(mods);

		var filesToRemove:Array<String> = [];

		for (file in locatedFiles) {
			if (FileSystem.exists(file)
				|| OpenFLAssets.exists(getFile(Path.join([Path.directory(getFile(file)), IGNORE_FOLDER_FILE_NAME])))) {
				filesToRemove.push(file);
			}
		}

		for (file in filesToRemove)
			locatedFiles.remove(file);

		maxLoopTimes = locatedFiles.length;

		return (maxLoopTimes <= 0);
	}
}
