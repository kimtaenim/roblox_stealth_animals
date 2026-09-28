# Stealth Animals (Roblox)

농장에 몰래 들어가 동물을 훔쳐 내 기지에 모으는 로블록스 스텔스 게임.

- 농장에서 동물(닭 🐔 / 돼지 🐷 / 소 🐮)에게 다가가 **E를 길게** 눌러 훔치기
- 머리에 이고 **내 기지**까지 운반 → 기지의 동물이 **초당 코인**을 생산
- **농부**가 순찰 중! 시야에 걸리면 발각 게이지가 차고, 가득 차면 동물을 놓치고 처음으로
- **왼쪽 Ctrl** 살금살금: 느리지만 잘 안 들킴. 건초더미 뒤에 숨기

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
   - 스폰 앞쪽(+Z)에 농장, 뒤쪽에 기지가 생깁니다

> ⚠️ Rojo는 `src/` 폴더의 **스크립트만** 동기화합니다. 맵·모델(파트, 지형 등)은 Studio에서 직접 만들고
> Studio 파일(.rbxl)로 저장하세요. 스크립트는 Studio에서 고치지 말고 `src/` 파일을 고쳐야 덮어써지지 않습니다.

## 폴더 구조

| 파일/폴더 | Studio 위치 | 용도 |
|---|---|---|
| `src/server/` | ServerScriptService.Server | 서버 로직 (`*.server.luau`) |
| `src/client/` | StarterPlayer.StarterPlayerScripts.Client | 클라이언트 로직 (`*.client.luau`) |
| `src/shared/` | ReplicatedStorage.Shared | 공용 모듈 (`*.luau`, ModuleScript) |
| `src/shared/Config.luau` | — | **게임 조정값** (속도, 동물 수입, 농부 시야, 위치 등) |
| `default.project.json` | — | Rojo 매핑 설정 |
| `rokit.toml` | — | 도구 버전 |

## 로드맵 (초안)

- [x] 프로젝트 뼈대 + Rojo 동기화 + 살금살금 이동
- [x] 농장/기지 자동 생성, 동물 훔치기 → 운반 → 기지 보관 → 코인 생산
- [x] 농부 순찰 + 시야(거리·각도·벽 가림) 판정 + 발각 게이지
- [ ] 코인으로 업그레이드 (이동 속도, 기지 확장, 운반량)
- [ ] 저장 (DataStore) — 다시 들어와도 동물·코인 유지
- [ ] 경비견 🐕, 더 비싼 동물 (말, 양 …)
- [ ] 다른 플레이어 기지에서 훔치기
- [ ] Studio에서 직접 꾸민 농장 맵으로 교체
