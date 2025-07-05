package ui;

import flixel.FlxG;
import toolbox.CharacterCreator;
import flixel.FlxSprite;
import haxe.Json;
import lime.utils.Assets;

class HealthIcon extends TrackerSprite {
	public var isPlayer:Bool = false;

	public var animatedIcon:Bool = false;

	public var offsetX:Float = 0.0;
	public var offsetY:Float = 0.0;

	public var startSize:Float = 1;

	public var char:String = "placeholder";

	public function new(char:String = 'placeholder', isPlayer:Bool = false) {
		super(null, 10, -30, RIGHT);

		this.isPlayer = isPlayer;

		// plays anim lol
		setupIcon(this.char = char);
		scrollFactor.set();
	}

	public function setupIcon(char:String = 'placeholder') {
		var iconPath:String = 'placeholder-icons';
		var iconConfig:HealthIconConfig = {
			offset: [0, 0],
			scale: 1,
			fps: 24,
			antialiasing: true
		};
		for (path in [char, '$char-icons', 'icon-$char']) {
			if (Assets.exists(Paths.image('icons/$path'))) {
				iconPath = path;
				break;
			}
		}

		if (Assets.exists('assets/images/icons/$iconPath.json')) {
			iconConfig = cast Json.parse(Assets.getText('assets/images/icons/$iconPath.json'));
		} else if (Assets.exists('assets/images/icons/$iconPath.txt')) {
			var textArray:Array<String> = Assets.getText('assets/images/icons/$iconPath.txt').split(" ");
			iconConfig.offset = [Std.parseFloat(textArray[0]), Std.parseFloat(textArray[1])];
			iconConfig.scale = Std.parseFloat(textArray[2]);
		}

		animatedIcon = Assets.exists('assets/images/icons/$iconPath.xml');
		if (animatedIcon) {
			frames = Paths.getSparrowAtlas('icons/$iconPath', null, FlxG.state is CharacterCreator);
			animation.addByPrefix('neutral', '${char}0', iconConfig.fps, true, isPlayer);
			animation.addByPrefix('lose', '${char}-lose0', iconConfig.fps, true, isPlayer);
			animation.addByPrefix('win', '${char}-win0', iconConfig.fps, true, isPlayer);
		} else {
			var dummy:FlxSprite = new FlxSprite().loadGraphic(Paths.gpuBitmap('icons/$iconPath'));			
			if (dummy.height == 32) // damn pixel icons >:(
				loadGraphic(Paths.gpuBitmap('icons/$iconPath', null, FlxG.state is CharacterCreator), true, 32, 32);
			else if (dummy.height != 150) // damn psych engine edge cases >:(
				loadGraphic(Paths.gpuBitmap('icons/$iconPath', null, FlxG.state is CharacterCreator), true, Std.int(dummy.width / 2), Std.int(dummy.height));
			else
				loadGraphic(Paths.gpuBitmap('icons/$iconPath', null, FlxG.state is CharacterCreator), true, 150, 150);
			
			var winFrame:Int = (dummy.width >= dummy.height * 3 ? 2 : 0);
			var loseFrame:Int = (dummy.width >= dummy.height * 2 ? 1 : 0);
			
			dummy.destroy();
			dummy = null;

			animation.add('win', [winFrame], 0, false, isPlayer);
			animation.add('lose', [loseFrame], 0, false, isPlayer);
			animation.add('neutral', [0], 0, false, isPlayer);
		}
		animation.play('neutral');

		scale.set(iconConfig.scale, iconConfig.scale);
		offsetX = iconConfig.offset[0];
		offsetY = iconConfig.offset[1];
		antialiasing = iconConfig.antialiasing;
		if(char.endsWith('-pixel')){
			antialiasing = false;
		}
		startSize = scale.x;
		updateHitbox();
		centerOffsets();
	}
}

typedef HealthIconConfig = {
	var offset:Array<Float>;
	var scale:Float;
	var fps:Int;
	var antialiasing:Bool;
}
