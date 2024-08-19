import substates.GameOverSubstate;

var retry:FlxSprite = new FlxSprite();

function onDeath(){
    retry.frames = Paths.getSparrowAtlas("characters/Pico_Death_Retry", "shared");
    retry.visible = false;
    retry.antialiasing = Options.getData("antialiasing");
    retry.x = GameOverSubstate.instance.bf.x + 425;
    retry.y = GameOverSubstate.instance.bf.y + 50;
    retry.animation.addByPrefix('loop', 'Retry Text Loop', 24, true);
    retry.animation.addByPrefix('confirm', 'Retry Text Confirm', 24, false);
    retry.animation.play('loop', false);
    GameOverSubstate.instance.add(retry);
    GameOverSubstate.instance.bf.animation.finishCallback = function(name:String){
        if (name == "firstDeath"){
            retry.visible = true;
        }
    }
}
function onRetry(){
    retry.visible = true;
    retry.animation.play('confirm', true);
    retry.x -= 250;
	retry.y -= 200;
}