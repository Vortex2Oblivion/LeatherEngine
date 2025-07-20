package game;

import haxe.ds.ArraySort;
import flixel.util.FlxSort;
import utilities.NoteVariables;
import haxe.Json;
import lime.utils.Assets;

class SongLoader {
	public static function getPath(difficulty:String, ?folder:String, ?mix:String):String {
		var chartSuffix:String = '';
		if (difficulty.toLowerCase() == 'erect' || difficulty.toLowerCase() == 'nightmare') {
			chartSuffix = '-erect';
		}
		if (mix != null) {
			chartSuffix += '-${mix.toLowerCase()}';
		}
		folder = folder.toLowerCase();
		difficulty = difficulty.toLowerCase();
		var path:String = Paths.json('song data/$folder/$folder-chart$chartSuffix');
		if (!Assets.exists(path)) { // prefer FNFC charts lol
			path = Paths.json('song data/$folder/$folder${difficulty != 'normal' ? '-$difficulty' : ''}');
		}

		return path;
	}

	public static function loadFromJson(difficulty:String, ?folder:String, ?mix:String):SongData {
		var path:String = getPath(difficulty, folder, mix);
		var raw:String = Assets.getText(path).trim();
		if (raw == '') { // should never happen but just in case
			var tutorialPath:String = getPath('normal', 'tutorial', null);
			if (!Assets.exists(tutorialPath)) {
				trace("Why the fuck did you remove tutorial and the song doesn't exist too");
				return null;
			}

			raw = Assets.getText(tutorialPath).trim();
			return parseRaw(raw, folder, difficulty, mix, true);
		}

		return parseRaw(raw, folder, difficulty, mix);
	}

	public static function parseRaw(raw:String, songName:String, difficulty:String, ?mix:String, force:Bool = false):SongData {
		var parsedJSON:Dynamic = Json.parse(raw);

		if (parsedJSON.song == null) { // invalid chart OR (more likely) new format!
			return parseFNFC(parsedJSON, songName, difficulty, mix);
		} else {
			return parseLegacy(parsedJSON, songName, force);
		}
	}

