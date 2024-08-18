package utilities;

import game.TimeBar;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import states.PlayState;
import flixel.FlxG;
import game.Conductor;
import game.StageGroup;

class EventHandeler {
	public static function processEvent(game:PlayState, event:Array<Dynamic>) {
		switch (event[0].toLowerCase()) {
			#if !linc_luajit
			case "hey!":
				var charString:String = event[2].toLowerCase();

				var char:Int = 0;

				if (charString == "bf" || charString == "boyfriend" || charString == "player" || charString == "player1")
					char = 1;

				if (charString == "gf" || charString == "girlfriend" || charString == "player3")
					char = 2;

				switch (char) {
					case 0:
						boyfriend.playAnim("hey", true);
						gf.playAnim("cheer", true);
					case 1:
						boyfriend.playAnim("hey", true);
					case 2:
						gf.playAnim("cheer", true);
				}
			case "set gf speed":
				if (Std.parseInt(event[2]) != null)
					gfSpeed = Std.parseInt(event[2]);
			case "character will idle":
				var char = getCharFromEvent(event[2]);

				var funny = Std.string(event[3]).toLowerCase() == "true";

				char.shouldDance = funny;
			case "set camera zoom":
				var defaultCamZoomThing:Float = Std.parseFloat(event[2]);
				var hudCamZoomThing:Float = Std.parseFloat(event[3]);

				if (Math.isNaN(defaultCamZoomThing))
					defaultCamZoomThing = defaultCamZoom;

				if (Math.isNaN(hudCamZoomThing))
					hudCamZoomThing = 1;

				defaultCamZoom = defaultCamZoomThing;
				defaultHudCamZoom = hudCamZoomThing;
			case "change character alpha":
				var char = getCharFromEvent(event[2]);

				var alphaVal:Float = Std.parseFloat(event[3]);

				if (Math.isNaN(alphaVal))
					alphaVal = 0.5;

				char.alpha = alphaVal;
			case "play character animation":
				var character:Character = getCharFromEvent(event[2]);

				var anim:String = "idle";

				if (event[3] != "")
					anim = event[3];

				character.playAnim(anim, true);
			case "camera flash":
				var time = Std.parseFloat(event[3]);

				if (Math.isNaN(time))
					time = 1;

				if (Options.getData("flashingLights"))
					camGame.flash(FlxColor.fromString(event[2].toLowerCase()), time);
			case "camera fade":
				var time = Std.parseFloat(event[3]);

				if (Math.isNaN(time))
					time = 1;

				if (Options.getData("flashingLights"))
					camGame.fade(FlxColor.fromString(event[2].toLowerCase()), time);
			#end
			case "add camera zoom":
				if (game.cameraZooms && ((FlxG.camera.zoom < 1.35 && game.camZooming) || !game.camZooming)) {
					var addGame:Float = Std.parseFloat(event[2]);
					var addHUD:Float = Std.parseFloat(event[3]);

					if (Math.isNaN(addGame))
						addGame = 0.015;

					if (Math.isNaN(addHUD))
						addHUD = 0.03;

					FlxG.camera.zoom += addGame * game.cameraZoomStrength;
					game.camHUD.zoom += addHUD * game.cameraZoomStrength;
				}
			case "screen shake":
				if (Options.getData("screenShakes")) {
					var valuesArray:Array<String> = [event[2], event[3]];
					var targetsArray:Array<FlxCamera> = [game.camGame, game.camHUD];

					for (i in 0...targetsArray.length) {
						var split:Array<String> = valuesArray[i].split(',');
						var duration:Float = 0;
						var intensity:Float = 0;

						if (split[0] != null)
							duration = Std.parseFloat(split[0].trim());
						if (split[1] != null)
							intensity = Std.parseFloat(split[1].trim());
						if (Math.isNaN(duration))
							duration = 0;
						if (Math.isNaN(intensity))
							intensity = 0;

						if (duration > 0 && intensity != 0)
							targetsArray[i].shake(intensity, duration);
					}
				}
			case "change scroll speed":
				var duration:Float = Std.parseFloat(event[3]);

				if (duration == Math.NaN)
					duration = 0;

				var funnySpeed = Std.parseFloat(event[2]);

				if (!Math.isNaN(funnySpeed)) {
					if (duration > 0)
						FlxTween.tween(game, {speed: funnySpeed}, duration);
					else
						game.speed = funnySpeed;
				}
			case "change camera speed":
				var speed:Float = Std.parseFloat(event[2]);
				if (Math.isNaN(speed))
					speed = 1;
				game.cameraSpeed = speed;
			case "change camera zoom speed":
				var speed:Float = Std.parseFloat(event[2]);
				if (Math.isNaN(speed))
					speed = 1;
				game.cameraZoomSpeed = speed;
			case "change camera zoom strength":
				var strength:Float = Std.parseFloat(event[2]);
				if (Math.isNaN(strength))
					game.speed = 1;
				game.cameraZoomStrength = strength;

				var speed:Float = Std.parseFloat(event[2]);
				if (Math.isNaN(speed))
					speed = 1;
				game.cameraZoomRate = speed;
			case "character will idle?":
				var char = PlayState.getCharFromEvent(event[2]);

				var funny = Std.string(event[3]).toLowerCase() == "true";

				char.shouldDance = funny;
			case "change character":
				if (Options.getData("charsAndBGs"))
					game.eventCharacterShit(event);
			case "change stage":
				if (Options.getData("charsAndBGs")) {
					game.removeBgStuff();

					if (!Options.getData("preloadChangeBGs")) {
						game.stage.kill();
						game.stage.foregroundSprites.kill();
						game.stage.infrontOfGFSprites.kill();

						game.stage.foregroundSprites.destroy();
						game.stage.infrontOfGFSprites.destroy();
						game.stage.destroy();
					} else {
						game.stage.active = false;

						game.stage.visible = false;
						game.stage.foregroundSprites.visible = false;
						game.stage.infrontOfGFSprites.visible = false;
					}

					if (!Options.getData("preloadChangeBGs"))
						game.stage = new StageGroup(event[2]);
					else
						game.stage = game.stageMap.get(event[2]);

					game.stage.visible = true;
					game.stage.foregroundSprites.visible = true;
					game.stage.infrontOfGFSprites.visible = true;
					game.stage.active = true;

					game.defaultCamZoom = game.stage.camZoom;

					#if LUA_ALLOWED
					game.stage.createLuaStuff();
					#end

					game.call("create", [game.stage.stage], STAGE);
					game.call("createStage", [game.stage.stage]);

					#if LUA_ALLOWED
					if (game.stage.stageScript != null)
						game.stage.stageScript.setupTheShitCuzPullRequestsSuck();
					#end

					game.call("start", [game.stage.stage], STAGE);

					@:privateAccess
					game.addBgStuff();
				}
			case "change keycount":
				var toChange:Int = Std.parseInt(event[2]);
				var toChangeAlt:Int = Std.parseInt(event[3]);
				if (toChange < 1 || Math.isNaN(toChange))
					toChange = 1;

				if (toChangeAlt < 1 || Math.isNaN(toChangeAlt))
					toChangeAlt = 1;

				PlayState.SONG.keyCount = toChangeAlt;
				PlayState.SONG.playerKeyCount = toChange;
				PlayState.playerStrums.clear();
				PlayState.enemyStrums.clear();
				PlayState.strumLineNotes.clear();
				game.splash_group.clear();
				game.binds = Options.getData("binds", "binds")[PlayState.SONG.playerKeyCount - 1];
				if (Options.getData("middlescroll")) {
					game.generateStaticArrows(50, false);
					game.generateStaticArrows(0.5, true);
				} else {
					if (PlayState.characterPlayingAs == 0) {
						game.generateStaticArrows(0, false);
						game.generateStaticArrows(1, true);
					} else {
						game.generateStaticArrows(1, false);
						game.generateStaticArrows(0, true);
					}
				}
				#if LUA_ALLOWED
				for (i in 0...PlayState.strumLineNotes.length) {
					var member = PlayState.strumLineNotes.members[i];

					game.setLuaVar("defaultStrum" + i + "X", member.x);
					game.setLuaVar("defaultStrum" + i + "Y", member.y);
					game.setLuaVar("defaultStrum" + i + "Angle", member.angle);

					game.setLuaVar("defaultStrum" + i, {
						x: member.x,
						y: member.y,
						angle: member.angle,
					});

					if (PlayState.enemyStrums.members.contains(member)) {
						game.setLuaVar("enemyStrum" + i % PlayState.SONG.keyCount, {
							x: member.x,
							y: member.y,
							angle: member.angle,
						});
					} else {
						game.setLuaVar("playerStrum" + i % PlayState.SONG.playerKeyCount, {
							x: member.x,
							y: member.y,
							angle: member.angle,
						});
					}
				}
				#end
			case "change ui skin":
				var noteskin:String = Std.string(event[2]);
				PlayState.SONG.ui_Skin = noteskin;
				game.ui_settings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + PlayState.SONG.ui_Skin + "/config"));
				game.mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/" + PlayState.SONG.ui_Skin + "/maniasize"));
				game.mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/" + PlayState.SONG.ui_Skin + "/maniaoffset"));

