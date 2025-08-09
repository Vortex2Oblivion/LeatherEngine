package game;

class Replay {
	public var inputs:Array<Array<Float>>;

	public function new() {
		inputs = [];
	}

	public inline function recordKeyHit(strumTime:Float, noteDifference:Float) {
		inputs.push([strumTime, noteDifference]);
	}
}
