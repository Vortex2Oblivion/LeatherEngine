package game;

import utilities.NoteVariables;
import haxe.Json;
import lime.utils.Assets;

class SongLoader {
	public static function loadFromJson(difficulty:String, ?folder:String):SongData {
		var chartSuffix:String = '';
		if(difficulty.toLowerCase() == 'erect' || difficulty.toLowerCase() == 'nightmare'){
			chartSuffix = '-erect';
		}
		folder = folder.toLowerCase();
		difficulty = difficulty.toLowerCase();
		var path:String = Paths.json('song data/$folder/$folder-chart$chartSuffix');
		if (!Assets.exists(path)) { // prefer FNFC charts lol
			path = Paths.json('song data/$folder/$folder${difficulty != 'normal' ? '-$difficulty' : ''}');
		}

		var raw:String = Assets.getText(path).trim();
		if (raw == '') { // should never happen but just in case
			raw = Assets.getText(Paths.json('song data/tutorial/tutorial')).trim();
			return parseRaw(raw, folder, difficulty, true);
		}

		return parseRaw(raw, folder, difficulty);
	}

	public static function parseRaw(raw:String, songName:String, difficulty:String, force:Bool = false):SongData {
		var parsedJSON:Dynamic = Json.parse(raw);

		if (parsedJSON.song == null) { // invalid chart OR (more likely) new format!
			return parseFNFC(parsedJSON, songName, difficulty);
		} else {
			return parseLegacy(parsedJSON, songName, force);
		}
	}

	public static function parseFNFC(parsedJSON:Dynamic, songName:String, difficulty:String):SongData {
		var chartSuffix:String = '';
		if(difficulty.toLowerCase() == 'erect' || difficulty.toLowerCase() == 'nightmare'){
			chartSuffix = '-erect';
		}
		var metaPath:String = Paths.json('song data/$songName/$songName-metadata$chartSuffix');
		if (!Assets.exists(metaPath)) {
			trace('You can\'t load an FNFC chart without putting in the metadata!', ERROR);
			return null;
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
					bpm: 0.0,
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
		};

		// should work with custom skins i think
		if (metadata.playData.noteStyle != 'funkin') {
			output.ui_Skin = metadata.playData.noteStyle;
		}

		var section:Section = output.notes[0];
		var notes:Array<FNFCNote> = cast Reflect.field(song.notes, difficulty);
		for (note in notes) {
			// [time, dir, length, type]
			section.sectionNotes.push([note.t, note.d, note.l, note.k != null ? note.k : 'default']);
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
					output.events.push(['play character animation', event.t, event.v.target, event.v.anim]);
				default:
					output.events.push([event.e, event.t, Std.string(event.v), '']);
			}
		}

		return output;
	}

	public static function parseLegacy(parsedJSON:Dynamic, songName:String, force:Bool = false):SongData {
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
		song.keyCount = Math.floor(Math.min(song.keyCount, NoteVariables.Note_Count_Directions.length));

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
					if(note[3] is String){
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
