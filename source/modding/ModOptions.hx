package modding;

typedef ModOptions = {
	var options:Array<ModOption>;
}

typedef ModOption = {
	var name:String;
	var description:String;
	var type:ModOptionType;

    @:optional
	var save:String;
    @:optional
	var defaultValue:Dynamic;
	@:optional
	var values:Array<String>;
    @:optional
    var script:String;
}

enum abstract ModOptionType(String) to String from String {
	var BOOL:String = "bool";
    var STRING:String = "string";
    var STATE:String = "state";
    var SUBSTATE:String = "substate";
}
