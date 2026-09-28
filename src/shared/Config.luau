-- 서버와 클라이언트가 함께 쓰는 게임 설정값
-- 좌표는 Baseplate 기준. 스폰 지점(0, 0, 0)에서 +Z 방향이 농장, -Z 방향이 플레이어 기지.
local Config = {
	GameName = "Stealth Animals",

	-- 플레이어 이동
	WalkSpeed = 16,
	SneakSpeed = 8, -- 살금살금 모드 속도
	SneakKey = Enum.KeyCode.LeftControl,
	CarrySpeedMultiplier = 0.75, -- 동물을 들고 있을 때 속도 배율

	-- 훔칠 수 있는 동물. Income = 기지에 있을 때 초당 버는 코인
	Animals = {
		Chicken = { DisplayName = "닭", Emoji = "🐔", Income = 1, StealTime = 0.5 },
		Pig = { DisplayName = "돼지", Emoji = "🐷", Income = 3, StealTime = 1 },
		Cow = { DisplayName = "소", Emoji = "🐮", Income = 6, StealTime = 1.5 },
	},

	Farm = {
		Center = Vector3.new(0, 0, 120),
		Width = 100, -- X 방향 크기
		Depth = 80, -- Z 방향 크기 (z 80 ~ 160)
		RespawnTime = 10, -- 훔쳐간 자리에 새 동물이 나타나기까지 (초)

		-- 입구(앞쪽)에 가까울수록 싸고, 깊숙할수록 비싼 동물
		AnimalSpots = {
			{ Kind = "Chicken", Position = Vector3.new(-15, 0, 100) },
			{ Kind = "Chicken", Position = Vector3.new(-8, 0, 104) },
			{ Kind = "Chicken", Position = Vector3.new(12, 0, 102) },
			{ Kind = "Pig", Position = Vector3.new(-12, 0, 120) },
			{ Kind = "Pig", Position = Vector3.new(14, 0, 122) },
			{ Kind = "Cow", Position = Vector3.new(-12, 0, 152) },
			{ Kind = "Cow", Position = Vector3.new(12, 0, 152) },
		},

		-- 숨을 수 있는 건초더미 위치
		HayBales = {
			Vector3.new(0, 0, 112),
			Vector3.new(-22, 0, 128),
			Vector3.new(22, 0, 132),
			Vector3.new(0, 0, 138),
		},
	},

	Base = {
		-- 플레이어마다 기지 하나 (최대 4명)
		PlotCenters = {
			Vector3.new(-60, 0, -40),
			Vector3.new(-20, 0, -40),
			Vector3.new(20, 0, -40),
			Vector3.new(60, 0, -40),
		},
		PlotColors = {
			Color3.fromRGB(90, 150, 230),
			Color3.fromRGB(230, 110, 110),
			Color3.fromRGB(120, 200, 120),
			Color3.fromRGB(230, 190, 80),
		},
		PlotSize = 30,
	},

	World = {
		FenceHeight = 3,
		FenceGap = 12, -- 울타리 입구 폭
	},

	-- 농부(경비)
	Guard = {
		WalkSpeed = 10,
		ViewDistance = 40, -- 볼 수 있는 최대 거리 (스터드)
		ViewAngle = 90, -- 시야각 (정면 기준 전체 각도, 도)

		-- 순찰 경로 하나당 농부 한 명. 경로를 추가하면 농부도 늘어난다.
		PatrolRoutes = {
			{
				Vector3.new(-35, 0, 95),
				Vector3.new(35, 0, 95),
				Vector3.new(35, 0, 145),
				Vector3.new(-35, 0, 145),
			},
		},
	},

	Detection = {
		BaseRate = 0.5, -- 보이는 동안 초당 차오르는 양 (1이면 가득). 가까울수록 최대 2배
		SneakMultiplier = 0.4, -- 살금살금/가만히 있을 때 차오르는 속도 배율
		DecayPerSecond = 0.25, -- 안 보일 때 초당 줄어드는 양
		AlertThreshold = 0.5, -- 이 값 이상이면 농부 머리 위가 "?" 에서 "!" 로 바뀜
	},
}

return Config
