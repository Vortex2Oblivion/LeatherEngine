package ui;

import lime.utils.Assets;

class HealthIcon extends TrackerSprite {
	public var isPlayer:Bool = false;

	public var animatedIcon:Bool = false;

	public var offsetX:Float = 0.0;
	public var offsetY:Float = 0.0;

	public var startSize:Float = 1;

	public var char:String = "bf";

	public function new(char:String = 'bf', isPlayer:Bool = false) {
		super(null, 10, -30, RIGHT);

		this.isPlayer = isPlayer;

		// plays anim lol
		playSwagAnim(char);
		scrollFactor.set();
	}

	public function playSwagAnim(?char:String = 'bf') {
		changeIconSet(char);
		this.char = char;
	}

	public function changeIconSet(char:String = 'bf') {
		antialiasing = Options.getData("antialiasing");

		if (Assets.exists(Paths.image('icons/' + char + '-icons').split(".png")[0] + ".xml")
			|| Assets.exists(Paths.image('icons/icon-' + char).split(".png")[0] + ".xml")
			|| Assets.exists(Paths.image('icons/' + char).split(".png")[0] + ".xml")) {
			var selected = "your";

			if (Assets.exists(Paths.image('icons/' + char + '-icons').split(".png")[0] + ".xml")) {
				frames = Paths.getSparrowAtlas('icons/' + char + '-icons');
				selected = Paths.image('icons/' + char + '-icons');
			} else if (Assets.exists(Paths.image('icons/icon-' + char).split(".png")[0] + ".xml")) {
				frames = Paths.getSparrowAtlas('icons/icon-' + char);
				selected = Paths.image('icons/icon-' + char);
			} else if (Assets.exists(Paths.image('icons/' + char).split(".png")[0] + ".xml")) {
				frames = Paths.getSparrowAtlas('icons/' + char);
				selected = Paths.image('icons/' + char);
			}

			animation.addByPrefix(char, char, 24, true, isPlayer);

			if (Assets.exists(selected.split(".png")[0] + ".txt")) {
				var theFunny = Assets.getText(selected.split(".png")[0] + ".txt").split(" ");

				setGraphicSize(Std.int(width * Std.parseFloat(theFunny[2])));
				updateHitbox();

				offsetX = Std.parseFloat(theFunny[0]);
				offsetY = Std.parseFloat(theFunny[1]);
			}

			animatedIcon = true;
		} else {
			if (Assets.exists(Paths.image('icons/' + char + '-icons'))) // LE ICONS
				loadGraphic(Paths.image('icons/' + char + '-icons'));
			else if (Assets.exists(Paths.image('icons/' + 'icon-' + char))) // BASE GAME ICONS
				loadGraphic(Paths.image('icons/' + 'icon-' + char));
			else if (Assets.exists(Paths.image('icons/' + char))) // just the name as file name
				loadGraphic(Paths.image('icons/' + char));
			else // UNKNOWN ICON
				loadGraphic(Paths.image('icons/placeholder-icon'));

			if (height != 150) // damn weird edge cases >:(
				loadGraphic(graphic, true, Std.int(width / 2), Std.int(height));
			else
				loadGraphic(graphic, true, 150, 150);

			animation.add(char, [0, 1, 2], 0, false, isPlayer);
		}

		animation.play(char);
		startSize = scale.x;

		// antialiasing override
		switch (char) {
			case 'senpai' | 'senpai-angry' | 'spirit':
				antialiasing = false;
		}

		if (char.endsWith('-pixel')) {
			antialiasing = false;
		}
	}
}
