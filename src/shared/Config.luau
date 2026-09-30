-- 서버와 클라이언트가 함께 쓰는 게임 설정값
-- 좌표는 Baseplate 기준. 스폰(0, 0, 0) 주변이 기지, +Z 방향으로 출발선을 넘으면 지역들이 차례로 나온다.
local Config = {}

Config.GameName = "Stealth Animals"

--------------------------------------------------------------------------------
-- 속도
--------------------------------------------------------------------------------
-- 속도 숫자가 클수록 실제로 빨리 달린다. 숫자가 너무 커지므로 log로 줄여서 WalkSpeed로 바꾼다.
Config.Movement = {
	BaseWalkSpeed = 16, -- 속도 0일 때
	PerDigit = 8, -- 속도가 10배 될 때마다 늘어나는 WalkSpeed
	MaxWalkSpeed = 120,
}

function Config.walkSpeedFor(speed: number): number
	local m = Config.Movement
	return math.min(m.BaseWalkSpeed + m.PerDigit * math.log10(1 + math.max(speed, 0)), m.MaxWalkSpeed)
end

--------------------------------------------------------------------------------
-- 러닝머신: 레벨별 초당 속도 증가량(Gain)과 업그레이드 비용(Cost). 숫자는 자유롭게 바꿔도 된다.
--------------------------------------------------------------------------------
Config.Treadmill = {
	BeltSpeed = 10, -- 벨트가 뒤로 미는 속도. 달리지 않으면 밀려서 떨어진다.
	WallColor = Color3.fromRGB(120, 230, 255), -- 방벽 색 (밝은 하늘색)
	Levels = {
		{ Gain = 1, Cost = 0 }, -- Lv.1 (처음)
		{ Gain = 2, Cost = 100 }, -- Lv.2
		{ Gain = 3, Cost = 180 }, -- Lv.3
		{ Gain = 4, Cost = 320 }, -- Lv.4
		{ Gain = 5, Cost = 580 }, -- Lv.5
		{ Gain = 8, Cost = 1_000 }, -- Lv.6
		{ Gain = 11, Cost = 1_900 }, -- Lv.7
		{ Gain = 17, Cost = 3_400 }, -- Lv.8
		{ Gain = 26, Cost = 6_100 }, -- Lv.9
		{ Gain = 38, Cost = 11_000 }, -- Lv.10
		{ Gain = 58, Cost = 20_000 }, -- Lv.11
		{ Gain = 86, Cost = 36_000 }, -- Lv.12
		{ Gain = 130, Cost = 64_000 }, -- Lv.13
		{ Gain = 190, Cost = 120_000 }, -- Lv.14
		{ Gain = 290, Cost = 210_000 }, -- Lv.15
		{ Gain = 440, Cost = 370_000 }, -- Lv.16
		{ Gain = 660, Cost = 670_000 }, -- Lv.17
		{ Gain = 990, Cost = 1_200_000 }, -- Lv.18
		{ Gain = 1_500, Cost = 2_200_000 }, -- Lv.19
		{ Gain = 2_200, Cost = 3_900_000 }, -- Lv.20
		{ Gain = 3_300, Cost = 7_100_000 }, -- Lv.21
		{ Gain = 5_000, Cost = 13_000_000 }, -- Lv.22
		{ Gain = 7_500, Cost = 23_000_000 }, -- Lv.23
		{ Gain = 11_000, Cost = 41_000_000 }, -- Lv.24
		{ Gain = 17_000, Cost = 74_000_000 }, -- Lv.25
		{ Gain = 25_000, Cost = 130_000_000 }, -- Lv.26
		{ Gain = 38_000, Cost = 240_000_000 }, -- Lv.27
		{ Gain = 57_000, Cost = 430_000_000 }, -- Lv.28
		{ Gain = 85_000, Cost = 780_000_000 }, -- Lv.29
		{ Gain = 130_000, Cost = 1_400_000_000 }, -- Lv.30 (최고)
	},
}

