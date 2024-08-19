function onDeathLoop() {
    if(!character.isPlayer) {
        FlxG.sound.play(Paths.soundRandom("jeffGameover/jeffGameover-", 1, 25, "shared"), 5);
    }
}