-- 클라이언트 진입점: 속도 숫자에 맞춰 달리기 속도 조절, 동물에게 맞으면 날아가기,
-- 러닝머신 위에 서 있으면 제자리에서 달리는 동작
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local knockback = ReplicatedStorage:WaitForChild("Knockback") :: RemoteEvent

local function updateWalkSpeed()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.walkSpeedFor(player:GetAttribute("Speed") or 0)
	end
end

player:GetAttributeChangedSignal("Speed"):Connect(updateWalkSpeed)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	updateWalkSpeed()
end)
updateWalkSpeed()

-- 캐릭터 물리는 내 컴퓨터가 담당하므로 날려 보내는 것도 여기서 한다
knockback.OnClientEvent:Connect(function(velocity: Vector3)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		root.AssemblyLinearVelocity = velocity
	end
end)

--------------------------------------------------------------------------------
-- 러닝머신: 가만히 서 있어도 달리는 동작
--------------------------------------------------------------------------------

local runTrack: AnimationTrack? = nil
local trackOwner: Model? = nil

-- 캐릭터에 들어 있는 기본 달리기 애니메이션을 가져온다
local function getRunTrack(character: Model, humanoid: Humanoid): AnimationTrack?
	if trackOwner == character and runTrack then
		return runTrack
	end
	local animate = character:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local animation = run and run:FindFirstChildOfClass("Animation")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animation or not animator then
		return nil
	end
	runTrack = animator:LoadAnimation(animation)
	trackOwner = character
	if runTrack then
		runTrack.Priority = Enum.AnimationPriority.Action
		runTrack.Looped = true
	end
	return runTrack
end

local function isOnTreadmill(position: Vector3): boolean
	local base = workspace:FindFirstChild("Base")
	if not base then
		return false
	end
	for _, belt in base:GetChildren() do
		if belt.Name == "Treadmill" and belt:IsA("BasePart") then
			local offset = position - belt.Position
			if math.abs(offset.X) <= belt.Size.X / 2 and math.abs(offset.Z) <= belt.Size.Z / 2 and offset.Y < 6 then
				return true
			end
		end
	end
	return false
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or not root then
		return
	end

	local shouldRun = isOnTreadmill(root.Position) and humanoid.MoveDirection.Magnitude < 0.1
	local track = getRunTrack(character, humanoid)
	if not track then
		return
	end
	if shouldRun and not track.IsPlaying then
		track:Play(0.2, 1, 1.5)
	elseif not shouldRun and track.IsPlaying then
		track:Stop(0.2)
	end
end)

print(`[{Config.GameName}] 클라이언트 시작!`)