				// if the file exists, use it dammit
				if (Assets.exists(Paths.txt("ui skins/" + PlayState.SONG.ui_Skin + "/maniagap")))
					game.mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/" + PlayState.SONG.ui_Skin + "/maniagap"));
				else
					game.mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

				game.types = CoolUtil.coolTextFile(Paths.txt("ui skins/" + PlayState.SONG.ui_Skin + "/types"));

				game.arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("ui skins/" + PlayState.SONG.ui_Skin + "/default")));
				game.type_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("arrow types/default")));

				// reload ratings
				game.uiMap.set("marvelous", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + PlayState.SONG.ui_Skin + "/ratings/marvelous")));
				game.uiMap.set("sick", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + PlayState.SONG.ui_Skin + "/ratings/sick")));
				game.uiMap.set("good", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + PlayState.SONG.ui_Skin + "/ratings/good")));
				game.uiMap.set("bad", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + PlayState.SONG.ui_Skin + "/ratings/bad")));
				game.uiMap.set("shit", FlxGraphic.fromAssetKey(Paths.image("ui skins/" + PlayState.SONG.ui_Skin + "/ratings/shit")));

				// preload numbers
				for (i in 0...10)
					game.uiMap.set(Std.string(i),
						FlxGraphic.fromAssetKey(Paths.image("ui skins/" + PlayState.SONG.ui_Skin + "/numbers/num" + Std.string(i))));
				game.timeBar = new TimeBar(PlayState.SONG, PlayState.storyDifficultyStr);

				PlayState.playerStrums.clear();
				PlayState.enemyStrums.clear();
				PlayState.strumLineNotes.clear();
				game.splash_group.clear();
				if (Options.getData("middlescroll")) {
					game.generateStaticArrows(50, false, false);
					game.generateStaticArrows(0.5, true, false);
				} else {
					if (PlayState.characterPlayingAs == 0) {
						game.generateStaticArrows(0, false, false);
						game.generateStaticArrows(1, true, false);
					} else {
						game.generateStaticArrows(1, false, false);
						game.generateStaticArrows(0, true, false);
					}
				}
			// FNFC stuff
			case 'focuscamera':
				switch (Std.string(event[2])) {
					case '0':
						game.turnChange('bf');
						if (Options.getData("timeBarStyle")
							.toLowerCase() == "leather engine") FlxTween.color(game.timeBar.bar, Conductor.crochet * 0.002, game.timeBar.bar.color,
								PlayState.boyfriend.barColor);
					case '1':
						game.turnChange('dad');
						if (Options.getData("timeBarStyle")
							.toLowerCase() == "leather engine") FlxTween.color(game.timeBar.bar, Conductor.crochet * 0.002, game.timeBar.bar.color,
								PlayState.dad.barColor);
				}
			case 'zoomcamera':
				game.defaultCamZoom = Std.parseFloat(event[2]);
		}
	}
}
