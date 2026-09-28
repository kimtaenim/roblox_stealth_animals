-- 화면 UI: 내 정보, 운반 중 안내, 알림 메시지, 인덱스(모두 받기), 업그레이드 안내 문구
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local notify = ReplicatedStorage:WaitForChild("Notify") :: RemoteEvent
local claimAll = ReplicatedStorage:WaitForChild("ClaimAll") :: RemoteEvent

local NOTIFY_COLORS = {
	info = Color3.fromRGB(255, 255, 255),
	success = Color3.fromRGB(120, 230, 120),
	danger = Color3.fromRGB(255, 90, 90),
}

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeText(parent: Instance, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 20
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Parent = parent
	Instance.new("UICorner").Parent = button
	return button
end

-- 내 정보 (왼쪽 위) ------------------------------------------------------------
local info = makeText(gui, 18)
info.AnchorPoint = Vector2.new(0, 0)
info.Position = UDim2.fromOffset(16, 60)
info.Size = UDim2.fromOffset(320, 70)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top

local function refreshInfo()
	local speed = player:GetAttribute("Speed") or 0
	local money = player:GetAttribute("Money") or 0
	local level = player:GetAttribute("TreadmillLevel") or 1
	local gain = Config.Treadmill.Levels[level].Gain
	info.Text =
		`⚡ 속도 {Format.number(speed)}\n💰 돈 {Format.number(money)}\n🏃 러닝머신 Lv.{level} (초당 +{Format.number(
			gain
		)})`
end

-- 운반 중 안내 ---------------------------------------------------------------
local carryLabel = makeText(gui, 22)
carryLabel.AnchorPoint = Vector2.new(0.5, 1)
carryLabel.Position = UDim2.new(0.5, 0, 1, -120)
carryLabel.Size = UDim2.fromOffset(500, 30)

local function refreshCarry()
	local carrying = player:GetAttribute("Carrying")
	carryLabel.Visible = carrying ~= nil
	if carrying then
		carryLabel.Text = `🥚 {carrying} 운반 중! 출발선 안(내 기지)으로 돌아가세요`
	end
end

-- 알림 메시지 ---------------------------------------------------------------
local toast = makeText(gui, 28)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0.2, 0)
toast.Size = UDim2.fromOffset(700, 40)
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

-- 인덱스 ---------------------------------------------------------------------
local indexButton = makeButton(gui, "📖 인덱스", Color3.fromRGB(80, 120, 220))
indexButton.AnchorPoint = Vector2.new(0, 0.5)
indexButton.Position = UDim2.new(0, 16, 0.5, 0)
indexButton.Size = UDim2.fromOffset(130, 50)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(560, 420)
panel.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner").Parent = panel

local title = makeText(panel, 26)
title.Text = "📖 인덱스"
title.Position = UDim2.fromOffset(0, 10)
title.Size = UDim2.new(1, 0, 0, 34)

local closeButton = makeButton(panel, "X", Color3.fromRGB(200, 70, 70))
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -10, 0, 10)
closeButton.Size = UDim2.fromOffset(36, 36)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(16, 54)
list.Size = UDim2.new(1, -32, 1, -130)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ScrollBarThickness = 6
list.Parent = panel
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

