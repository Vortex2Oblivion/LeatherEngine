import flixel.addons.display.FlxTiledSprite;
import utilities.MathUtil;


var rainShader:CustomShader = new CustomShader(Assets.getText(Paths.frag("rain")), null, 100);
var rainShaderFilter:ShaderFilter;
var scrollingSky:FlxTiledSprite;

function createPost() {
	cameraInitialized = false;
	cameraDarkened = false;
	lightningActive = true;

    rainShader.setFloat('uTime', 0);
    rainShader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	rainShader.setFloat('uScale', FlxG.height / 200); // adjust this value so that the rain looks nice
    rainShader.setFloat("uIntensity", 0.5);


    if(Options.getData("shaders")){ //dont apply if shaders are disabled
        rainShaderFilter = new ShaderFilter(rainShader);
	    FlxG.camera.filters = [rainShaderFilter];
    }
	PlayState.instance.addBehind(scrollingSky, PlayState.instance.stage);
	PlayState.instance.camFollow.x = gf.x + (gf.width / 2) + 75;
	PlayState.instance.camFollow.y = gf.y + (gf.height / 2) - 50;
}

function onDeath():Void {
	FlxG.camera.filters = [];
}

function createStage() {
    
    scrollingSky = new FlxTiledSprite(Paths.image('blazin/skyBlur', 'stages'), 2000, 359, true, false);
	scrollingSky.setPosition(-500, -120);
	scrollingSky.scrollFactor.set(0, 0);

	var skyAdditive = PlayState.instance.stage.getNamedProp('skyAdditive');
	skyAdditive.blend = 0; // ADD
	skyAdditive.visible = false;

	var lightning = PlayState.instance.stage.getNamedProp('lightning');
	lightning.visible = false;

	var foregroundMultiply = PlayState.instance.stage.getNamedProp('foregroundMultiply');
	foregroundMultiply.blend = 9; // MULTIPLY
	foregroundMultiply.visible = false;

	var additionalLighten = PlayState.instance.stage.getNamedProp('additionalLighten');
	additionalLighten.blend = 0; // ADD
	additionalLighten.visible = false;

}

var cameraInitialized:Bool = false;
var cameraDarkened:Bool = false;
var lightningTimer:Float = 3.0;
var lightningActive:Bool = true;
var rainTimeScale:Float = 1.0;

function updatePost(elapsed:Float) {
    rainShader.setFloat("uTime", rainShader.getFloat("uTime") +  elapsed);
	rainShader.setFloatArray("uCameraBounds", [FlxG.camera.scroll.x + FlxG.camera.viewMarginX, FlxG.camera.scroll.y + FlxG.camera.viewMarginY, FlxG.camera.scroll.x + FlxG.camera.width, FlxG.camera.scroll.y + FlxG.camera.height]);
	rainTimeScale = MathUtil.coolLerp(rainTimeScale, 0.02, 0.05);

	if (scrollingSky != null)
		scrollingSky.scrollX -= FlxG.elapsed * 35;

	// Manually focus the camera before the song starts.
	if (!cameraInitialized){
		cameraInitialized = true;
		initializeCamera();

		bf.color = 0xFFDEDEDE;
		dad.color = 0xFFDEDEDE;
		gf.color = 0xFF888888;
	}
	if (lightningActive) {
		lightningTimer -= FlxG.elapsed;
	} else {
		lightningTimer = 1;
	}

	if (lightningTimer <= 0) {
		applyLightning();
		lightningTimer = FlxG.random.float(7, 15);
	}
	PlayState.instance.camFollow.x = gf.x + (gf.width / 2) + 75;
	PlayState.instance.camFollow.y = gf.y + (gf.height / 2) - 50;
}

function goodNoteHit() {
	rainTimeScale += 0.7;
}

function applyLightning():Void {
	var lightning = PlayState.instance.stage.getNamedProp('lightning');
	var skyAdditive = PlayState.instance.stage.getNamedProp('skyAdditive');
	var foregroundMultiply = PlayState.instance.stage.getNamedProp('foregroundMultiply');
	var additionalLighten = PlayState.instance.stage.getNamedProp('additionalLighten');

	var LIGHTNING_FULL_DURATION = 1.5;
	var LIGHTNING_FADE_DURATION = 0.3;

	skyAdditive.visible = true;
	skyAdditive.alpha = 0.7;
	FlxTween.tween(skyAdditive, {alpha: 0.0}, LIGHTNING_FULL_DURATION, {
		onComplete: cleanupLightning, // Make sure to call this only once!
	});

	foregroundMultiply.visible = true;
	foregroundMultiply.alpha = 0.64;
	FlxTween.tween(foregroundMultiply, {alpha: 0.0}, LIGHTNING_FULL_DURATION);

	additionalLighten.visible = true;
	additionalLighten.alpha = 0.3;
	FlxTween.tween(additionalLighten, {alpha: 0.0}, LIGHTNING_FADE_DURATION);

	lightning.visible = true;
	lightning.animation.play('strike');

	if (FlxG.random.bool(65)) {
		lightning.x = FlxG.random.int(-250, 280);
	} else {
		lightning.x = FlxG.random.int(780, 900);
	}

	// Darken characters
	var boyfriend = bf;
	FlxTween.color(boyfriend, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
	FlxTween.color(dad, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
	FlxTween.color(gf, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);

	// Sound
    FlxG.sound.play(Paths.soundRandom('Lightning', 1, 3, 'shared'));
}

function endSong():Void {
	// Disable lightning during ending cutscene.
	lightningActive = false;
}

function cleanupLightning(tween:FlxTween):Void {
	var skyAdditive = PlayState.instance.stage.getNamedProp('skyAdditive');
	var foregroundMultiply = PlayState.instance.stage.getNamedProp('foregroundMultiply');
	var additionalLighten = PlayState.instance.stage.getNamedProp('additionalLighten');
	var lightning = PlayState.instance.stage.getNamedProp('lightning');
	skyAdditive.visible = false;
	foregroundMultiply.visible = false;
	additionalLighten.visible = false;
	lightning.visible = false;
}

function initializeCamera():Void {
	PlayState.instance.camGame.fade(0xFF000000, 1.5, true, null, true);
}