	public static function parseFNFC(parsedJSON:Dynamic, songName:String, difficulty:String, ?mix:String):SongData {
		difficulty = difficulty.toLowerCase();
		var chartSuffix:String = '';
		if (difficulty.toLowerCase() == 'erect' || difficulty.toLowerCase() == 'nightmare') {
			chartSuffix = '-erect';
		}
		if (mix != null) {
			chartSuffix += '-${mix.toLowerCase()}';
		}
		var metaPath:String = Paths.json('song data/$songName/$songName-metadata$chartSuffix');
		if (!Assets.exists(metaPath)) {
			if (Assets.exists(metaPath.toLowerCase())) {
				metaPath = metaPath.toLowerCase();
			} else {
				trace('You can\'t load an FNFC chart without putting in the metadata!', ERROR);
				return null;
			}
		}

		var metadata:FNFCMetadata = cast Json.parse(Assets.getText(metaPath).trim());
		var song:FNFCSong = cast parsedJSON;
		// TODO: BPM CHANGES
		var output:SongData = {
			validScore: true,
			keyCount: 4,
			playerKeyCount: 4,
			chartOffset: 0.0,
			timescale: [4, 4],
			needsVoices: true, // no way to specify this really
			song: metadata.songName,
			bpm: metadata.timeChanges[0].bpm,
			player1: metadata.playData.characters.player,
			player2: metadata.playData.characters.opponent,
			gf: metadata.playData.characters.girlfriend,
			stage: metadata.playData.stage,
			speed: Reflect.field(song.scrollSpeed, difficulty),
			ui_Skin: 'default',
			notes: [
				{
					sectionNotes: [],
					lengthInSteps: 16,
					mustHitSection: true,
					bpm: metadata.timeChanges[0].bpm,
					changeBPM: false,
					altAnim: false,
					timeScale: [0, 0],
					changeTimeScale: false
				}
			],
			specialAudioName: null,
			player3: null,
			modchartingTools: false,
			modchartPath: null,
			mania: null,
			gfVersion: null,
			events: [],
			endCutscene: metadata.playData.endCutscene,
			cutscene: metadata.playData.cutscene,
			moveCamera: false,
			chartType: VSLICE
		};

		// should work with custom skins i think
		if (metadata.playData.noteStyle != 'funkin') {
			output.ui_Skin = metadata.playData.noteStyle;
		}

		if (song == null) {
			trace("Couldn't find FNFC chart json properly");
			return output;
		}

		var notes:Array<FNFCNote> = cast Reflect.field(song.notes, difficulty);
		if (notes == null) {
			trace("Couldn't find the difficulty '" + difficulty + "' for the chart being loaded, sorry! (FNFC)");
			return output;
		}
		var bpm:Float = metadata.timeChanges[0].bpm;
		var curSection:Int = 0;
		var crochet:Float = Conductor.calculateCrochet(bpm);
		for (note in notes) {
			if (Math.ceil(note.t) >= Math.floor((curSection + 1) * (crochet * 4))) {
				curSection++;
				output.notes.push({
					sectionNotes: [],
					lengthInSteps: 16,
					mustHitSection: true,
					bpm: bpm,
					changeBPM: false,
					altAnim: false,
					timeScale: [0, 0],
					changeTimeScale: false
				});
			}
			output.notes[curSection].sectionNotes.push([note.t, note.d, note.l, 0, note.k ?? 'default']);
		}

		// engine specific shit

		// TODO: implement all events
		for (event in song.events) {
			switch (event.e.toLowerCase()) {
				case 'focuscamera':
					output.events.push([event.e, event.t, event.v.char ?? event.v, '${event.v.x},${event.v.y}']);
				case 'zoomcamera':
					output.events.push([event.e, event.t, event.v.zoom, '${event.v.ease},${event.v.duration}']);
				case 'setcamerabop':
					output.events.push(['change camera zoom strength', event.t, event.v.intensity, event.v.rate]);
				case 'playanimation':
					output.events.push([event.e, event.t, event.v.target, '${event.v.anim},${event.v.force}']);
				case 'scrollspeed':
					output.events.push([
						event.e,
						event.t,
						'${event.v.duration},${event.v.scroll}',
						'${event.v.strumline},${event.v.ease},${event.v.absolute}'
					]);
				default:
					output.events.push([event.e, event.t, Std.string(event.v), '']);
			}
		}

		return output;
	}

	public static function parseLegacy(parsedJSON:Dynamic, ?songName:String, force:Bool = false):SongData {
		var song:SongData = cast parsedJSON.song;
		song.validScore = true;

		if (force)
			song.song = songName;

		if (song.keyCount == null)
			song.keyCount = 4;

		// support the dumb psych exkey shit
		if (song.mania != null) {
			song.keyCount = song.mania + 1;
			song.mania = null;
		}

		if (song.playerKeyCount == null)
			song.playerKeyCount = song.keyCount;

		if (song.ui_Skin == null)
			song.ui_Skin = song.song == "Senpai" || song.song == "Roses" || song.song == "Thorns" ? "pixel" : "default";

		if (song.timescale == null)
			song.timescale = [4, 4];

		if (song.chartOffset == null)
			song.chartOffset = 0.0;

		// guarenteed safe value
		song.keyCount = Math.floor(Math.min(song.keyCount, NoteVariables.maniaDirections.length));

		if (song.events == null)
			song.events = [];

		if (song.gf == null) {
			if (song.gfVersion != null)
				song.gf = song.gfVersion;

			// prefer player3 since it's newer ig
			if (song.player3 != null)
				song.gf = song.player3;
		}

		var events:Array<Array<Dynamic>> = [];
		for (rawEvent in song.events) {
			// aka, if(event == A Psych Engine Event Lmfao)
			if ((rawEvent[0] is Float || rawEvent[0] is Int) && rawEvent[1] is Array) {
				var psychEvents:Array<Array<Dynamic>> = rawEvent[1];
				var time:Float = rawEvent[0]; // might cast to float, oh well
				// convert all events to correct format
				for (psychEvent in psychEvents) {
					events.push([
						Std.string(psychEvent[0]), // name
						time, // time
						Std.string(psychEvent[1]), // param 1
						Std.string(psychEvent[2]) // param 2
					]);
				}
			} else { // should be supported since it's not psych
				events.push(rawEvent);
			}
		}

		// parse older psych events too
		if (song.notes != null) {
			for (i in 0...song.notes.length) {
				var sec:Section = song.notes[i];
				var notes:Array<Dynamic> = sec.sectionNotes;
				var noteCount:Int = notes.length;
				var noteIndex:Int = 0;
				while (noteIndex < noteCount) {
					var note:Array<Dynamic> = notes[noteIndex];
					if (note[3] is String) {
						note[4] = note[3];
					}
					if (note[1] < 0 && note[2] is String) {
						if (note[3] == null)
							note[3] = '';
						if (note[4] == null)
							note[4] = '';

						events.push([note[2], note[0], note[3], note[4]]);
						notes.remove(note);
						noteCount = notes.length;
					} else {
						noteIndex++;
					}
				}
			}
		}

		song.events = events;
		song.moveCamera = true;

		song.chartType = LEGACY;

		return song;
	}
}

