function start(song)
    newText('yourMom', 'i am a little goofy', 0, 0, 16)
    set('yourMom.borderColor', color(0, 0, 0))
    set('yourMom.borderStyle', "OUTLINE")
    setCamera('yourMom', 'hud')
    add('yourMom')

    tween("yourMom", { x = 640, y = 360 }, 2, "linear", 0, function()
        tween("yourMom", { x = 0, y = FlxG.height - 18 }, 2, "linear")
    end)

    loadScript("test-script")

    print(exists('yourMom'))
end