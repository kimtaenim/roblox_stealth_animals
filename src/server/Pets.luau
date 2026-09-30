-- 부화한 동물: 기지 울타리 안을 자유롭게 돌아다닌다.
-- 보상을 아직 안 받은 동물은 머리 위에 보상 숫자가 뜨고, 인덱스의 "모두 받기"로 받는다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local AnimalFactory = require(script.Parent.AnimalFactory)
local World = require(script.Parent.World)

local Pets = {}

export type Pet = {
	model: Model,
	label: TextLabel,
	regionIndex: number,
	rarityIndex: number,
	claimed: boolean,
	goal: Vector3,
	restUntil: number,
}

local petsOf: { [Player]: { Pet } } = {}
local random = Random.new()

local folder = Instance.new("Folder")
folder.Name = "Pets"
folder.Parent = workspace

local function infoOf(pet: Pet)
	return Config.Regions[pet.regionIndex].Animals[Config.Rarities[pet.rarityIndex].Id]
end

local function refreshLabel(pet: Pet)
	local info = infoOf(pet)
	if pet.claimed then
		pet.label.Text = info.Name
		pet.label.TextColor3 = Color3.new(1, 1, 1)
	else
		local speed, money = Config.rewardFor(pet.regionIndex, pet.rarityIndex)
		pet.label.Text = `{info.Name}\n⚡{Format.number(speed)} 💰{Format.number(money)}`
		pet.label.TextColor3 = Config.Rarities[pet.rarityIndex].Color:Lerp(Color3.new(1, 1, 1), 0.4)
	end
end

function Pets.list(owner: Player): { Pet }
	local list = petsOf[owner]
	if not list then
		list = {}
		petsOf[owner] = list
	end
	return list
end

local function removePet(owner: Player, pet: Pet)
	local list = Pets.list(owner)
	local index = table.find(list, pet)
	if index then
		table.remove(list, index)
	end
	pet.model:Destroy()
end

-- 새 동물을 기지에 풀어놓는다. 너무 많으면 가장 오래된(보상 받은) 동물이 떠난다.
function Pets.spawn(owner: Player, regionIndex: number, rarityIndex: number, claimed: boolean, position: Vector3?): Pet
	local list = Pets.list(owner)
	if #list >= Config.Base.MaxPets then
		local oldest = list[1]
		for _, pet in list do
			if pet.claimed then
				oldest = pet
				break
			end
		end
		removePet(owner, oldest)
	end

	local info = Config.Regions[regionIndex].Animals[Config.Rarities[rarityIndex].Id]
	local model = AnimalFactory.build(info.Kind, info)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	local start = position or World.randomBaseSpot(random)
	model:PivotTo(CFrame.new(start.X, 0.2, start.Z))
	model.Parent = folder
	local _, size = model:GetBoundingBox()

	local pet: Pet = {
		model = model,
		label = World.makeLabel(model.PrimaryPart :: BasePart, size.Y / 2 + 2, 150, 50, "", 80),
		regionIndex = regionIndex,
		rarityIndex = rarityIndex,
		claimed = claimed,
		goal = World.randomBaseSpot(random),
		restUntil = 0,
	}
	refreshLabel(pet)
	table.insert(list, pet)
	return pet
end

-- 아직 받지 않은 보상 합계
function Pets.pending(owner: Player): (number, number)
	local speed, money = 0, 0
	for _, pet in Pets.list(owner) do
		if not pet.claimed then
			local s, m = Config.rewardFor(pet.regionIndex, pet.rarityIndex)
			speed += s
			money += m
		end
	end
	return speed, money
end

-- 모두 받기: 보상 합계와 마릿수를 돌려주고, 동물은 그대로 남는다
function Pets.claimAll(owner: Player): (number, number, number)
	local speed, money, count = 0, 0, 0
	for _, pet in Pets.list(owner) do
		if not pet.claimed then
			local s, m = Config.rewardFor(pet.regionIndex, pet.rarityIndex)
			speed += s
			money += m
			count += 1
			pet.claimed = true
			refreshLabel(pet)
		end
	end
	return speed, money, count
end

function Pets.removeAll(owner: Player)
	for _, pet in Pets.list(owner) do
		pet.model:Destroy()
	end
	petsOf[owner] = nil
end

-- 매 프레임 호출: 목적지까지 천천히 걷고, 도착하면 잠깐 쉬었다가 다음 목적지로
function Pets.update(dt: number)
	local now = os.clock()
	local speed = Config.Base.PetWalkSpeed
	for _, list in petsOf do
		for _, pet in list do
			if now < pet.restUntil then
				continue
			end
			local position = pet.model:GetPivot().Position
			local offset = Vector3.new(pet.goal.X - position.X, 0, pet.goal.Z - position.Z)
			if offset.Magnitude < 1 then
				pet.restUntil = now + random:NextNumber(1, 5)
				pet.goal = World.randomBaseSpot(random)
			else
				local direction = offset.Unit
				local moved = position + direction * math.min(offset.Magnitude, speed * dt)
				pet.model:PivotTo(CFrame.lookAt(moved, moved + direction))
			end
		end
	end
end

return Pets
