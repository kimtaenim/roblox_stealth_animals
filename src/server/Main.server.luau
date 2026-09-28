-- 서버 진입점: ServerScriptService/Server/Main
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

print(`[{Config.GameName}] 서버 시작! Rojo 동기화가 정상 동작 중입니다.`)

Players.PlayerAdded:Connect(function(player)
	print(`[{Config.GameName}] {player.Name} 님이 입장했습니다.`)
end)
