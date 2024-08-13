function startCutscene() {
	PlayState.instance.camHUD.visible = false;
	var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFFF0000);
	red.scrollFactor.set();
	add(red);

	var senpaiEvil:FlxSprite = new FlxSprite();
	senpaiEvil.frames = Paths.getSparrowAtlas('cutscenes/week6/senpaiButHeFuckingDies', 'shared');
	senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
	senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
	senpaiEvil.scrollFactor.set();
	senpaiEvil.updateHitbox();
	senpaiEvil.screenCenter();

	new FlxTimer().start(0.3, function(tmr:FlxTimer) {
			PlayState.instance.inCutscene = true;

			add(senpaiEvil);
			senpaiEvil.alpha = 0;
			new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
				senpaiEvil.alpha += 0.15;
				if (senpaiEvil.alpha < 1) {
					swagTimer.reset();
				} else {
					senpaiEvil.animation.play('idle');
					FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function() {
						PlayState.instance.remove(senpaiEvil);
						PlayState.instance.remove(red);
						FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
							PlayState.instance.bruhDialogue();
							PlayState.instance.camHUD.visible = true;
						}, true);
					});
					new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
						FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
					});
				}
			});
	});
}
