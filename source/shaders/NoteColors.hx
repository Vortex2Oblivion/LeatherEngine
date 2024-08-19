package shaders;

class NoteColors {
	public static var noteColors:Map<String, Array<Int>> = new Map<String, Array<Int>>();

	public static final defaultColors:Map<String, Array<Int>> = [
		"left" => [194, 75, 153],
		"down" => [0, 255, 255],
		"up" => [18, 250, 5],
		"right" => [249, 57, 63],
		"square" => [204, 204, 204],
		"left2" => [255, 255, 0],
		"down2" => [139, 74, 255],
		"up2" => [255, 0, 0],
		"right2" => [0, 51, 255],
		"rleft" => [255, 0, 0],
		"rdown" => [30, 255, 255],
		"rup" => [0, 255, 33],
		"rright" => [30, 41, 255],
		"plus" => [175, 0, 158],
		"rleft2" => [98, 0, 255],
		"rdown2" => [169, 255, 30],
		"rup2" => [255, 131, 0],
		"rright2" => [30, 255, 105]
	];

	public static function setNoteColor(note:String, color:Array<Int>):Void {
		noteColors.set(note, color);
		Options.setData(noteColors, "arrowColors", "arrowColors");
	}

	public static function getNoteColor(note:String):Array<Int> {
		if (!noteColors.exists(note))
			setNoteColor(note, defaultColors.get(note));

		return noteColors.get(note);
	}

	public static function load():Void {
		if (Options.getData("arrowColors", "arrowColors") != null)
			noteColors = Options.getData("arrowColors", "arrowColors");
		else
			Options.setData(defaultColors, "arrowColors", "arrowColors");
	}
}