--------------------------------------------------------------------------------
-- 에그 등급
--------------------------------------------------------------------------------
-- Weight: 훔쳤을 때 이 등급이 나올 확률 비중 (클수록 잘 나옴)
-- RewardFraction: 그 지역 코스믹 보상의 몇 배를 주는지 (코스믹 = 1)
Config.Rarities = {
	{
		Id = "Common",
		Name = "일반",
		Color = Color3.fromRGB(180, 180, 180),
		HatchTime = 5,
		Weight = 50,
		RewardFraction = 0.001,
	},
	{
		Id = "Uncommon",
		Name = "드문",
		Color = Color3.fromRGB(90, 200, 90),
		HatchTime = 30,
		Weight = 25,
		RewardFraction = 0.003,
	},
	{
		Id = "Rare",
		Name = "희귀",
		Color = Color3.fromRGB(70, 140, 255),
		HatchTime = 180,
		Weight = 12,
		RewardFraction = 0.01,
	},
	{
		Id = "Epic",
		Name = "에픽",
		Color = Color3.fromRGB(170, 80, 230),
		HatchTime = 300,
		Weight = 7,
		RewardFraction = 0.03,
	},
	{
		Id = "Legendary",
		Name = "전설",
		Color = Color3.fromRGB(255, 170, 30),
		HatchTime = 600,
		Weight = 3.5,
		RewardFraction = 0.08,
	},
	{
		Id = "Mythic",
		Name = "신화",
		Color = Color3.fromRGB(240, 60, 60),
		HatchTime = 1800,
		Weight = 1.5,
		RewardFraction = 0.2,
	},
	{
		Id = "Secret",
		Name = "비밀",
		Color = Color3.fromRGB(35, 35, 35),
		HatchTime = 2400,
		Weight = 0.7,
		RewardFraction = 0.5,
	},
	{
		Id = "Cosmic",
		Name = "코스믹",
		Color = Color3.fromRGB(255, 100, 220),
		HatchTime = 3600,
		Weight = 0.3,
		RewardFraction = 1,
		Neon = true,
	},
}

Config.Egg = {
	Color = Color3.fromRGB(250, 240, 215), -- 훔치기 전 에그 색 (등급을 모름)
	NestSize = 10, -- 지역마다 둥지에 모여 있는 에그 수
	RespawnTime = 8, -- 에그를 기지로 가져간 뒤 둥지에 새 에그가 생기기까지 (초)
}

--------------------------------------------------------------------------------
-- 낮과 밤: 밤에는 부화가 빨라진다
--------------------------------------------------------------------------------
Config.DayNight = {
	DayLength = 600, -- 낮 10분
	NightLength = 180, -- 밤 3분
	NightHatchMultiplier = 30,
}

--------------------------------------------------------------------------------
-- 효과음. Roblox Creator Store(도구 상자 → 오디오)에서 마음에 드는 소리의 ID를 찾아
-- "rbxassetid://숫자" 로 바꿔 넣으면 된다. "" 로 두면 소리가 나지 않는다.
--------------------------------------------------------------------------------
Config.Sounds = {
	Steal = "rbxasset://sounds/electronicpingshort.wav", -- 에그 훔칠 때
	ChaseStart = "rbxasset://sounds/unsheath.wav", -- 동물이 쫓아오기 시작할 때
	Hit = "rbxasset://sounds/swordslash.wav", -- 맞아서 에그를 떨어뜨릴 때
	Hatch = "rbxasset://sounds/electronicpingshort.wav", -- 부화할 때
	Volume = 1,
}

