-- 서버 진입점: 러닝머신 → 둥지에서 에그 훔치기(등급 랜덤) → 기지로 운반 → 부화(밤엔 30배)
-- → 부화한 동물은 기지를 돌아다님 → 인덱스에서 모두 받기. 진행 상황은 저장된다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local AnimalFactory = require(script.Parent.AnimalFactory)
local Chaser = require(script.Parent.Chaser)
local DayNight = require(script.Parent.DayNight)
local Pets = require(script.Parent.Pets)
local PlayerStats = require(script.Parent.PlayerStats)
local SaveData = require(script.Parent.SaveData)
local Sounds = require(script.Parent.Sounds)
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
local equipBest = makeRemote("EquipBest") -- 클라→서버: 펫 창의 "최고 장비"

local base = World.buildBase()
local regions: { World.Region } = {}
for i = 1, Config.BuiltRegionCount do
	regions[i] = World.buildRegion(i)
end

-- 지역마다 지키는 동물 한 마리 (석기시대·봄은 보스)
local chasersFolder = Instance.new("Folder")
chasersFolder.Name = "Chasers"
chasersFolder.Parent = workspace
local chasersOf: { [number]: { any } } = {}
local allChasers = {}
for _, region in regions do
	local config = Config.Regions[region.index]
	local list = {}
	for i, entry in config.Chasers do
		table.insert(list, Chaser.new(entry, region.chaserHomes[i], config.ChaserSpeed, region, chasersFolder))
	end
	if config.Boss then
		local boss = config.Boss
		table.insert(list, Chaser.new(boss, region.bossHome, boss.Speed, region, chasersFolder))
	end
	chasersOf[region.index] = list
	for _, chaser in list do
		table.insert(allChasers, chaser)
	end
end

type Carry = { model: Model, region: World.Region, spot: World.NestSpot, rarityIndex: number, warned: boolean }

local carrying: { [Player]: Carry } = {}
local plotOf: { [Player]: World.Plot } = {}
local canSave: { [Player]: boolean } = {} -- 불러오기에 성공한 사람만 저장 (실패했는데 저장하면 기록이 지워짐)

--------------------------------------------------------------------------------
-- 둥지의 에그
--------------------------------------------------------------------------------

local function rollRarity(): number
	local total = 0
	for _, rarity in Config.Rarities do
		total += rarity.Weight
	end
	local roll = math.random() * total
	for index, rarity in Config.Rarities do
		roll -= rarity.Weight
		if roll <= 0 then
			return index
		end
	end
	return 1
end

-- 에그를 플레이어 머리 위에 붙인다
local function attachToHead(player: Player, model: Model): boolean
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
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = primary
	weld.C0 = CFrame.new(0, head.Size.Y / 2 + boxSize.Y / 2, 0)
	weld.C1 = primary.CFrame:ToObjectSpace(boxCFrame)
	weld.Parent = primary
	model.Parent = character
	return true
end

local spawnNestEgg: (region: World.Region, spot: World.NestSpot) -> ()

local function onSteal(player: Player, region: World.Region, spot: World.NestSpot, egg: Model, prompt: ProximityPrompt)
	if carrying[player] then
		notify:FireClient(player, "이미 에그를 들고 있어요!", "info")
		return
	end
	if not plotOf[player] then
		notify:FireClient(player, "빈 기지가 없어서 훔칠 수 없어요.", "danger")
		return
	end

	prompt:Destroy() -- 다른 사람이 동시에 가져가지 못하게
	spot.egg = nil
	if not attachToHead(player, egg) then
		egg:Destroy()
		spawnNestEgg(region, spot)
		return
	end

	-- 훔친 순간 등급 공개
	local rarityIndex = rollRarity()
	local rarity = Config.Rarities[rarityIndex]
	AnimalFactory.paintEgg(egg, rarity.Color, rarity.Neon)
	carrying[player] = { model = egg, region = region, spot = spot, rarityIndex = rarityIndex, warned = false }
	player:SetAttribute("Carrying", `{rarity.Name} 에그`)
	Sounds.play("Steal", egg.PrimaryPart :: BasePart)
	notify:FireClient(player, `✨ {rarity.Name} 에그! 동물을 피해 기지로 돌아가세요`, "success")
end

