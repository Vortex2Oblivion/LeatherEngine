function startCutscene() {
	PlayState.instance.inCutscene = true;
	for (camera in FlxG.cameras.list) {
		camera.visible = false;
	}
	var sound:FlxSound = FlxG.sound.play(Paths.sound('Lights_Shut_off'));
	sound.onComplete = () -> {
		PlayState.instance.moveToResultsScreen();
		PlayState.instance.inCutscene = false;
	};
}
