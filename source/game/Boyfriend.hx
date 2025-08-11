package game;

import openfl.utils.Assets;
import states.PlayState;
import flixel.FlxG;

using StringTools;


/**
 * The ``Boyfriend`` class
 * Has extra code for playing the death animation and such.
 */
class Boyfriend extends Character
{
	public var stunned:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf', ?isDeathCharacter:Bool = false)
	{
		if(isDeathCharacter && !Assets.exists(Paths.json('character data/$char/config'))){
			char = 'bf-dead';
		}
		super(x, y, char, true, isDeathCharacter);
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed * (FlxG.state == PlayState.instance ? PlayState.songMultiplier : 1);
			else
				holdTimer = 0;

			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
				dance();

			if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
				playAnim('deathLoop');
		}

		super.update(elapsed);
	}
}
