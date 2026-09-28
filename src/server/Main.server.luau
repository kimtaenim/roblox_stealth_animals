-- 서버 진입점: 러닝머신 → 에그 훔치기 → 기지로 운반 → 부화 → 인덱스에서 모두 받기
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local AnimalFactory = require(script.Parent.AnimalFactory)
local Chaser = require(script.Parent.Chaser)
local PlayerStats = require(script.Parent.PlayerStats)
local World = require(script.Parent.World)

local function makeRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local notify = makeRemote("Notify") -- 서버→클라: (text, kind: "info" | "success" | "danger")
local knockback = makeRemote("Knockback") -- 서버→클라: (velocity)
local claimAll = makeRemote("ClaimAll") -- 클라→서버: 인덱스의 "모두 받기"

local base = World.buildBase()
local regions: { World.Region } = {}
for i = 1, Config.BuiltRegionCount do
	regions[i] = World.buildRegion(i)
end

local chasersFolder = Instance.new("Folder")
chasersFolder.Name = "Chasers"
chasersFolder.Parent = workspace
local chasers = {}
for _, region in regions do
	local config = Config.Regions[region.index]
	for i, kind in config.Chasers do
		table.insert(chasers, Chaser.new(kind, region.chaserHomes[i], config.ChaserSpeed, region, chasersFolder))
	end
end

type Carry = { model: Model, regionIndex: number, rarityIndex: number, warned: boolean }

local carrying: { [Player]: Carry } = {}
local plotOf: { [Player]: World.Plot } = {}

--------------------------------------------------------------------------------
-- 에그 훔치기 / 운반
--------------------------------------------------------------------------------

local function dropCarry(player: Player)
	local carry = carrying[player]
	if carry then
		carrying[player] = nil
		carry.model:Destroy()
		player:SetAttribute("Carrying", nil)
	end
end

-- 에그를 플레이어 머리 위에 붙인다
local function pickUp(player: Player, model: Model): boolean
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not character or not head then
		return false
	end

	local boxCFrame, boxSize = model:GetBoundingBox()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	local primary = model.PrimaryPart :: BasePart
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = primary
	weld.C0 = CFrame.new(0, head.Size.Y / 2 + boxSize.Y / 2, 0)
	weld.C1 = primary.CFrame:ToObjectSpace(boxCFrame)
	weld.Parent = primary
	model.Parent = character
	return true
end

local function spawnEgg(region: World.Region, spot: World.EggSpot)
	local rarity = Config.Rarities[spot.rarityIndex]
	local egg = AnimalFactory.buildEgg(rarity.Color, rarity.Neon)
	egg:PivotTo(CFrame.new(spot.position))
	egg.Parent = region.eggs

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "훔치기"
	prompt.ObjectText = `{rarity.Name} 에그`
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg.PrimaryPart

	prompt.Triggered:Connect(function(player)
		if carrying[player] then
			notify:FireClient(player, "이미 에그를 들고 있어요!", "info")
			return
		end
		if not plotOf[player] then
			notify:FireClient(player, "빈 기지가 없어서 훔칠 수 없어요.", "danger")
			return
		end

		prompt:Destroy() -- 다른 사람이 동시에 가져가지 못하게
		if pickUp(player, egg) then
			carrying[player] =
				{ model = egg, regionIndex = region.index, rarityIndex = spot.rarityIndex, warned = false }
			player:SetAttribute("Carrying", `{rarity.Name} 에그`)
			notify:FireClient(
				player,
				`{rarity.Name} 에그를 훔쳤어요! 동물을 피해 기지로 돌아가세요`,
				"success"
			)
		else
			egg:Destroy()
		end
		task.delay(rarity.RespawnTime, spawnEgg, region, spot)
	end)
end

for _, region in regions do
	for _, spot in region.eggSpots do
		spawnEgg(region, spot)
	end
end

--------------------------------------------------------------------------------
-- 부화
--------------------------------------------------------------------------------

