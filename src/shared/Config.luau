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
	PerDigit = 7, -- 속도가 10배 될 때마다 늘어나는 WalkSpeed
	MaxWalkSpeed = 110,
}

function Config.walkSpeedFor(speed: number): number
	local m = Config.Movement
	return math.min(m.BaseWalkSpeed + m.PerDigit * math.log10(1 + math.max(speed, 0)), m.MaxWalkSpeed)
end

--------------------------------------------------------------------------------
-- 러닝머신 (레벨별 초당 속도 증가량과 업그레이드 비용은 자유롭게 바꿔도 된다)
--------------------------------------------------------------------------------
Config.Treadmill = {
	BeltSpeed = 10, -- 벨트가 뒤로 미는 속도. 달리지 않으면 밀려서 떨어진다.
	Levels = {
		{ Gain = 1, Cost = 0 }, -- 레벨 1 (처음)
		{ Gain = 3, Cost = 100 },
		{ Gain = 10, Cost = 1_000 },
		{ Gain = 40, Cost = 10_000 },
		{ Gain = 150, Cost = 100_000 },
		{ Gain = 500, Cost = 1_000_000 }, -- 레벨 6 (최고)
	},
}

--------------------------------------------------------------------------------
-- 에그 등급
--------------------------------------------------------------------------------
-- RewardFraction: 그 지역 코스믹 보상의 몇 배를 주는지 (코스믹 = 1)
-- RespawnTime: 훔쳐간 뒤 같은 자리에 새 에그가 나타나기까지 (초)
Config.Rarities = {
	{
		Id = "Common",
		Name = "일반",
		Color = Color3.fromRGB(180, 180, 180),
		HatchTime = 5,
		RewardFraction = 0.001,
		RespawnTime = 5,
	},
	{
		Id = "Uncommon",
		Name = "드문",
		Color = Color3.fromRGB(90, 200, 90),
		HatchTime = 30,
		RewardFraction = 0.003,
		RespawnTime = 10,
	},
	{
		Id = "Rare",
		Name = "희귀",
		Color = Color3.fromRGB(70, 140, 255),
		HatchTime = 180,
		RewardFraction = 0.01,
		RespawnTime = 20,
	},
	{
		Id = "Epic",
		Name = "에픽",
		Color = Color3.fromRGB(170, 80, 230),
		HatchTime = 300,
		RewardFraction = 0.03,
		RespawnTime = 30,
	},
	{
		Id = "Legendary",
		Name = "전설",
		Color = Color3.fromRGB(255, 170, 30),
		HatchTime = 600,
		RewardFraction = 0.08,
		RespawnTime = 45,
	},
	{
		Id = "Mythic",
		Name = "신화",
		Color = Color3.fromRGB(240, 60, 60),
		HatchTime = 1800,
		RewardFraction = 0.2,
		RespawnTime = 60,
	},
	{
		Id = "Secret",
		Name = "비밀",
		Color = Color3.fromRGB(35, 35, 35),
		HatchTime = 2400,
		RewardFraction = 0.5,
		RespawnTime = 90,
	},
	{
		Id = "Cosmic",
		Name = "코스믹",
		Color = Color3.fromRGB(255, 100, 220),
		HatchTime = 3600,
		RewardFraction = 1,
		RespawnTime = 120,
		Neon = true,
	},
}

--------------------------------------------------------------------------------
-- 지역 (위에서부터 1번 지역). RequiredSpeed = 들어가는 데 필요한 속도
--------------------------------------------------------------------------------
Config.Regions = {
	{
		Id = "Forest",
		Name = "숲",
		Emoji = "🌲",
		RequiredSpeed = 0,
		Cosmic = { Speed = 50_000, Money = 100_000 },
		GroundColor = Color3.fromRGB(90, 150, 70),
		-- 등급별로 부화하는 동물 (Kind = AnimalFactory 모양 이름)
		Animals = {
			Common = { Kind = "Rabbit", Name = "토끼" },
			Uncommon = { Kind = "Boar", Name = "멧돼지" },
			Rare = { Kind = "Fox", Name = "여우" },
			Epic = { Kind = "Deer", Name = "사슴" },
			Legendary = { Kind = "Wolf", Name = "늑대" },
			Mythic = { Kind = "Bear", Name = "곰" },
			Secret = { Kind = "Unicorn", Name = "유니콘" },
			Cosmic = { Kind = "CosmicStag", Name = "우주 사슴" },
		},
		-- 에그를 들고 있으면 쫓아와서 때리는 동물
		Chasers = { "Wolf", "Wolf", "Bear" },
		ChaserSpeed = 24,
	},
	-- 아래 지역들은 아직 맵을 만들지 않았다 (BuiltRegionCount 참고). 보상은 확정, 필요 속도는 임시값.
	{
		Id = "Desert",
		Name = "사막",
		Emoji = "🏜️",
		RequiredSpeed = 5_000,
		Cosmic = { Speed = 100_000, Money = 1_000_000 },
	},
	{
		Id = "Jungle",
		Name = "정글",
		Emoji = "🌴",
		RequiredSpeed = 50_000,
		Cosmic = { Speed = 10_000_000, Money = 10_000_000 },
	},
	{
		Id = "DeepSea",
		Name = "심해",
		Emoji = "🌊",
		RequiredSpeed = 5_000_000,
		Cosmic = { Speed = 100_000_000, Money = 10_000_000 },
	},
	{
		Id = "StoneAge",
		Name = "석기시대",
		Emoji = "🪨",
		RequiredSpeed = 50_000_000,
		Boss = "망치를 든 원시인",
		Cosmic = { Speed = 1_000_000_000, Money = 10_000_000 },
	},
	{
		Id = "Spring",
		Name = "봄",
		Emoji = "🌸",
		RequiredSpeed = 500_000_000,
		Boss = "구미호",
		Cosmic = { Speed = 10_000_000_000, Money = 10_000_000 },
	},
}

Config.BuiltRegionCount = 1 -- 지금은 숲만 만든다

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
	PlotSize = 28,
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
}

Config.Chaser = {
	AggroRange = 50, -- 에그를 든 플레이어를 알아채는 거리
	LeashMargin = 20, -- 지역 밖으로 이만큼 나가면 포기하고 돌아감
	HitRange = 5,
	HitCooldown = 1.5,
	KnockbackHorizontal = 90,
	KnockbackVertical = 60,
}

return Config
