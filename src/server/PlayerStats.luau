-- 플레이어별 속도·돈·러닝머신 레벨.
-- 값은 여기서 관리하고, 화면 표시용으로 Player 속성(Speed, Money, TreadmillLevel)과 순위표에 복사한다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)

local PlayerStats = {}

export type Data = {
	speed: number,
	money: number,
	treadmillLevel: number,
	speedDisplay: StringValue,
	moneyDisplay: StringValue,
	dirty: boolean,
}

local dataOf: { [Player]: Data } = {}

export type Saved = { speed: number?, money: number?, treadmillLevel: number? }

-- saved: 저장돼 있던 값 (없으면 처음부터)
function PlayerStats.add(player: Player, saved: Saved?)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local speedDisplay = Instance.new("StringValue")
	speedDisplay.Name = "속도"
	speedDisplay.Parent = leaderstats
	local moneyDisplay = Instance.new("StringValue")
	moneyDisplay.Name = "돈"
	moneyDisplay.Parent = leaderstats
	leaderstats.Parent = player

	dataOf[player] = {
		speed = (saved and saved.speed) or 0,
		money = (saved and saved.money) or 0,
		treadmillLevel = (saved and saved.treadmillLevel) or 1,
		speedDisplay = speedDisplay,
		moneyDisplay = moneyDisplay,
		dirty = true,
	}
	PlayerStats.flush()
end

-- 저장할 값
function PlayerStats.snapshot(player: Player): Saved?
	local data = dataOf[player]
	if not data then
		return nil
	end
	return { speed = data.speed, money = data.money, treadmillLevel = data.treadmillLevel }
end

function PlayerStats.remove(player: Player)
	dataOf[player] = nil
end

function PlayerStats.get(player: Player): Data?
	return dataOf[player]
end

function PlayerStats.addSpeed(player: Player, amount: number)
	local data = dataOf[player]
	if data then
		data.speed += amount
		data.dirty = true
	end
end

function PlayerStats.addMoney(player: Player, amount: number)
	local data = dataOf[player]
	if data then
		data.money += amount
		data.dirty = true
	end
end

-- 돈이 충분하면 쓰고 true
function PlayerStats.spend(player: Player, amount: number): boolean
	local data = dataOf[player]
	if not data or data.money < amount then
		return false
	end
	data.money -= amount
	data.dirty = true
	return true
end

function PlayerStats.setTreadmillLevel(player: Player, level: number)
	local data = dataOf[player]
	if data then
		data.treadmillLevel = level
		data.dirty = true
	end
end

-- 바뀐 값만 속성/순위표에 반영 (러닝머신은 매 프레임 바뀌므로 자주 부르지 않는다)
function PlayerStats.flush()
	for player, data in dataOf do
		if data.dirty then
			data.dirty = false
			player:SetAttribute("Speed", data.speed)
			player:SetAttribute("Money", data.money)
			player:SetAttribute("TreadmillLevel", data.treadmillLevel)
			data.speedDisplay.Value = Format.number(data.speed)
			data.moneyDisplay.Value = Format.number(data.money)
		end
	end
end

return PlayerStats