local function updatePending(player: Player, plot: World.Plot)
	local speed, money = 0, 0
	for _, pad in plot.pads do
		if pad.state == "hatched" then
			local s, m = Config.rewardFor(pad.regionIndex, pad.rarityIndex)
			speed += s
			money += m
		end
	end
	player:SetAttribute("PendingSpeed", speed)
	player:SetAttribute("PendingMoney", money)
end

local function placeOnPad(pad: World.Pad, model: Model)
	local top = pad.part.Position + Vector3.new(0, pad.part.Size.Y / 2, 0)
	model:PivotTo(CFrame.new(top) * CFrame.Angles(0, math.rad(180), 0)) -- 출발선 쪽을 보게
	model.Parent = pad.part
end

-- 기지에 도착하면 빈 부화 자리에 에그를 놓는다
local function tryDeposit(player: Player, plot: World.Plot, carry: Carry)
	local pad: World.Pad? = nil
	for _, candidate in plot.pads do
		if candidate.state == "empty" then
			pad = candidate
			break
		end
	end
	if not pad then
		if not carry.warned then
			carry.warned = true
			notify:FireClient(
				player,
				"부화 자리가 꽉 찼어요! 인덱스에서 '모두 받기'를 눌러 주세요",
				"danger"
			)
		end
		return
	end

	carrying[player] = nil
	player:SetAttribute("Carrying", nil)
	carry.model:Destroy()

	local rarity = Config.Rarities[carry.rarityIndex]
	local egg = AnimalFactory.buildEgg(rarity.Color, rarity.Neon)
	placeOnPad(pad, egg)
	pad.model = egg
	pad.state = "hatching"
	pad.regionIndex = carry.regionIndex
	pad.rarityIndex = carry.rarityIndex
	pad.hatchAt = os.clock() + rarity.HatchTime
	notify:FireClient(player, `{rarity.Name} 에그 부화 시작! ({Format.duration(rarity.HatchTime)})`, "success")
end

local function hatch(player: Player, plot: World.Plot, pad: World.Pad)
	if pad.model then
		pad.model:Destroy()
	end
	local rarity = Config.Rarities[pad.rarityIndex]
	local region = Config.Regions[pad.regionIndex]
	local info = region.Animals[rarity.Id]
	local speed, money = Config.rewardFor(pad.regionIndex, pad.rarityIndex)

	local animal = AnimalFactory.build(info.Kind)
	placeOnPad(pad, animal)
	pad.model = animal
	pad.state = "hatched"
	pad.label.Text = `{info.Name}\n⚡{Format.number(speed)} 💰{Format.number(money)}`
	pad.label.TextColor3 = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.4)

	player:SetAttribute(`Index_{region.Id}_{rarity.Id}`, true) -- 인덱스 잠금 해제
	updatePending(player, plot)
	notify:FireClient(player, `{rarity.Name} {info.Name} 부화! 인덱스에서 받아 가세요`, "success")
end

local function clearPad(pad: World.Pad)
	if pad.model then
		pad.model:Destroy()
	end
	pad.model = nil
	pad.state = "empty"
	pad.label.Text = ""
end

-- 1초마다 부화 남은 시간 표시 & 부화
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, plot in base.plots do
			local owner = plot.owner
			if not owner then
				continue
			end
			for _, pad in plot.pads do
				if pad.state == "hatching" then
					local remaining = pad.hatchAt - now
					if remaining <= 0 then
						hatch(owner, plot, pad)
					else
						local rarity = Config.Rarities[pad.rarityIndex]
						pad.label.Text = `{rarity.Name} 에그\n{Format.countdown(remaining)}`
						pad.label.TextColor3 = Color3.new(1, 1, 1)
					end
				end
			end
		end
	end
end)

