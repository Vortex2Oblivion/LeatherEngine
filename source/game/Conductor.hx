package game;

import game.SongLoader.SongData;

using StringTools;

typedef BPMChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;

	@:optional
	var stepCrochet:Float;
}

typedef TimeScaleChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var timeScale:Array<Int>;
}

class Conductor {
	/**
	 * The BPM (Beats Per Minute) of the current song.
	 */
	public static var bpm:Float = 100;

	/**
	 * Beats in milliseconds
	 */
	public static var crochet:Float = ((60 / bpm) * 1000);

	/**
	 * Steps in milliseconds
	 */
	public static var stepCrochet:Float = crochet / 4;

	/**
	 * The position of the song in milliseconds.
	 */
	public static var songPosition:Float;

	public static var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000); // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var timeScaleChangeMap:Array<TimeScaleChangeEvent> = [];

	public static var timeScale:Array<Int> = [4, 4];

	public static var stepsPerSection:Int = 16;

	public function new() {}

	public static function recalculateStuff(?multi:Float = 1) {
		safeZoneOffset = Math.floor((safeFrames / 60) * 1000) * multi;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / timeScale[1];

		stepsPerSection = Math.floor((16 / timeScale[1]) * timeScale[0]);
	}

	public static function mapBPMChanges(song:SongData, ?songMultiplier:Float = 1.0) // also maps time signature changes cuz frick u
	{
		bpmChangeMap = [];
		timeScaleChangeMap = [];

		var curBPM:Float = song.bpm;
		var curTimeScale:Array<Int> = timeScale;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length) {
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM) {
				curBPM = song.notes[i].bpm;

				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};

				bpmChangeMap.push(event);
			}

			if (song.notes[i].changeTimeScale
				&& song.notes[i].timeScale[0] != curTimeScale[0]
				&& song.notes[i].timeScale[1] != curTimeScale[1]) {
				curTimeScale = song.notes[i].timeScale;

				var event:TimeScaleChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					timeScale: curTimeScale
				};

				timeScaleChangeMap.push(event);
			}

			var deltaSteps:Int = Math.floor((16 / curTimeScale[1]) * curTimeScale[0]);
			totalSteps += deltaSteps;

			totalPos += ((60 / curBPM) * 1000 / curTimeScale[0]) * deltaSteps;
		}

		recalculateStuff(songMultiplier);
	}

	public static function changeBPM(newBpm:Float, ?multi:Float = 1) {
		bpm = newBpm;
		recalculateStuff(multi);
	}

	inline public static function calculateCrochet(bpm:Float) {
		return (60 / bpm) * 1000;
	}

	public static function getBPMFromSeconds(time:Float):BPMChangeEvent {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm
		}

		for (i in 0...Conductor.bpmChangeMap.length) {
			if (time >= Conductor.bpmChangeMap[i].songTime) {
				lastChange = Conductor.bpmChangeMap[i];
			}
		}
		lastChange.stepCrochet = calculateCrochet(lastChange.bpm) / 4;

		return lastChange;
	}

	// i stole this from psych engine lol :p

	/**
	 * Returns the current step at the given position of the song.
	 * @param time the position of the song (in millseconds)
	 */
	public static inline function getStep(time:Float) {
		var lastChange:BPMChangeEvent = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	/**
	 * Returns the current beat at the given position of the song.
	 * @param time the position of the song (in millseconds)
	 */
	public static inline function getBeat(time:Float) {
		return getStep(time) / 4;
	}
}
