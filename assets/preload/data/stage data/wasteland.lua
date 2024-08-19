-- same time that 'start' is called for regular modcharts :flushed:
local tankAngle = 0
local tankSpeed = 0
local time = 0

function start(stage)
	print(stage .. ' is our stage!')

	randomizeStuff(getClass('flixel.FlxG', 'game.ticks'))

	set('clouds.x', math.random(-700, -100))
	set('clouds.y', math.random(-20, 20))
	set('clouds.velocity.x', math.random(5, 15))

	tankAngle = math.random(-90, 45)
	tankSpeed = math.random(5, 7)

	moveDaTank()
end

-- called each frame with elapsed being the seconds between the last frame
function update(elapsed)
	time = time + elapsed
	moveDaTank()
end

function randomizeStuff(beat)
	local ticks = getClass('flixel.FlxG', 'game.ticks') / 1000

	local offsetRand = songBpm + bpm + beat + curBeat + scrollspeed + keyCount + curStep + crochet + safeZoneOffset + screenWidth + screenHeight + fpsCap
	offsetRand = offsetRand + getWindowX() + getWindowY()
	offsetRand = offsetRand + ticks
	
	math.randomseed(time + offsetRand)
end

function moveDaTank()
	local tankX = 400
	tankAngle = tankAngle + (FlxG.elapsed * tankSpeed)

	set('tank.angle', tankAngle - 90 + 15)
	set('tank.x', tankX + 1500 * math.cos(math.pi / 180 * (1 * tankAngle + 180)))
	set('tank.y', 1300 + 1100 * math.sin(math.pi / 180 * (1 * tankAngle + 180)))
end