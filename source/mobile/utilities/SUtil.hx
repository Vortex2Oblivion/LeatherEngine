package mobile.utilities;

import lime.system.System as LimeSystem;
#if android
import android.Permissions as AndroidPermissions;
import android.os.Environment as AndroidEnvironment;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/**
 * A storage utility class for mobile platforms.
 * Provides methods for handling storage directories, creating directories, saving content, and requesting permissions for android.
 * 
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class SUtil
{
    #if sys
    /**
     * The root directory for application storage.
     */
    public static final rootDir:String = LimeSystem.applicationStorageDirectory;

    /**
     * Gets the storage directory based on the platform and optional forced storage type.
     * 
     * @param forcedType The optional forced storage type.
     * @return The path to the storage directory.
     */
    public static function getStorageDirectory(?forcedType:Null<String>):String
    {
        var daPath:String = Sys.getCwd();
        #if android
        if (!FileSystem.exists(rootDir + 'storagetype.txt'))
            File.saveContent(rootDir + 'storagetype.txt', Options.getData("storageType"));
        var curStorageType:String = File.getContent(rootDir + 'storagetype.txt');
        if (forcedType != null) curStorageType = forcedType;
        daPath = switch (curStorageType)
        {
            case "EXTERNAL": AndroidEnvironment.getExternalStorageDirectory() + '/.' + lime.app.Application.current.meta.get('file');
            case "OBB": android.content.Context.getObbDir();
            case "MEDIA": AndroidEnvironment.getExternalStorageDirectory() + '/Android/media/' + lime.app.Application.current.meta.get('packageName');
            default: android.content.Context.getExternalFilesDir();
        }
        daPath = haxe.io.Path.addTrailingSlash(daPath);
        #elseif ios
        daPath = LimeSystem.documentsDirectory;
        #end

        return daPath;
    }

    /**
     * Creates directories along the specified path.
     * 
     * @param directory The path of the directory to create.
     */
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
                    CoolUtil.coolError('Error while creating folder. (${e.message})');
            }
        }
    }

    /**
     * Saves content to a file in the saves directory.
     * 
     * @param fileName The name of the file.
     * @param fileExtension The extension of the file. Defaults to '.json'.
     * @param fileData The content to save in the file. Defaults to a placeholder string.
     */
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
            CoolUtil.coolError('File couldn\'t be saved. (${e.message})');
    }

    #if android
    /**
     * Requests Android permissions for external storage access.
     */
    public static function doPermissionsShit():Void
    {
        if (!AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')
            && !AndroidPermissions.getGrantedPermissions().contains('android.permission.WRITE_EXTERNAL_STORAGE'))
        {
            AndroidPermissions.requestPermission('READ_EXTERNAL_STORAGE');
            AndroidPermissions.requestPermission('WRITE_EXTERNAL_STORAGE');
            showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress Ok to see what happens',
                'Notice!');
            if (!AndroidEnvironment.isExternalStorageManager())
                android.Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
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
                showPopUp('Please create folder to\n' + SUtil.getStorageDirectory() + '\nPress OK to close the game', 'Error!');
                LimeSystem.exit(1);
            }
        }
    }
    #end
    #end

    /**
     * Displays a pop-up message.
     * 
     * @param message The message to display in the pop-up.
     * @param title The title of the pop-up.
     */
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