--------------------------------------------------------------------------------
-- 지역 (위에서부터 1번 지역). RequiredSpeed = 들어가는 데 필요한 속도
--------------------------------------------------------------------------------
-- Animals: 등급별로 부화하는 동물. Kind = AnimalFactory 모양 이름, Color/Neon 으로 색을 바꿀 수 있다.
-- Chasers: 에그를 들고 있으면 쫓아와서 때리는 동물. Boss: 더 크고 빠른 보스.
-- Decor: 꾸미기 종류 ("Tree", "Cactus", "Coral", "Rock")
Config.Regions = {
	{
		Id = "Forest",
		Name = "숲",
		Emoji = "🌲",
		RequiredSpeed = 0,
		Cosmic = { Speed = 50_000, Money = 100_000 },
		GroundColor = Color3.fromRGB(90, 150, 70),
		GroundMaterial = Enum.Material.Grass,
		Decor = { Kind = "Tree", Color = Color3.fromRGB(60, 130, 60) },
		Animals = {
			Common = { Kind = "Rabbit", Name = "토끼" },
			Uncommon = { Kind = "Boar", Name = "멧돼지" },
			Rare = { Kind = "Fox", Name = "여우" },
			Epic = { Kind = "Deer", Name = "사슴" },
			Legendary = { Kind = "Wolf", Name = "늑대" },
			Mythic = { Kind = "Bear", Name = "곰" },
			Secret = { Kind = "Unicorn", Name = "유니콘" },
			Cosmic = { Kind = "Deer", Name = "우주 사슴", Color = Color3.fromRGB(120, 60, 220), Neon = true },
		},
		Chasers = { { Kind = "Wolf" }, { Kind = "Wolf" }, { Kind = "Bear" } },
		ChaserSpeed = 20,
	},
	{
		Id = "Desert",
		Name = "사막",
		Emoji = "🏜️",
		RequiredSpeed = 5_000,
		Cosmic = { Speed = 100_000, Money = 1_000_000 },
		GroundColor = Color3.fromRGB(230, 200, 130),
		GroundMaterial = Enum.Material.Sand,
		Decor = { Kind = "Cactus", Color = Color3.fromRGB(70, 140, 70) },
		Animals = {
			Common = { Kind = "Lizard", Name = "도마뱀", Color = Color3.fromRGB(200, 170, 100) },
			Uncommon = { Kind = "Fox", Name = "사막여우", Color = Color3.fromRGB(235, 200, 140) },
			Rare = { Kind = "Bird", Name = "독수리", Color = Color3.fromRGB(110, 75, 45) },
			Epic = { Kind = "Camel", Name = "낙타" },
			Legendary = { Kind = "Wolf", Name = "코요테", Color = Color3.fromRGB(190, 150, 100) },
			Mythic = { Kind = "Camel", Name = "황금 낙타", Color = Color3.fromRGB(255, 200, 50), Neon = true },
			Secret = { Kind = "Unicorn", Name = "모래 유니콘", Color = Color3.fromRGB(240, 220, 170) },
			Cosmic = { Kind = "Camel", Name = "우주 낙타", Color = Color3.fromRGB(120, 60, 220), Neon = true },
		},
		Chasers = {
			{ Kind = "Wolf", Color = Color3.fromRGB(190, 150, 100) },
			{ Kind = "Wolf", Color = Color3.fromRGB(190, 150, 100) },
			{ Kind = "Camel" },
		},
		ChaserSpeed = 40,
	},
	{
		Id = "Jungle",
		Name = "정글",
		Emoji = "🌴",
		RequiredSpeed = 50_000,
		Cosmic = { Speed = 10_000_000, Money = 10_000_000 },
		GroundColor = Color3.fromRGB(50, 110, 50),
		GroundMaterial = Enum.Material.Grass,
		Decor = { Kind = "Tree", Color = Color3.fromRGB(30, 90, 40) },
		Animals = {
			Common = { Kind = "Lizard", Name = "개구리", Color = Color3.fromRGB(80, 200, 80) },
			Uncommon = { Kind = "Bird", Name = "앵무새", Color = Color3.fromRGB(230, 50, 50) },
			Rare = { Kind = "Fox", Name = "원숭이", Color = Color3.fromRGB(120, 80, 50) },
			Epic = { Kind = "Wolf", Name = "표범", Color = Color3.fromRGB(230, 200, 90) },
			Legendary = { Kind = "Wolf", Name = "호랑이", Color = Color3.fromRGB(240, 130, 30) },
			Mythic = { Kind = "Bear", Name = "고릴라", Color = Color3.fromRGB(45, 45, 50) },
			Secret = { Kind = "Bird", Name = "무지개 앵무새", Color = Color3.fromRGB(80, 220, 255), Neon = true },
			Cosmic = { Kind = "Wolf", Name = "우주 호랑이", Color = Color3.fromRGB(120, 60, 220), Neon = true },
		},
		Chasers = {
			{ Kind = "Wolf", Color = Color3.fromRGB(240, 130, 30) },
			{ Kind = "Wolf", Color = Color3.fromRGB(240, 130, 30) },
			{ Kind = "Bear", Color = Color3.fromRGB(45, 45, 50) },
		},
		ChaserSpeed = 50,
	},
	{
		Id = "DeepSea",
		Name = "심해",
		Emoji = "🌊",
		RequiredSpeed = 5_000_000,
		Cosmic = { Speed = 100_000_000, Money = 10_000_000 },
		GroundColor = Color3.fromRGB(30, 60, 110),
		GroundMaterial = Enum.Material.Sand,
		Decor = { Kind = "Coral" },
		Animals = {
			Common = { Kind = "Fish", Name = "흰동가리", Color = Color3.fromRGB(255, 140, 40) },
			Uncommon = { Kind = "Fish", Name = "복어", Color = Color3.fromRGB(240, 220, 90) },
			Rare = { Kind = "Lizard", Name = "바다거북", Color = Color3.fromRGB(60, 140, 90) },
			Epic = { Kind = "Fish", Name = "해파리", Color = Color3.fromRGB(255, 150, 220), Neon = true },
			Legendary = { Kind = "Fish", Name = "돌고래", Color = Color3.fromRGB(120, 150, 190) },
			Mythic = { Kind = "Fish", Name = "상어", Color = Color3.fromRGB(110, 120, 130), Scale = 1.5 },
			Secret = { Kind = "Fish", Name = "고래", Color = Color3.fromRGB(40, 60, 120), Scale = 2 },
			Cosmic = {
				Kind = "Fish",
				Name = "우주 고래",
				Color = Color3.fromRGB(120, 60, 220),
				Neon = true,
				Scale = 2,
			},
		},
		Chasers = {
			{ Kind = "Fish", Color = Color3.fromRGB(110, 120, 130), Scale = 2 },
			{ Kind = "Fish", Color = Color3.fromRGB(110, 120, 130), Scale = 2 },
			{ Kind = "Fish", Color = Color3.fromRGB(110, 120, 130), Scale = 2 },
		},
		ChaserSpeed = 65,
	},
	{
		Id = "StoneAge",
		Name = "석기시대",
		Emoji = "🪨",
		RequiredSpeed = 50_000_000,
		Cosmic = { Speed = 1_000_000_000, Money = 10_000_000 },
		GroundColor = Color3.fromRGB(140, 110, 80),
		GroundMaterial = Enum.Material.Ground,
		Decor = { Kind = "Rock" },
		Animals = {
			Common = { Kind = "Bird", Name = "도도새", Color = Color3.fromRGB(150, 150, 160) },
			Uncommon = { Kind = "Boar", Name = "원시 멧돼지" },
			Rare = { Kind = "Wolf", Name = "검치호", Color = Color3.fromRGB(210, 170, 110) },
			Epic = { Kind = "Bear", Name = "털코뿔소", Color = Color3.fromRGB(130, 120, 110) },
			Legendary = { Kind = "Mammoth", Name = "매머드" },
			Mythic = { Kind = "Lizard", Name = "공룡", Color = Color3.fromRGB(70, 150, 70), Scale = 2.5 },
			Secret = { Kind = "Mammoth", Name = "황금 매머드", Color = Color3.fromRGB(255, 200, 50), Neon = true },
			Cosmic = {
				Kind = "Lizard",
				Name = "우주 공룡",
				Color = Color3.fromRGB(120, 60, 220),
				Neon = true,
				Scale = 2.5,
			},
		},
		Chasers = { { Kind = "Wolf", Color = Color3.fromRGB(210, 170, 110) }, { Kind = "Mammoth" } },
		ChaserSpeed = 72,
		Boss = { Kind = "Caveman", Name = "망치를 든 원시인", Scale = 2, Speed = 80 },
	},
	{
		Id = "Spring",
		Name = "봄",
		Emoji = "🌸",
		RequiredSpeed = 500_000_000,
		Cosmic = { Speed = 10_000_000_000, Money = 10_000_000 },
		GroundColor = Color3.fromRGB(150, 210, 120),
		GroundMaterial = Enum.Material.Grass,
		Decor = { Kind = "Tree", Color = Color3.fromRGB(255, 180, 210) },
		Animals = {
			Common = { Kind = "Bird", Name = "병아리", Color = Color3.fromRGB(255, 230, 90) },
			Uncommon = { Kind = "Rabbit", Name = "분홍 토끼", Color = Color3.fromRGB(255, 190, 210) },
			Rare = { Kind = "Bird", Name = "백조", Color = Color3.fromRGB(250, 250, 250) },
			Epic = { Kind = "Deer", Name = "꽃사슴", Color = Color3.fromRGB(220, 150, 110) },
			Legendary = { Kind = "Bear", Name = "판다", Color = Color3.fromRGB(245, 245, 245) },
			Mythic = { Kind = "Unicorn", Name = "벚꽃 유니콘", Color = Color3.fromRGB(255, 200, 225) },
			Secret = { Kind = "NineTail", Name = "구미호", Color = Color3.fromRGB(250, 250, 250) },
			Cosmic = { Kind = "NineTail", Name = "우주 구미호", Color = Color3.fromRGB(120, 60, 220), Neon = true },
		},
		Chasers = { { Kind = "Fox" }, { Kind = "Fox" } },
		ChaserSpeed = 80,
		Boss = { Kind = "NineTail", Name = "구미호", Scale = 2.5, Speed = 90, Color = Color3.fromRGB(250, 250, 250) },
	},
}

