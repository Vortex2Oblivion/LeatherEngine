package modding.scripts;

/**
    Base class for any scripting languages to inherit from.

    Usage:
        This class should be mainly used for creating different types
        of scripts of different languages. Like how Leather Engine supports
        both Lua and HScript, if you were to add another language
        you would just extend this (aka Python or something, idk what your plans are).

    @author Leather128
**/
class Script
{
    public function new(script_path:String)
    {
        // Simple trace as actual loading logic is held in the extension of this class
        trace('Loading script at path \'${script_path}\'', DEBUG);
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
    public function call(func:String, ?arguments:Array<Dynamic>):Null<Bool>
        return null;

    /**
        Sets the desired `variable` to the specified `value`.

        @param variable `String` name for the variable to set.
        @param value `Dynamic` value to set the `variable` to.

        @return `true` if the variable didn't already exist and was succesfully set,
            `false` if the variable already existed and thus wasn't set (should trace an error), and
            `null` if the function was not specified.

        @author Leather128
    **/
    public function set(variable:String, value:Dynamic):Null<Bool>
        return null;

    /**
        Setup the enviroment for a script.

        @return `true` if the enviroment was setup correctly,
            `false` if there was an exception, and
            `null` if the function wasn't specified.
        
        @author Leather128
    **/
    public function setup_enviroment():Null<Bool>
        return null;
}