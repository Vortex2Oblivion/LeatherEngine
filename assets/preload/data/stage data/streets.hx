import openfl.filters.BlurFilter;
import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxPoint;


var rainShader:CustomShader = new CustomShader(Assets.getText(Paths.frag("rain")), null, 100);
var rainShaderFilter:ShaderFilter;
var blurFilter:BlurFilter = new BlurFilter(6, 6);

// as song goes on, these are used to make the rain more intense throught the song
// these values are also used for the rain sound effect volume intensity!
var rainShaderStartIntensity:Float;
var rainShaderEndIntensity:Float;

// var rainSndAmbience:FunkinSound;
// var carSndAmbience:FunkinSound;

var lightsStop:Bool = false; // state of the traffic lights
var lastChange:Int = 0;
var changeInterval:Int = 8; // make sure it doesnt change until AT LEAST this many beats

var carWaiting:Bool = false; // if the car is waiting at the lights and is ready to go on green
var carInterruptable:Bool = true; // if the car can be reset
var car2Interruptable:Bool = true;

var scrollingSky:FlxTiledSprite;

function create():Void
{
    rainShader.setFloat('uTime', 0);
    rainShader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	rainShader.setFloat('uScale', FlxG.height / 200); // adjust this value so that the rain looks nice

	switch (PlayState.instance.curSong.toLowerCase())
	{
		case "lit up":
			rainShaderStartIntensity = 0.1;
			rainShaderEndIntensity = 0.2;
		case "2hot":
			rainShaderStartIntensity = 0.2;
			rainShaderEndIntensity = 0.4;
        default:
            rainShaderStartIntensity = 0;
			rainShaderEndIntensity = 0.1;
	}

	rainShader.setFloat("uIntensity", 0.5);

    if(Options.getData("shaders")){ //dont apply if shaders are disabled
        rainShaderFilter = new ShaderFilter(rainShader);
	    FlxG.camera.filters = [rainShaderFilter];
    }

	resetCar(true, true);
	resetStageValues();
}

function createPost(){
    dad.cameraOffset[0] += 250;
    bf.cameraOffset[0] -= 250;
}

/**
  * Changes the current state of the traffic lights.
	* Updates the next change accordingly and will force cars to move when ready
  */
  function changeLights(beat:Int):Void{

    lastChange = beat;
    lightsStop = !lightsStop;

    if(lightsStop){
        phillyTraffic.animation.play('tored');
        changeInterval = 20;
    } else {
        phillyTraffic.animation.play('togreen');
        changeInterval = 30;

        if(carWaiting == true) finishCarLights(phillyCars);
    }
}

/**
* Resets every value of a car and hides it from view.
*/
function resetCar(left:Bool, right:Bool){
    if(left){
        carWaiting = false;
        carInterruptable = true;
        var cars = phillyCars;
        if (cars != null) {
            FlxTween.cancelTweensOf(cars);
            cars.x = 1200;
            cars.y = 818;
            cars.angle = 0;
        }
    }

    if(right){
        car2Interruptable = true;
        var cars2 = phillyCars2;
        if (cars2 != null) {
            FlxTween.cancelTweensOf(cars2);
            phillyCars2.flipX = true;
            phillyCars2.x = 1200;
            phillyCars2.y = 818;
            phillyCars2.angle = 0;
        }
    }
}
function startCountdown() {
    resetCar(true, true);
    resetStageValues();
}
function createStage()
{
	scrollingSky = new FlxTiledSprite(Paths.image('phillyStreets/phillySkybox'), 2922, 718, true, false);
	scrollingSky.setPosition(-650, -375);
	scrollingSky.scrollFactor.set(0.1, 0.1);
	scrollingSky.scale.set(0.65, 0.65);

	PlayState.instance.stage.add(scrollingSky);
    addProp(phillyTraffic_lightmap, 'phillyTraffic_lightmap');
    addProp(phillyHighwayLights_lightmap, 'phillyHighwayLights_lightmap');
}
function onDestroy() {
    trace('Cancelling car tweens weee');
    var cars = phillyCars;
    if (cars != null) FlxTween.cancelTweensOf(cars);
    var cars2 = phillyCars2;
    if (cars2 != null) FlxTween.cancelTweensOf(cars2);
    trace('Done');
}
/**
  * Drive the car away from the lights to the end of the road.
	* Used when the lights turn green and the car is waiting in position.
  */
  function finishCarLights(sprite:FlxSprite):Void{
    carWaiting = false;
    var duration:Float = FlxG.random.float(1.8, 3);
    var rotations:Array<Int> = [-5, 18];
    var offset:Array<Float> = [306.6, 168.3];
    var startdelay:Float = FlxG.random.float(0.2, 1.2);

    var path:Array<FlxPoint> = [
        FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15),
        FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
        FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
    ];

    FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay} );
    FlxTween.quadPath(sprite, path, duration, true,
{
  ease: FlxEase.sineIn,
        startDelay: startdelay,
        onComplete: function(_) {
        carInterruptable = true;
  }
});
}

