# Stealth Animals (Roblox)

동물이 되어 몰래 숨어다니는 로블록스 게임.

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
   - **왼쪽 Ctrl** 을 누르고 있으면 살금살금 느리게 걷습니다

> ⚠️ Rojo는 `src/` 폴더의 **스크립트만** 동기화합니다. 맵·모델(파트, 지형 등)은 Studio에서 직접 만들고
> Studio 파일(.rbxl)로 저장하세요. 스크립트는 Studio에서 고치지 말고 `src/` 파일을 고쳐야 덮어써지지 않습니다.

## 폴더 구조

| 파일/폴더 | Studio 위치 | 용도 |
|---|---|---|
| `src/server/` | ServerScriptService.Server | 서버 로직 (`*.server.luau`) |
| `src/client/` | StarterPlayer.StarterPlayerScripts.Client | 클라이언트 로직 (`*.client.luau`) |
| `src/shared/` | ReplicatedStorage.Shared | 공용 모듈 (`*.luau`, ModuleScript) |
| `default.project.json` | — | Rojo 매핑 설정 |
| `rokit.toml` | — | 도구 버전 |

## 로드맵 (초안)

- [x] 프로젝트 뼈대 + Rojo 동기화 + 살금살금 이동
- [ ] 동물 캐릭터 선택 (고양이, 여우, 쥐 …)
- [ ] 경비 NPC와 시야(시야각/거리/벽 가림) 판정
- [ ] 발각 게이지 & 잡히면 리스폰
- [ ] 숨을 곳(풀숲, 상자) 들어가기
- [ ] 목표물 훔치고 탈출 → 라운드 종료
