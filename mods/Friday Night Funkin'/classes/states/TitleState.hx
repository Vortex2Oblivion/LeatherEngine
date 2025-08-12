function update(elapsed:Float):Void {
	if (FlxG.keys.justPressed.Y) {
        FlxTween.cancelTweensOf(FlxG.stage.window, ['x', 'y']);
		FlxTween.tween(FlxG.stage.window, {x: FlxG.stage.window.x + 300}, 1.4, {ease: FlxEase.quadInOut, type: 4, startDelay: 0.35});
		FlxTween.tween(FlxG.stage.window, {y: FlxG.stage.window.y + 100}, 0.7, {ease: FlxEase.quadInOut, type: 4});
	}
}
