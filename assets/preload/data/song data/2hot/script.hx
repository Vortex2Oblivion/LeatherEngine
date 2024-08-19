import game.graphics.SpraycanAtlasSprite;


var STATE_ARCING:Int = 2; // In the air.
var STATE_SHOT:Int = 3; // Hit by the player.
var STATE_IMPACTED:Int = 4; // Impacted the player.
var spawnedCans:Array<SpraycanAtlasSprite> = [];


function createPost(){
    bf.frames.addAtlas(Paths.getSparrowAtlas('characters/Pico_Shooting', 'shared'));
    bf.animation.addByPrefix('cock', "Pico Reload0", 24, false);
    bf.animation.addByPrefix('shoot', "Pico Shoot Hip Full0", 24, false);
    bf.addOffset('shoot', -300, 250);
    for(i in 1...4){ //precache sounds
        FlxG.sound.play(Paths.soundRandom('shot'+i));
    }
    //precache can
    var cacheCan:SpraycanAtlasSprite = new SpraycanAtlasSprite(0, 0);
}


function onEvent(name:String, position:Float, value1:String, value2:String){
    switch (name.toLowerCase()) {
        case 'play character animation':
            switch (value2.toLowerCase()) {
                case 'kickcan':
                    var newCan:SpraycanAtlasSprite = new SpraycanAtlasSprite(0, 0);

                    var spraycanPile = PlayState.instance.stage.getNamedProp('spraycanPile');

                    newCan.x = spraycanPile.x - 430;
                    newCan.y = spraycanPile.y - 840;
                    newCan.playCanStart();

                    PlayState.instance.add(newCan);
                    spawnedCans.push(newCan);
                case 'kneecan':
                    gunCocked = true;
                    new FlxTimer().start(1.0, function()
                    {
                        gunCocked = false;
                    });
                    bf.playAnim('cock', true);
                case "shoot":
                    if (gunCocked)
                    {
                        FlxG.sound.play(Paths.soundRandom('shot', 1, 4));
                        trace('Firing gun!');
                        shootNextCan();
                    }
                    else
                    {
                        trace('Cannot fire gun!');
                    }
            }
    }
}

function getNextCanWithState(desiredState:Int)
	{
		for (index in 0...spawnedCans.length)
		{
			var can = spawnedCans[index];
			var canState = can.currentState;

			if (canState == desiredState)
			{
				// Return the can we found.
				return can;
			}
		}
		return null;
	}

function shootNextCan()
	{
		var can = getNextCanWithState(STATE_ARCING);

		if (can != null)
		{
			can.currentState = STATE_SHOT;
			can.playCanShot();

			new FlxTimer().start(1/24, function(tmr)
			{
				darkenStageProps();
			});

		}
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