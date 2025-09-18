package modding.scripts;

import haxe.io.Path;
import haxe.exceptions.NotImplementedException;

/**
	Base class for any scripting languages to inherit from.

	Usage:
		This class should be mainly used for creating different types
		of scripts of different languages. Like how Leather Engine supports
		both Lua and HScript, if you were to add another language
		you would just extend this (aka Python or something, idk what your plans are).

	@author Leather128
**/
class Script {
	public var executeOn:ExecuteOn;

    public var path:String;

    public var name:String;

	public var extension:String;

    public var otherScripts:Array<Script> = [];

    public var createPost:Bool = false;

	public function new(path:String, executeOn:ExecuteOn = BOTH) {
		path = path.replace(Sys.getCwd(), '').replace('/scripts/..', '');
		trace('Loading script at path \'${path}\'');
        this.path = path;
		var _path:Path = new Path(path);
        this.name = _path.file.replace(Sys.getCwd(), '').replace('/scripts/..', '');
		this.extension = _path.ext;
		this.executeOn = executeOn;
		_path = null; // We dont need this anymore
	}

	/**
		Calls the desired `func` (function) with the specified `arguments`.

		@param func The function name to call in the script.
		@param arguments (Optional) Array of arguments to run the `func` (function) with.

		@return `true` if the function was successfully ran,
			`false` if the function was unsuccessful, and
			`null` if the function was not specified.

		@author Leather128
	**/
	public function call(func:String, ?arguments:Array<Any>):Bool
		throw new NotImplementedException();

	/**
		Sets the desired `variable` to the specified `value`.

		@param variable `String` name for the variable to set.
		@param value `Any` value to set the `variable` to.

		@author Leather128
	**/
	public function set(variable:String, value:Any)
		throw new NotImplementedException();

	/**
		Setup the enviroment for a script.

		@return `true` if the enviroment was setup correctly,
			`false` if there was an exception, and
			`null` if the function wasn't specified.

		@author Leather128
	**/
	public function setup()
		throw new NotImplementedException();

	public function destroy()
		throw new NotImplementedException();
}
