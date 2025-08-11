function start(song)
    set('girlfriend.shouldDance', false)
end

function beatHit(curBeat)
    if get('girlfriend.animation.curAnim.name') == 'shoot2' then
        playAnimation('girlfriend', 'shoot2', true, false, 23)
    end
end