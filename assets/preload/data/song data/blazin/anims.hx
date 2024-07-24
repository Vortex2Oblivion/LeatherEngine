function onEvent(name:String) {
	switch (name.toLowerCase()) {
		case "weekend-1-punchlow":
			playPunchLowAnim();
		case "weekend-1-punchlowblocked":
			playPunchLowAnim();
		case "weekend-1-punchlowdodged":
			playPunchLowAnim();
		case "weekend-1-punchlowspin":
			playPunchLowAnim();

		case "weekend-1-punchhigh":
			playPunchHighAnim();
		case "weekend-1-punchhighblocked":
			playPunchHighAnim();
		case "weekend-1-punchhighdodged":
			playPunchHighAnim();
		case "weekend-1-punchhighspin":
			playPunchHighAnim();

		case "weekend-1-blockhigh":
			playBlockAnim();
		case "weekend-1-blocklow":
			playBlockAnim();
		case "weekend-1-blockspin":
			playBlockAnim();

		case "weekend-1-dodgehigh":
			playDodgeAnim();
		case "weekend-1-dodgelow":
			playDodgeAnim();
		case "weekend-1-dodgespin":
			playDodgeAnim();

		// Pico ALWAYS gets punched.
		case "weekend-1-hithigh":
			playHitHighAnim();
		case "weekend-1-hitlow":
			playHitLowAnim();
		case "weekend-1-hitspin":
			playHitSpinAnim();

		case "weekend-1-picouppercutprep":
			playUppercutPrepAnim();
		case "weekend-1-picouppercut":
			playUppercutAnim(true);

		case "weekend-1-darnelluppercutprep":
			playIdleAnim();
		case "weekend-1-darnelluppercut":
			playUppercutHitAnim();

		case "weekend-1-idle":
			playIdleAnim();
		case "weekend-1-fakeout":
			playFakeoutAnim();
			playCringeAnim();
		case "weekend-1-taunt":
			playTauntConditionalAnim();
		case "weekend-1-tauntforce":
			playTauntAnim();
		case "weekend-1-reversefakeout":
			playIdleAnim();
	}
}

var alternate:Bool = false;

function doAlternate():String {
	alternate = !alternate;
	return alternate ? '1' : '2';
}

function playCringeAnim() {
	dad.playAnim('cringe', true, false);
	moveToBack();
}

function playDodgeAnim() {
	bf.playAnim('dodge', true, false);
	dad.playAnim('punchHigh' + doAlternate(), true, false);
	moveToBack();
}

function playIdleAnim() {
	bf.playAnim('idle', false, false);
	dad.playAnim('idle', false, false);
	moveToBack();
}

function playFakeoutAnim() {
	bf.playAnim('fakeout', true, false);
	dad.playAnim('pissed', true, false);
	moveToBack();
}

function playUppercutPrepAnim() {
	bf.playAnim('uppercutPrep', true, false);
	moveToFront();
}

function playUppercutAnim(hit:Bool) {
	bf.playAnim('uppercut', true, false);
	dad.playAnim('uppercutHit', true, false);
	if (hit) {
		PlayState.instance.camGame.shake(0.005, 0.25);
	}
	moveToFront();
}

function playUppercutHitAnim() {
	bf.playAnim('uppercutHit', true, false);
	dad.playAnim('hitHigh', true, false);
	PlayState.instance.camGame.shake(0.005, 0.25);
	moveToBack();
}

function playHitHighAnim() {
	bf.playAnim('hitHigh', true, false);
	dad.playAnim('punchHigh' + doAlternate(), true, false);
	PlayState.instance.camGame.shake(0.0025, 0.15);
	moveToBack();
}

function playHitLowAnim() {
	bf.playAnim('hitLow', true, false);
	dad.playAnim('punchLow' + doAlternate(), true, false);
	PlayState.instance.camGame.shake(0.0025, 0.15);
	moveToBack();
}

function playHitSpinAnim() {
	bf.playAnim('hitSpin', true, false, true);
	PlayState.instance.camGame.shake(0.0025, 0.15);
	moveToBack();
}

function playPunchHighAnim() {
	bf.playAnim('punchHigh' + doAlternate(), true, false);
	dad.playAnim(FlxG.random.int(0,1) == 1 ? 'block' : 'hitHigh', true, false);
	moveToFront();
}

function playPunchLowAnim() {
	bf.playAnim('punchLow' + doAlternate(), true, false);
	dad.playAnim(FlxG.random.int(0,1) == 1 ? 'block' : 'hitHigh', true, false);
	moveToFront();
}

function playTauntConditionalAnim() {
	if (bf.curAnimName() == "fakeout") {
		playTauntAnim();
	} else {
		playIdleAnim();
	}
}

function playTauntAnim() {
	bf.playAnim('taunt', true, false);
	dad.playAnim('pissed', true, false);
	moveToBack();
}

function playBlockAnim() {
	bf.playAnim('block', true, false);
	dad.playAnim('punchHigh' + doAlternate(), true, false);
	PlayState.instance.camGame.shake(0.002, 0.1);
	moveToBack();
}
function moveToBack() {
	PlayState.instance.remove(bf);
	PlayState.instance.addBehindDad(bf);
}
function moveToFront() {
	PlayState.instance.remove(dad);
	PlayState.instance.addBehindBF(dad);
}