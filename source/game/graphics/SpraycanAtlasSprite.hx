//fuck you hscript
package game.graphics;

import states.PlayState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import game.graphics.FlxAtlasSprite;

class SpraycanAtlasSprite extends FlxAtlasSprite {
    public var STATE_ARCING:Int = 2; // In the air.
	public var STATE_SHOT:Int = 3; // Hit by the player.
	public var STATE_IMPACTED:Int = 4; // Impacted the player.

  public var currentState:Int = 2;

  override public function new(x:Float, y:Float)
  {
    super(x, y, Paths.getTextureAtlas('streets/spraycanAtlas', 'stages'), {
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: false,
      Antialiasing: Options.getData("antialiasing"),
      ScrollFactor: new FlxPoint(1, 1),
    });

    trace('Spawned Atlas Spraycan!');
    trace('Got frames: ' + this.anim.length);
    trace('Got animations: ' + listAnimations());

    onAnimationFinish.add(finishCanAnimation);
  }

  public function finishCanAnimation(name:String) {
    switch(name) {
      case 'Can Start':
        trace('Can Start finished');
        playHitPico();
      case 'Can Shot':
        trace('Can Shot finished');
        this.kill();
      case 'Hit Pico':
        trace('Hit Pico finished');
        playHitExplosion();
        this.kill();
    }
  }

    public function playHitExplosion():Void {
	    var explodeEZ:FlxSprite = new FlxSprite(this.x + 1050, this.y + 150);
	    explodeEZ.frames = Paths.getSparrowAtlas('streets/spraypaintExplosionEZ', 'stages');
		explodeEZ.animation.addByPrefix("idle", "explosion round 1 short0", 24, false);
		explodeEZ.animation.play("idle");

		PlayState.instance.stage.add(explodeEZ);
		explodeEZ.animation.finishCallback = (name:String) -> {
            trace('killing explodeEZ');
            explodeEZ.kill();
        };
    }

  public function playCanStart():Void {
    trace('Atlas Spraycan playCanStart');

    this.playAnimation('Can Start');
  }

  public function playCanShot():Void {
    trace('Atlas Spraycan playCanShot');

    this.playAnimation('Can Shot');
  }

  public function playHitPico():Void {
    trace('Atlas Spraycan playHitPico');

    this.playAnimation('Hit Pico');
  }
}
