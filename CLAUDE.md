# CLAUDE.md

Roblox 스텔스 게임 "Stealth Animals". 사용자는 한국어로 소통하며 로블록스 개발 입문자입니다 — 설명은 한국어로, 쉽게.

## 구조
- Rojo 7 프로젝트. 매핑은 `default.project.json`.
- `src/server/*.server.luau` → ServerScriptService.Server
- `src/client/*.client.luau` → StarterPlayer.StarterPlayerScripts.Client
- `src/shared/*.luau` → ReplicatedStorage.Shared (ModuleScript)
- 맵/모델/파트는 Rojo로 관리하지 않음 (사용자가 Studio에서 제작). 코드는 필요한 인스턴스를 `WaitForChild`로 찾거나 직접 생성.

## 규칙
- 언어는 Luau. 타입 주석 사용 권장, 문자열 보간(``` `{x}` ```) 사용.
- 게임 로직의 권한은 서버에 둔다(발각 판정, 점수 등). 클라이언트는 입력/연출만. 클라이언트↔서버 통신은 RemoteEvent, 서버에서 입력 검증.
- 조정값(속도, 시야각 등)은 `src/shared/Config.luau`에 모은다.
- 포맷: `stylua src`, 린트: `selene src` (도구가 설치된 경우).
- 사용자는 이 컨테이너가 아닌 로컬 Studio에서 테스트하므로, 변경 후 Studio에서 무엇을 확인하면 되는지 안내할 것.