spawnNestEgg = function(region: World.Region, spot: World.NestSpot)
	if spot.egg then
		return
	end
	local egg = AnimalFactory.buildEgg(Config.Egg.Color)
	egg:PivotTo(CFrame.new(spot.position))
	egg.Parent = region.eggs
	spot.egg = egg

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "훔치기"
	prompt.ObjectText = "??? 에그"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg.PrimaryPart
	prompt.Triggered:Connect(function(player)
		onSteal(player, region, spot, egg, prompt)
	end)
end

for _, region in regions do
	for _, spot in region.nestSpots do
		spawnNestEgg(region, spot)
	end
end

-- 들고 있던 에그가 사라질 때 (죽음, 나감): 둥지에 바로 새 에그
local function loseCarry(player: Player)
	local carry = carrying[player]
	if carry then
		carrying[player] = nil
		player:SetAttribute("Carrying", nil)
		carry.model:Destroy()
		spawnNestEgg(carry.region, carry.spot)
	end
end

-- 맞았을 때: 에그를 땅에 떨어뜨리고, 그 지역 동물이 주워서 둥지로 가져간다
local function dropOnHit(player: Player, root: BasePart)
	local carry = carrying[player]
	if not carry then
		return
	end
	carrying[player] = nil
	player:SetAttribute("Carrying", nil)

	local egg = carry.model
	local weld = egg:FindFirstChild("CarryWeld", true)
	if weld then
		weld:Destroy()
	end
	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	egg:PivotTo(CFrame.new(root.Position.X, 0.2, root.Position.Z))
	egg.Parent = carry.region.eggs

	-- 할 일이 가장 적은 동물에게 맡긴다
	local best = nil
	for _, chaser in chasersOf[carry.region.index] do
		if not best or (not chaser:isBusy() and best:isBusy()) then
			best = chaser
		end
	end
	if best then
		best:fetch({ model = egg, spot = carry.spot })
	else
		egg:Destroy()
		spawnNestEgg(carry.region, carry.spot)
	end
end

--------------------------------------------------------------------------------
-- 부화
--------------------------------------------------------------------------------

local function updatePending(player: Player)
	local speed, money = Pets.pending(player)
	player:SetAttribute("PendingSpeed", speed)
	player:SetAttribute("PendingMoney", money)
end

local function clearPad(pad: World.Pad)
	if pad.model then
		pad.model:Destroy()
	end
	pad.model = nil
	pad.state = "empty"
	pad.progress = 0
	pad.label.Text = ""
end

-- 부화 자리에 에그를 놓고 부화를 시작한다 (progress: 이어서 부화할 때)
local function startHatching(pad: World.Pad, regionIndex: number, rarityIndex: number, progress: number)
	local rarity = Config.Rarities[rarityIndex]
	local egg = AnimalFactory.buildEgg(rarity.Color, rarity.Neon)
	local top = pad.part.Position + Vector3.new(0, pad.part.Size.Y / 2, 0)
	egg:PivotTo(CFrame.new(top))
	egg.Parent = pad.part
	pad.model = egg
	pad.state = "hatching"
	pad.regionIndex = regionIndex
	pad.rarityIndex = rarityIndex
	pad.progress = progress
end

local function emptyPad(plot: World.Plot): World.Pad?
	for _, pad in plot.pads do
		if pad.state == "empty" then
			return pad
		end
	end
	return nil
end

-- 기지에 도착하면 빈 부화 자리에 에그를 놓는다
local function tryDeposit(player: Player, plot: World.Plot, carry: Carry)
	local pad = emptyPad(plot)
	if not pad then
		if not carry.warned then
			carry.warned = true
			notify:FireClient(
				player,
				"부화 자리가 꽉 찼어요! 부화가 끝날 때까지 기다려 주세요",
				"danger"
			)
		end
		return
	end

	carrying[player] = nil
	player:SetAttribute("Carrying", nil)
	carry.model:Destroy()
	task.delay(Config.Egg.RespawnTime, spawnNestEgg, carry.region, carry.spot)

	startHatching(pad, carry.region.index, carry.rarityIndex, 0)
	local rarity = Config.Rarities[carry.rarityIndex]
	notify:FireClient(player, `{rarity.Name} 에그 부화 시작! ({Format.duration(rarity.HatchTime)})`, "success")
end

