-- 파트를 조립해서 동물·에그 모델을 만든다. 모델의 기준점(Pivot)은 발밑 중앙, 앞쪽은 -Z.
local AnimalFactory = {}

-- anchor: "head" 면 머리 중심, "body" 면 몸통 중심 기준 위치. 없으면 발밑 중앙 기준.
type Extra = { size: Vector3, offset: Vector3, color: Color3, anchor: string?, neon: boolean? }
type Shape = {
	body: Vector3,
	head: Vector3,
	legLength: number,
	legWidth: number,
	color: Color3,
	noseSize: Vector3,
	noseColor: Color3,
	neon: boolean?,
	extras: { Extra },
}

local WHITE = Color3.fromRGB(245, 245, 240)
local BLACK = Color3.fromRGB(25, 25, 25)
local PINK = Color3.fromRGB(240, 170, 180)
local ORANGE = Color3.fromRGB(230, 120, 40)
local BROWN = Color3.fromRGB(150, 100, 60)
local DARK_BROWN = Color3.fromRGB(100, 65, 40)
local GRAY = Color3.fromRGB(120, 120, 130)
local ANTLER = Color3.fromRGB(225, 210, 170)

local function antlers(color: Color3, neon: boolean?): { Extra }
	return {
		{
			size = Vector3.new(0.2, 1.2, 0.2),
			offset = Vector3.new(-0.4, 1.2, 0.2),
			color = color,
			anchor = "head",
			neon = neon,
		},
		{
			size = Vector3.new(0.2, 1.2, 0.2),
			offset = Vector3.new(0.4, 1.2, 0.2),
			color = color,
			anchor = "head",
			neon = neon,
		},
		{
			size = Vector3.new(0.9, 0.2, 0.2),
			offset = Vector3.new(-0.7, 1.6, 0.2),
			color = color,
			anchor = "head",
			neon = neon,
		},
		{
			size = Vector3.new(0.9, 0.2, 0.2),
			offset = Vector3.new(0.7, 1.6, 0.2),
			color = color,
			anchor = "head",
			neon = neon,
		},
	}
end

