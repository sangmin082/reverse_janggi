# 리버스 장기 — iOS

져야 이기는 장기. SwiftUI로 만든 네이티브 iOS 게임 ([리버스 체스](https://github.com/sangmin082/reverse_chess)의 장기판).

- Bundle ID: `com.reversejanggi.game`
- 오프라인 동작 · 데이터 수집 없음 (온라인 대전만 릴레이 서버 사용)
- 규칙 전문과 결정 근거: [RULES.md](./RULES.md) · 출시 체크리스트: [APP_STORE_PLAN.md](./APP_STORE_PLAN.md)

## 게임 규칙 요약

- **한이 선공.** 배치는 양쪽 모두 마상상마
- **궁만 남기고 모든 기물을 잃으면 승리**
- **강제 캡처**: 잡을 수 있으면 반드시 잡아야 함. 단, 차의 캡처는 **2칸 이내**일 때만 강제
- **장군 규칙은 일반 장기와 동일**, 장군 피하기가 강제 캡처보다 우선. **외통수를 당한 쪽이 승리**
- **외딴 섬**: 장군이 아닌데 움직일 수 있는 기물이 궁뿐이면 승리
- **빅장 금지 · 한수쉼 없음**
- **점수 판정**: 캡처 없이 50수 → 남은 점수가 낮은 쪽 승리 (같으면 무승부)
- 무승부: 둘 수 없음 · 3회 동형

## 앱 구성

```
ReverseJanggi/
  App/       ReverseJanggiApp.swift
  Engine/    JanggiCore.swift(타입·보드·궁성) Rules.swift(수 생성·강제캡처·장군·빅장)
             Game.swift(진행·종료 판정) TutorialPositions.swift(튜토리얼 배치)
  AI/        Bot.swift (네가맥스+알파베타+강제캡처 연장, 쉬움/보통/어려움, 시간 제한)
  Online/    RoomClient(WebSocket) · OnlineConfig(서버 주소)
  Views/     Home / GameScreen / BoardView / Tutorial(미션형 7레슨) / Online / Theme / Haptics / Names
Tests/       엔진 단위 테스트 · 튜토리얼 배치 검증 · 자가대국 통계
server/      온라인 대전 릴레이 서버 (Node, Render 배포)
```

- **배우기**: 미션 기반 인터랙티브 튜토리얼 — 각 레슨에서 직접 정답 수를 찾아야 통과
- **컴퓨터 대전**: 쉬움/보통/어려움 (사람이 한, 선공) · 무르기 지원
- **함께 하기**: 한 기기로 로컬 2인 대전
- **온라인 대전**: 6자리 방코드로 친구와 대결 (선공 무작위, 내 진영이 항상 아래)

## 빌드 · 테스트

- 앱: `ReverseJanggi.xcodeproj`를 Xcode 16+로 열고 실행
- 엔진 테스트 (macOS/Linux): `swift test`
- 규칙 밸런스 자가대국: `SELFPLAY_GAMES=30 swift test -c release -Xswiftc -enable-testing --filter SelfPlay`
- 서버 테스트: `cd server && npm install && npm test`

CI (GitHub Actions):

- `.github/workflows/ios.yml` — push/PR 시 엔진 테스트 + 서명 없이 컴파일 검증
- `.github/workflows/testflight.yml` — main 푸시 또는 수동 실행 시 서명 후 TestFlight 업로드
  (fastlane match, 리버스 체스와 같은 시크릿 7개를 이 저장소에도 등록해야 함)
