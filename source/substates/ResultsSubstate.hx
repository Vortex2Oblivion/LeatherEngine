package substates;

import openfl.utils.Assets;
import states.PlayState;
import game.ResultScore;
import utilities.ScoringRank;
import flixel.sound.FlxSound;
import flixel.FlxG;
import states.StoryMenuState;
import game.FlxAtlasSprite;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import substates.MusicBeatSubstate;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.FlxCamera;
import states.FreeplayState;
import flixel.tweens.FlxTween;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import shaders.LeftMaskShader;
import game.TallyCounter;
import game.ClearPercentCounter;

/**
 * The substate for the results screen after a song or week is finished.
 */
class ResultsSubstate extends MusicBeatSubstate {
	final params:ResultsStateParams;

	final rank:ScoringRank;
	final songName:FlxBitmapText;
	var difficulty:FlxSprite;
	final clearPercentSmall:ClearPercentCounter;

	final maskShaderSongName:LeftMaskShader = new LeftMaskShader();
	final maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();

	final resultsAnim:FlxSprite;
	final ratingsPopin:FlxSprite;
	final scorePopin:FlxSprite;

	final bgFlash:FlxSprite;

	final highscoreNew:FlxSprite;
	final score:ResultScore;

	var bfPerfect:FlxAtlasSprite;
	var heartsPerfect:FlxAtlasSprite;
	var bfExcellent:FlxAtlasSprite;
	var bfGreat:FlxAtlasSprite;
	var gfGreat:FlxAtlasSprite;
	var bfGood:FlxSprite;
	var gfGood:FlxSprite;
	var bfShit:FlxAtlasSprite;

	var rankBg:FlxSprite;
	final cameraBG:FlxCamera;
	final cameraScroll:FlxCamera;
	final cameraEverything:FlxCamera;

	var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";

	function getRank(percent:Float):ScoringRank {
		if (percent >= 100)
			return PERFECT;
		if (percent >= 90)
			return EXCELLENT;
		if (percent >= 80)
			return GREAT;
		if (percent >= 60)
			return GOOD;
		return SHIT;
	}

