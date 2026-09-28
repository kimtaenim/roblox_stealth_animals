-- 서버 진입점: 농장 동물 훔치기 → 기지로 운반 → 코인 생산, 그리고 농부의 감시를 담당한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local AnimalFactory = require(script.Parent.AnimalFactory)
local Guard = require(script.Parent.Guard)
local World = require(script.Parent.World)

-- 클라이언트 화면에 메시지를 띄우는 통로. (text, kind: "info" | "success" | "danger")
local notify = Instance.new("RemoteEvent")
notify.Name = "Notify"
notify.Parent = ReplicatedStorage

local farmAnimals = World.buildFarm()
local plots = World.buildPlots()

local guardsFolder = Instance.new("Folder")
guardsFolder.Name = "Farmers"
guardsFolder.Parent = workspace
local guards = {}
for _, route in Config.Guard.PatrolRoutes do
	table.insert(guards, Guard.new(route, guardsFolder))
end

type Carry = { kind: string, model: Model }
type Stats = { coins: IntValue, animals: IntValue }

local carrying: { [Player]: Carry } = {}
local plotOf: { [Player]: World.Plot } = {}
local statsOf: { [Player]: Stats } = {}
local incomeOf: { [Player]: number } = {}
local detection: { [Player]: number } = {}

--------------------------------------------------------------------------------
-- 동물 운반
--------------------------------------------------------------------------------

-- 들고 있던 동물을 없앤다 (들켰거나, 죽었거나, 나갔을 때). 농장 자리는 이미 리스폰 예약되어 있다.
local function dropCarry(player: Player)
	local carry = carrying[player]
	if not carry then
		return
	end
	carrying[player] = nil
	carry.model:Destroy()
	player:SetAttribute("Carrying", nil)
end

-- 동물을 플레이어 머리 위에 붙인다.
local function pickUp(player: Player, model: Model, kind: string): boolean
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

	local body = model.PrimaryPart :: BasePart
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = body
	weld.C0 = CFrame.new(0, head.Size.Y / 2 + boxSize.Y / 2, 0)
	weld.C1 = body.CFrame:ToObjectSpace(boxCFrame)
	weld.Parent = body
	model.Parent = character

	carrying[player] = { kind = kind, model = model }
	player:SetAttribute("Carrying", kind)
	return true
end

local function spawnFarmAnimal(spot: { Kind: string, Position: Vector3 })
	local info = Config.Animals[spot.Kind]
	local model = AnimalFactory.build(spot.Kind)
	local groundTop = Vector3.new(0, 0.2, 0) -- 농장 바닥 두께
	model:PivotTo(CFrame.new(spot.Position + groundTop) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0))
	model.Parent = farmAnimals

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "훔치기"
	prompt.ObjectText = `{info.Emoji} {info.DisplayName}`
	prompt.HoldDuration = info.StealTime
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(player)
		if carrying[player] then
			notify:FireClient(player, "이미 동물을 들고 있어요!", "info")
			return
		end
		if not plotOf[player] then
			notify:FireClient(player, "빈 기지가 없어서 훔칠 수 없어요.", "danger")
			return
		end
		prompt:Destroy() -- 다른 사람이 동시에 훔치지 못하게
		if pickUp(player, model, spot.Kind) then
			notify:FireClient(
				player,
				`{info.Emoji} {info.DisplayName} 훔치기 성공! 내 기지로 가져가세요`,
				"success"
			)
		else
			model:Destroy()
		end
		task.delay(Config.Farm.RespawnTime, spawnFarmAnimal, spot)
	end)
end

for _, spot in Config.Farm.AnimalSpots do
	spawnFarmAnimal(spot)
end

-- 기지에 도착하면 동물을 내려놓고 수입을 올린다.
local function deposit(player: Player, plot: World.Plot, carry: Carry)
	dropCarry(player)

	local model = AnimalFactory.build(carry.kind)
	model:PivotTo(World.randomSpotInPlot(plot))
	model.Parent = plot.animals

	local info = Config.Animals[carry.kind]
	incomeOf[player] = (incomeOf[player] or 0) + info.Income
	statsOf[player].animals.Value += 1
	notify:FireClient(player, `{info.Emoji} {info.DisplayName} 도착! 초당 +{info.Income} 코인`, "success")
end

--------------------------------------------------------------------------------
-- 플레이어 입장/퇴장
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "코인"
	coins.Parent = leaderstats
	local animals = Instance.new("IntValue")
	animals.Name = "동물"
	animals.Parent = leaderstats
	leaderstats.Parent = player
	statsOf[player] = { coins = coins, animals = animals }
	incomeOf[player] = 0

	for _, plot in plots do
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
		plot.animals:ClearAllChildren()
	end
	plotOf[player] = nil
	statsOf[player] = nil
	incomeOf[player] = nil
	detection[player] = nil
end)

-- 코인 생산
task.spawn(function()
	while true do
		task.wait(1)
		for player, income in incomeOf do
			local stats = statsOf[player]
			if stats and income > 0 then
				stats.coins.Value += income
			end
		end
	end
end)

--------------------------------------------------------------------------------
-- 농부의 감시
--------------------------------------------------------------------------------

-- 서버는 클라이언트의 WalkSpeed를 볼 수 없으므로 실제 이동 속도로 살금살금 여부를 판단한다.
local function isSneaking(root: BasePart): boolean
	local velocity = root.AssemblyLinearVelocity
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude <= Config.SneakSpeed + 1
end

local function setDetection(player: Player, value: number)
	detection[player] = value
	if player:GetAttribute("Detection") ~= value then
		player:SetAttribute("Detection", value)
	end
end

local function caught(player: Player)
	dropCarry(player)
	setDetection(player, 0)
	notify:FireClient(player, "농부에게 들켰어요! 처음으로 돌아갑니다", "danger")
	task.spawn(player.LoadCharacterAsync, player)
end

RunService.Heartbeat:Connect(function(dt)
	-- 농부마다 이번 프레임에 쳐다볼 대상 (가장 많이 들킨 플레이어)
	local targets: { [any]: { position: Vector3, level: number } } = {}

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not character or not humanoid or humanoid.Health <= 0 or not root then
			continue
		end

		-- 기지 도착 확인
		local carry = carrying[player]
		local plot = plotOf[player]
		if carry and plot and World.isInsidePlot(plot, root.Position) then
			deposit(player, plot, carry)
		end

		-- 시야 판정
		local level = detection[player] or 0
		local seenBy = {}
		for _, guard in guards do
			local visible, distance = guard:canSee(character)
			if visible then
				local closeness = 1 - distance / Config.Guard.ViewDistance
				local rate = Config.Detection.BaseRate * (0.5 + 1.5 * closeness)
				if isSneaking(root) then
					rate *= Config.Detection.SneakMultiplier
				end
				level += rate * dt
				table.insert(seenBy, guard)
			end
		end
		if #seenBy == 0 then
			level -= Config.Detection.DecayPerSecond * dt
		end
		level = math.clamp(level, 0, 1)

		if level >= 1 then
			caught(player)
			continue
		end
		setDetection(player, level)

		for _, guard in seenBy do
			local current = targets[guard]
			if not current or level > current.level then
				targets[guard] = { position = root.Position, level = level }
			end
		end
	end

	for _, guard in guards do
		local target = targets[guard]
		local alertText = ""
		if target then
			alertText = if target.level >= Config.Detection.AlertThreshold then "!" else "?"
		end
		guard:update(target and target.position, alertText)
	end
end)

print(`[{Config.GameName}] 서버 시작! 농장에서 동물을 훔쳐 기지로 가져가세요.`)
