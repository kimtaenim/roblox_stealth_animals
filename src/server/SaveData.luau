-- 저장/불러오기 (DataStore).
-- Studio에서 테스트하려면: 게임을 Roblox에 게시(Publish)한 뒤
-- 홈 → 게임 설정 → 보안 → "Studio의 API 서비스 액세스 사용"을 켜야 한다.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SaveData = {}

-- 저장하는 내용
export type Data = {
	speed: number?,
	money: number?,
	treadmillLevel: number?,
	index: { string }?, -- 잠금 해제한 인덱스 ("Forest_Common" 등)
	pets: { { r: number, k: number, c: boolean } }?, -- 기지 동물 (지역, 등급, 보상 받았는지)
	eggs: { { r: number, k: number, p: number } }?, -- 부화 중인 에그 (지역, 등급, 진행)
}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Save.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn(`[저장] DataStore를 쓸 수 없어요: {result}`)
	end
end

local function keyFor(player: Player): string
	return `player_{player.UserId}`
end

-- 성공하면 (true, 데이터 또는 nil=처음 온 사람), 실패하면 (false, 에러 메시지)
function SaveData.load(player: Player): (boolean, any)
	local dataStore = store
	if not dataStore then
		return false, "DataStore 없음"
	end
	local ok, result = pcall(function()
		return dataStore:GetAsync(keyFor(player))
	end)
	if not ok then
		warn(`[저장] {player.Name} 불러오기 실패: {result}`)
	end
	return ok, result
end

function SaveData.save(player: Player, data: Data): boolean
	local dataStore = store
	if not dataStore then
		return false
	end
	local ok, err = pcall(function()
		dataStore:SetAsync(keyFor(player), data)
	end)
	if not ok then
		warn(`[저장] {player.Name} 저장 실패: {err}`)
	end
	return ok
end

return SaveData
