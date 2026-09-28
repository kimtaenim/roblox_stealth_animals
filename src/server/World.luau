-- 맵 생성: 농장(바닥·울타리·건초더미)과 플레이어 기지.
-- 나중에 Studio에서 직접 맵을 꾸미게 되면 이 부분을 교체하면 된다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local World = {}

export type Plot = {
	floor: BasePart,
	animals: Folder,
	sign: TextLabel,
	owner: Player?,
}

local FENCE_COLOR = Color3.fromRGB(150, 105, 60)

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

-- 사각형 울타리. openSide = 1 이면 +Z 쪽, -1 이면 -Z 쪽 가운데에 입구가 뚫린다.
local function buildFence(parent: Instance, center: Vector3, width: number, depth: number, openSide: number)
	local height = Config.World.FenceHeight
	local gap = Config.World.FenceGap
	local y = height / 2

	makePart(
		parent,
		"Fence",
		Vector3.new(1, height, depth),
		center + Vector3.new(-width / 2, y, 0),
		FENCE_COLOR,
		Enum.Material.Wood
	)
	makePart(
		parent,
		"Fence",
		Vector3.new(1, height, depth),
		center + Vector3.new(width / 2, y, 0),
		FENCE_COLOR,
		Enum.Material.Wood
	)
	makePart(
		parent,
		"Fence",
		Vector3.new(width, height, 1),
		center + Vector3.new(0, y, -openSide * depth / 2),
		FENCE_COLOR,
		Enum.Material.Wood
	)

	local segment = (width - gap) / 2
	for _, side in { -1, 1 } do
		makePart(
			parent,
			"Fence",
			Vector3.new(segment, height, 1),
			center + Vector3.new(side * (gap / 2 + segment / 2), y, openSide * depth / 2),
			FENCE_COLOR,
			Enum.Material.Wood
		)
	end
end

local function makeSign(parent: BasePart, text: string): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(240, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 150
	billboard.Parent = parent

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

-- 농장을 만들고, 동물을 넣을 폴더를 돌려준다.
function World.buildFarm(): Folder
	local farm = Config.Farm
	local folder = Instance.new("Folder")
	folder.Name = "Farm"

	makePart(
		folder,
		"Ground",
		Vector3.new(farm.Width, 0.2, farm.Depth),
		farm.Center + Vector3.new(0, 0.1, 0),
		Color3.fromRGB(110, 170, 80),
		Enum.Material.Grass
	)
	buildFence(folder, farm.Center, farm.Width, farm.Depth, -1) -- 입구는 스폰 쪽(-Z)

	for _, position in farm.HayBales do
		makePart(
			folder,
			"HayBale",
			Vector3.new(6, 5, 5),
			position + Vector3.new(0, 2.5, 0),
			Color3.fromRGB(225, 195, 90),
			Enum.Material.Fabric
		)
	end

	local gatePost = makePart(
		folder,
		"GateSign",
		Vector3.new(1, 1, 1),
		farm.Center + Vector3.new(0, 3, -farm.Depth / 2),
		FENCE_COLOR
	)
	gatePost.Transparency = 1
	gatePost.CanCollide = false
	makeSign(gatePost, "🌾 농장")

	local animals = Instance.new("Folder")
	animals.Name = "Animals"
	animals.Parent = folder

	folder.Parent = workspace
	return animals
end

function World.buildPlots(): { Plot }
	local base = Config.Base
	local size = base.PlotSize
	local folder = Instance.new("Folder")
	folder.Name = "Bases"

	local plots: { Plot } = {}
	for i, center in base.PlotCenters do
		local plotFolder = Instance.new("Folder")
		plotFolder.Name = `Base{i}`
		plotFolder.Parent = folder

		local floor = makePart(
			plotFolder,
			"Floor",
			Vector3.new(size, 0.4, size),
			center + Vector3.new(0, 0.2, 0),
			base.PlotColors[i]
		)
		buildFence(plotFolder, center, size, size, 1) -- 입구는 농장 쪽(+Z)

		local animals = Instance.new("Folder")
		animals.Name = "Animals"
		animals.Parent = plotFolder

		plots[i] = {
			floor = floor,
			animals = animals,
			sign = makeSign(floor, "빈 기지"),
			owner = nil,
		}
	end

	folder.Parent = workspace
	return plots
end

function World.isInsidePlot(plot: Plot, position: Vector3): boolean
	local offset = position - plot.floor.Position
	local half = Config.Base.PlotSize / 2
	return math.abs(offset.X) <= half and math.abs(offset.Z) <= half
end

-- 기지 안의 무작위 위치 (동물을 놓을 자리)
function World.randomSpotInPlot(plot: Plot): CFrame
	local half = math.floor(Config.Base.PlotSize / 2 - 4)
	local top = plot.floor.Position + Vector3.new(0, plot.floor.Size.Y / 2, 0)
	return CFrame.new(top + Vector3.new(math.random(-half, half), 0, math.random(-half, half)))
		* CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
end

return World