	public function new(params:ResultsStateParams) {
		super();

		this.params = params;

		var successHits:Int = PlayState.instance.ratings.get("marvelous") + PlayState.instance.ratings.get("sick") + PlayState.instance.ratings.get("good");
		var comboBreaks:Int = PlayState.instance.ratings.get("bad") + PlayState.instance.ratings.get("shit") + PlayState.instance.misses;

		rank = getRank(Math.floor(successHits / Math.max(successHits + comboBreaks, 1) * 100));

		cameraBG = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		cameraScroll = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		cameraEverything = new FlxCamera(0, 0, FlxG.width, FlxG.height);

		// We build a lot of this stuff in the constructor, then place it in create().
		// This prevents having to do `null` checks everywhere.

		songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
		songName.text = params.title;
		songName.letterSpacing = -15;
		songName.angle = -4.4;
		// songName.zIndex = 1000;

		difficulty = new FlxSprite(555);
		// difficulty.zIndex = 1000;

		clearPercentSmall = new ClearPercentCounter(FlxG.width / 2 + 300, FlxG.height / 2 - 100, 100, true);
		clearPercentSmall.shader = maskShaderDifficulty;
		// clearPercentSmall.zIndex = 1000;
		clearPercentSmall.visible = false;

		bgFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFF1A6, 0xFFFFF1BE], 90);

		resultsAnim = new FlxSprite(-200, -10);
		resultsAnim.frames = Paths.getSparrowAtlas("resultScreen/results");

		ratingsPopin = new FlxSprite(-135, 135);
		ratingsPopin.frames = Paths.getSparrowAtlas("resultScreen/ratingsPopin");

		scorePopin = new FlxSprite(-180, 515);
		scorePopin.frames = Paths.getSparrowAtlas("resultScreen/scorePopin");

		highscoreNew = new FlxSprite(44, 557);

		score = new ResultScore(35, 305, 10, params.scoreData.score);

		rankBg = new FlxSprite(0, 0);
	}

	override function create():Void {
		if ((PlayState.storyPlaylist.length > 1 && PlayState.isStoryMode) || Options.getData("skipResultsScreen")) {
			PlayState.instance.finishSongStuffs();
			return;
		}
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// We need multiple cameras so we can put one at an angle.
		cameraScroll.angle = -3.8;

		cameraBG.bgColor = 0xFFFECC5C;
		cameraScroll.bgColor = FlxColor.TRANSPARENT;
		cameraEverything.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.add(cameraBG, false);
		FlxG.cameras.add(cameraScroll, false);
		FlxG.cameras.add(cameraEverything, false);

		FlxG.cameras.setDefaultDrawTarget(cameraEverything, true);
		this.camera = cameraEverything;

		// Reset the camera zoom on the results screen.
		FlxG.camera.zoom = 1.0;

		var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
		bg.scrollFactor.set();
		// bg.zIndex = 10;
		bg.cameras = [cameraBG];
		add(bg);

		bgFlash.scrollFactor.set();
		bgFlash.visible = false;
		// bgFlash.zIndex = 20;
		// bgFlash.cameras = [cameraBG];
		add(bgFlash);

		new FlxTimer().start(37 / 24, _ -> {
			try {
				score.visible = true;
				score.animateNumbers();
				startRankTallySequence();
			} catch (e) {
				#if debug
				trace(e, ERROR);
				#end
			}
		});

		switch (rank) {
			case PERFECT | PERFECT_GOLD:
				heartsPerfect = new FlxAtlasSprite(1342, 370, Paths.getTextureAtlas("resultScreen/results-bf/resultsPERFECT/hearts", "shared"));
				heartsPerfect.visible = false;
				// heartsPerfect.zIndex = 501;
				add(heartsPerfect);

				heartsPerfect.anim.onComplete = () -> {
					if (heartsPerfect != null) {
						// bfPerfect.anim.curFrame = 137;
						heartsPerfect.anim.curFrame = 43;
						heartsPerfect.anim.play(); // unpauses this anim, since it's on PlayOnce!
					}
				};

				bfPerfect = new FlxAtlasSprite(1342, 370, Paths.getTextureAtlas("resultScreen/results-bf/resultsPERFECT", "shared"));
				bfPerfect.visible = false;
				// bfPerfect.zIndex = 500;
				add(bfPerfect);

				bfPerfect.anim.onComplete = () -> {
					if (bfPerfect != null) {
						// bfPerfect.anim.curFrame = 137;
						bfPerfect.anim.curFrame = 137;
						bfPerfect.anim.play(); // unpauses this anim, since it's on PlayOnce!
					}
				};

			case EXCELLENT:
				bfExcellent = new FlxAtlasSprite(1329, 429, Paths.getTextureAtlas("resultScreen/results-bf/resultsEXCELLENT", "shared"));
				bfExcellent.visible = false;
				// bfExcellent.zIndex = 500;
				add(bfExcellent);

				bfExcellent.anim.onComplete = () -> {
					if (bfExcellent != null) {
						bfExcellent.anim.curFrame = 28;
						bfExcellent.anim.play(); // unpauses this anim, since it's on PlayOnce!
					}
				};

			case GREAT:
				gfGreat = new FlxAtlasSprite(802, 331, Paths.getTextureAtlas("resultScreen/results-bf/resultsGREAT/gf", "shared"));
				gfGreat.visible = false;
				// gfGreat.zIndex = 499;
				add(gfGreat);

				gfGreat.scale.set(0.93, 0.93);

				gfGreat.anim.onComplete = () -> {
					if (gfGreat != null) {
						gfGreat.anim.curFrame = 9;
						gfGreat.anim.play(); // unpauses this anim, since it's on PlayOnce!
					}
				};

				bfGreat = new FlxAtlasSprite(929, 363, Paths.getTextureAtlas("resultScreen/results-bf/resultsGREAT/bf", "shared"));
				bfGreat.visible = false;
				// bfGreat.zIndex = 500;
				add(bfGreat);

				bfGreat.scale.set(0.93, 0.93);

				bfGreat.anim.onComplete = () -> {
					if (bfGreat != null) {
						bfGreat.anim.curFrame = 15;
						bfGreat.anim.play(); // unpauses this anim, since it's on PlayOnce!
					}
				};

			case GOOD:
				gfGood = new FlxSprite(625, 325);
				gfGood.frames = Paths.getSparrowAtlas('resultScreen/results-bf/resultsGOOD/resultGirlfriendGOOD');
				gfGood.animation.addByPrefix("clap", "Girlfriend Good Anim", 24, false);
				gfGood.visible = false;
				// gfGood.zIndex = 500;
				gfGood.animation.onFinish.add((animName:String) -> {
					if (gfGood != null) {
						gfGood.animation.play('clap', true, false, 9);
					}
				});
				add(gfGood);

				bfGood = new FlxSprite(640, -200);
				bfGood.frames = Paths.getSparrowAtlas('resultScreen/results-bf/resultsGOOD/resultBoyfriendGOOD');
				bfGood.animation.addByPrefix("fall", "Boyfriend Good Anim0", 24, false);
				bfGood.visible = false;
				// bfGood.zIndex = 501;
				bfGood.animation.onFinish.add(function(_) {
					if (bfGood != null) {
						bfGood.animation.play('fall', true, false, 14);
					}
				});
				add(bfGood);

			case SHIT:
				bfShit = new FlxAtlasSprite(0, 20, Paths.getTextureAtlas("resultScreen/results-bf/resultsSHIT", "shared"));
				bfShit.visible = false;
				// bfShit.zIndex = 500;
				add(bfShit);
				bfShit.onAnimationFinish.add((animName) -> {
					if (bfShit != null) {
						bfShit.playAnimation('Loop Start');
					}
				});
		}

		var diffSpr:String = 'diff_${params?.difficultyId ?? 'Normal'}';
		if (!Assets.exists(Paths.image("resultScreen/" + diffSpr))) {
			difficulty = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
			cast(difficulty, FlxBitmapText).text = params?.difficultyId ?? 'Normal';
			cast(difficulty, FlxBitmapText).letterSpacing = -15;
			difficulty.angle = -4.4;
		} else
			difficulty.loadGraphic(Paths.gpuBitmap("resultScreen/" + diffSpr));
		add(difficulty);

		add(songName);

		var angleRad = songName.angle * Math.PI / 180;
		speedOfTween.x = -1.0 * Math.cos(angleRad);
		speedOfTween.y = -1.0 * Math.sin(angleRad);

		timerThenSongName(1.0, false);

		songName.shader = maskShaderSongName;
		difficulty.shader = maskShaderDifficulty;

		// maskShaderSongName.swagMaskX = difficulty.x - 15;
		maskShaderDifficulty.swagMaskX = difficulty.x - 15;
		if (difficulty is FlxBitmapText) {
			maskShaderDifficulty.swagMaskX += difficulty.width;
		}

		var blackTopBar:FlxSprite = new FlxSprite().loadGraphic(Paths.gpuBitmap("resultScreen/topBarBlack"));
		blackTopBar.y = -blackTopBar.height;
		FlxTween.tween(blackTopBar, {y: 0}, 7 / 24, {ease: FlxEase.quartOut, startDelay: 3 / 24});
		// blackTopBar.zIndex = 1010;
		add(blackTopBar);

		// The sound system which falls into place behind the score text. Plays every time!
		var soundSystem:FlxSprite = new FlxSprite(-15, -180);
		soundSystem.frames = Paths.getSparrowAtlas("resultScreen/soundSystem");
		soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
		soundSystem.visible = false;
		new FlxTimer().start(8 / 24, _ -> {
			soundSystem.animation.play("idle");
			soundSystem.visible = true;
		});
		// soundSystem.zIndex = 1100;
		add(soundSystem);
		insert(members.indexOf(soundSystem), clearPercentSmall);

		resultsAnim.animation.addByPrefix("result", "results", 24, false);
		resultsAnim.visible = false;
		// resultsAnim.zIndex = 1200;
		add(resultsAnim);
		try {
			new FlxTimer().start(6 / 24, _ -> {
				try {
					resultsAnim.visible = true;
					resultsAnim?.animation?.play("result");
				} catch (e) {}
			});
		} catch (e) {}

		ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
		ratingsPopin.visible = false;
		// ratingsPopin.zIndex = 1200;
		add(ratingsPopin);
		new FlxTimer().start(21 / 24, _ -> {
			try {
				ratingsPopin.visible = true;
				ratingsPopin.animation.play("idle");
			} catch (e) {
				#if debug
				trace(e, ERROR);
				#end
			}
		});

		scorePopin.animation.addByPrefix("score", "tally score", 24, false);
		scorePopin.visible = false;
		// scorePopin.zIndex = 1200;
		add(scorePopin);

		new FlxTimer().start(36 / 24, _ -> {
			try {
				scorePopin.visible = true;
				scorePopin.animation.play("score");
				scorePopin.animation.onFinish.add(anim -> {});
			} catch (e) {
				#if debug
				trace(e, ERROR);
				#end
			}
		});

		new FlxTimer().start(rank.getBFDelay() ?? 1, _ -> {
			afterRankTallySequence();
		});

		new FlxTimer().start(rank.getFlashDelay() ?? 1, _ -> {
			try {
				displayRankText();
			} catch (e) {
				#if debug
				trace(e, ERROR);
				#end
			}
		});

		highscoreNew.frames = Paths.getSparrowAtlas("resultScreen/highscoreNew");
		highscoreNew.animation.addByPrefix("new", "highscoreAnim0", 24, false);
		highscoreNew.visible = false;
		highscoreNew.updateHitbox();
		add(highscoreNew);

		new FlxTimer().start(rank.getHighscoreDelay(), _ -> {
			if (params.isNewHighscore ?? false) {
				try {
					highscoreNew.visible = true;
					highscoreNew.animation.play("new");
					highscoreNew.animation.onFinish.add((animName:String) -> highscoreNew.animation.play("new", true, false, 16));
				} catch (e) {}
			} else {
				highscoreNew.visible = false;
			}
		});

		var hStuf:Int = 50;

		var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
		// ratingGrp.zIndex = 1200;
		add(ratingGrp);

		/**
		 * NOTE: We display how many notes were HIT, not how many notes there were in total.
		 *
		 */
		var totalHit:TallyCounter = new TallyCounter(375, hStuf * 3, params.scoreData.tallies.totalNotesHit);
		ratingGrp.add(totalHit);

		var maxCombo:TallyCounter = new TallyCounter(375, hStuf * 4, params.scoreData.tallies.maxCombo);
		ratingGrp.add(maxCombo);

		hStuf += 2;
		var extraYOffset:Float = 7;

		hStuf += 2;

		ratingGrp.add(new TallyCounter(230, (hStuf * 5) + extraYOffset, params.scoreData.tallies.sick, 0xFF89E59E));

		ratingGrp.add(new TallyCounter(210, (hStuf * 6) + extraYOffset, params.scoreData.tallies.good, 0xFF89C9E5));

		ratingGrp.add(new TallyCounter(190, (hStuf * 7) + extraYOffset, params.scoreData.tallies.bad, 0xFFE6CF8A));

		ratingGrp.add(new TallyCounter(220, (hStuf * 8) + extraYOffset, params.scoreData.tallies.shit, 0xFFE68C8A));

		ratingGrp.add(new TallyCounter(260, (hStuf * 9) + extraYOffset, params.scoreData.tallies.missed, 0xFFC68AE6));

		score.visible = false;
		// score.zIndex = 1200;
		add(score);

		for (ind => rating in ratingGrp.members) {
			rating.visible = false;
			new FlxTimer().start((0.3 * ind) + 1.20, _ -> {
				rating.visible = true;
				FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
			});
		}

		// if (params.isNewHighscore ?? false)
		// {
		//   highscoreNew.visible = true;
		//   highscoreNew.animation.play("new");
		//   //FlxTween.tween(highscoreNew, {y: highscoreNew.y + 10}, 0.8, {ease: FlxEase.quartOut});
		// }
		// else
		// {
		//   highscoreNew.visible = false;
		// }

		new FlxTimer().start(rank.getMusicDelay(), _ -> {
			if (rank.hasMusicIntro()) {
				// Play the intro music.
				// trace(Paths.music(rank.getMusicPath() + '/' + rank.getMusicPath()), DEBUG);
				var introMusic:String = Paths.music(rank.getMusicPath() + '/' + rank.getMusicPath());
				var introSound:FlxSound = new FlxSound().loadEmbedded(introMusic);
				introSound.play();
				introSound.onComplete = () -> {
					FlxG.sound.playMusic(rank.getMusicPath(), 1, rank.shouldMusicLoop());
				};
				FlxG.sound.list.add(introSound);
			} else {
				FlxG.sound.playMusic(Paths.music(rank.getMusicPath() + '/' + rank.getMusicPath()), 1, rank.shouldMusicLoop());
			}
		});

		rankBg.makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		add(rankBg);

		rankBg.alpha = 0;

		// refresh();

		super.create();
	}

	var rankTallyTimer:Null<FlxTimer> = null;
	var clearPercentTarget:Int = 100;
	var clearPercentLerp:Int = 0;

	function startRankTallySequence():Void {
		bgFlash.visible = true;
		FlxTween.tween(bgFlash, {alpha: 0}, 5 / 24);
		var clearPercentFloat = (params.scoreData.tallies.sick + params.scoreData.tallies.good) / params.scoreData.tallies.totalNotes * 100;
		clearPercentTarget = Math.floor(clearPercentFloat);
		// Prevent off-by-one errors.

		if (Math.isNaN(clearPercentFloat) || clearPercentFloat < 0) {
			clearPercentFloat = 0;
		}
		if (Math.isNaN(clearPercentTarget) || clearPercentTarget < 0) {
			clearPercentTarget = 0;
		}

		clearPercentLerp = Std.int(Math.max(0, clearPercentTarget - 36));

		trace('Clear percent target: ' + clearPercentFloat + ', round: ' + clearPercentTarget);

		var clearPercentCounter:ClearPercentCounter = new ClearPercentCounter(FlxG.width / 2 + 190, FlxG.height / 2 - 70, clearPercentLerp);
		FlxTween.tween(clearPercentCounter, {curNumber: clearPercentTarget}, 58 / 24, {
			ease: FlxEase.quartOut,
			onUpdate: _ -> {
				// Only play the tick sound if the number increased.
				if (clearPercentLerp != clearPercentCounter.curNumber) {
					clearPercentLerp = clearPercentCounter.curNumber;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			},
			onComplete: _ -> {
				// Play confirm sound.
				FlxG.sound.play(Paths.sound('confirmMenu'));

				// Just to be sure that the lerp didn't mess things up.
				clearPercentCounter.curNumber = clearPercentTarget;

				clearPercentCounter.flash(true);
				new FlxTimer().start(0.4, _ -> {
					clearPercentCounter.flash(false);
				});

				// displayRankText();

				// previously 2.0 seconds
				new FlxTimer().start(0.25, _ -> {
					FlxTween.tween(clearPercentCounter, {alpha: 0}, 0.5, {
						startDelay: 0.5,
						ease: FlxEase.quartOut,
						onComplete: _ -> {
							remove(clearPercentCounter);
						}
					});

					// afterRankTallySequence();
				});
			}
		});
		// clearPercentCounter.zIndex = 450;
		add(clearPercentCounter);

		if (ratingsPopin == null) {
			trace("Could not build ratingsPopin!");
		} else {
			// ratingsPopin.animation.play("idle");
			// ratingsPopin.visible = true;

			ratingsPopin.animation.onFinish.add((animName:String) -> {
				// scorePopin.animation.play("score");

				// scorePopin.visible = true;

				if (params.isNewHighscore ?? false) {
					highscoreNew.visible = true;
					highscoreNew.animation.play("new");
				} else {
					highscoreNew.visible = false;
				}
			});
		}

		// refresh();
	}

	function displayRankText():Void {
		bgFlash.visible = true;
		bgFlash.alpha = 1;
		FlxTween.tween(bgFlash, {alpha: 0}, 14 / 24);

		var rankTextVert:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getVerTextAsset()), Y, 0, 30);
		rankTextVert.x = FlxG.width - 44;
		rankTextVert.y = 100;
		// rankTextVert.zIndex = 990;
		add(rankTextVert);

		FlxFlicker.flicker(rankTextVert, 2 / 24 * 3, 2 / 24, true);

		// Scrolling.
		new FlxTimer().start(30 / 24, _ -> {
			try {
				if (rankTextVert != null && rankTextVert.velocity != null) {
					rankTextVert.velocity.y = -80;
				}
			} catch (e) {}
		});

		for (i in 0...12) {
			var rankTextBack:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getHorTextAsset()), X, 10, 0);
			rankTextBack.x = FlxG.width / 2 - 320;
			rankTextBack.y = 50 + (135 * i / 2) + 10;
			// rankTextBack.angle = -3.8;
			// rankTextBack.zIndex = 100;
			rankTextBack.cameras = [cameraScroll];
			add(rankTextBack);

			// Scrolling.
			rankTextBack.velocity.x = (i % 2 == 0) ? -7.0 : 7.0;
		}

		// refresh();
	}

	function afterRankTallySequence():Void {
		showSmallClearPercent();

		trace(rank);

		switch (rank) {
			case PERFECT | PERFECT_GOLD:
				if (bfPerfect == null) {
					trace("Could not build PERFECT animation!", ERROR);
				} else {
					bfPerfect.visible = true;
					bfPerfect.playAnimation('');
				}
				new FlxTimer().start(106 / 24, _ -> {
					if (heartsPerfect == null) {
						trace("Could not build heartsPerfect animation!", ERROR);
					} else {
						heartsPerfect.visible = true;
						heartsPerfect.playAnimation('');
					}
				});
			case EXCELLENT:
				if (bfExcellent == null) {
					trace("Could not build EXCELLENT animation!", ERROR);
				} else {
					bfExcellent.visible = true;
					bfExcellent.playAnimation('');
				}
			case GREAT:
				if (bfGreat == null) {
					trace("Could not build GREAT animation!", ERROR);
				} else {
					bfGreat.visible = true;
					bfGreat.playAnimation('');
				}

				new FlxTimer().start(6 / 24, _ -> {
					if (gfGreat == null) {
						trace("Could not build GREAT animation for gf!", ERROR);
					} else {
						gfGreat.visible = true;
						gfGreat.playAnimation('');
					}
				});
			case SHIT:
				if (bfShit == null) {
					trace("Could not build SHIT animation!", ERROR);
				} else {
					bfShit.visible = true;
					bfShit.playAnimation('Intro');
				}
			case GOOD:
				if (bfGood == null) {
					bfGood = new FlxSprite(640, -200);
					trace("Could not build GOOD animation!", ERROR);
				} else {
					bfGood.animation.play('fall');
					bfGood.visible = true;
					new FlxTimer().start((1 / 24) * 22, _ -> {
						// plays about 22 frames (at 24fps timing) after bf spawns in
						if (gfGood != null) {
							gfGood.animation.play('clap', true);
							gfGood.visible = true;
						} else {
							trace("Could not build GOOD animation!", ERROR);
						}
					});
				}
			default:
		}
	}

	function timerThenSongName(timerLength:Float = 3.0, autoScroll:Bool = true):Void {
		movingSongStuff = false;

		difficulty.x = 555;

		var diffYTween:Float = 122;

		difficulty.y = -difficulty.height;
		FlxTween.tween(difficulty, {y: diffYTween}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.8});

		if (clearPercentSmall != null) {
			clearPercentSmall.x = (difficulty.x + difficulty.width) + 60;
			clearPercentSmall.y = -clearPercentSmall.height;
			FlxTween.tween(clearPercentSmall, {y: 122 - 5}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.85});
		}

		songName.y = -songName.height;
		var fuckedupnumber = (10) * (songName.text.length / 15);
		FlxTween.tween(songName, {y: diffYTween - 25 - fuckedupnumber}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.9});
		songName.x = clearPercentSmall.x + 94;

		new FlxTimer().start(timerLength, _ -> {
			var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);

			speedOfTween.set(0, 0);
			FlxTween.tween(speedOfTween, {x: tempSpeed.x, y: tempSpeed.y}, 0.7, {ease: FlxEase.quadIn});

			movingSongStuff = (autoScroll);
		});
	}

	function showSmallClearPercent():Void {
		try {
			if (clearPercentSmall != null) {
				add(clearPercentSmall);
				clearPercentSmall.visible = true;
				clearPercentSmall.flash(true);
				new FlxTimer().start(0.4, _ -> {
					clearPercentSmall.flash(false);
				});

				clearPercentSmall.curNumber = clearPercentTarget;
				// refresh();
			}

			new FlxTimer().start(2.5, _ -> {
				movingSongStuff = true;
			});
		} catch (e) {}
	}

	var movingSongStuff:Bool = false;
	var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);

	override function draw():Void {
		super.draw();

		songName.clipRect = FlxRect.get(Math.max(0, 520 - songName.x), 0, FlxG.width, songName.height);

		// PROBABLY SHOULD FIX MEMORY FREE OR WHATEVER THE PUT() FUNCTION DOES !!!! FEELS LIKE IT STUTTERS!!!

		// if (songName != null && songName.frame != null)
		// maskShaderSongName.frameUV = songName.frame.uv;
	}

	override function update(elapsed:Float):Void {
		// if(FlxG.keys.justPressed.R){
		//   FlxG.switchState(() -> new funkin.play.ResultState(
		//   {
		//     storyMode: false,
		//     title: "Cum Song Erect by Kawai Sprite",
		//     songId: "cum",
		//     difficultyId: "nightmare",
		//     isNewHighscore: true,
		//     scoreData:
		//       {
		//         score: 1_234_567,
		//         tallies:
		//           {
		//             sick: 200,
		//             good: 0,
		//             bad: 0,
		//             shit: 0,
		//             missed: 0,
		//             combo: 0,
		//             maxCombo: 69,
		//             totalNotesHit: 200,
		//             totalNotes: 200 // 0,
		//           }
		//       },
		//   }));
		// }

		// if(heartsPerfect != null){
		// if (FlxG.keys.justPressed.I)
		// {
		//   heartsPerfect.y -= 1;
		//   trace(heartsPerfect.x, heartsPerfect.y);
		// }
		// if (FlxG.keys.justPressed.J)
		// {
		//   heartsPerfect.x -= 1;
		//   trace(heartsPerfect.x, heartsPerfect.y);
		// }
		// if (FlxG.keys.justPressed.L)
		// {
		//   heartsPerfect.x += 1;
		//   trace(heartsPerfect.x, heartsPerfect.y);
		// }
		// if (FlxG.keys.justPressed.K)
		// {
		//   heartsPerfect.y += 1;
		//   trace(heartsPerfect.x, heartsPerfect.y);
		// }
		// }

		// if(bfGreat != null){
		// if (FlxG.keys.justPressed.W)
		// {
		//   bfGreat.y -= 1;
		//   trace(bfGreat.x, bfGreat.y);
		// }
		// if (FlxG.keys.justPressed.A)
		// {
		//   bfGreat.x -= 1;
		//   trace(bfGreat.x, bfGreat.y);
		// }
		// if (FlxG.keys.justPressed.D)
		// {
		//   bfGreat.x += 1;
		//   trace(bfGreat.x, bfGreat.y);
		// }
		// if (FlxG.keys.justPressed.S)
		// {
		//   bfGreat.y += 1;
		//   trace(bfGreat.x, bfGreat.y);
		// }
		// }

		// maskShaderSongName.swagSprX = songName.x;
		maskShaderDifficulty.swagSprX = difficulty.x;

		if (movingSongStuff) {
			songName.x += speedOfTween.x;
			difficulty.x += speedOfTween.x;
			clearPercentSmall.x += speedOfTween.x;
			songName.y += speedOfTween.y;
			difficulty.y += speedOfTween.y;
			clearPercentSmall.y += speedOfTween.y;

			if (songName.x + songName.width < 100) {
				timerThenSongName();
			}
		}

		if (FlxG.keys.justPressed.RIGHT)
			speedOfTween.x += 0.1;

		if (FlxG.keys.justPressed.LEFT) {
			speedOfTween.x -= 0.1;
		}

		if (controls.PAUSE) {
			if (FlxG.sound.music != null) {
				// FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.8);
				FlxTween.tween(FlxG.sound.music, {pitch: 3}, 0.1, {
					onComplete: _ -> {
						FlxTween.tween(FlxG.sound.music, {pitch: 0.5}, 0.4);
					}
				});
			}
			if (params.storyMode) {
				FlxG.switchState(() -> new StoryMenuState());
			} else {
				/*var rigged:Bool = true;
					if (rank > getRank(params?.prevScoreData)) // if (rigged)
					{
						trace('THE RANK IS Higher.....');
						FlxTween.tween(rankBg, {alpha: 1}, 0.5,
							ease: FlxEase.expoOut,
							onComplete: function(_) {
								FlxG.switchState(() -> new FreeplayState());
							});
					else */
				{
					trace('rank is lower...... and/or equal');
					FlxG.switchState(() -> new FreeplayState());
				}
			}
		}

		super.update(elapsed);
	}
}

typedef ResultsStateParams = {
	/**
	 * True if results are for a level, false if results are for a single song.
	 */
	var storyMode:Bool;

	/**
	 * Either "Song Name by Artist Name" or "Week Name"
	 */
	var title:String;

	/**
	 * Whether the displayed score is a new highscore
	 */
	var ?isNewHighscore:Bool;

	/**
	 * The difficulty ID of the song/week we just played.
	 * @default Normal
	 */
	var ?difficultyId:String;

	/**
	 * The score, accuracy, and judgements.
	 */
	var scoreData:SaveScoreData;

	/**
	 * The previous score data, used for rank comparision.
	 */
	var ?prevScoreData:SaveScoreData;
};

/**
 * An individual score. Contains the score, accuracy, and count of each judgement hit.
 */
typedef SaveScoreData = {
	/**
	 * The score achieved.
	 */
	var score:Int;

	/**
	 * The count of each judgement hit.
	 */
	var tallies:SaveScoreTallyData;
}

typedef SaveScoreTallyData = {
	var sick:Int;
	var good:Int;
	var bad:Int;
	var shit:Int;
	var missed:Int;
	var combo:Int;
	var maxCombo:Int;
	var totalNotesHit:Int;
	var totalNotes:Int;
}
