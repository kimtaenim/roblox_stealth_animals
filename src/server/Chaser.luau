-- 에그를 들고 있는 플레이어를 쫓아가서 때리는 동물.
-- 물리 대신 매 프레임 위치를 직접 옮긴다 (바닥이 평평해서 충분).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local AnimalFactory = require(script.Parent.AnimalFactory)
local World = require(script.Parent.World)

local Chaser = {}
Chaser.__index = Chaser

export type Target = { player: Player, root: BasePart }

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Chaser.new(kind: string, home: Vector3, speed: number, region: World.Region, parent: Instance)
	local model = AnimalFactory.build(kind)
	model:ScaleTo(1.4)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false -- 플레이어를 밀지 않고 통과. 때리는 건 거리로 판정
		end
	end
	model:PivotTo(CFrame.new(home))
	model.Parent = parent

	return setmetatable({
		model = model,
		home = home,
		speed = speed,
		region = region,
		lastHit = {} :: { [Player]: number },
	}, Chaser)
end

-- 매 프레임 호출. 때린 플레이어와 날려 보낼 방향을 돌려준다.
function Chaser:update(dt: number, targets: { Target }): (Player?, Vector3?)
	local position = self.model:GetPivot().Position
	local settings = Config.Chaser

	-- 가장 가까운 대상 고르기 (지역 근처에 있는 사람만)
	local target: Target? = nil
	local bestDistance = settings.AggroRange
	for _, candidate in targets do
		local distance = flat(candidate.root.Position - position).Magnitude
		if
			distance < bestDistance and World.isInsideRegion(self.region, candidate.root.Position, settings.LeashMargin)
		then
			target = candidate
			bestDistance = distance
		end
	end

	local goal = if target then target.root.Position else self.home
	local offset = flat(goal - position)
	if offset.Magnitude > 0.5 then
		local direction = offset.Unit
		local newPosition = position + direction * math.min(offset.Magnitude, self.speed * dt)
		newPosition = Vector3.new(newPosition.X, self.home.Y, newPosition.Z)
		self.model:PivotTo(CFrame.lookAt(newPosition, newPosition + direction))
	end

	if target and bestDistance <= settings.HitRange then
		local now = os.clock()
		if now - (self.lastHit[target.player] or 0) >= settings.HitCooldown then
			self.lastHit[target.player] = now
			local away = flat(target.root.Position - position)
			return target.player, if away.Magnitude > 0.01 then away.Unit else Vector3.zAxis
		end
	end
	return nil, nil
end

return Chaser
