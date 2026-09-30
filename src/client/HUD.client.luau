-- 화면 UI: 내 정보, 운반 중 안내, 알림 메시지, 인덱스(모두 받기), 업그레이드 안내 문구
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local notify = ReplicatedStorage:WaitForChild("Notify") :: RemoteEvent
local claimAll = ReplicatedStorage:WaitForChild("ClaimAll") :: RemoteEvent
local equipBest = ReplicatedStorage:WaitForChild("EquipBest") :: RemoteEvent

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
info.Size = UDim2.fromOffset(440, 70)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top

-- 속도가 오를 때 옆에 "+숫자" 가 잠깐 뜬다
local gainLabel = makeText(gui, 22)
gainLabel.Position = UDim2.fromOffset(16, 132)
gainLabel.Size = UDim2.fromOffset(160, 26)
gainLabel.TextXAlignment = Enum.TextXAlignment.Left
gainLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
gainLabel.Visible = false

local lastSpeed = player:GetAttribute("Speed") or 0
local gainCount = 0

local function refreshInfo()
	local speed = player:GetAttribute("Speed") or 0
	local money = player:GetAttribute("Money") or 0
	local level = player:GetAttribute("TreadmillLevel") or 1
	local gain = Config.Treadmill.Levels[level].Gain
	local walk = math.floor(Config.walkSpeedFor(speed))
	info.Text =
		`⚡ 속도 {Format.number(speed)}  (달리기 {walk})\n💰 돈 {Format.number(money)}\n🏃 러닝머신 Lv.{level}/{#Config.Treadmill.Levels} (초당 +{Format.number(
			gain
		)})`

	local delta = speed - lastSpeed
	lastSpeed = speed
	if delta >= 0.5 then
		gainLabel.Text = `+{Format.number(delta)} ⚡`
		gainLabel.Visible = true
		gainCount += 1
		local myCount = gainCount
		task.delay(0.6, function()
			if gainCount == myCount then
				gainLabel.Visible = false
			end
		end)
	end
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

-- 낮/밤 ---------------------------------------------------------------------
local dayLabel = makeText(gui, 20)
dayLabel.AnchorPoint = Vector2.new(0.5, 0)
dayLabel.Position = UDim2.new(0.5, 0, 0, 12)
dayLabel.Size = UDim2.fromOffset(420, 26)

task.spawn(function()
	while true do
		local endsAt = workspace:GetAttribute("PhaseEndsAt")
		if endsAt then
			local remaining = Format.countdown(endsAt - workspace:GetServerTimeNow())
			if workspace:GetAttribute("IsNight") then
				dayLabel.Text =
					`🌙 밤 (부화 {Config.DayNight.NightHatchMultiplier}배!) · 아침까지 {remaining}`
				dayLabel.TextColor3 = Color3.fromRGB(180, 190, 255)
			else
				dayLabel.Text = `☀️ 낮 · 밤까지 {remaining}`
				dayLabel.TextColor3 = Color3.new(1, 1, 1)
			end
		end
		task.wait(0.5)
	end
end)

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

local claimButton = makeButton(panel, "✔ 모두 받기", Color3.fromRGB(60, 170, 90))
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
	claimButton.Text = `✔ 모두 받기   ⚡{Format.number(pendingSpeed)}  💰{Format.number(pendingMoney)}`
	indexButton.Text = if pendingSpeed > 0 or pendingMoney > 0 then "📖 인덱스 ❗" else "📖 인덱스"
end

claimButton.Activated:Connect(function()
	claimAll:FireServer()
end)

-- 펫 / 인벤토리 ---------------------------------------------------------------
-- 서버가 Player 속성 BasePets, Inventory 에 JSON 으로 목록을 보내 준다: { { n = 이름, k = 등급, c = 마릿수 } }

local function makeListPanel(titleText: string): (Frame, ScrollingFrame, TextLabel, TextButton)
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(460, 420)
	frame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
	frame.Visible = false
	frame.Parent = gui
	Instance.new("UICorner").Parent = frame

	local heading = makeText(frame, 24)
	heading.Text = titleText
	heading.Position = UDim2.fromOffset(0, 10)
	heading.Size = UDim2.new(1, 0, 0, 32)

	local summary = makeText(frame, 16)
	summary.Position = UDim2.fromOffset(0, 44)
	summary.Size = UDim2.new(1, 0, 0, 20)
	summary.TextColor3 = Color3.fromRGB(200, 200, 210)

	local close = makeButton(frame, "X", Color3.fromRGB(200, 70, 70))
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Size = UDim2.fromOffset(36, 36)
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	local rows = Instance.new("ScrollingFrame")
	rows.Position = UDim2.fromOffset(16, 72)
	rows.Size = UDim2.new(1, -32, 1, -150)
	rows.BackgroundTransparency = 1
	rows.BorderSizePixel = 0
	rows.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rows.CanvasSize = UDim2.new()
	rows.ScrollBarThickness = 6
	rows.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = rows

	return frame, rows, summary, close