local SHAPES: { [string]: Shape } = {
	Rabbit = {
		body = Vector3.new(1.6, 1.4, 2),
		head = Vector3.new(1.1, 1.1, 1),
		legLength = 0.5,
		legWidth = 0.4,
		color = WHITE,
		noseSize = Vector3.new(0.3, 0.2, 0.2),
		noseColor = PINK,
		extras = {
			{ size = Vector3.new(0.3, 1.2, 0.2), offset = Vector3.new(-0.3, 1.1, 0.1), color = WHITE, anchor = "head" },
			{ size = Vector3.new(0.3, 1.2, 0.2), offset = Vector3.new(0.3, 1.1, 0.1), color = WHITE, anchor = "head" },
		},
	},
	Boar = {
		body = Vector3.new(2.6, 2.2, 3.6),
		head = Vector3.new(1.8, 1.8, 1.4),
		legLength = 0.9,
		legWidth = 0.6,
		color = DARK_BROWN,
		noseSize = Vector3.new(0.9, 0.7, 0.3),
		noseColor = Color3.fromRGB(70, 45, 30),
		extras = {
			{
				size = Vector3.new(0.15, 0.5, 0.15),
				offset = Vector3.new(-0.55, -0.2, -0.9),
				color = WHITE,
				anchor = "head",
			}, -- 엄니
			{
				size = Vector3.new(0.15, 0.5, 0.15),
				offset = Vector3.new(0.55, -0.2, -0.9),
				color = WHITE,
				anchor = "head",
			},
			{
				size = Vector3.new(0.5, 0.4, 0.3),
				offset = Vector3.new(-0.6, 1, 0.2),
				color = DARK_BROWN,
				anchor = "head",
			}, -- 귀
			{
				size = Vector3.new(0.5, 0.4, 0.3),
				offset = Vector3.new(0.6, 1, 0.2),
				color = DARK_BROWN,
				anchor = "head",
			},
		},
	},
	Fox = {
		body = Vector3.new(1.6, 1.5, 2.8),
		head = Vector3.new(1.3, 1.2, 1.2),
		legLength = 0.9,
		legWidth = 0.4,
		color = ORANGE,
		noseSize = Vector3.new(0.5, 0.4, 0.6),
		noseColor = WHITE,
		extras = {
			{ size = Vector3.new(0.4, 0.5, 0.2), offset = Vector3.new(-0.4, 0.8, 0), color = ORANGE, anchor = "head" },
			{ size = Vector3.new(0.4, 0.5, 0.2), offset = Vector3.new(0.4, 0.8, 0), color = ORANGE, anchor = "head" },
			{ size = Vector3.new(0.6, 0.6, 1.6), offset = Vector3.new(0, 0.3, 2.1), color = ORANGE, anchor = "body" }, -- 꼬리
			{ size = Vector3.new(0.62, 0.62, 0.4), offset = Vector3.new(0, 0.3, 2.9), color = WHITE, anchor = "body" },
		},
	},
	Deer = {
		body = Vector3.new(2, 2, 3.6),
		head = Vector3.new(1.3, 1.4, 1.4),
		legLength = 2,
		legWidth = 0.4,
		color = BROWN,
		noseSize = Vector3.new(0.5, 0.4, 0.2),
		noseColor = BLACK,
		extras = antlers(ANTLER),
	},
	Wolf = {
		body = Vector3.new(2, 1.8, 3.6),
		head = Vector3.new(1.5, 1.4, 1.6),
		legLength = 1.4,
		legWidth = 0.5,
		color = GRAY,
		noseSize = Vector3.new(0.7, 0.6, 0.6),
		noseColor = Color3.fromRGB(90, 90, 100),
		extras = {
			{ size = Vector3.new(0.4, 0.6, 0.2), offset = Vector3.new(-0.45, 0.9, 0.2), color = GRAY, anchor = "head" },
			{ size = Vector3.new(0.4, 0.6, 0.2), offset = Vector3.new(0.45, 0.9, 0.2), color = GRAY, anchor = "head" },
			{ size = Vector3.new(0.5, 0.5, 1.6), offset = Vector3.new(0, 0.4, 2.4), color = GRAY, anchor = "body" },
		},
	},
	Bear = {
		body = Vector3.new(3.4, 3, 4.6),
		head = Vector3.new(2.2, 2, 2),
		legLength = 1.4,
		legWidth = 1,
		color = DARK_BROWN,
		noseSize = Vector3.new(1, 0.7, 0.5),
		noseColor = Color3.fromRGB(190, 150, 110),
		extras = {
			{
				size = Vector3.new(0.6, 0.6, 0.3),
				offset = Vector3.new(-0.8, 1.1, 0.3),
				color = DARK_BROWN,
				anchor = "head",
			},
			{
				size = Vector3.new(0.6, 0.6, 0.3),
				offset = Vector3.new(0.8, 1.1, 0.3),
				color = DARK_BROWN,
				anchor = "head",
			},
		},
	},
	Unicorn = {
		body = Vector3.new(2.2, 2.2, 3.8),
		head = Vector3.new(1.4, 1.6, 1.8),
		legLength = 2.2,
		legWidth = 0.5,
		color = WHITE,
		noseSize = Vector3.new(0.9, 0.6, 0.3),
		noseColor = PINK,
		extras = {
			{
				size = Vector3.new(0.3, 1.4, 0.3),
				offset = Vector3.new(0, 1.4, -0.3),
				color = Color3.fromRGB(255, 215, 80),
				anchor = "head",
				neon = true,
			}, -- 뿔
			{
				size = Vector3.new(0.3, 1, 1.4),
				offset = Vector3.new(0, 0.6, 0.8),
				color = Color3.fromRGB(255, 150, 220),
				anchor = "head",
			}, -- 갈기
		},
	},
	CosmicStag = {
		body = Vector3.new(2, 2, 3.6),
		head = Vector3.new(1.3, 1.4, 1.4),
		legLength = 2,
		legWidth = 0.4,
		color = Color3.fromRGB(120, 60, 220),
		neon = true,
		noseSize = Vector3.new(0.5, 0.4, 0.2),
		noseColor = WHITE,
		extras = antlers(Color3.fromRGB(80, 230, 255), true),
	},
}

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	neon: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- 모든 파트를 PrimaryPart에 고정해서 한 덩어리로 움직이게 한다
local function weldToPrimary(model: Model)
	local primary = model.PrimaryPart :: BasePart
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = part
		end
	end
	model.WorldPivot = CFrame.new()
