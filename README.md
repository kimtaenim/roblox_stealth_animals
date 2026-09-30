# Stealth Animals (Roblox)

러닝머신으로 속도를 올리고, 여러 지역에서 에그를 훔쳐 부화시키는 로블록스 게임.

- **출발선 안쪽이 내 기지** (초록 잔디 + 울퉁불퉁한 나무 울타리). 방벽이 있는 러닝머신 위에 **서 있기만 해도** 달리는 동작을 하며 속도(⚡)가 올라요
- 러닝머신은 돈(💰)으로 업그레이드, **최고 레벨 30**
- 기지와 6개 지역은 **가로로 넓고 경계선에서 바로 이어져요.** 속도가 낮아도 어느 지역이든 갈 수 있지만, 먼 지역 동물은 빨라서 도망치기 어려워요
- 지역마다 **에그 둥지**에 에그가 모여 있어요. **E를 길게** 눌러 훔치면 그때 **등급이 랜덤으로 공개**
- 지역마다 **지키는 동물 한 마리**(석기시대·봄은 보스)가 어슬렁거려요. 둥지 가까이는 오지 않지만, **그 지역 에그를 훔치면 어디 있든 바로 쫓아와요**. **맞으면 날아가고 에그를 떨어뜨리고, 동물이 에그를 둥지로 다시 가져가요**
- 기지로 가져오면 부화 → 부화한 동물은 **기지 안을 돌아다니고** 머리 위에 보상 숫자 → **인덱스 → ✔ 모두 받기**로 속도·돈 획득
- 기지에는 최대 **40마리**가 돌아다녀요. 새로 부화하면 기지로 오고, 넘치면 **가장 약한 녀석이 🎒 인벤토리**로 가요. **🐾 펫 → ⭐ 최고 장비**를 누르면 가장 강한 40마리가 기지에 남아요
- **10분마다 밤**(3분)이 되고, 밤에는 부화가 **30배** 빨라요
- **자동 저장**: 속도·돈·러닝머신 레벨·인덱스·기지 동물·인벤토리·부화 중인 에그

| 등급 | 일반 | 드문 | 희귀 | 에픽 | 전설 | 신화 | 비밀 | 코스믹 |
|---|---|---|---|---|---|---|---|---|
| 부화 시간 | 5초 | 30초 | 3분 | 5분 | 10분 | 30분 | 40분 | 1시간 |
| 확률 | 50% | 25% | 12% | 7% | 3.5% | 1.5% | 0.7% | 0.3% |

| 지역 | 코스믹 보상 (속도 / 돈) | 보스 | 상태 |
|---|---|---|---|
| 🌲 숲 | 50k / 100k | | ✅ 만듦 |
| 🏜️ 사막 | 100k / 1m | | ✅ 만듦 |
| 🌴 정글 | 10m / 10m | | ✅ 만듦 |
| 🌊 심해 | 100m / 10m | | ✅ 만듦 |
| 🪨 석기시대 | 1b / 10m | 망치를 든 원시인 | ✅ 만듦 |
| 🌸 봄 | 10b / 10m | 구미호 | ✅ 만듦 |

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

**바탕화면의 `Stealth Animals 시작` 아이콘을 더블클릭**하면 아래 1~3번을 자동으로 해 줍니다 (`start.bat`).
그다음 Studio에서 **Rojo → Connect** 만 누르면 됩니다.

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

- [x] 기지(출발선·러닝머신 30단계·부화 자리 16칸)
- [x] 6개 지역 + 에그 둥지 + 보스(석기시대·봄)
- [x] 훔치면 랜덤 등급 공개, 맞으면 에그 떨어뜨림 → 동물이 둥지로 가져감
- [x] 낮/밤 (밤에 부화 30배), 효과음
- [x] 저장 (DataStore) — Studio에서는 게시 + API 서비스 액세스 설정 필요
- [ ] 효과음을 Creator Store의 더 어울리는 소리로 교체