end

local function fillRows(rows: ScrollingFrame, json: string?): number
	for _, child in rows:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local ok, groups = pcall(HttpService.JSONDecode, HttpService, json or "[]")
	if not ok or type(groups) ~= "table" then
		groups = {}
	end
	local total = 0
	for i, group in groups do
		local rarity = Config.Rarities[group.k] or Config.Rarities[1]
		local row = makeText(rows, 18)
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -8, 0, 26)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = `[{rarity.Name}] {group.n}  ×{group.c}`
		row.TextColor3 = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.35)
		total += group.c
	end
	if #groups == 0 then
		local row = makeText(rows, 18)
		row.Size = UDim2.new(1, -8, 0, 26)
		row.Text = "아직 없어요"
		row.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
	return total
end

local petsPanel, petRows, petSummary = makeListPanel("🐾 펫 (기지에서 돌아다니는 동물)")
local equipButton = makeButton(petsPanel, "⭐ 최고 장비", Color3.fromRGB(230, 160, 40))
equipButton.AnchorPoint = Vector2.new(0.5, 1)
equipButton.Position = UDim2.new(0.5, 0, 1, -16)
equipButton.Size = UDim2.fromOffset(300, 50)
equipButton.Activated:Connect(function()
	equipBest:FireServer()
end)

local inventoryPanel, inventoryRows, inventorySummary = makeListPanel("🎒 인벤토리 (보관 중인 동물)")

local function refreshPets()
	local count = fillRows(petRows, player:GetAttribute("BasePets"))
	petSummary.Text =
		`기지 {count}/{Config.Base.MaxPets}마리 · 최고 장비를 누르면 강한 녀석이 기지에, 약한 녀석은 인벤토리로`
	local stored = fillRows(inventoryRows, player:GetAttribute("Inventory"))
	inventorySummary.Text = `보관 중 {stored}마리 · 펫 창의 ⭐ 최고 장비로 정리할 수 있어요`
end

-- 왼쪽 버튼들: 인덱스 · 펫 · 인벤토리 (창은 하나만 열림)
local petsButton = makeButton(gui, "🐾 펫", Color3.fromRGB(230, 140, 60))
petsButton.AnchorPoint = Vector2.new(0, 0.5)
petsButton.Position = UDim2.new(0, 16, 0.5, 60)
petsButton.Size = UDim2.fromOffset(130, 50)

local inventoryButton = makeButton(gui, "🎒 인벤토리", Color3.fromRGB(120, 90, 200))
inventoryButton.AnchorPoint = Vector2.new(0, 0.5)
inventoryButton.Position = UDim2.new(0, 16, 0.5, 120)
inventoryButton.Size = UDim2.fromOffset(130, 50)

local allPanels = { panel, petsPanel, inventoryPanel }
local function toggle(target: Frame)
	local show = not target.Visible
	for _, other in allPanels do
		other.Visible = false
	end
	target.Visible = show
end

indexButton.Activated:Connect(function()
	toggle(panel)
end)
petsButton.Activated:Connect(function()
	toggle(petsPanel)
end)
inventoryButton.Activated:Connect(function()
	toggle(inventoryPanel)
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
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
	elseif name == "BasePets" or name == "Inventory" then
		refreshPets()
	else
		refreshIndex()
	end
end)
refreshInfo()
refreshCarry()
refreshIndex()
refreshPets()

-- 조작법 ---------------------------------------------------------------------
local help = makeText(gui, 16)
help.AnchorPoint = Vector2.new(0, 1)
help.Position = UDim2.new(0, 16, 1, -16)
help.Size = UDim2.fromOffset(600, 20)
help.TextXAlignment = Enum.TextXAlignment.Left
help.Text =
	"러닝머신 위에 서 있으면 속도 UP · [E 길게] 에그 훔치기 · 인덱스에서 ✔ 모두 받기"
