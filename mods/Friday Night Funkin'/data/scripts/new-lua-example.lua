function start(song)
    newText('exampleText', 'This is example text!', 0, 0, 16)
    set('exampleText.borderColor', color(0, 0, 0))
    set('exampleText.borderStyle', "OUTLINE")
    setCamera('exampleText', 'hud')
    add('exampleText')

    tween("exampleText", { x = 640, y = 360 }, 2, "linear", 0, function()
        tween("exampleText", { x = 0, y = flxG.height - 18 }, 2, "linear")
    end)

    loadScript("test-script")

    print(exists('exampleText'))
end