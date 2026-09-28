-- 농부(경비) NPC: 정해진 경로를 순찰하고, 시야(거리·각도·벽 가림) 안의 캐릭터를 감지한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Guard = {}
Guard.__index = Guard

local function createBody(): Model
	local description = Instance.new("HumanoidDescription")
	local shirt = Color3.fromRGB(190, 50, 50) -- 빨간 셔츠
	local overalls = Color3.fromRGB(50, 80, 150) -- 청 멜빵바지
	description.TorsoColor = shirt
	description.LeftArmColor = shirt
	description.RightArmColor = shirt
	description.LeftLegColor = overalls
	description.RightLegColor = overalls

	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	model.Name = "Farmer"
	return model
end

-- 머리 위에 "?" / "!" 를 띄우는 표시
local function createAlertLabel(head: BasePart): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 0)
	label.TextStrokeTransparency = 0
	label.Text = ""
	label.Parent = billboard
	return label
end

function Guard.new(route: { Vector3 }, parent: Instance)
	local model = createBody()
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:WaitForChild("HumanoidRootPart") :: BasePart
	local head = model:WaitForChild("Head") :: BasePart

	humanoid.WalkSpeed = Config.Guard.WalkSpeed
	model:PivotTo(CFrame.new(route[1] + Vector3.new(0, 5, 0)))
	model.Parent = parent
	root:SetNetworkOwner(nil) -- 서버가 직접 움직이게 해서 끊김 방지

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { model }

	local self = setmetatable({
		model = model,
		humanoid = humanoid,
		root = root,
		head = head,
		route = route,
		routeIndex = 1,
		alertLabel = createAlertLabel(head),
		rayParams = rayParams,
	}, Guard)
	return self
end

-- 캐릭터가 보이는지와 거리를 돌려준다.
function Guard:canSee(character: Model): (boolean, number)
	local targetRoot = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		return false, math.huge
	end

	local eye = self.head.Position
	local offset = targetRoot.Position - eye
	local distance = offset.Magnitude

	-- 1) 거리
	if distance > Config.Guard.ViewDistance then
		return false, distance
	end

	-- 2) 시야각: 정면 방향과 대상 방향 사이의 각도
	local cosHalfAngle = math.cos(math.rad(Config.Guard.ViewAngle / 2))
	if self.root.CFrame.LookVector:Dot(offset.Unit) < cosHalfAngle then
		return false, distance
	end

	-- 3) 벽 가림: 눈에서 대상까지 레이를 쏴서 중간에 다른 물체가 있는지
	local hit = workspace:Raycast(eye, offset, self.rayParams)
	if hit and not hit.Instance:IsDescendantOf(character) then
		return false, distance
	end

	return true, distance
end

-- 매 프레임 호출. target이 있으면 멈춰서 그쪽을 보고, 없으면 순찰을 계속한다.
function Guard:update(target: Vector3?, alertText: string)
	self.alertLabel.Text = alertText

	local position = self.root.Position

	if target then
		self.humanoid:MoveTo(position)
		local lookAt = Vector3.new(target.X, position.Y, target.Z)
		if (lookAt - position).Magnitude > 0.1 then
			self.root.CFrame = CFrame.lookAt(position, lookAt)
		end
		return
	end

	local waypoint = self.route[self.routeIndex]
	if Vector3.new(waypoint.X - position.X, 0, waypoint.Z - position.Z).Magnitude < 2 then
		self.routeIndex = self.routeIndex % #self.route + 1
		waypoint = self.route[self.routeIndex]
	end
	self.humanoid:MoveTo(waypoint)
end

return Guard
