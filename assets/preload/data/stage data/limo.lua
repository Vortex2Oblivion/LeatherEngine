-- same time that 'start' is called for regular modcharts :flushed:
function create(stage)
	print(stage .. " is our stage!")

	set("car.x", -12600)
	set("car.y", randomFloat(140, 250))
	set("car.velocity.x", 0)

	if animatedBackgrounds then
		createSound("pass1", "carPass0")
		createSound("pass2", "carPass1")
	end
end

local danceValue = false
local carCanGoVroom = true
local funnyTimer = 0
local time = 0

function update(elapsed)
	if animatedBackgrounds then
		time = time + elapsed
		funnyTimer = funnyTimer + elapsed

		if not carCanGoVroom and funnyTimer >= 2 then
			set("car.x", -12600)
			set("car.y", randomFloat(140, 250))
			set("car.velocity.x", 0)

			carCanGoVroom = true
		end
	end
end

function countdownTick(tick)
	if animatedBackgrounds then
		danceValue = not danceValue

		if danceValue then
			for i = 1,4 do
				playAnimation("dancer"..i, "danceRight", true)
			end
		else
			for i = 1,4 do
				playAnimation("dancer"..i, "danceLeft", true)
			end
		end
	end
end

-- everytime a beat hit is called on the song this happens
function beatHit(beat)
	if animatedBackgrounds then
		danceValue = not danceValue

		if danceValue then
			for i = 1,4 do
				playAnimation("dancer"..i, "danceRight", true)
			end
		else
			for i = 1,4 do
				playAnimation("dancer"..i, "danceLeft", true)
			end
		end

		if randomBool(10) and carCanGoVroom then
			playSound("pass" .. tostring(randomInt(1,2)), true)

			set("car.velocity.x", (randomFloat(170, 220) / FlxG.elapsed) * 3)

			carCanGoVroom = false
			funnyTimer = 0
		end
	end
end