typedef Section = {
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;

	var timeScale:Array<Int>;
	var changeTimeScale:Bool;
}

enum abstract ChartType(String) to String from String {
	var LEGACY = "LEGACY";
	var VSLICE = "VSLICE";
}

typedef SongData = {
	// 0.2.8 and before stuff
	var song:Null<String>;
	var notes:Null<Array<Section>>;
	var bpm:Null<Float>;
	var needsVoices:Null<Bool>;
	var speed:Null<Float>;
	var player1:Null<String>;
	var player2:Null<String>;
	var validScore:Null<Bool>;

	// engine specific shit
	var gf:Null<String>;
	var stage:Null<String>;
	var ui_Skin:Null<String>;

	var modchartPath:Null<String>;
	var modchartingTools:Null<Bool>;

	var keyCount:Null<Int>;
	var playerKeyCount:Null<Int>;
	var events:Null<Array<Array<Dynamic>>>;

	var cutscene:Null<String>;
	var endCutscene:Null<String>;

	var timescale:Null<Array<Int>>;
	var chartOffset:Null<Float>; // in milliseconds
	var specialAudioName:Null<String>;

	var chartType:ChartType;

	// psych compat
	var gfVersion:Null<String>;
	var player3:Null<String>;

	// shaggy moment (ugh)
	var mania:Null<Int>;
	var moveCamera:Null<Bool>;
}

typedef FNFCTimeChange = {
	var t:Float; // time
	var b:Float; // beat
	var bpm:Float;
	// there are other values
	// but we won't use them
	// sorry! :p (we don't have good time sig support lo)
}

typedef FNFCCharacters = {
	var player:String;
	var girlfriend:String;
	var opponent:String;
}

typedef FNFCPlayData = {
	var difficulties:Array<String>;
	var characters:FNFCCharacters;
	var stage:String;
	var noteStyle:String;
	var cutscene:String;
	var endCutscene:String;
}

// this doesn't have everything,
// just the important stuff we need.
typedef FNFCMetadata = {
	var songName:String;
	var playData:FNFCPlayData;
	var timeChanges:Array<FNFCTimeChange>;
}

typedef FNFCEvent = {
	var t:Float; // time
	var e:String; // event
	var v:Dynamic; // value
}

typedef FNFCNote = {
	var t:Float; // time
	var d:Int; // direction
	var l:Float; // length
	var k:Null<String>; // kind
}

typedef FNFCSong = {
	var scrollSpeed:Dynamic; // basically a Map<String, Float> but not really
	var events:Array<FNFCEvent>;
	var notes:Dynamic; // basically a Map<String, Array<FNFCNote>> but not really
}
