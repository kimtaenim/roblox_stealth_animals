-- 클라이언트 진입점: 이동 속도 조절
-- 살금살금(Sneak) 키를 누르고 있으면 느려지고, 동물을 들고 있으면 한 번 더 느려진다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local sneaking = false

local function updateSpeed()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local speed = if sneaking then Config.SneakSpeed else Config.WalkSpeed
	if player:GetAttribute("Carrying") then
		speed *= Config.CarrySpeedMultiplier
	end
	humanoid.WalkSpeed = speed
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Config.SneakKey then
		sneaking = true
		updateSpeed()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Config.SneakKey then
		sneaking = false
		updateSpeed()
	end
end)

player:GetAttributeChangedSignal("Carrying"):Connect(updateSpeed)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	updateSpeed()
end)

print(`[{Config.GameName}] 클라이언트 시작! {Config.SneakKey.Name} 키로 살금살금 걸을 수 있어요.`)
