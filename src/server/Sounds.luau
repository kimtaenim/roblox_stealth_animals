-- 효과음 재생. 소리 ID는 Config.Sounds 에서 바꾼다.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Sounds = {}

-- parent(파트) 위치에서 소리를 낸다. 서버에서 틀면 근처의 모든 플레이어가 듣는다.
function Sounds.play(name: string, parent: Instance)
	local id = (Config.Sounds :: any)[name]
	if type(id) ~= "string" or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Config.Sounds.Volume
	sound.RollOffMaxDistance = 150
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 6)
end

return Sounds
