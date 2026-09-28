-- 클라이언트 진입점: StarterPlayerScripts/Client/Main
-- 살금살금(Sneak) 키를 누르고 있는 동안 이동 속도를 줄인다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local function setSpeed(speed: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Config.SneakKey then
		setSpeed(Config.SneakSpeed)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Config.SneakKey then
		setSpeed(Config.WalkSpeed)
	end
end)

print(`[{Config.GameName}] 클라이언트 시작! {Config.SneakKey.Name} 키로 살금살금 걸을 수 있어요.`)
