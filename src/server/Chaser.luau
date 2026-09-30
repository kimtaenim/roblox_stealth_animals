-- 지역을 지키는 동물 (보스도 이걸로 만든다). 할 일 순서:
-- 1) 떨어진 에그가 있으면 주워서 둥지로 가져간다
-- 2) 에그를 들고 있는 플레이어가 가까이 있으면 쫓아가서 때린다
-- 3) 할 일이 없으면 지역 안을 어슬렁어슬렁 돌아다닌다
-- 둥지 가까이(NestKeepOut)는 들어가지 않아서, 에그를 훔칠 틈이 있다.
-- 물리 대신 매 프레임 위치를 직접 옮긴다 (바닥이 평평해서 충분).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local AnimalFactory = require(script.Parent.AnimalFactory)
local Sounds = require(script.Parent.Sounds)
local World = require(script.Parent.World)

local Chaser = {}
Chaser.__index = Chaser

export type Target = { player: Player, root: BasePart }
export type DroppedEgg = { model: Model, spot: World.NestSpot }
export type Entry = { Kind: string, Color: Color3?, Neon: boolean?, Scale: number? }

local PICKUP_RANGE = 3
local random = Random.new()

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Chaser.new(entry: Entry, home: Vector3, speed: number, region: World.Region, parent: Instance)
	local model =
		AnimalFactory.build(entry.Kind, { Color = entry.Color, Neon = entry.Neon, Scale = entry.Scale or 1.4 })
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false -- 플레이어를 밀지 않고 통과. 때리는 건 거리로 판정
		end
	end
	model:PivotTo(CFrame.new(home))
	model.Parent = parent
	local _, size = model:GetBoundingBox()

	return setmetatable({
		model = model,
		height = size.Y,
		speed = speed,
		region = region,
		chasing = false,
		wanderGoal = home,
		restUntil = 0,
		queue = {} :: { DroppedEgg }, -- 주우러 갈 에그
		holding = nil :: DroppedEgg?, -- 물고 있는 에그
		lastHit = {} :: { [Player]: number },
	}, Chaser)
end

function Chaser:isBusy(): boolean
	return self.holding ~= nil or #self.queue > 0
end

function Chaser:fetch(egg: DroppedEgg)
	table.insert(self.queue, egg)
end

-- 둥지 가까이 들어가려 하면 둥지 둘레로 밀어낸다
function Chaser:keepOutOfNest(position: Vector3): Vector3
	local fromNest = flat(position - self.region.nestCenter)
	local keepOut = Config.Chaser.NestKeepOut
	if fromNest.Magnitude < keepOut then
		local direction = if fromNest.Magnitude > 0.01 then fromNest.Unit else Vector3.new(0, 0, -1)
		local pushed = self.region.nestCenter + direction * keepOut
		return Vector3.new(pushed.X, position.Y, pushed.Z)
	end
	return position
end

-- 매 프레임 호출. 돌려주는 값: (때린 플레이어, 날려 보낼 방향, 둥지에 돌려놓은 에그)
function Chaser:update(dt: number, targets: { Target }): (Player?, Vector3?, DroppedEgg?)
	local position = self.model:GetPivot().Position
	local settings = Config.Chaser
	local now = os.clock()

	local target: Target? = nil
	local bestDistance = settings.AggroRange
	local goal: Vector3? = nil
	local speed = self.speed

	if self.holding then
		goal = self.region.nestCenter
	elseif self.queue[1] then
		goal = self.queue[1].model:GetPivot().Position
	else
		for _, candidate in targets do
			local distance = flat(candidate.root.Position - position).Magnitude
			if
				distance < bestDistance
				and World.isInsideRegion(self.region, candidate.root.Position, settings.LeashMargin)
			then
				target = candidate
				bestDistance = distance
			end
		end
		if target then
			goal = target.root.Position
		elseif now >= self.restUntil then
			-- 어슬렁어슬렁: 목적지에 닿으면 잠깐 쉬었다가 다음 목적지로
			if flat(self.wanderGoal - position).Magnitude < 2 then
				self.restUntil = now + random:NextNumber(1, 4)
				self.wanderGoal = World.randomWanderSpot(self.region, random)
			else
				goal = self.wanderGoal
				speed = self.speed * settings.WanderSpeedRatio
			end
		end
	end

	-- 쫓기 시작하는 순간 효과음
	local chasing = target ~= nil
	if chasing and not self.chasing then
		Sounds.play("ChaseStart", self.model.PrimaryPart :: BasePart)
	end
	self.chasing = chasing

	-- 이동 (둥지 가까이는 들어가지 않음)
	if goal then
		local offset = flat(goal - position)
		if offset.Magnitude > 0.5 then
			local direction = offset.Unit
			local moved = position + direction * math.min(offset.Magnitude, speed * dt)
			moved = self:keepOutOfNest(Vector3.new(moved.X, self.region.nestCenter.Y, moved.Z))
			position = moved
			self.model:PivotTo(CFrame.lookAt(position, position + direction))
		end
	end

	-- 물고 있는 에그는 머리 위에 따라다니고, 둥지 가장자리에 닿으면 돌려놓는다
	if self.holding then
		self.holding.model:PivotTo(self.model:GetPivot() * CFrame.new(0, self.height, 0))
		if flat(self.region.nestCenter - position).Magnitude <= settings.NestKeepOut + PICKUP_RANGE then
			local returned = self.holding
			self.holding = nil
			return nil, nil, returned
		end
		return nil, nil, nil
	end

	-- 떨어진 에그에 도착하면 줍기 (둥지 근처에 떨어졌으면 가장자리에서 줍는다)
	local next = self.queue[1]
	if next then
		local eggPosition = next.model:GetPivot().Position
		local reach = PICKUP_RANGE
		if flat(eggPosition - self.region.nestCenter).Magnitude < settings.NestKeepOut then
			reach = settings.NestKeepOut
		end
		if flat(eggPosition - position).Magnitude <= reach then
			self.holding = table.remove(self.queue, 1)
		end
		return nil, nil, nil
	end

	-- 때리기
	if target and bestDistance <= settings.HitRange then
		if now - (self.lastHit[target.player] or 0) >= settings.HitCooldown then
			self.lastHit[target.player] = now
			local away = flat(target.root.Position - position)
			return target.player, if away.Magnitude > 0.01 then away.Unit else Vector3.zAxis, nil
		end
	end
	return nil, nil, nil
end

return Chaser
