package states;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class FlashingLightsMenu extends MusicBeatState {
	private var text:FlxText;
	private var canInput:Bool = true;

	override public function create() {
		addVirtualPad(NONE, A_B);
		super.create();

		final buttonY:String = controls.mobileC ? 'A' : 'Y';
		final buttonN:String = controls.mobileC ? 'B' : 'N';

		text = new FlxText(0, 0, 0, 'This game has flashing lights!\nPress $buttonY to enable them, or $buttonN to disable them.\n(Either ${controls.mobileC ? 'button' : 'key'} closes takes you to the title screen.)',
			32);
		text.font = Paths.font('vcr.ttf');
		text.screenCenter();
		add(text);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!canInput) {
			return;
		}

		var yes:Bool = FlxG.keys.justPressed.Y;
		var no:Bool = FlxG.keys.justPressed.N;

		if (yes) {
			Options.setData(true, 'flashingLights');
		} else if (no) {
			Options.setData(false, 'flashingLights');
		}

		if (yes || no) {
			FlxG.sound.play(Paths.sound('confirmMenu'));

			FlxTween.tween(text, {alpha: 0}, 2.0, {
				ease: FlxEase.cubeInOut,
				onComplete: (_) -> FlxG.switchState(new TitleState())
			});

			canInput = false;
		}
	}
}
