local trainMoving = false
local trainCooldown = 0

local trainFrameTiming = 0

local startedMoving = false

local trainFinishing = false

local trainCars = 0

local time = 0

local lightColors = {
	0x31A2FD,
	0x31FD8C,
	0xFB33F5,
	0xFD4531,
	0xFBA633
}

-- when the stage lua is created
function create(stage)
	print(stage .. " is our stage!")

	createSound("trainSound", "train_passes", "shared")
end

function createPost()
	set("light.color", lightColors[randomInt(1, 5)])
end

-- called each frame with elapsed being the seconds between the last frame
function update(elapsed)
	time = time + elapsed

	if trainMoving then
		trainFrameTiming = trainFrameTiming + elapsed

		if trainFrameTiming >= 1 / 24 then
			updateTrainPos()
			trainFrameTiming = 0
		end
	end
end

function beatHit(curBeat)
	if not trainMoving then
		trainCooldown = trainCooldown + 1
	end

	if curBeat % 4 == 0 then
		set('light.alpha', 1)
		set("light.color", lightColors[randomInt(1, 5)])
	end

	if curBeat % 8 == 4 and randomBool(30) and not trainMoving and trainCooldown > 8 then
		trainCooldown = randomInt(-4, 0)
		startDaTrain()
	end
end



function startDaTrain()
	trainMoving = true
	playSound("trainSound", true)
end

function updateTrainPos()
	if get("trainSound.time") >= 4700 then
		startedMoving = true
		playCharAnim("girlfriend", "hairBlow", false)
	end

	if startedMoving then
		set("train.x", get("train.x") - 400)
		set("train.visible", true)

		if get("train.x") < -2000 and not trainFinishing then
			set("train.x", -1150)
			trainCars = trainCars - 1

			if trainCars <= 0 then
				trainFinishing = true
			end
		end

		if get("train.x") < -4000 and trainFinishing then
			trainReset()
		end
	end
end

function trainReset()
	playCharAnim("girlfriend", "hairFall", true)
    
	set("train.x", windowWidth + 200)
	set("train.visible", false)
	trainMoving = false
	trainCars = 8
	trainFinishing = false
	startedMoving = false
end

function updatePost(elapsed)
	set("timeBar.color", get("light.color"))
	set('light.alpha', lerp(1, 0, ((Conductor.songPosition / Conductor.crochet / 4) % 1)))
end