/**
* Drives a car towards the lights and stops.
* Used when a car tries to drive while the lights are red.
*/
function driveCarLights(sprite:FlxSprite):Void{
    carInterruptable = false;
    FlxTween.cancelTweensOf(sprite);
    var variant:Int = FlxG.random.int(1,4);
    sprite.animation.play('car' + variant);
    var extraOffset = [0, 0];
    var duration:Float = 2;

    switch(variant){
        case 1:
            duration = FlxG.random.float(1, 1.7);
        case 2:
            extraOffset = [20, -15];
            duration = FlxG.random.float(0.9, 1.5);
        case 3:
            extraOffset = [30, 50];
            duration = FlxG.random.float(1.5, 2.5);
        case 4:
            extraOffset = [10, 60];
            duration = FlxG.random.float(1.5, 2.5);
    }
    var rotations:Array<Int> = [-7, -5];
    var offset:Array<Float> = [306.6, 168.3];
    sprite.offset.set(extraOffset[0], extraOffset[1]);

    var path:Array<FlxPoint> = [
        FlxPoint.get(1500 - offset[0] - 20, 1049 - offset[1] - 20),
        FlxPoint.get(1770 - offset[0] - 80, 994 - offset[1] + 10),
        FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15)
    ];
    // debug shit!!! keeping it here just in case
    // for(point in path){
    // 	var debug:FlxSprite = new FlxSprite(point.x - 5, point.y - 5).makeGraphic(10, 10, 0xFFFF0000);
// 	add(debug);
    // }
    FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut} );
    FlxTween.quadPath(sprite, path, duration, true,
{
  ease: FlxEase.cubeOut,
        onComplete: function(_) {
        carWaiting = true;
                    if(lightsStop == false) finishCarLights(phillyCars);
  }
});
}

/**
* Drives a car across the screen without stopping.
* Used when the lights are green.
*/
function driveCar(sprite:FlxSprite):Void{
    carInterruptable = false;
    FlxTween.cancelTweensOf(sprite);
    var variant:Int = FlxG.random.int(1,4);
    sprite.animation.play('car' + variant);
    // setting an offset here because the current implementation of stage prop offsets was not working at all for me
    // if possible id love to not have to do this but im keeping this for now
    var extraOffset = [0, 0];
    var duration:Float = 2;
    // set different values of speed for the car types (and the offset)
    switch(variant){
        case 1:
            duration = FlxG.random.float(1, 1.7);
        case 2:
            extraOffset = [20, -15];
            duration = FlxG.random.float(0.6, 1.2);
        case 3:
            extraOffset = [30, 50];
            duration = FlxG.random.float(1.5, 2.5);
        case 4:
            extraOffset = [10, 60];
            duration = FlxG.random.float(1.5, 2.5);
    }
    // random arbitrary values for getting the cars in place
    // could just add them to the points but im LAZY!!!!!!
    var offset:Array<Float> = [306.6, 168.3];
    sprite.offset.set(extraOffset[0], extraOffset[1]);
    // start/end rotation
    var rotations:Array<Int> = [-8, 18];
    // the path to move the car on
    var path:Array<FlxPoint> = [
            FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 30),
            FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
            FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
    ];

    FlxTween.angle(sprite, rotations[0], rotations[1], duration, null );
    FlxTween.quadPath(sprite, path, duration, true,
  {
    ease: null,
            onComplete: function(_) {
        carInterruptable = true;
      }
});
}

