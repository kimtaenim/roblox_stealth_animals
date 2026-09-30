-- 낮과 밤. workspace 속성으로 상태를 알린다:
--   IsNight (boolean), PhaseEndsAt (workspace:GetServerTimeNow() 기준 끝나는 시각)
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local DayNight = {}

local DAY_CLOCK = 14
local NIGHT_CLOCK = 22

local function setPhase(night: boolean, length: number)
	workspace:SetAttribute("IsNight", night)
	workspace:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + length)
	TweenService:Create(Lighting, TweenInfo.new(4), { ClockTime = if night then NIGHT_CLOCK else DAY_CLOCK }):Play()
end

function DayNight.isNight(): boolean
	return workspace:GetAttribute("IsNight") == true
end

-- 부화가 몇 배 빠른지
function DayNight.hatchMultiplier(): number
	return if DayNight.isNight() then Config.DayNight.NightHatchMultiplier else 1
end

function DayNight.start(onChange: (night: boolean) -> ())
	Lighting.ClockTime = DAY_CLOCK
	task.spawn(function()
		while true do
			setPhase(false, Config.DayNight.DayLength)
			onChange(false)
			task.wait(Config.DayNight.DayLength)
			setPhase(true, Config.DayNight.NightLength)
			onChange(true)
			task.wait(Config.DayNight.NightLength)
		end
	end)
end

return DayNight
