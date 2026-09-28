-- 파트를 조립해서 동물 모델을 만든다. 모델의 기준점(Pivot)은 발밑 중앙.
local AnimalFactory = {}

type Extra = { size: Vector3, offset: Vector3, color: Color3 }
type Shape = {
	body: Vector3,
	head: Vector3,
	legLength: number,
	legWidth: number,
	legCount: number,
	color: Color3,
	legColor: Color3,
	noseSize: Vector3,
	noseColor: Color3,
	extras: { Extra },
}

local WHITE = Color3.fromRGB(245, 245, 240)
local PINK = Color3.fromRGB(240, 170, 180)
local ORANGE = Color3.fromRGB(240, 160, 40)
local BLACK = Color3.fromRGB(25, 25, 25)

local SHAPES: { [string]: Shape } = {
	Chicken = {
		body = Vector3.new(1.4, 1.4, 1.8),
		head = Vector3.new(0.9, 0.9, 0.9),
		legLength = 0.8,
		legWidth = 0.2,
		legCount = 2,
		color = WHITE,
		legColor = ORANGE,
		noseSize = Vector3.new(0.4, 0.3, 0.4),
		noseColor = ORANGE,
		extras = {
			{
				size = Vector3.new(0.15, 0.4, 0.5),
				offset = Vector3.new(0, 2.64, -1.25),
				color = Color3.fromRGB(220, 40, 40),
			}, -- 볏
		},
	},
	Pig = {
		body = Vector3.new(2.6, 2.2, 3.6),
		head = Vector3.new(1.8, 1.8, 1.4),
		legLength = 0.9,
		legWidth = 0.6,
		legCount = 4,
		color = PINK,
		legColor = PINK,
		noseSize = Vector3.new(0.9, 0.7, 0.3),
		noseColor = Color3.fromRGB(220, 130, 150),
		extras = {
			{ size = Vector3.new(0.5, 0.3, 0.4), offset = Vector3.new(-0.6, 3.82, -2.4), color = PINK }, -- 귀
			{ size = Vector3.new(0.5, 0.3, 0.4), offset = Vector3.new(0.6, 3.82, -2.4), color = PINK },
		},
	},
	Cow = {
		body = Vector3.new(3.4, 3, 5.4),
		head = Vector3.new(2, 2, 1.8),
		legLength = 2,
		legWidth = 0.8,
		legCount = 4,
		color = WHITE,
		legColor = WHITE,
		noseSize = Vector3.new(1.4, 0.9, 0.4),
		noseColor = Color3.fromRGB(230, 160, 160),
		extras = {
			{ size = Vector3.new(0.1, 1.2, 1.4), offset = Vector3.new(1.72, 3.8, 0.8), color = BLACK }, -- 얼룩
			{ size = Vector3.new(0.1, 1, 1.6), offset = Vector3.new(-1.72, 3.2, -1), color = BLACK },
			{ size = Vector3.new(1.4, 0.1, 1.2), offset = Vector3.new(0.4, 5.02, 1), color = BLACK },
			{
				size = Vector3.new(0.25, 0.5, 0.25),
				offset = Vector3.new(-0.7, 5.8, -3.5),
				color = Color3.fromRGB(230, 220, 190),
			}, -- 뿔
			{
				size = Vector3.new(0.25, 0.5, 0.25),
				offset = Vector3.new(0.7, 5.8, -3.5),
				color = Color3.fromRGB(230, 220, 190),
			},
		},
	},
}

local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function AnimalFactory.build(kind: string): Model
	local shape = SHAPES[kind]
	assert(shape, `모르는 동물 종류: {kind}`)

	local model = Instance.new("Model")
	model.Name = kind

	-- 몸통 (앞쪽이 -Z)
	local body = makePart(model, "Body", shape.body, Vector3.new(0, shape.legLength + shape.body.Y / 2, 0), shape.color)
	model.PrimaryPart = body

	-- 머리, 코, 눈
	local headY = shape.legLength + shape.body.Y * 0.85
	local headZ = -(shape.body.Z / 2 + shape.head.Z / 2 - 0.1)
	makePart(model, "Head", shape.head, Vector3.new(0, headY, headZ), shape.color)

	local faceZ = headZ - shape.head.Z / 2
	makePart(
		model,
		"Nose",
		shape.noseSize,
		Vector3.new(0, headY - shape.head.Y * 0.15, faceZ - shape.noseSize.Z / 2 + 0.05),
		shape.noseColor
	)
	local eyeSize = shape.head.X * 0.15
	for _, side in { -1, 1 } do
		makePart(
			model,
			"Eye",
			Vector3.new(eyeSize, eyeSize, 0.1),
			Vector3.new(side * shape.head.X * 0.28, headY + shape.head.Y * 0.2, faceZ - 0.03),
			BLACK
		)
	end

	-- 다리
	local legX = shape.body.X / 2 - shape.legWidth / 2
	local legZ = shape.body.Z / 2 - shape.legWidth / 2
	local legSpots = if shape.legCount == 2
		then { Vector2.new(-legX * 0.6, 0), Vector2.new(legX * 0.6, 0) }
		else {
			Vector2.new(-legX, -legZ),
			Vector2.new(legX, -legZ),
			Vector2.new(-legX, legZ),
			Vector2.new(legX, legZ),
		}
	for _, spot in legSpots do
		makePart(
			model,
			"Leg",
			Vector3.new(shape.legWidth, shape.legLength, shape.legWidth),
			Vector3.new(spot.X, shape.legLength / 2, spot.Y),
			shape.legColor
		)
	end

	for _, extra in shape.extras do
		makePart(model, "Detail", extra.size, extra.offset, extra.color)
	end

	-- 모든 파트를 몸통에 고정해서 한 덩어리로 움직이게 한다
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = part
		end
	end

	model.WorldPivot = CFrame.new() -- 발밑 중앙
	return model
end

return AnimalFactory