function driveCarBack(sprite:FlxSprite):Void{
    car2Interruptable = false;
    FlxTween.cancelTweensOf(sprite);
    var variant:Int = FlxG.random.int(1,4);
    sprite.animation.play('car' + variant);
    // setting an offset here because the current implementation of stage prop offsets was not working at all for me
    // if possible id love to not have to do this but im keeping this for now
    var extraOffset = [0, 0];
    var duration:Float = 2;
    // set different values of speed for the car types (and the offset)
    switch(variant){
        case 1:
            duration = FlxG.random.float(1, 1.7);
        case 2:
            extraOffset = [20, -15];
            duration = FlxG.random.float(0.6, 1.2);
        case 3:
            extraOffset = [30, 50];
            duration = FlxG.random.float(1.5, 2.5);
        case 4:
            extraOffset = [10, 60];
            duration = FlxG.random.float(1.5, 2.5);
    }
    // random arbitrary values for getting the cars in place
    // could just add them to the points but im LAZY!!!!!!
    var offset:Array<Float> = [306.6, 168.3];
    sprite.offset.set(extraOffset[0], extraOffset[1]);
    // start/end rotation
    var rotations:Array<Int> = [18, -8];
    // the path to move the car on
    var path:Array<FlxPoint> = [
            FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 60),
            FlxPoint.get(2400 - offset[0], 980 - offset[1] - 30),
            FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 10)

    ];

    FlxTween.angle(sprite, rotations[0], rotations[1], duration, null );
    FlxTween.quadPath(sprite, path, duration, true,
  {
    ease: null,
            onComplete: function(_) {
        car2Interruptable = true;
      }
});
}

/**
* Resets the values tied to the lights that need to be accounted for on a restart.
*/
function resetStageValues():Void{
    lastChange = 0;
    changeInterval = 8;
    var traffic = phillyTraffic;
    if (traffic != null) {
        traffic.animation.play('togreen');
    }
    lightsStop = false;
}

var rainDropTimer:Float = 0;
var rainDropWait:Float = 6;
function updatePost(elapsed:Float)
{

		var remappedIntensityValue:Float = FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music != null ? FlxG.sound.music.length : 0.0, rainShaderStartIntensity, rainShaderEndIntensity);
        rainShader.setFloat("uIntensity", remappedIntensityValue);
        rainShader.setFloat("uTime", rainShader.getFloat("uTime") +  elapsed);
        rainShader.setFloatArray("uCameraBounds", [FlxG.camera.scroll.x + FlxG.camera.viewMarginX, FlxG.camera.scroll.y + FlxG.camera.viewMarginY, FlxG.camera.scroll.x + FlxG.camera.width, FlxG.camera.scroll.y + FlxG.camera.height]);

		if(scrollingSky != null) scrollingSky.scrollX -= FlxG.elapsed * 22;

		// if (rainSndAmbience != null) {
		// 	rainSndAmbience.volume = Math.min(0.3, remappedIntensityValue * 2);
		// }
}

function beatHit(beat:Int)
{

	// Try driving a car when its possible
	if (FlxG.random.bool(10) && beat != (lastChange + changeInterval) && carInterruptable == true)
	{
		if(lightsStop == false){
			driveCar(phillyCars);
		}else{
			driveCarLights(phillyCars);
		}
	}

	// try driving one on the right too. in this case theres no red light logic, it just can only spawn on green lights
	if(FlxG.random.bool(10) && beat != (lastChange + changeInterval) && car2Interruptable == true && lightsStop == false) driveCarBack(phillyCars2);

	// After the interval has been hit, change the light state.
	if (beat == (lastChange + changeInterval)) changeLights(beat);
}
function onPause() {
    pauseCars();
}
function onResume() {
    resumeCars();
}
function pauseCars():Void {
    var cars = phillyCars;
    if (cars != null) {
        FlxTweenUtil.pauseTweensOf(cars);
    }

    var cars2 = phillyCars2;
    if (cars2 != null) {
        FlxTweenUtil.pauseTweensOf(cars2);
    }
}

function resumeCars():Void {
    var cars = phillyCars;
    if (cars != null) {
        FlxTweenUtil.resumeTweensOf(cars);
    }

    var cars2 = phillyCars2;
    if (cars2 != null) {
        FlxTweenUtil.resumeTweensOf(cars2);
    }
}
function onDeath():Void {
    // Make it so the rain shader doesn't show over the game over screen
    FlxG.camera.filters = [];
}
function addProp(prop:FlxSprite, ?name:String = null)
	{
		if (StringTools.endsWith(name, "_lightmap"))
		{
			prop.blend = 0; // 0 means ADD (see openfl.display.BlendMode)
			prop.alpha = 0.6;
			//frameBufferMan.moveSpriteTo("lightmap", prop);
		}
	}