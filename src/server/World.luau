-- 맵 생성: 기지(출발선·러닝머신·업그레이드 판매대·부화 자리)와 지역(바닥·나무·에그 받침대·표지판).
-- 나중에 Studio에서 직접 맵을 꾸미게 되면 이 부분을 교체하면 된다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local World = {}

export type Pad = {
	part: BasePart,
	label: TextLabel,
	state: "empty" | "hatching" | "hatched",
	model: Model?,
	regionIndex: number,
	rarityIndex: number,
	hatchAt: number,
}

export type Plot = {
	floor: BasePart,
	sign: TextLabel,
	pads: { Pad },
	owner: Player?,
}

export type EggSpot = { rarityIndex: number, position: Vector3 }

export type Region = {
	index: number,
	center: Vector3,
	size: Vector3,
	eggs: Folder,
	eggSpots: { EggSpot },
	chaserHomes: { Vector3 },
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
	local floor = makePart(
		parent,
		`Plot{index}`,
		Vector3.new(base.PlotSize, 0.4, base.PlotSize),
		center + Vector3.new(0, 0.3, 0),
		base.PlotColors[index]
	)

	-- 부화 자리 8칸 (4 x 2)
	local pads: { Pad } = {}
	for _, dz in { -5, 5 } do
		for _, dx in { -9, -3, 3, 9 } do
			local part = makePart(
				parent,
				"Pad",
				Vector3.new(4.5, 0.3, 4.5),
				center + Vector3.new(dx, 0.65, dz),
				base.PlotColors[index]:Lerp(Color3.new(0, 0, 0), 0.35)
			)
			table.insert(pads, {
				part = part,
				label = makeLabel(part, 6, 140, 50, "", 60),
				state = "empty",
				model = nil,
				regionIndex = 0,
				rarityIndex = 0,
				hatchAt = 0,
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

function World.buildBase(): Base
	local base = Config.Base
	local folder = Instance.new("Folder")
	folder.Name = "Base"

	makePart(
		folder,
		"Ground",
		Vector3.new(base.Width, 0.2, base.Depth),
		Vector3.new(0, 0.1, 0),
		Color3.fromRGB(200, 190, 160),
		Enum.Material.Concrete
	)

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

	-- 러닝머신
	local treadmills = {}
	for _, x in base.TreadmillXs do
		local belt = makePart(
			folder,
			"Treadmill",
			Vector3.new(6, 1, 16),
			Vector3.new(x, 0.5, 10),
			Color3.fromRGB(40, 40, 45),
			Enum.Material.Rubber
		)
		belt.AssemblyLinearVelocity = Vector3.new(0, 0, -Config.Treadmill.BeltSpeed) -- 컨베이어 벨트
		makeLabel(belt, 5, 200, 40, "🏃 러닝머신")
		table.insert(treadmills, belt)
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
-- 지역
--------------------------------------------------------------------------------

function World.buildRegion(index: number): Region
	local config = Config.Regions[index]
	local layout = Config.RegionLayout
	local startZ = layout.FirstStartZ + (index - 1) * (layout.Length + layout.Gap)
	local center = Vector3.new(0, 0, startZ + layout.Length / 2)
	local size = Vector3.new(layout.Width, 0, layout.Length)

	local folder = Instance.new("Folder")
	folder.Name = config.Id

	makePart(
		folder,
		"Ground",
		Vector3.new(size.X, 0.2, size.Z),
		center + Vector3.new(0, 0.1, 0),
		config.GroundColor,
		Enum.Material.Grass
	)

	local entrance = makeSignPost(folder, Vector3.new(0, 1, startZ))
	local required = if config.RequiredSpeed > 0
		then `필요 속도 ⚡{Format.number(config.RequiredSpeed)}`
		else "누구나 입장 가능"
	makeLabel(entrance, 8, 320, 70, `{config.Emoji} {config.Name}\n{required}`, 200)

	-- 나무 (가운데 길은 비워 둔다)
	local random = Random.new(index)
	for _ = 1, 30 do
		local side = if random:NextNumber() < 0.5 then -1 else 1
		local x = side * random:NextNumber(24, size.X / 2 - 3)
		local z = startZ + random:NextNumber(5, size.Z - 5)
		makePart(
			folder,
			"Trunk",
			Vector3.new(1.5, 8, 1.5),
			Vector3.new(x, 4, z),
			Color3.fromRGB(110, 75, 45),
			Enum.Material.Wood
		)
		makePart(
			folder,
			"Leaves",
			Vector3.new(7, 6, 7),
			Vector3.new(x, 10, z),
			Color3.fromRGB(60, 130, 60),
			Enum.Material.Grass
		)
	end

	-- 에그 받침대: 입구 가까이는 일반, 깊숙할수록 좋은 등급
	local eggSpots = {}
	for rarityIndex, rarity in Config.Rarities do
		local x = if rarityIndex % 2 == 0 then 12 else -12
		local z = startZ + 20 + (rarityIndex - 1) * 22
		local pedestal = makePart(
			folder,
			"Pedestal",
			Vector3.new(4, 1, 4),
			Vector3.new(x, 0.5, z),
			Color3.fromRGB(150, 150, 150),
			Enum.Material.Slate
		)

		local speed, money = Config.rewardFor(index, rarityIndex)
		local signPost = makeSignPost(folder, Vector3.new(x + (if x > 0 then 5 else -5), 1, z))
		local sign = makeLabel(
			signPost,
			3,
			200,
			90,
			`{rarity.Name} 에그\n부화 {Format.duration(rarity.HatchTime)}\n⚡{Format.number(speed)}  💰{Format.number(
				money
			)}`,
			70
		)
		sign.TextColor3 = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.3)

		table.insert(eggSpots, { rarityIndex = rarityIndex, position = pedestal.Position + Vector3.new(0, 0.5, 0) })
	end

	local chaserHomes = {}
	for i, _ in config.Chasers do
		table.insert(chaserHomes, Vector3.new((i - 2) * 10, 0.2, startZ + 50 + (i - 1) * 50))
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
		eggSpots = eggSpots,
		chaserHomes = chaserHomes,
	}
end

-- margin 만큼 넓혀서 지역 안인지 확인
function World.isInsideRegion(region: Region, position: Vector3, margin: number?): boolean
	local extra = margin or 0
	local offset = position - region.center
	return math.abs(offset.X) <= region.size.X / 2 + extra and math.abs(offset.Z) <= region.size.Z / 2 + extra
end

return World