claimAll.OnServerEvent:Connect(function(player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	local speed, money, count = 0, 0, 0
	for _, pad in plot.pads do
		if pad.state == "hatched" then
			local s, m = Config.rewardFor(pad.regionIndex, pad.rarityIndex)
			speed += s
			money += m
			count += 1
			clearPad(pad)
		end
	end
	if count == 0 then
		notify:FireClient(player, "받을 동물이 없어요. 에그를 부화시켜 보세요!", "info")
		return
	end
	PlayerStats.addSpeed(player, speed)
	PlayerStats.addMoney(player, money)
	updatePending(player, plot)
	notify:FireClient(
		player,
		`동물 {count}마리 보상! ⚡+{Format.number(speed)} 💰+{Format.number(money)}`,
		"success"
	)
end)

--------------------------------------------------------------------------------
-- 러닝머신 업그레이드
--------------------------------------------------------------------------------

do
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.ActionText = "업그레이드" -- 실제 문구는 각 클라이언트가 자기 레벨에 맞게 바꿔서 보여 준다
	prompt.ObjectText = "러닝머신"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = base.kiosk

	prompt.Triggered:Connect(function(player)
		local data = PlayerStats.get(player)
		if not data then
			return
		end
		local levels = Config.Treadmill.Levels
		local nextLevel = data.treadmillLevel + 1
		if nextLevel > #levels then
			notify:FireClient(player, "이미 최고 레벨이에요!", "info")
			return
		end
		local cost = levels[nextLevel].Cost
		if not PlayerStats.spend(player, cost) then
			notify:FireClient(player, `돈이 부족해요! 💰{Format.number(cost)} 필요`, "danger")
			return
		end
		PlayerStats.setTreadmillLevel(player, nextLevel)
		notify:FireClient(
			player,
			`러닝머신 Lv.{nextLevel}! 초당 ⚡+{Format.number(levels[nextLevel].Gain)}`,
			"success"
		)
	end)
end

--------------------------------------------------------------------------------
-- 플레이어 입장/퇴장
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	PlayerStats.add(player)
	player:SetAttribute("PendingSpeed", 0)
	player:SetAttribute("PendingMoney", 0)

	for _, plot in base.plots do
		if not plot.owner then
			plot.owner = player
			plot.sign.Text = `{player.DisplayName}의 기지`
			plotOf[player] = plot
			break
		end
	end

	player.CharacterRemoving:Connect(function()
		dropCarry(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	dropCarry(player)
	local plot = plotOf[player]
	if plot then
		plot.owner = nil
		plot.sign.Text = "빈 기지"
		for _, pad in plot.pads do
			clearPad(pad)
		end
	end
	plotOf[player] = nil
	PlayerStats.remove(player)
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		PlayerStats.flush()
	end
end)

--------------------------------------------------------------------------------
-- 매 프레임: 러닝머신, 지역 입장 조건, 기지 도착, 쫓아오는 동물
--------------------------------------------------------------------------------

local BASE_RETURN = CFrame.new(0, 4, Config.Base.Depth / 2 - 6)

RunService.Heartbeat:Connect(function(dt)
	local targets: { Chaser.Target } = {}

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local data = PlayerStats.get(player)
		if not character or not humanoid or humanoid.Health <= 0 or not root or not data then
			continue
		end
		local position = root.Position

		if World.isOnTreadmill(base, position) then
			PlayerStats.addSpeed(player, Config.Treadmill.Levels[data.treadmillLevel].Gain * dt)
		end

		for _, region in regions do
			local required = Config.Regions[region.index].RequiredSpeed
			if data.speed < required and World.isInsideRegion(region, position) then
				character:PivotTo(BASE_RETURN)
				notify:FireClient(player, `속도가 부족해요! ⚡{Format.number(required)} 필요`, "danger")
			end
		end

		local carry = carrying[player]
		if carry then
			local plot = plotOf[player]
			if plot and World.isInsideBase(position) then
				tryDeposit(player, plot, carry)
			else
				table.insert(targets, { player = player, root = root })
			end
		end
	end

	for _, chaser in chasers do
		local hitPlayer, direction = chaser:update(dt, targets)
		if hitPlayer and direction then
			local settings = Config.Chaser
			knockback:FireClient(
				hitPlayer,
				direction * settings.KnockbackHorizontal + Vector3.yAxis * settings.KnockbackVertical
			)
			notify:FireClient(hitPlayer, "동물에게 맞았어요! 💥", "danger")
		end
	end
end)

print(`[{Config.GameName}] 서버 시작! 러닝머신으로 속도를 올리고 숲에서 에그를 훔쳐 오세요.`)