-- 부화하면 동물이 부화 자리에서 나와 기지를 돌아다닌다
local function hatch(player: Player, pad: World.Pad)
	local rarity = Config.Rarities[pad.rarityIndex]
	local region = Config.Regions[pad.regionIndex]
	local info = region.Animals[rarity.Id]
	local regionIndex, rarityIndex = pad.regionIndex, pad.rarityIndex
	local position = pad.part.Position
	clearPad(pad)

	local moved = Pets.add(player, { regionIndex = regionIndex, rarityIndex = rarityIndex, claimed = false }, position)
	player:SetAttribute(`Index_{region.Id}_{rarity.Id}`, true) -- 인덱스 잠금 해제
	updatePending(player)
	Sounds.play("Hatch", pad.part)
	local where = "인덱스에서 보상을 받으세요"
	if moved then
		local movedInfo = Config.Regions[moved.regionIndex].Animals[Config.Rarities[moved.rarityIndex].Id]
		where = `기지가 꽉 차서 {movedInfo.Name}(이)가 인벤토리로 갔어요`
	end
	notify:FireClient(player, `{rarity.Name} {info.Name} 부화! {where}`, "success")
end

-- 1초마다 부화 진행 (밤에는 30배 빠르게)
task.spawn(function()
	while true do
		task.wait(1)
		local multiplier = DayNight.hatchMultiplier()
		for _, plot in base.plots do
			local owner = plot.owner
			if not owner then
				continue
			end
			for _, pad in plot.pads do
				if pad.state == "hatching" then
					local rarity = Config.Rarities[pad.rarityIndex]
					pad.progress += multiplier
					if pad.progress >= rarity.HatchTime then
						hatch(owner, pad)
					else
						local remaining = (rarity.HatchTime - pad.progress) / multiplier
						local moon = if multiplier > 1 then " 🌙" else ""
						pad.label.Text = `{rarity.Name} 에그\n{Format.countdown(remaining)}{moon}`
					end
				end
			end
		end
	end
end)

DayNight.start(function(night)
	if night then
		notify:FireAllClients(
			`🌙 밤이 되었어요! 부화가 {Config.DayNight.NightHatchMultiplier}배 빨라져요`,
			"success"
		)
	else
		notify:FireAllClients("☀️ 아침이 되었어요", "info")
	end
end)

equipBest.OnServerEvent:Connect(function(player)
	if not PlayerStats.get(player) then
		return
	end
	Pets.equipBest(player)
	notify:FireClient(
		player,
		"⭐ 가장 강한 동물들을 기지에 두고, 나머지는 인벤토리에 넣었어요",
		"success"
	)
end)