end

function AnimalFactory.build(kind: string): Model
	local shape = SHAPES[kind]
	assert(shape, `모르는 동물 종류: {kind}`)

	local model = Instance.new("Model")
	model.Name = kind

	local bodyCenter = Vector3.new(0, shape.legLength + shape.body.Y / 2, 0)
	local body = makePart(model, "Body", shape.body, bodyCenter, shape.color, shape.neon)
	model.PrimaryPart = body

	-- 머리, 코, 눈
	local headCenter =
		Vector3.new(0, shape.legLength + shape.body.Y * 0.85, -(shape.body.Z / 2 + shape.head.Z / 2 - 0.1))
	makePart(model, "Head", shape.head, headCenter, shape.color, shape.neon)

	local faceZ = headCenter.Z - shape.head.Z / 2
	makePart(
		model,
		"Nose",
		shape.noseSize,
		Vector3.new(0, headCenter.Y - shape.head.Y * 0.15, faceZ - shape.noseSize.Z / 2 + 0.05),
		shape.noseColor
	)
	local eyeSize = shape.head.X * 0.15
	for _, side in { -1, 1 } do
		makePart(
			model,
			"Eye",
			Vector3.new(eyeSize, eyeSize, 0.1),
			Vector3.new(side * shape.head.X * 0.28, headCenter.Y + shape.head.Y * 0.2, faceZ - 0.03),
			BLACK
		)
	end

	-- 다리 4개
	local legX = shape.body.X / 2 - shape.legWidth / 2
	local legZ = shape.body.Z / 2 - shape.legWidth / 2
	for _, x in { -legX, legX } do
		for _, z in { -legZ, legZ } do
			makePart(
				model,
				"Leg",
				Vector3.new(shape.legWidth, shape.legLength, shape.legWidth),
				Vector3.new(x, shape.legLength / 2, z),
				shape.color,
				shape.neon
			)
		end
	end

	for _, extra in shape.extras do
		local origin = if extra.anchor == "head"
			then headCenter
			elseif extra.anchor == "body" then bodyCenter
			else Vector3.zero
		makePart(model, "Detail", extra.size, origin + extra.offset, extra.color, extra.neon)
	end

	weldToPrimary(model)
	return model
end

-- 달걀 모양 에그
function AnimalFactory.buildEgg(color: Color3, neon: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "Egg"

	local shell = makePart(model, "Body", Vector3.new(2, 2.6, 2), Vector3.new(0, 1.3, 0), color, neon)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = shell
	model.PrimaryPart = shell

	-- 점무늬
	for _, offset in { Vector3.new(0.7, 1.8, -0.55), Vector3.new(-0.6, 1.1, -0.7), Vector3.new(0.2, 0.7, -0.9) } do
		local dot = makePart(model, "Spot", Vector3.new(0.4, 0.4, 0.4), offset, Color3.new(1, 1, 1))
		dot.Shape = Enum.PartType.Ball
	end

	weldToPrimary(model)
	return model
end

return AnimalFactory