-- 칸마다 { label, regionId, rarity, animalName }
local cells = {}
for regionIndex = 1, Config.BuiltRegionCount do
	local region = Config.Regions[regionIndex]

	local header = makeText(list, 20)
	header.LayoutOrder = regionIndex * 2 - 1
	header.Size = UDim2.new(1, 0, 0, 26)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = `{region.Emoji} {region.Name}`

	local grid = Instance.new("Frame")
	grid.LayoutOrder = regionIndex * 2
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 0, 150)
	grid.Parent = list
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(120, 68)
	gridLayout.CellPadding = UDim2.fromOffset(8, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	for rarityIndex, rarity in Config.Rarities do
		local cell = Instance.new("Frame")
		cell.LayoutOrder = rarityIndex
		cell.BackgroundColor3 = Color3.fromRGB(50, 52, 62)
		cell.Parent = grid
		Instance.new("UICorner").Parent = cell
		local stroke = Instance.new("UIStroke")
		stroke.Color = rarity.Color
		stroke.Thickness = 2
		stroke.Parent = cell

		local label = makeText(cell, 16)
		label.Size = UDim2.fromScale(1, 1)
		table.insert(
			cells,
			{ label = label, regionId = region.Id, rarity = rarity, animalName = region.Animals[rarity.Id].Name }
		)
	end
end

local claimButton = makeButton(panel, "모두 받기", Color3.fromRGB(60, 170, 90))
claimButton.AnchorPoint = Vector2.new(0.5, 1)
claimButton.Position = UDim2.new(0.5, 0, 1, -16)
claimButton.Size = UDim2.fromOffset(360, 50)

local function refreshIndex()
	for _, cell in cells do
		local unlocked = player:GetAttribute(`Index_{cell.regionId}_{cell.rarity.Id}`) == true
		cell.label.Text = `{cell.rarity.Name}\n{if unlocked then cell.animalName else "???"}`
		cell.label.TextColor3 = if unlocked
			then cell.rarity.Color:Lerp(Color3.new(1, 1, 1), 0.4)
			else Color3.fromRGB(130, 130, 130)
	end

	local pendingSpeed = player:GetAttribute("PendingSpeed") or 0
	local pendingMoney = player:GetAttribute("PendingMoney") or 0
	claimButton.Text = `모두 받기   ⚡{Format.number(pendingSpeed)}  💰{Format.number(pendingMoney)}`
	indexButton.Text = if pendingSpeed > 0 or pendingMoney > 0 then "📖 인덱스 ❗" else "📖 인덱스"
end

indexButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)
claimButton.Activated:Connect(function()
	claimAll:FireServer()
end)

-- 러닝머신 업그레이드 안내 문구 (내 레벨에 맞게, 내 화면에서만 바뀜) ------------
local function refreshUpgradePrompt()
	local base = workspace:FindFirstChild("Base")
	local kiosk = base and base:FindFirstChild("UpgradeKiosk")
	local prompt = kiosk and kiosk:FindFirstChild("UpgradePrompt") :: ProximityPrompt?
	if not prompt then
		return
	end
	local levels = Config.Treadmill.Levels
	local level = player:GetAttribute("TreadmillLevel") or 1
	if level >= #levels then
		prompt.ObjectText = `러닝머신 Lv.{level} (최고)`
		prompt.ActionText = "최고 레벨!"
	else
		local nextLevel = levels[level + 1]
		prompt.ObjectText = `러닝머신 Lv.{level} → Lv.{level + 1} (초당 +{Format.number(nextLevel.Gain)})`
		prompt.ActionText = `업그레이드 💰{Format.number(nextLevel.Cost)}`
	end
end

task.spawn(function()
	local base = workspace:WaitForChild("Base")
	base:WaitForChild("UpgradeKiosk"):WaitForChild("UpgradePrompt")
	refreshUpgradePrompt()
end)

-- 속성이 바뀔 때마다 화면 갱신 ------------------------------------------------
player.AttributeChanged:Connect(function(name)
	if name == "Speed" or name == "Money" or name == "TreadmillLevel" then
		refreshInfo()
		refreshUpgradePrompt()
	elseif name == "Carrying" then
		refreshCarry()
	else
		refreshIndex()
	end
end)
refreshInfo()
refreshCarry()
refreshIndex()

-- 조작법 ---------------------------------------------------------------------
local help = makeText(gui, 16)
help.AnchorPoint = Vector2.new(0, 1)
help.Position = UDim2.new(0, 16, 1, -16)
help.Size = UDim2.fromOffset(600, 20)
help.TextXAlignment = Enum.TextXAlignment.Left
help.Text =
	"러닝머신 위에서 달려 속도 올리기 · [E 길게] 에그 훔치기 · 인덱스에서 모두 받기"
