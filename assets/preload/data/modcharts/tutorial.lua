function turnChange(turn)
    if turn == 'bf' then
        set('defaultCamZoom', get('stage.camZoom'))
    elseif get('SONG.player2') == 'gf' then
        set('defaultCamZoom', 1.3)
    end
end
