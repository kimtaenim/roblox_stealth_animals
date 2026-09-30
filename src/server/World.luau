-- 맵 생성: 기지(초록 잔디·울타리·출발선·러닝머신·업그레이드 판매대·부화 자리)와
-- 지역(바닥·꾸미기·에그 둥지·표지판). 기지와 지역은 폭이 같고 경계선에서 바로 이어진다.
-- 나중에 Studio에서 직접 맵을 꾸미게 되면 이 부분을 교체하면 된다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local World = {}

-- 부화 자리: 에그가 부화하는 동안만 쓰고, 부화하면 동물은 기지를 돌아다닌다
export type Pad = {
	part: BasePart,
	label: TextLabel,
	state: "empty" | "hatching",
	model: Model?,
	regionIndex: number,
	rarityIndex: number,
	progress: number, -- 부화 진행 (초). 밤에는 빨리 찬다
}

export type Plot = {
	floor: BasePart,
	sign: TextLabel,
	pads: { Pad },
	owner: Player?,
}

export type NestSpot = { index: number, position: Vector3, egg: Model? }

export type Region = {
	index: number,
	center: Vector3,
	size: Vector3,
	eggs: Folder,
	nestCenter: Vector3,
	nestSpots: { NestSpot },
	chaserHomes: { Vector3 },
	bossHome: Vector3,
}

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeLabel(
	adornee: BasePart,
	offsetY: number,
	width: number,
	height: number,
	text: string,
	maxDistance: number?
): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(width, height)
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.MaxDistance = maxDistance or 120
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = billboard
	return label
end
World.makeLabel = makeLabel

-- 보이지 않는 표지판 기둥 (글자만 띄우기)
local function makeSignPost(parent: Instance, position: Vector3): Part
	local post = makePart(parent, "Sign", Vector3.new(1, 1, 1), position, Color3.new(1, 1, 1))
	post.Transparency = 1
	post.CanCollide = false
	post.CanQuery = false
	return post
end

--------------------------------------------------------------------------------
-- 기지
--------------------------------------------------------------------------------

export type Base = {
	treadmills: { BasePart },
	kiosk: BasePart,
	plots: { Plot },
}

local function buildPlot(parent: Instance, index: number): Plot
	local base = Config.Base
	local center = base.PlotCenters[index]
	local color = base.PlotColors[index]
	local floor = makePart(
		parent,
		`Plot{index}`,
		Vector3.new(base.PlotSize, 0.4, base.PlotSize),
		center + Vector3.new(0, 0.3, 0),
		color
	)

	-- 부화 자리 16칸 (4 x 4)
	local pads: { Pad } = {}
	for _, dz in { -9, -3, 3, 9 } do
		for _, dx in { -9, -3, 3, 9 } do
			local part = makePart(
				parent,
				"Pad",
				Vector3.new(4.5, 0.3, 4.5),
				center + Vector3.new(dx, 0.65, dz),
				color:Lerp(Color3.new(0, 0, 0), 0.35)
			)
			table.insert(pads, {
				part = part,
				label = makeLabel(part, 5, 140, 50, "", 60),
				state = "empty",
				model = nil,
				regionIndex = 0,
				rarityIndex = 0,
				progress = 0,
			})
		end
	end

	local signPost = makeSignPost(parent, center + Vector3.new(0, 1, -base.PlotSize / 2 + 1))
	return {
		floor = floor,
		sign = makeLabel(signPost, 5, 240, 50, "빈 기지"),
		pads = pads,
		owner = nil,
	}
end

