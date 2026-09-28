# Stealth Animals (Roblox)

러닝머신으로 속도를 올리고, 여러 지역에서 에그를 훔쳐 부화시키는 로블록스 게임.

- **출발선 안쪽이 내 기지.** 러닝머신 위에서 달리면 속도(⚡)가 올라요 (속도가 높을수록 실제로 더 빨리 달려요)
- 러닝머신은 돈(💰)으로 업그레이드, **최고 레벨 6**
- 출발선을 넘어 지역으로 가서 **E를 길게** 눌러 에그 훔치기 (에그 옆 표지판에 등급·부화 시간·보상)
- 에그를 들고 있으면 **동물이 쫓아와서 때리고, 맞으면 날아가요**
- 기지로 가져오면 부화 시작 → 부화하면 동물 위에 보상 숫자 → **인덱스 → 모두 받기**로 속도·돈 획득

| 등급 | 일반 | 드문 | 희귀 | 에픽 | 전설 | 신화 | 비밀 | 코스믹 |
|---|---|---|---|---|---|---|---|---|
| 부화 시간 | 5초 | 30초 | 3분 | 5분 | 10분 | 30분 | 40분 | 1시간 |

| 지역 | 코스믹 보상 (속도 / 돈) | 보스 | 상태 |
|---|---|---|---|
| 🌲 숲 | 50k / 100k | | ✅ 만듦 |
| 🏜️ 사막 | 100k / 1m | | 예정 |
| 🌴 정글 | 10m / 10m | | 예정 |
| 🌊 심해 | 100m / 10m | | 예정 |
| 🪨 석기시대 | 1b / 10m | 망치를 든 원시인 | 예정 |
| 🌸 봄 | 10b / 10m | 구미호 | 예정 |

돈 보상은 최대 10m. 다른 등급 보상은 코스믹 보상에 비율을 곱해서 정해요 (`Config.luau`의 `RewardFraction`).

코드는 **GitHub(이 저장소)** 에서 관리하고, **Rojo** 로 로컬 Roblox Studio에 실시간 동기화합니다.
Claude Code가 이 저장소의 코드를 수정 → 내 컴퓨터에서 `git pull` → Studio에 자동 반영되는 흐름입니다.

```
Claude Code ──push──▶ GitHub ──pull──▶ 내 컴퓨터(src/) ──Rojo──▶ Roblox Studio
```

## 처음 한 번만 하는 설정 (로컬 컴퓨터)

1. **Git 설치** 후 저장소 받기
   ```bash
   git clone https://github.com/kimtaenim/roblox_stealth_animals.git
   cd roblox_stealth_animals
   ```
2. **Rokit 설치** (Rojo 등 도구 관리자): https://github.com/rojo-rbx/rokit 의 설치 안내를 따른 뒤
   ```bash
   rokit install     # rokit.toml에 적힌 rojo, stylua, selene 설치
   ```
3. **Studio에 Rojo 플러그인 설치**
   ```bash
   rojo plugin install
   ```
   (또는 Roblox Creator Store에서 "Rojo" 플러그인 설치)
4. (선택) **VS Code** 로 열면 추천 확장(Rojo, Luau LSP, StyLua, Selene) 설치 안내가 뜹니다.

## 매일 작업하는 방법

1. 최신 코드 받기: `git pull`
2. Rojo 서버 켜기: `rojo serve`
3. Roblox Studio에서 새 Baseplate(또는 게임 파일) 열기 → **플러그인 탭 → Rojo → Connect**
4. ▶ Play 를 눌러 테스트
   - 출력(Output) 창에 `[Stealth Animals] 서버 시작!` 이 보이면 성공
   - 스폰 주변이 기지, 앞쪽(+Z) 출발선 너머에 숲 지역이 생깁니다

> ⚠️ Rojo는 `src/` 폴더의 **스크립트만** 동기화합니다. 맵·모델(파트, 지형 등)은 Studio에서 직접 만들고
> Studio 파일(.rbxl)로 저장하세요. 스크립트는 Studio에서 고치지 말고 `src/` 파일을 고쳐야 덮어써지지 않습니다.

## 폴더 구조

| 파일/폴더 | Studio 위치 | 용도 |
|---|---|---|
| `src/server/` | ServerScriptService.Server | 서버 로직 (`*.server.luau`) |
| `src/client/` | StarterPlayer.StarterPlayerScripts.Client | 클라이언트 로직 (`*.client.luau`) |
| `src/shared/` | ReplicatedStorage.Shared | 공용 모듈 (`*.luau`, ModuleScript) |
| `src/shared/Config.luau` | — | **게임 조정값** (러닝머신 레벨, 등급·부화 시간, 지역 보상, 위치 등) |
| `default.project.json` | — | Rojo 매핑 설정 |
| `rokit.toml` | — | 도구 버전 |

## 로드맵

- [x] 기지(출발선·러닝머신·부화 자리) + 숲 지역
- [x] 에그 훔치기 → 쫓아오는 동물(맞으면 날아감) → 부화 → 인덱스 모두 받기
- [x] 러닝머신 업그레이드 (레벨 1~6)
- [ ] 사막 · 정글 · 심해 지역
- [ ] 석기시대(보스: 망치를 든 원시인) · 봄(보스: 구미호)
- [ ] 저장 (DataStore) — 다시 들어와도 속도·돈·인덱스 유지
