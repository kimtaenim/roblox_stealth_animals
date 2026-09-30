-- 부화한 동물(펫). 기지에는 최대 MaxPets 마리가 돌아다니고, 넘치면 약한 녀석부터 인벤토리에 보관한다.
-- "최고 장비"를 누르면 가장 강한(희귀도가 높은) 녀석들이 기지에 남고, 약한 녀석들은 인벤토리로 간다.
-- 보상을 아직 안 받은 동물은 머리 위에 보상 숫자가 뜨고, 인덱스의 "모두 받기"로 받는다.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local AnimalFactory = require(script.Parent.AnimalFactory)
local World = require(script.Parent.World)

local Pets = {}

-- 동물 한 마리의 정보 (저장도 이 모양으로)
export type Entry = { regionIndex: number, rarityIndex: number, claimed: boolean }

-- 기지를 돌아다니는 동물
export type Pet = Entry & {
	model: Model,
	label: TextLabel,
	goal: Vector3,
	restUntil: number,
}

local petsOf: { [Player]: { Pet } } = {}
local inventoryOf: { [Player]: { Entry } } = {}
local random = Random.new()

local folder = Instance.new("Folder")
folder.Name = "Pets"
folder.Parent = workspace

local function infoOf(entry: Entry)
	return Config.Regions[entry.regionIndex].Animals[Config.Rarities[entry.rarityIndex].Id]
end

-- 강한 순서: 희귀도가 높을수록, 같으면 먼 지역일수록
local function isStronger(a: Entry, b: Entry): boolean
	if a.rarityIndex ~= b.rarityIndex then
		return a.rarityIndex > b.rarityIndex
	end
	return a.regionIndex > b.regionIndex
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

function Pets.inventory(owner: Player): { Entry }
	local list = inventoryOf[owner]
	if not list then
		list = {}
		inventoryOf[owner] = list
	end
	return list
end

-- 화면에 보여 줄 목록을 Player 속성(JSON)으로 보낸다: BasePets, Inventory
-- 같은 동물은 묶어서 { n = 이름, k = 등급, c = 마릿수 }
local function groupForDisplay(entries: { Entry }): string
	local sorted = table.clone(entries)
	table.sort(sorted, isStronger)
	local groups = {}
	local last = nil
	for _, entry in sorted do
		if last and last.regionIndex == entry.regionIndex and last.rarityIndex == entry.rarityIndex then
			groups[#groups].c += 1
		else
			table.insert(groups, { n = infoOf(entry).Name, k = entry.rarityIndex, c = 1 })
		end
		last = entry
	end
	return HttpService:JSONEncode(groups)
end

function Pets.publish(owner: Player)
	owner:SetAttribute("BasePets", groupForDisplay(Pets.list(owner)))
	owner:SetAttribute("Inventory", groupForDisplay(Pets.inventory(owner)))
end

local function spawnInBase(owner: Player, entry: Entry, position: Vector3?): Pet
	local info = infoOf(entry)
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
		regionIndex = entry.regionIndex,
		rarityIndex = entry.rarityIndex,
		claimed = entry.claimed,
		model = model,
		label = World.makeLabel(model.PrimaryPart :: BasePart, size.Y / 2 + 2, 150, 50, "", 80),
		goal = World.randomBaseSpot(random),
		restUntil = 0,
	}
	refreshLabel(pet)
	table.insert(Pets.list(owner), pet)
	return pet
end

-- 새 동물은 항상 기지에 풀어놓는다. 기지가 꽉 차면 기존 동물 중 가장 약한(희귀도 낮은) 녀석이
-- 인벤토리로 간다. 인벤토리로 간 녀석을 돌려준다 (없으면 nil).
function Pets.add(owner: Player, entry: Entry, position: Vector3?): Entry?
	local list = Pets.list(owner)
	local moved: Entry? = nil
	if #list >= Config.Base.MaxPets then
		local weakest = list[1]
		for _, pet in list do
			if isStronger(weakest, pet) then
				weakest = pet
			end
		end
		table.remove(list, table.find(list, weakest) :: number)
		weakest.model:Destroy()
		moved = { regionIndex = weakest.regionIndex, rarityIndex = weakest.rarityIndex, claimed = weakest.claimed }
		table.insert(Pets.inventory(owner), moved :: Entry)
	end
	spawnInBase(owner, entry, position)
	Pets.publish(owner)
	return moved
end

-- 인벤토리에 바로 넣기 (저장된 인벤토리를 불러올 때)
function Pets.store(owner: Player, entry: Entry)
	table.insert(Pets.inventory(owner), entry)
end

-- 최고 장비: 기지 + 인벤토리 전체에서 가장 강한 녀석들을 기지에 두고, 나머지는 인벤토리로
function Pets.equipBest(owner: Player)
	local all: { Entry } = {}
	for _, pet in Pets.list(owner) do
		table.insert(all, { regionIndex = pet.regionIndex, rarityIndex = pet.rarityIndex, claimed = pet.claimed })
		pet.model:Destroy()
	end
	for _, entry in Pets.inventory(owner) do
		table.insert(all, entry)
	end
	table.sort(all, isStronger)

	petsOf[owner] = {}
	inventoryOf[owner] = {}
	for i, entry in all do
		if i <= Config.Base.MaxPets then
			spawnInBase(owner, entry)
		else
			table.insert(Pets.inventory(owner), entry)
		end
	end
	Pets.publish(owner)
end

-- 아직 받지 않은 보상 합계 (기지 + 인벤토리)
function Pets.pending(owner: Player): (number, number)
	local speed, money = 0, 0
	local function add(entry: Entry)
		if not entry.claimed then
			local s, m = Config.rewardFor(entry.regionIndex, entry.rarityIndex)
			speed += s
			money += m
		end
	end
	for _, pet in Pets.list(owner) do
		add(pet)
	end
	for _, entry in Pets.inventory(owner) do
		add(entry)
	end
	return speed, money
end

-- 모두 받기: 보상 합계와 마릿수를 돌려주고, 동물은 그대로 남는다
function Pets.claimAll(owner: Player): (number, number, number)
	local speed, money, count = 0, 0, 0
	local function claim(entry: Entry): boolean
		if entry.claimed then
			return false
		end
		local s, m = Config.rewardFor(entry.regionIndex, entry.rarityIndex)
		speed += s
		money += m
		count += 1
		entry.claimed = true
		return true
	end
	for _, pet in Pets.list(owner) do
		if claim(pet) then
			refreshLabel(pet)
		end
	end
	for _, entry in Pets.inventory(owner) do
		claim(entry)
	end
	return speed, money, count
end

-- 저장용: 기지 동물과 인벤토리를 { r, k, c } 목록으로
function Pets.serialize(
	owner: Player
): ({ { r: number, k: number, c: boolean } }, { { r: number, k: number, c: boolean } })
	local base, inventory = {}, {}
	for _, pet in Pets.list(owner) do
		table.insert(base, { r = pet.regionIndex, k = pet.rarityIndex, c = pet.claimed })
	end
	for _, entry in Pets.inventory(owner) do
		table.insert(inventory, { r = entry.regionIndex, k = entry.rarityIndex, c = entry.claimed })
	end
	return base, inventory
end

function Pets.removeAll(owner: Player)
	for _, pet in Pets.list(owner) do
		pet.model:Destroy()
	end
	petsOf[owner] = nil
	inventoryOf[owner] = nil
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
