-- 화면 UI: 발각 게이지, 운반 중 안내, 알림 메시지, 조작법
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local notify = ReplicatedStorage:WaitForChild("Notify") :: RemoteEvent

local NOTIFY_COLORS = {
	info = Color3.fromRGB(255, 255, 255),
	success = Color3.fromRGB(120, 230, 120),
	danger = Color3.fromRGB(255, 90, 90),
}

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeText(name: string, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	return label
end

-- 발각 게이지 ---------------------------------------------------------------
local meter = Instance.new("Frame")
meter.Name = "DetectionMeter"
meter.AnchorPoint = Vector2.new(0.5, 0)
meter.Position = UDim2.new(0.5, 0, 0, 80)
meter.Size = UDim2.fromOffset(260, 16)
meter.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
meter.BackgroundTransparency = 0.3
meter.Visible = false
meter.Parent = gui
Instance.new("UICorner").Parent = meter

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BorderSizePixel = 0
fill.Parent = meter
Instance.new("UICorner").Parent = fill

local meterLabel = makeText("MeterLabel", 16)
meterLabel.Text = "👀 농부가 수상하게 보고 있어요"
meterLabel.AnchorPoint = Vector2.new(0.5, 1)
meterLabel.Position = UDim2.new(0.5, 0, 0, 76)
meterLabel.Size = UDim2.fromOffset(300, 20)
meterLabel.Visible = false

local function refreshMeter()
	local value = player:GetAttribute("Detection") or 0
	fill.Size = UDim2.fromScale(value, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 220, 0):Lerp(Color3.fromRGB(230, 40, 40), value)
	meter.Visible = value > 0
	meterLabel.Visible = value > 0
end
player:GetAttributeChangedSignal("Detection"):Connect(refreshMeter)
refreshMeter()

-- 운반 중 안내 ---------------------------------------------------------------
local carryLabel = makeText("CarryLabel", 22)
carryLabel.AnchorPoint = Vector2.new(0.5, 1)
carryLabel.Position = UDim2.new(0.5, 0, 1, -120)
carryLabel.Size = UDim2.fromOffset(500, 30)

local function refreshCarry()
	local kind = player:GetAttribute("Carrying")
	local info = kind and Config.Animals[kind]
	carryLabel.Visible = info ~= nil
	if info then
		carryLabel.Text = `{info.Emoji} {info.DisplayName} 운반 중! 내 기지로 가져가세요`
	end
end
player:GetAttributeChangedSignal("Carrying"):Connect(refreshCarry)
refreshCarry()

-- 알림 메시지 ---------------------------------------------------------------
local toast = makeText("Toast", 28)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0.22, 0)
toast.Size = UDim2.fromOffset(600, 40)
toast.Visible = false

local toastCount = 0
notify.OnClientEvent:Connect(function(text: string, kind: string)
	toast.Text = text
	toast.TextColor3 = NOTIFY_COLORS[kind] or NOTIFY_COLORS.info
	toast.Visible = true

	toastCount += 1
	local myCount = toastCount
	task.delay(2.5, function()
		if toastCount == myCount then
			toast.Visible = false
		end
	end)
end)

-- 조작법 ---------------------------------------------------------------------
local help = makeText("Help", 16)
help.AnchorPoint = Vector2.new(0, 1)
help.Position = UDim2.new(0, 16, 1, -16)
help.Size = UDim2.fromOffset(400, 20)
help.TextXAlignment = Enum.TextXAlignment.Left
help.Text = `[{Config.SneakKey.Name}] 살금살금   [E 길게] 훔치기`
