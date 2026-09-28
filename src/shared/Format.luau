-- 숫자·시간을 보기 좋게 바꾸는 함수들
local Format = {}

local SUFFIXES = { "", "k", "m", "b", "t", "qd" }

-- 1234 -> "1.2k", 10000000 -> "10m"
function Format.number(n: number): string
	local value = math.floor(n)
	local i = 1
	while math.abs(value) >= 1000 and i < #SUFFIXES do
		value /= 1000
		i += 1
	end
	if i == 1 then
		return tostring(value)
	end
	local text = string.format("%.1f", math.floor(value * 10) / 10)
	text = (text:gsub("%.0$", ""))
	return text .. SUFFIXES[i]
end

-- 남은 시간: 65 -> "1:05", 3600 -> "1:00:00"
function Format.countdown(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	local h = total // 3600
	local m = (total % 3600) // 60
	local s = total % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- 부화 시간 안내: 5 -> "5초", 180 -> "3분", 3600 -> "1시간"
function Format.duration(seconds: number): string
	if seconds >= 3600 and seconds % 3600 == 0 then
		return `{seconds // 3600}시간`
	elseif seconds >= 60 and seconds % 60 == 0 then
		return `{seconds // 60}분`
	end
	return `{seconds}초`
end

return Format
