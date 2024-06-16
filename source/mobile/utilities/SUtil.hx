package mobile.utilities;

import lime.system.System as LimeSystem;
#if android
import android.Permissions as AndroidPermissions;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/**
 * A storage class for mobile.
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class SUtil
{
	#if sys
	public static function getStorageDirectory(?force:Bool = false):String
	{
		var daPath:String = Sys.getCwd();
		#if android
		daPath = haxe.io.Path.addTrailingSlash(android.os.Build.VERSION.SDK_INT > 30 ? android.content.Context.getObbDir() : android.content.Context.getExternalFilesDir());
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#end

		return daPath;
	}

	public static function mkDirs(directory:String):Void
	{
		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				try
				{
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
				catch (e:haxe.Exception)
					trace('Error while creating folder. (${e.message})');
			}
		}
	}

	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'You forgor to add somethin\' in yo code :3'):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/' + fileName + fileExtension, fileData);
			showPopUp(fileName + " file has been saved.", "Success!");
		}
		catch (e:haxe.Exception)
			trace('File couldn\'t be saved. (${e.message})');
	}

	#if android
	public static function doPermissionsShit():Void
	{
		if (!AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.WRITE_EXTERNAL_STORAGE'))
		{
			AndroidPermissions.requestPermission('READ_EXTERNAL_STORAGE');
			AndroidPermissions.requestPermission('WRITE_EXTERNAL_STORAGE');
			showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress Ok to see what happens',
				'Notice!');
		}
		else
		{
			try
			{
				if (!FileSystem.exists(SUtil.getStorageDirectory()))
					FileSystem.createDirectory(SUtil.getStorageDirectory());
			}
			catch (e:Dynamic)
			{
				showPopUp('Please create folder to\n' + SUtil.getStorageDirectory(true) + '\nPress OK to close the game', 'Error!');
				LimeSystem.exit(1);
			}
		}
	}
	#end
	#end

	public static function showPopUp(message:String, title:String):Void
	{
		#if !ios
		try
		{
			flixel.FlxG.stage.window.alert(message, title);
		}
		catch (e:Dynamic)
			trace('$title - $message');
		#else
		trace('$title - $message');
		#end
	}
}