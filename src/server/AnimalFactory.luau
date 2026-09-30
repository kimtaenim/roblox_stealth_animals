-- 파트를 조립해서 동물·에그 모델을 만든다. 모델의 기준점(Pivot)은 발밑 중앙, 앞쪽은 -Z.
local AnimalFactory = {}

-- Config.Regions 의 동물 항목처럼 색·네온·크기를 바꿀 때 쓰는 값
export type Look = { Color: Color3?, Neon: boolean?, Scale: number? }

-- anchor: "head" 면 머리 중심, "body" 면 몸통 중심 기준 위치. 없으면 발밑 중앙 기준.
-- tint: true 면 몸 색을 따라간다 (색을 바꾸면 같이 바뀜)
type Extra = { size: Vector3, offset: Vector3, color: Color3?, anchor: string?, tint: boolean?, neon: boolean? }
type Shape = {
	body: Vector3,
	head: Vector3,
	legLength: number,
	legWidth: number,
	legCount: number?, -- 기본 4, 새는 2, 물고기는 0
	lift: number?, -- 바닥에서 띄우는 높이 (물고기)
	color: Color3,
	noseSize: Vector3,
	noseColor: Color3,
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
local IVORY = Color3.fromRGB(240, 235, 215)

local function ears(width: number, height: number, spread: number, up: number): { Extra }
	return {
		{
			size = Vector3.new(width, height, 0.25),
			offset = Vector3.new(-spread, up, 0.1),
			anchor = "head",
			tint = true,
		},
		{
			size = Vector3.new(width, height, 0.25),
			offset = Vector3.new(spread, up, 0.1),
			anchor = "head",
			tint = true,
		},
	}
end

local function join(...: { Extra }): { Extra }
	local result = {}
	for _, list in { ... } do
		for _, extra in list do
			table.insert(result, extra)
		end
	end
	return result
end

local function nineTails(): { Extra }
	local tails = {}
	for i = 1, 9 do
		local spread = (i - 5) * 0.35
		table.insert(tails, {
			size = Vector3.new(0.35, 0.35, 2.2),
			offset = Vector3.new(spread, 0.5 + math.abs(spread) * 0.4, 2.5),
			anchor = "body",
			tint = true,
		})
	end
	return tails
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
		extras = ears(0.3, 1.2, 0.3, 1.1),
	},
	Boar = {
		body = Vector3.new(2.6, 2.2, 3.6),
		head = Vector3.new(1.8, 1.8, 1.4),
		legLength = 0.9,
		legWidth = 0.6,
		color = DARK_BROWN,
		noseSize = Vector3.new(0.9, 0.7, 0.3),
		noseColor = Color3.fromRGB(70, 45, 30),
		extras = join(ears(0.5, 0.4, 0.6, 1), {
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
		}),
	},
	Fox = {
		body = Vector3.new(1.6, 1.5, 2.8),
		head = Vector3.new(1.3, 1.2, 1.2),
		legLength = 0.9,
		legWidth = 0.4,
		color = ORANGE,
		noseSize = Vector3.new(0.5, 0.4, 0.6),
		noseColor = WHITE,
		extras = join(ears(0.4, 0.5, 0.4, 0.8), {
			{ size = Vector3.new(0.6, 0.6, 1.6), offset = Vector3.new(0, 0.3, 2.1), anchor = "body", tint = true }, -- 꼬리
			{ size = Vector3.new(0.62, 0.62, 0.4), offset = Vector3.new(0, 0.3, 2.9), color = WHITE, anchor = "body" },
		}),
	},
	Deer = {
		body = Vector3.new(2, 2, 3.6),
		head = Vector3.new(1.3, 1.4, 1.4),
		legLength = 2,
		legWidth = 0.4,
		color = BROWN,
		noseSize = Vector3.new(0.5, 0.4, 0.2),
		noseColor = BLACK,
		extras = {
			{
				size = Vector3.new(0.2, 1.2, 0.2),
				offset = Vector3.new(-0.4, 1.2, 0.2),
				color = ANTLER,
				anchor = "head",
			}, -- 뿔
			{ size = Vector3.new(0.2, 1.2, 0.2), offset = Vector3.new(0.4, 1.2, 0.2), color = ANTLER, anchor = "head" },
			{
				size = Vector3.new(0.9, 0.2, 0.2),
				offset = Vector3.new(-0.7, 1.6, 0.2),
				color = ANTLER,
				anchor = "head",
			},
			{ size = Vector3.new(0.9, 0.2, 0.2), offset = Vector3.new(0.7, 1.6, 0.2), color = ANTLER, anchor = "head" },
		},
	},
	Wolf = {
		body = Vector3.new(2, 1.8, 3.6),
		head = Vector3.new(1.5, 1.4, 1.6),
		legLength = 1.4,
		legWidth = 0.5,
		color = GRAY,
		noseSize = Vector3.new(0.7, 0.6, 0.6),
		noseColor = Color3.fromRGB(60, 60, 65),
		extras = join(ears(0.4, 0.6, 0.45, 0.9), {
			{ size = Vector3.new(0.5, 0.5, 1.6), offset = Vector3.new(0, 0.4, 2.4), anchor = "body", tint = true },
		}),
	},
	Bear = {
		body = Vector3.new(3.4, 3, 4.6),
		head = Vector3.new(2.2, 2, 2),
		legLength = 1.4,
		legWidth = 1,
		color = DARK_BROWN,
		noseSize = Vector3.new(1, 0.7, 0.5),
		noseColor = Color3.fromRGB(190, 150, 110),
		extras = ears(0.6, 0.6, 0.8, 1.1),
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
	Bird = {
		body = Vector3.new(1.4, 1.4, 1.8),
		head = Vector3.new(0.9, 0.9, 0.9),
		legLength = 0.8,
		legWidth = 0.2,
		legCount = 2,
		color = WHITE,
		noseSize = Vector3.new(0.4, 0.3, 0.5),
		noseColor = Color3.fromRGB(240, 160, 40),
		extras = {
			{ size = Vector3.new(0.2, 0.9, 1.3), offset = Vector3.new(-0.8, 0.1, 0.1), anchor = "body", tint = true }, -- 날개
			{ size = Vector3.new(0.2, 0.9, 1.3), offset = Vector3.new(0.8, 0.1, 0.1), anchor = "body", tint = true },
			{ size = Vector3.new(0.8, 0.5, 0.6), offset = Vector3.new(0, 0.4, 1.1), anchor = "body", tint = true }, -- 꼬리
		},
	},
	Lizard = {
		body = Vector3.new(1.6, 0.8, 3),
		head = Vector3.new(1.1, 0.7, 1.2),
		legLength = 0.4,
		legWidth = 0.4,
		color = Color3.fromRGB(90, 170, 80),
		noseSize = Vector3.new(0.5, 0.2, 0.2),
		noseColor = Color3.fromRGB(60, 110, 50),
		extras = {
			{ size = Vector3.new(0.5, 0.4, 2), offset = Vector3.new(0, -0.1, 2.4), anchor = "body", tint = true }, -- 꼬리
		},
	},
	Camel = {
		body = Vector3.new(2.2, 2, 4),
		head = Vector3.new(1.2, 1.2, 1.6),
		legLength = 3,
		legWidth = 0.5,
		color = Color3.fromRGB(200, 160, 100),
		noseSize = Vector3.new(0.8, 0.5, 0.3),
		noseColor = Color3.fromRGB(150, 110, 70),
		extras = {
			{ size = Vector3.new(1.4, 1, 1.3), offset = Vector3.new(0, 1.3, -0.7), anchor = "body", tint = true }, -- 혹
			{ size = Vector3.new(1.4, 1, 1.3), offset = Vector3.new(0, 1.3, 0.9), anchor = "body", tint = true },
		},
	},
	Fish = {
		body = Vector3.new(1.2, 2, 3),
		head = Vector3.new(1.1, 1.7, 0.8),
		legLength = 0,
		legWidth = 0,
		legCount = 0,
		lift = 1.5,
		color = Color3.fromRGB(255, 140, 40),
		noseSize = Vector3.new(0.4, 0.3, 0.1),
		noseColor = Color3.fromRGB(40, 40, 40),
		extras = {
			{ size = Vector3.new(0.2, 1.8, 1), offset = Vector3.new(0, 0, 2), anchor = "body", tint = true }, -- 꼬리 지느러미
			{ size = Vector3.new(0.2, 0.8, 1.2), offset = Vector3.new(0, 1.3, 0), anchor = "body", tint = true }, -- 등 지느러미
		},
	},
	Mammoth = {
		body = Vector3.new(4, 3.6, 5.4),
		head = Vector3.new(2.6, 2.4, 2),
		legLength = 2.2,
		legWidth = 1.2,
		color = Color3.fromRGB(110, 75, 50),
		noseSize = Vector3.new(0.6, 0.6, 0.3),
		noseColor = Color3.fromRGB(90, 60, 40),
		extras = join(ears(1, 1.2, 1.4, 0.2), {
			{ size = Vector3.new(0.7, 2.4, 0.7), offset = Vector3.new(0, -1.4, -1.2), anchor = "head", tint = true }, -- 코
			{ size = Vector3.new(0.3, 0.3, 2), offset = Vector3.new(-0.8, -0.9, -1.6), color = IVORY, anchor = "head" }, -- 상아
			{ size = Vector3.new(0.3, 0.3, 2), offset = Vector3.new(0.8, -0.9, -1.6), color = IVORY, anchor = "head" },
		}),
	},
	NineTail = {
		body = Vector3.new(2, 1.8, 3.2),
		head = Vector3.new(1.5, 1.4, 1.4),
		legLength = 1.2,
		legWidth = 0.5,
		color = WHITE,
		noseSize = Vector3.new(0.5, 0.4, 0.6),
		noseColor = Color3.fromRGB(255, 120, 150),
		extras = join(ears(0.45, 0.6, 0.45, 0.9), nineTails()),
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

-- 모든 파트를 PrimaryPart에 고정해서 한 덩어리로 움직이게 하고, 크기를 맞춘다
local function finish(model: Model, scale: number?)
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
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
end

-- 망치를 든 원시인 (석기시대 보스)
local function buildCaveman(look: Look?): Model
	local model = Instance.new("Model")
	model.Name = "Caveman"
	local skin = Color3.fromRGB(215, 165, 120)
	local fur = (look and look.Color) or Color3.fromRGB(130, 90, 50)

	local torso = makePart(model, "Body", Vector3.new(2.2, 2.2, 1.2), Vector3.new(0, 3.1, 0), fur)
	model.PrimaryPart = torso
	makePart(model, "Head", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 4.9, 0), skin)
	makePart(model, "Hair", Vector3.new(1.55, 0.5, 1.55), Vector3.new(0, 5.65, 0.05), BLACK)
	for _, side in { -1, 1 } do
		makePart(model, "Eye", Vector3.new(0.22, 0.22, 0.1), Vector3.new(side * 0.35, 5.05, -0.72), BLACK)
		makePart(model, "Leg", Vector3.new(0.8, 2, 0.8), Vector3.new(side * 0.6, 1, 0), skin)
		makePart(model, "Arm", Vector3.new(0.7, 2.1, 0.7), Vector3.new(side * 1.45, 3.1, 0), skin)
	end
	-- 오른손의 망치
	makePart(model, "Handle", Vector3.new(0.4, 3.2, 0.4), Vector3.new(1.45, 2.8, -0.9), BROWN)
	makePart(model, "Hammer", Vector3.new(1.6, 1.3, 2), Vector3.new(1.45, 4.6, -0.9), GRAY)

	finish(model, look and look.Scale)
	return model
end

function AnimalFactory.build(kind: string, look: Look?): Model
	if kind == "Caveman" then
		return buildCaveman(look)
	end

	local shape = SHAPES[kind]
	assert(shape, `모르는 동물 종류: {kind}`)

	local color = (look and look.Color) or shape.color
	local neon = look ~= nil and look.Neon == true

	local model = Instance.new("Model")
	model.Name = kind

	local lift = shape.lift or 0
	local bodyCenter = Vector3.new(0, lift + shape.legLength + shape.body.Y / 2, 0)
	local body = makePart(model, "Body", shape.body, bodyCenter, color, neon)
	model.PrimaryPart = body

	-- 머리, 코, 눈
	local headCenter =
		Vector3.new(0, lift + shape.legLength + shape.body.Y * 0.85, -(shape.body.Z / 2 + shape.head.Z / 2 - 0.1))
	if kind == "Fish" then
		headCenter = Vector3.new(0, bodyCenter.Y, headCenter.Z)
	end
	makePart(model, "Head", shape.head, headCenter, color, neon)

	local faceZ = headCenter.Z - shape.head.Z / 2
	makePart(
		model,
		"Nose",
		shape.noseSize,
		Vector3.new(0, headCenter.Y - shape.head.Y * 0.15, faceZ - shape.noseSize.Z / 2 + 0.05),
		shape.noseColor
	)
	local eyeSize = math.max(shape.head.X * 0.15, 0.18)
	for _, side in { -1, 1 } do
		makePart(
			model,
			"Eye",
			Vector3.new(eyeSize, eyeSize, 0.1),
			Vector3.new(side * shape.head.X * 0.28, headCenter.Y + shape.head.Y * 0.2, faceZ - 0.03),
			BLACK
		)
	end

	-- 다리
	local legCount = shape.legCount or 4
	local legX = shape.body.X / 2 - shape.legWidth / 2
	local legZ = shape.body.Z / 2 - shape.legWidth / 2
	local legSpots = {}
	if legCount == 2 then
		legSpots = { Vector2.new(-legX * 0.5, 0), Vector2.new(legX * 0.5, 0) }
	elseif legCount == 4 then
		legSpots =
			{ Vector2.new(-legX, -legZ), Vector2.new(legX, -legZ), Vector2.new(-legX, legZ), Vector2.new(legX, legZ) }
	end
	local legColor = if legCount == 2 then shape.noseColor else color
	for _, spot in legSpots do
		makePart(
			model,
			"Leg",
			Vector3.new(shape.legWidth, shape.legLength, shape.legWidth),
			Vector3.new(spot.X, shape.legLength / 2, spot.Y),
			legColor,
			neon and legCount ~= 2
		)
	end

	for _, extra in shape.extras do
		local origin = if extra.anchor == "head"
			then headCenter
			elseif extra.anchor == "body" then bodyCenter
			else Vector3.zero
		local extraColor = if extra.tint then color else extra.color or color
		makePart(model, "Detail", extra.size, origin + extra.offset, extraColor, extra.neon or (extra.tint and neon))
	end

	finish(model, look and look.Scale)
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
		local dot = makePart(model, "Spot", Vector3.new(0.4, 0.4, 0.4), offset, Color3.fromRGB(200, 170, 120))
		dot.Shape = Enum.PartType.Ball
	end

	finish(model)
	return model
end

-- 훔친 뒤 등급이 공개되면 에그 색을 바꾼다
function AnimalFactory.paintEgg(egg: Model, color: Color3, neon: boolean?)
	local shell = egg.PrimaryPart :: BasePart
	shell.Color = color
	shell.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
end

return AnimalFactory
