import game.graphics.SpraycanAtlasSprite;

function startCutscene(){
  trace("started cutscene");
  var picoPos:Array<Float> = [bf.x + bf.cameraOffset[0], bf.y + bf.cameraOffset[1]];
	var nenePos:Array<Float> = [gf.x + gf.cameraOffset[0], gf.y + gf.cameraOffset[1]];
	var darnellPos:Array<Float> = [dad.x + dad.cameraOffset[0], dad.y + dad.cameraOffset[1]];

	var cutsceneDelay:Float = 2;

	var cutsceneMusic:FlxSound = new FlxSound().loadEmbedded(Paths.music("cutscene/darnellCanCutscene", "shared"), true);
	cutsceneMusic.volume = 1;


	var cutsceneCan:FlxSprite = new FlxSprite(darnellPos[0], darnellPos[1]);
	cutsceneCan.frames = Paths.getSparrowAtlas('streets/wked1_cutscene_1_can', 'stages');
	cutsceneCan.animation.addByPrefix('forward', "can kick quick0", 24, false);
	cutsceneCan.animation.addByPrefix('up', "can kicked up0", 24, false);
	PlayState.instance.add(cutsceneCan);
    cutsceneCan.visible = false;

	cutsceneCan.x = spraycanPile.x + 30;
	cutsceneCan.y = spraycanPile.y - 320;

  	var newCan:SpraycanAtlasSprite = new SpraycanAtlasSprite(0, 0);
	newCan.x = spraycanPile.x - 430;
	newCan.y = spraycanPile.y - 840;
	newCan.visible = false;
	PlayState.instance.add(newCan);

	bf.frames.addAtlas(Paths.getSparrowAtlas('characters/Pico_Intro', 'shared'));
	bf.frames.addAtlas(Paths.getSparrowAtlas('characters/Pico_Shooting', 'shared'));
	bf.animation.addByPrefix('intro1', "Pico Gets Pissed0", 24, false);
	bf.animation.addByPrefix('intro2', "shoot and return0", 24, false);
	bf.animation.addByPrefix('cock', "Pico Reload0", 24, false);
	bf.addOffset('intro1', 60, 0);
	bf.addOffset('intro2', -260, 230);
	bf.addOffset('cock', 0, 0);
	bf.playAnim('intro1', true);

	// camera sets up, pico does his animation showing him pissed
	new FlxTimer().start(0.1, function(tmr)
	{
		tweenCameraToPosition(picoPos[0] - 250, picoPos[1], 0);

		tweenCameraZoom(1.3, 0, true, FlxEase.quadInOut);
	});

	new FlxTimer().start(0.7, function(tmr){
		cutsceneMusic.play(false);
      //FlxTween.tween(bgSprite, { alpha: 0}, 2, {startDelay: 0.3}, function(){bgSprite.visible = false;});
	});

	// move camera out to show everything
	new FlxTimer().start(cutsceneDelay, function(tmr){
		tweenCameraToPosition(darnellPos[0]+100+250+250, darnellPos[1], 2.5, FlxEase.quadInOut);
		tweenCameraZoom(0.66, 2.5, true, FlxEase.quadInOut);
	});

	// darnell lights up a can
	new FlxTimer().start(cutsceneDelay + 3, function(tmr)
	{
		dad.playAnim('lightCan', true);
		FlxG.sound.play(Paths.sound('Darnell_Lighter'), 1.0);
	});

	// pico cocks his gun, camera shifts to his side to show this
	new FlxTimer().start(cutsceneDelay + 4, function(tmr)
	{
		bf.playAnim('cock');
		tweenCameraToPosition(darnellPos[0]+180+250+250, darnellPos[1], 0.4, FlxEase.backOut);
		FlxG.sound.play(Paths.sound('Gun_Prep'), 1.0);
	});

	// darnell kicks the can up
	new FlxTimer().start(cutsceneDelay + 4.4, function(tmr)
	{
		dad.playAnim('kickCan', true);
		FlxG.sound.play(Paths.sound('Kick_Can_UP'), 1.0);
      cutsceneCan.animation.play('up');
      cutsceneCan.visible = true;
	});

	// darnell knees the can forward
	new FlxTimer().start(cutsceneDelay + 4.9, function(tmr)
	{
		dad.playAnim('kneeCan', true);
		FlxG.sound.play(Paths.sound('Kick_Can_FORWARD'), 1.0);
      cutsceneCan.animation.play('forward');
	});

	// pico shoots the can, it explodes
	new FlxTimer().start(cutsceneDelay + 5.1, function(tmr)
	{
		bf.playAnim('intro2', true);

		FlxG.sound.play(Paths.soundRandom('shot', 1, 4));

		tweenCameraToPosition(darnellPos[0]+100+250+250, darnellPos[1], 1, FlxEase.quadInOut);

		trace('Atlas Spraycan playCanShot');

    	newCan.playCanShot();
      	newCan.visible = true;
      	cutsceneCan.visible = false;
		new FlxTimer().start(1/24, function(tmr)
		{
		darkenStageProps();
		});
	});

	// darnell laughs
	new FlxTimer().start(cutsceneDelay + 5.9, function(tmr)
	{
		dad.playAnim('laughCutscene', true);
		FlxG.sound.play(Paths.sound('cutscene/darnell_laugh'), 0.6);
	});

	// nene spits and laughs
	new FlxTimer().start(cutsceneDelay + 6.2, function(tmr)
	{
		gf.playAnim('laughCutscene', true);
		FlxG.sound.play(Paths.sound('cutscene/nene_laugh'), 0.6);
	});

	// camera returns to normal, cutscene flags set and countdown starts.
	new FlxTimer().start(cutsceneDelay + 8, function(tmr)
	{
		tweenCameraZoom(0.77, 2, true, FlxEase.sineInOut);
		tweenCameraToPosition(darnellPos[0]+180+250+250, darnellPos[1], 2, FlxEase.sineInOut);
		PlayState.instance.inCutscene = false;
		PlayState.instance.startCountdown();
		cutsceneMusic.stop(); // stop the music!!!!!!
    PlayState.instance.camFollow.setPosition(PlayState.instance.dad.getMidpoint().x + 150 + dad.getMainCharacter().cameraOffset[0], dad.getMidpoint().y - 100 + dad.getMainCharacter().cameraOffset[1]);
	});
}
function darkenStageProps()
	{
		// Darken the background, then fade it back.
    var dumb:Array<FlxSprite> = [];
    for (penis in PlayState.instance.stage.stage_Objects){
      dumb.push(penis[1]);
    }
		for (stageProp in dumb)
		{
			// If not excluded, darken.
			stageProp.color = 0xFF111111;
			new FlxTimer().start(1/24, (tmr) ->
			{
				stageProp.color = 0xFF222222;
				FlxTween.color(stageProp, 1.4, 0xFF222222, 0xFFFFFFFF);
			});
		}
	}

var cameraZoomTween:FlxTween;
function tweenCameraZoom(zoom:Float, duration:Float, direct:Bool, ease:FlxEase = FlxEase.linear)
{
       cancelCameraZoomTween();
       var targetZoom = zoom * (direct ? 1 : 0.77);
       if (duration == 0) {
		FlxG.camera.zoom = targetZoom;
       } else {
         cameraZoomTween = FlxTween.tween(FlxG.camera, {
           zoom: targetZoom
         }, duration, {
           ease: ease
         });
       }
}
function tweenCameraToPosition(xPos:Float, yPos:Float, duration:Float, ease:FlxEase = FlxEase.linear)
    {
       FlxTween.tween(PlayState.instance.camFollow, {x: xPos, y: yPos}, duration, { ease: ease});
    }
function cancelCameraZoomTween()
    {
       if (cameraZoomTween != null) {
         cameraZoomTween.cancel();
       }
    }