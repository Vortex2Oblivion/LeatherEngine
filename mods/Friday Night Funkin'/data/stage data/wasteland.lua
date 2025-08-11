-- same time that 'start' is called for regular modcharts :flushed:
local tankAngle = 0
local tankSpeed = 0

function start(stage)
    print(stage .. ' is our stage!')


    set('clouds.x', randomInt(-700, -100))
    set('clouds.y', randomInt(-20, 20))
    set('clouds.velocity.x', randomInt(5, 15))

    tankAngle = randomInt(-90, 45)
    tankSpeed = randomInt(5, 7)

    moveDaTank()
end

-- called each frame with elapsed being the seconds between the last frame
function update(elapsed)
    moveDaTank(elapsed)
end

function moveDaTank(elapsed)
    local tankX = 400
    tankAngle = tankAngle + (elapsed * tankSpeed)

    set('tank.angle', tankAngle - 90 + 15)
    set('tank.x', tankX + 1500 * math.cos(math.pi / 180 * (tankAngle + 180)))
    set('tank.y', 1300 + 1100 * math.sin(math.pi / 180 * (tankAngle + 180)))
end
