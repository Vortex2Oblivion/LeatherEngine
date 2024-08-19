function create(stage)
	print(stage .. " is our stage!")

	if animatedBackgrounds then
		createSound("thunder1", "thunder_1", "shared", false)
		createSound("thunder2", "thunder_2", "shared", false)
	end
end

local lastBeat = 0
local beatOffset = 8

local time = 0

local justScared = false

function update(elapsed)
	if animatedBackgrounds then
		time = time + elapsed
	end
end

-- everytime a beat hit is called on the song this happens
function beatHit(beat)
	if animatedBackgrounds then
		if randomBool(10) and beat > lastBeat + beatOffset then
			lastBeat = beat

			set("boyfriend.shouldDance", false)
			set("girlfriend.shouldDance", false)

			playCharAnim("boyfriend", "scared", true)
			playCharAnim("girlfriend", "scared", true)

			playAnimation("bg", "lightning", true)
			playSound("thunder" .. tostring(randomInt(1,2)))

			beatOffset = randomInt(8, 24)

			justScared = true
		elseif justScared then
			set("boyfriend.shouldDance", true)
			dance("boyfriend")
			set("girlfriend.shouldDance", true)
			dance("girlfriend")

			justScared = false
		end
	end
end