Config.BuiltRegionCount = #Config.Regions

Config.MaxMoneyReward = 10_000_000 -- 에그 하나로 받을 수 있는 돈의 최대치

function Config.rewardFor(regionIndex: number, rarityIndex: number): (number, number)
	local cosmic = Config.Regions[regionIndex].Cosmic
	local fraction = Config.Rarities[rarityIndex].RewardFraction
	local speed = math.floor(cosmic.Speed * fraction)
	local money = math.min(math.floor(cosmic.Money * fraction), Config.MaxMoneyReward)
	return speed, money
end

--------------------------------------------------------------------------------
-- 맵 배치
--------------------------------------------------------------------------------
Config.Base = {
	Width = 140, -- X 방향
	Depth = 80, -- Z 방향 (z -40 ~ 40), z = 40 이 출발선
	PlotSize = 28, -- 부화 자리 16칸 (4 x 4)
	PlotCenters = {
		Vector3.new(-51, 0, -25),
		Vector3.new(-17, 0, -25),
		Vector3.new(17, 0, -25),
		Vector3.new(51, 0, -25),
	},
	PlotColors = {
		Color3.fromRGB(90, 150, 230),
		Color3.fromRGB(230, 110, 110),
		Color3.fromRGB(120, 200, 120),
		Color3.fromRGB(230, 190, 80),
	},
	TreadmillXs = { -45, -15, 15, 45 }, -- 러닝머신 위치 (z 2 ~ 18)
	UpgradeKiosk = Vector3.new(0, 0, 24),
}

Config.RegionLayout = {
	FirstStartZ = 100, -- 1번 지역이 시작되는 z
	Length = 200,
	Gap = 40, -- 지역 사이 간격
	Width = 100,
	NestOffset = 140, -- 지역 입구에서 둥지까지 거리
}

Config.Chaser = {
	AggroRange = 60, -- 에그를 든 플레이어를 알아채는 거리
	LeashMargin = 20, -- 지역 밖으로 이만큼 나가면 포기하고 돌아감
	HitRange = 5,
	HitCooldown = 1.5,
	KnockbackHorizontal = 90,
	KnockbackVertical = 60,
}

return Config
