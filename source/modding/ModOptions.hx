package modding;

typedef ModOptions = {
    var options:Array<ModOption>;
}

typedef ModOption = {
    var name:String;
    var description:String;
    var save:String;
    var type:ModOptionType;
}

enum abstract ModOptionType(String) to String from String {
    var BOOL:String = "bool";
}