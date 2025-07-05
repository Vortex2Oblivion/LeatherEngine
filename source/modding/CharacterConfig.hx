package modding;

typedef CharacterConfig =
{
	var imagePath:String;
	var animations:Array<CharacterAnimation>;
	var defaultFlipX:Bool;

	@:optional
	var defaultFlipY:Bool;

	var dancesLeftAndRight:Bool;
	var graphicsSize:Null<Float>;
	var graphicSize:Null<Float>;
	var barColor:Array<Int>;
	var positionOffset:Array<Float>;
	var cameraOffset:Array<Float>;
	var singDuration:Null<Float>;

	var offsetsFlipWhenPlayer:Null<Bool>;
	var offsetsFlipWhenEnemy:Null<Bool>;
	var swapDirectionSingWhenPlayer:Null<Bool>;
	var trail:Null<Bool>;
	var trailLength:Null<Int>;
	var trailDelay:Null<Int>;
	var trailStalpha:Null<Float>;
	var trailDiff:Null<Float>;
	var deathCharacter:Null<String>;
	var deathCharacterName:Null<String>;
	// multiple characters stuff
	var characters:Array<CharacterData>;
	var healthIcon:String;
	var antialiased:Null<Bool>;
	var antialiasing:Null<Bool>;
	var mainCharacterID:Null<Int>;
	var followMainCharacter:Null<Bool>;
	/**
	 * Any extra spritesheets to be with the main sheet.
	 */
	@:optional
	var extraSheets:Array<String>;
}

typedef CharacterData =
{
	var name:String;
	var positionOffset:Array<Float>;
}

typedef CharacterAnimation =
{
	var name:String;
	var animation_name:String;
	var indices:Null<Array<Int>>;
	var fps:Int;
	var looped:Bool;
}