claimAll.OnServerEvent:Connect(function(player)
	local speed, money, count = Pets.claimAll(player)
	if count == 0 then
		notify:FireClient(player, "받을 보상이 없어요. 에그를 부화시켜 보세요!", "info")
		return
	end
	PlayerStats.addSpeed(player, speed)
	PlayerStats.addMoney(player, money)
	updatePending(player)
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
-- 저장 / 불러오기
--------------------------------------------------------------------------------

local function collectSaveData(player: Player): SaveData.Data?
	local stats = PlayerStats.snapshot(player)
	if not stats then
		return nil
	end

	local index = {}
	for name, value in player:GetAttributes() do
		if value == true and string.sub(name, 1, 6) == "Index_" then
			table.insert(index, string.sub(name, 7))
		end
	end

	local pets, inventory = Pets.serialize(player)

	local eggs = {}
	local plot = plotOf[player]
	if plot then
		for _, pad in plot.pads do
			if pad.state == "hatching" then
				table.insert(eggs, { r = pad.regionIndex, k = pad.rarityIndex, p = pad.progress })
			end
		end
	end

	return {
		speed = stats.speed,
		money = stats.money,
		treadmillLevel = stats.treadmillLevel,
		index = index,
		pets = pets,
		inventory = inventory,
		eggs = eggs,
	}
end

local function savePlayer(player: Player)
	if not canSave[player] then
		return
	end
	local data = collectSaveData(player)
	if data then
		SaveData.save(player, data)
	end
end

-- 저장된 지역/등급 번호가 지금 설정에 있는지 (설정을 바꿨을 때 대비)
local function isValid(regionIndex: number?, rarityIndex: number?): boolean
	return type(regionIndex) == "number"
		and type(rarityIndex) == "number"
		and Config.Regions[regionIndex] ~= nil
		and Config.Rarities[rarityIndex] ~= nil
		and regionIndex <= Config.BuiltRegionCount
end

--------------------------------------------------------------------------------
-- 플레이어 입장/퇴장
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	local ok, saved = SaveData.load(player)
	if not player.Parent then
		return -- 불러오는 동안 나감
	end
	canSave[player] = ok
	local data: SaveData.Data = if ok and type(saved) == "table" then saved else {}

	PlayerStats.add(player, {
		speed = data.speed,
		money = data.money,
		treadmillLevel = if data.treadmillLevel
			then math.clamp(data.treadmillLevel, 1, #Config.Treadmill.Levels)
			else nil,
	})
	local savedIndex: { string } = data.index or {}
	for _, key in savedIndex do
		player:SetAttribute(`Index_{key}`, true)
	end

	for _, plot in base.plots do
		if not plot.owner then
			plot.owner = player
			plot.sign.Text = `{player.DisplayName}의 기지`
			plotOf[player] = plot
			break
		end
	end

	-- 저장된 동물과 부화 중이던 에그 되살리기
	local savedPets: { { r: number, k: number, c: boolean } } = data.pets or {}
	local savedInventory: { { r: number, k: number, c: boolean } } = data.inventory or {}
	for _, pet in savedPets do
		if isValid(pet.r, pet.k) then
			Pets.add(player, { regionIndex = pet.r, rarityIndex = pet.k, claimed = pet.c == true })
		end
	end
	for _, pet in savedInventory do
		if isValid(pet.r, pet.k) then
			Pets.store(player, { regionIndex = pet.r, rarityIndex = pet.k, claimed = pet.c == true })
		end
	end
	Pets.publish(player)
	local plot = plotOf[player]
	if plot then
		local savedEggs: { { r: number, k: number, p: number } } = data.eggs or {}
		for _, egg in savedEggs do
			local pad = emptyPad(plot)
			if pad and isValid(egg.r, egg.k) then
				startHatching(pad, egg.r, egg.k, egg.p or 0)
			end
		end
	end
	updatePending(player)

	if not ok then
		notify:FireClient(
			player,
			"⚠️ 저장 기능이 꺼져 있어요. 이번 기록은 저장되지 않아요",
			"danger"
		)
	elseif data.speed then
		notify:FireClient(player, "💾 저장된 기록을 불러왔어요!", "success")
	end

	player.CharacterRemoving:Connect(function()
		loseCarry(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	loseCarry(player)
	savePlayer(player)

	local plot = plotOf[player]
	if plot then
		plot.owner = nil
		plot.sign.Text = "빈 기지"
		for _, pad in plot.pads do
			clearPad(pad)
		end
	end
	Pets.removeAll(player)
	plotOf[player] = nil
	canSave[player] = nil
	PlayerStats.remove(player)
end)

-- 자동 저장 + 서버가 꺼질 때 저장
task.spawn(function()
	while true do
		task.wait(Config.Save.AutoSaveInterval)
		for _, player in Players:GetPlayers() do
			task.spawn(savePlayer, player)
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		savePlayer(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		PlayerStats.flush()
	end
end)

--------------------------------------------------------------------------------
-- 매 프레임: 러닝머신, 기지 도착, 지키는 동물, 기지 동물
--------------------------------------------------------------------------------

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

		-- 러닝머신 위에 있기만 하면 속도가 오른다
		if World.isOnTreadmill(base, position) then
			PlayerStats.addSpeed(player, Config.Treadmill.Levels[data.treadmillLevel].Gain * dt)
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

	for _, chaser in allChasers do
		local hitPlayer, direction, returnedEgg = chaser:update(dt, targets)
		if hitPlayer and direction then
			local character = hitPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local settings = Config.Chaser
				Sounds.play("Hit", root)
				dropOnHit(hitPlayer, root)
				knockback:FireClient(
					hitPlayer,
					direction * settings.KnockbackHorizontal + Vector3.yAxis * settings.KnockbackVertical
				)
				notify:FireClient(
					hitPlayer,
					"💥 맞아서 에그를 떨어뜨렸어요! 동물이 다시 가져가요",
					"danger"
				)
			end
		end
		if returnedEgg then
			returnedEgg.model:Destroy()
			spawnNestEgg(chaser.region, returnedEgg.spot)
		end
	end

	Pets.update(dt)
end)

print(
	`[{Config.GameName}] 서버 시작! 러닝머신으로 속도를 올리고 에그 둥지에서 에그를 훔쳐 오세요.`
)
