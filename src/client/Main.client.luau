-- 클라이언트 진입점: 속도 숫자에 맞춰 달리기 속도 조절, 동물에게 맞으면 날아가기
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local knockback = ReplicatedStorage:WaitForChild("Knockback") :: RemoteEvent

local function updateWalkSpeed()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.walkSpeedFor(player:GetAttribute("Speed") or 0)
	end
end

player:GetAttributeChangedSignal("Speed"):Connect(updateWalkSpeed)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	updateWalkSpeed()
end)
updateWalkSpeed()

-- 캐릭터 물리는 내 컴퓨터가 담당하므로 날려 보내는 것도 여기서 한다
knockback.OnClientEvent:Connect(function(velocity: Vector3)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		root.AssemblyLinearVelocity = velocity
	end
end)

print(`[{Config.GameName}] 클라이언트 시작!`)