-- 러닝머신: 올라가 있으면 달리는 동작을 하면서 속도가 오른다 (밀려나지 않음). 밝은 방벽으로 둘러싼다.
local function buildTreadmill(parent: Instance, x: number): BasePart
	local length, width, wallHeight = 16, 6, 4
	local belt = makePart(
		parent,
		"Treadmill",
		Vector3.new(width, 1, length),
		Vector3.new(x, 0.5, 10),
		Color3.fromRGB(40, 40, 45),
		Enum.Material.Rubber
	)

	local wallColor = Config.Treadmill.WallColor
	local wallY = 1 + wallHeight / 2
	for _, side in { -1, 1 } do
		makePart(
			parent,
			"TreadmillWall",
			Vector3.new(1, wallHeight, length),
			Vector3.new(x + side * (width / 2 + 0.5), wallY, 10),
			wallColor,
			Enum.Material.Neon
		)
	end
	local front = makePart(
		parent,
		"TreadmillWall",
		Vector3.new(width + 2, wallHeight, 1),
		Vector3.new(x, wallY, 10 + length / 2 + 0.5),
		wallColor,
		Enum.Material.Neon
	)
	makeLabel(front, 4, 200, 40, "🏃 러닝머신")
	return belt
end

-- 기지 울타리: 옆과 뒤는 막고, 출발선 쪽은 가운데에 문
local function buildBaseFence(parent: Instance)
	local base = Config.Base
	local height = 4
	local halfW, halfD = base.Width / 2, base.Depth / 2
	local color = base.FenceColor
	local y = height / 2

	makePart(parent, "Fence", Vector3.new(base.Width, height, 1), Vector3.new(0, y, -halfD), color, Enum.Material.Wood)
	for _, side in { -1, 1 } do
		makePart(
			parent,
			"Fence",
			Vector3.new(1, height, base.Depth),
			Vector3.new(side * halfW, y, 0),
			color,
			Enum.Material.Wood
		)
		local segment = (base.Width - base.GateWidth) / 2
		makePart(
			parent,
			"Fence",
			Vector3.new(segment, height, 1),
			Vector3.new(side * (base.GateWidth / 2 + segment / 2), y, halfD - 1.5),
			color,
			Enum.Material.Wood
		)
	end
end

function World.buildBase(): Base
	local base = Config.Base
	local folder = Instance.new("Folder")
	folder.Name = "Base"

	makePart(
		folder,
		"Ground",
		Vector3.new(base.Width, 0.2, base.Depth),
		Vector3.new(0, 0.1, 0),
		base.GroundColor,
		Enum.Material.Grass
	)
	buildBaseFence(folder)

	-- 출발선
	local line = makePart(
		folder,
		"StartLine",
		Vector3.new(base.Width, 0.3, 2),
		Vector3.new(0, 0.15, base.Depth / 2),
		Color3.new(1, 1, 1),
		Enum.Material.Neon
	)
	makeLabel(line, 6, 300, 60, "🏁 출발선  ·  안쪽이 내 기지")

	local treadmills = {}
	for _, x in base.TreadmillXs do
		table.insert(treadmills, buildTreadmill(folder, x))
	end

	-- 러닝머신 업그레이드 판매대
	local kiosk = makePart(
		folder,
		"UpgradeKiosk",
		Vector3.new(6, 4, 3),
		base.UpgradeKiosk + Vector3.new(0, 2, 0),
		Color3.fromRGB(255, 200, 60)
	)
	makeLabel(kiosk, 4.5, 260, 40, "⬆️ 러닝머신 업그레이드")

	local plots = {}
	for i in base.PlotCenters do
		plots[i] = buildPlot(folder, i)
	end

	folder.Parent = workspace
	return { treadmills = treadmills, kiosk = kiosk, plots = plots }
end

function World.isInsideBase(position: Vector3): boolean
	return math.abs(position.X) <= Config.Base.Width / 2 and math.abs(position.Z) <= Config.Base.Depth / 2
end

-- 기지 동물이 돌아다닐 다음 목적지 (울타리 안쪽)
function World.randomBaseSpot(random: Random): Vector3
	local margin = 6
	local halfW = Config.Base.Width / 2 - margin
	local halfD = Config.Base.Depth / 2 - margin
	return Vector3.new(random:NextNumber(-halfW, halfW), 0.2, random:NextNumber(-halfD, halfD))
end

function World.isOnTreadmill(base: Base, position: Vector3): boolean
	for _, belt in base.treadmills do
		local offset = position - belt.Position
		if math.abs(offset.X) <= belt.Size.X / 2 and math.abs(offset.Z) <= belt.Size.Z / 2 and offset.Y < 6 then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- 지역 꾸미기
