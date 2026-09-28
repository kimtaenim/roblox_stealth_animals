# CLAUDE.md

Roblox 스텔스 게임 "Stealth Animals": 농장에서 동물을 훔쳐 자기 기지로 운반하면 동물이 코인을 생산한다. 농부(경비 NPC)가 순찰하며 시야로 감지. 사용자는 한국어로 소통하며 로블록스 개발 입문자입니다 — 설명은 한국어로, 쉽게.

## 구조
- Rojo 7 프로젝트. 매핑은 `default.project.json`.
- `src/server/*.server.luau` → ServerScriptService.Server
- `src/client/*.client.luau` → StarterPlayer.StarterPlayerScripts.Client
- `src/shared/*.luau` → ReplicatedStorage.Shared (ModuleScript)
- 맵/모델/파트는 Rojo로 관리하지 않음. 현재 농장·기지·동물·농부는 코드가 생성(`World`, `AnimalFactory`, `Guard`). 사용자가 Studio에서 맵을 꾸미면 그쪽을 `WaitForChild`로 찾도록 전환.
- 서버 모듈: `Main.server`(게임 흐름), `World`(맵), `AnimalFactory`(동물 모델), `Guard`(농부 순찰/시야). 클라이언트: `Main.client`(이동 속도), `HUD.client`(UI). 서버→클라 메시지는 `ReplicatedStorage.Notify` RemoteEvent, 상태는 Player 속성(`Carrying`, `Detection`).

## 규칙
- 언어는 Luau. 타입 주석 사용 권장, 문자열 보간(``` `{x}` ```) 사용.
- 게임 로직의 권한은 서버에 둔다(발각 판정, 점수 등). 클라이언트는 입력/연출만. 클라이언트↔서버 통신은 RemoteEvent, 서버에서 입력 검증.
- 조정값(속도, 시야각 등)은 `src/shared/Config.luau`에 모은다.
- 포맷: `stylua src`, 린트: `selene src`, 타입 검사: `rojo sourcemap -o sourcemap.json` 후 `luau-lsp analyze --definitions=<globalTypes.d.luau> --sourcemap=sourcemap.json src` (도구가 설치된 경우).
- 사용자는 이 컨테이너가 아닌 로컬 Studio에서 테스트하므로, 변경 후 Studio에서 무엇을 확인하면 되는지 안내할 것.
