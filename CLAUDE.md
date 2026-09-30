# CLAUDE.md

Roblox 게임 "Stealth Animals": 출발선 안 기지에서 러닝머신으로 속도를 올리고, 지역(숲→사막→정글→심해→석기시대→봄)에서 에그를 훔쳐 와 부화시키고, 인덱스의 "모두 받기"로 속도·돈을 얻는다. 에그를 든 플레이어는 지역 동물이 쫓아와 때려서 날려 보낸다. 사용자는 한국어로 소통하며 로블록스 개발 입문자입니다 — 설명은 한국어로, 쉽게.

## 구조
- Rojo 7 프로젝트. 매핑은 `default.project.json`.
- `src/server/*.server.luau` → ServerScriptService.Server
- `src/client/*.client.luau` → StarterPlayer.StarterPlayerScripts.Client
- `src/shared/*.luau` → ReplicatedStorage.Shared (ModuleScript)
- 맵/모델/파트는 Rojo로 관리하지 않음. 현재 기지·지역·동물·에그는 코드가 생성. 사용자가 Studio에서 맵을 꾸미면 그쪽을 `WaitForChild`로 찾도록 전환.
- 서버 모듈: `Main.server`(게임 흐름), `World`(맵), `AnimalFactory`(동물·에그 모델), `Chaser`(둥지 지키는 동물·보스: 추격, 떨어진 에그 회수), `PlayerStats`(속도·돈·러닝머신 레벨), `DayNight`(낮/밤, workspace 속성 `IsNight`/`PhaseEndsAt`), `Sounds`(Config.Sounds 재생), `Pets`(부화한 동물이 기지를 돌아다님, 보상 받음 여부), `SaveData`(DataStore 저장/불러오기, 불러오기 실패 시 저장 안 함). 클라이언트: `Main.client`(WalkSpeed·넉백), `HUD.client`(UI·인덱스). 공용: `Config`, `Format`(숫자 k/m/b 표기).
- RemoteEvent: `Notify`(서버→클라 메시지), `Knockback`(서버→클라, 캐릭터 물리는 클라가 소유), `ClaimAll`(클라→서버). 상태는 Player 속성(`Speed`, `Money`, `TreadmillLevel`, `Carrying`, `PendingSpeed`, `PendingMoney`, `Index_<지역>_<등급>`).
- 지역은 `Config.Regions` 데이터로 정의 (Animals/Chasers/Boss/Decor). 에그 등급은 훔칠 때 `Weight`로 랜덤. 부화 자리(pad)는 empty ↔ hatching 만. 부화하면 Pets 로 넘어가 기지를 돌아다니고, '모두 받기'로 claimed 처리 (동물은 남음). 지키는 동물은 지역당 1마리, 둥지 반경(NestKeepOut) 안으로는 안 들어감. 지역 입장 제한 없음 (RecommendedSpeed 는 표지판용).

## 규칙
- 언어는 Luau. 타입 주석 사용 권장, 문자열 보간(``` `{x}` ```) 사용.
- 게임 로직의 권한은 서버에 둔다(발각 판정, 점수 등). 클라이언트는 입력/연출만. 클라이언트↔서버 통신은 RemoteEvent, 서버에서 입력 검증.
- 조정값(속도, 시야각 등)은 `src/shared/Config.luau`에 모은다.
- 포맷: `stylua src`, 린트: `selene src`, 타입 검사: `rojo sourcemap -o sourcemap.json` 후 `luau-lsp analyze --definitions=<globalTypes.d.luau> --sourcemap=sourcemap.json src` (도구가 설치된 경우).
- 사용자는 이 컨테이너가 아닌 로컬 Studio에서 테스트하므로, 변경 후 Studio에서 무엇을 확인하면 되는지 안내할 것.