--------------------------------------------------------------------------------

local CORAL_COLORS = {
	Color3.fromRGB(255, 120, 150),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(170, 90, 230),
	Color3.fromRGB(80, 220, 200),
}

local function buildDecor(parent: Instance, decor: { Kind: string, Color: Color3? }, position: Vector3, random: Random)
	local x, z = position.X, position.Z
	if decor.Kind == "Tree" then
		makePart(
			parent,
			"Trunk",
			Vector3.new(1.5, 8, 1.5),
			Vector3.new(x, 4, z),
			Color3.fromRGB(110, 75, 45),
			Enum.Material.Wood
		)
		makePart(
			parent,
			"Leaves",
			Vector3.new(7, 6, 7),
			Vector3.new(x, 10, z),
			decor.Color or Color3.fromRGB(60, 130, 60),
			Enum.Material.Grass
		)
	elseif decor.Kind == "Cactus" then
		local color = decor.Color or Color3.fromRGB(70, 140, 70)
		local height = random:NextNumber(5, 9)
		makePart(
			parent,
			"Cactus",
			Vector3.new(1.6, height, 1.6),
			Vector3.new(x, height / 2, z),
			color,
			Enum.Material.Grass
		)
		makePart(
			parent,
			"CactusArm",
			Vector3.new(2.4, 0.9, 0.9),
			Vector3.new(x + 1.6, height * 0.55, z),
			color,
			Enum.Material.Grass
		)
		makePart(
			parent,
			"CactusArm",
			Vector3.new(0.9, 2, 0.9),
			Vector3.new(x + 2.4, height * 0.55 + 1.3, z),
			color,
			Enum.Material.Grass
		)
	elseif decor.Kind == "Coral" then
		for _ = 1, 3 do
			local height = random:NextNumber(2, 7)
			local color = CORAL_COLORS[random:NextInteger(1, #CORAL_COLORS)]
			local offset = Vector3.new(random:NextNumber(-2, 2), 0, random:NextNumber(-2, 2))
			makePart(
				parent,
				"Coral",
				Vector3.new(1, height, 1),
				Vector3.new(x, height / 2, z) + offset,
				color,
				Enum.Material.Neon
			)
		end
	elseif decor.Kind == "Rock" then
		local size = random:NextNumber(3, 8)
		local rock = makePart(
			parent,
			"Rock",
			Vector3.new(size, size * 0.7, size),
			Vector3.new(x, size * 0.3, z),
			Color3.fromRGB(120, 115, 110),
			Enum.Material.Slate
		)
		rock.Orientation = Vector3.new(0, random:NextNumber(0, 90), 0)
	end
end

--------------------------------------------------------------------------------
-- 지역
--------------------------------------------------------------------------------

local function oddsText(): string
	local total = 0
	for _, rarity in Config.Rarities do
		total += rarity.Weight
	end
	local parts = {}
	for _, rarity in Config.Rarities do
		table.insert(parts, `{rarity.Name} {math.floor(rarity.Weight / total * 1000 + 0.5) / 10}%`)
	end
	return table.concat(parts, "  ")
end

function World.buildRegion(index: number): Region
	local config = Config.Regions[index]
	local layout = Config.RegionLayout
	local startZ = layout.FirstStartZ + (index - 1) * layout.Length
	local center = Vector3.new(0, 0, startZ + layout.Length / 2)
	local size = Vector3.new(layout.Width, 0, layout.Length)
	local nestCenter = Vector3.new(0, 0.2, startZ + layout.NestOffset)

	local folder = Instance.new("Folder")
	folder.Name = config.Id

	makePart(
		folder,
		"Ground",
		Vector3.new(size.X, 0.2, size.Z),
		center + Vector3.new(0, 0.1, 0),
		config.GroundColor,
		config.GroundMaterial
	)

	-- 경계선 표시
	local border = makePart(
		folder,
		"Border",
		Vector3.new(size.X, 0.25, 1),
		Vector3.new(0, 0.12, startZ),
		Color3.new(1, 1, 1),
		Enum.Material.Neon
	)
	border.Transparency = 0.5
	local recommended = if config.RecommendedSpeed > 0
		then `추천 속도 ⚡{Format.number(config.RecommendedSpeed)}`
		else "처음 오는 곳"
	local bossText = if config.Boss then `\n⚠️ 보스: {config.Boss.Name}` else ""
	-- 지역 이름 표지판 (출발선 표지판과 겹치지 않게 옆쪽에)
	local regionSign = makeSignPost(folder, Vector3.new(60, 1, startZ + 3))
	makeLabel(regionSign, 8, 340, 90, `{config.Emoji} {config.Name}\n{recommended}{bossText}`, 250)

	-- 꾸미기 (가운데 줄과 둥지 주변은 비워 둔다)
	local random = Random.new(index)
	for _ = 1, 70 do
		local side = if random:NextNumber() < 0.5 then -1 else 1
		local position =
			Vector3.new(side * random:NextNumber(24, size.X / 2 - 4), 0, startZ + random:NextNumber(5, size.Z - 5))
		buildDecor(folder, config.Decor, position, random)
	end

	-- 에그 둥지: 에그가 한곳에 동그랗게 모여 있다
	local nestSpots = {}
	local count = Config.Egg.NestSize
	for i = 1, count do
		local angle = (i / count) * math.pi * 2
		local position = nestCenter + Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
		table.insert(nestSpots, { index = i, position = position, egg = nil })
	end
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local twig = makePart(
			folder,
			"Nest",
			Vector3.new(3, 1, 1),
			nestCenter + Vector3.new(math.cos(angle) * 8, 0.5, math.sin(angle) * 8),
			Color3.fromRGB(140, 100, 60),
			Enum.Material.Wood
		)
		twig.Orientation = Vector3.new(0, -math.deg(angle) + 90, 0)
	end
	local nestSign = makeSignPost(folder, nestCenter + Vector3.new(0, 1, -10))
	makeLabel(nestSign, 6, 420, 100, `🥚 {config.Name} 에그 둥지\n훔치면 등급 공개!\n{oddsText()}`, 150)

	-- 지키는 동물이 처음 서 있는 자리 (둥지에서 떨어진 곳)
	local chaserHomes = {}
	for i = 1, #config.Chasers do
		table.insert(chaserHomes, nestCenter + Vector3.new((i - 1) * 20 - 30, 0, -40))
	end

	local eggs = Instance.new("Folder")
	eggs.Name = "Eggs"
	eggs.Parent = folder

	folder.Parent = workspace
	return {
		index = index,
		center = center,
		size = size,
		eggs = eggs,
		nestCenter = nestCenter,
		nestSpots = nestSpots,
		chaserHomes = chaserHomes,
		bossHome = nestCenter + Vector3.new(30, 0, -40),
	}
end

-- margin 만큼 넓혀서 지역 안인지 확인
function World.isInsideRegion(region: Region, position: Vector3, margin: number?): boolean
	local extra = margin or 0
	local offset = position - region.center
	return math.abs(offset.X) <= region.size.X / 2 + extra and math.abs(offset.Z) <= region.size.Z / 2 + extra
end

-- 지역 안에서 어슬렁거릴 다음 목적지 (둥지 가까이는 피한다)
function World.randomWanderSpot(region: Region, random: Random): Vector3
	local keepOut = Config.Chaser.NestKeepOut + 5
	for _ = 1, 20 do
		local spot = region.center
			+ Vector3.new(
				random:NextNumber(-region.size.X / 2 + 10, region.size.X / 2 - 10),
				0,
				random:NextNumber(-region.size.Z / 2 + 10, region.size.Z / 2 - 10)
			)
		spot = Vector3.new(spot.X, region.nestCenter.Y, spot.Z)
		if (spot - region.nestCenter).Magnitude > keepOut then
			return spot
		end
	end
	return region.nestCenter + Vector3.new(0, 0, -keepOut - 10)
end

return World
