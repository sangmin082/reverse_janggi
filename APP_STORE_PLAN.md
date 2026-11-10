# 리버스 장기 — 출시 체크리스트

> 작성일: 2026-10-28 · 리버스 체스 앱 구조(SwiftUI 네이티브 + fastlane TestFlight)를 그대로 재사용

## 진행 상황

| 단계 | 상태 |
|---|---|
| 규칙 설계 · 문서화 ([RULES.md](./RULES.md)) | ✅ |
| 규칙 엔진 + 단위 테스트 26개 (공격 판정 교차 검증 포함) | ✅ |
| AI 3단계 + 자가대국 밸런싱 | ✅ |
| UI (장기판·팔각 기물·강제 캡처 표시·무르기), 튜토리얼 7레슨 | ✅ |
| 온라인 대전 클라이언트 + 릴레이 서버 | ✅ (서버 배포는 아래 수동 작업) |
| 영어 현지화, 앱 아이콘, 개인정보 매니페스트 | ✅ |
| CI: 엔진 테스트 + 서명 없는 빌드, TestFlight 파이프라인 | ✅ |

## 사람이 직접 해야 하는 작업

1. **GitHub Secrets 등록** — 리버스 오목과 같은 5개를 이 저장소에 등록 (값도 동일, [docs/RELEASE.md](./docs/RELEASE.md)):
   `ASC_KEY_ID` `ASC_ISSUER_ID` `ASC_KEY_P8` `MATCH_PASSWORD` `MATCH_GIT_BASIC_AUTHORIZATION`
2. **Actions → TestFlight → Run workflow** — 첫 실행은 번들 ID를 자동 등록한 뒤
   "App Store Connect에 앱을 만들어 주세요"라며 멈춘다. 실행 요약(Summary)에 나온 이름·번들 ID·SKU로
   App Store Connect에서 앱을 만들고(API로는 불가) 다시 Run workflow → 업로드
3. **릴레이 서버 배포** — render.com → New → Blueprint → 이 저장소 연결 (`render.yaml` 자동 인식, free)
   - 주소가 `wss://reverse-janggi-server.onrender.com` 인지 확인 (다르면 `OnlineConfig.swift` 수정)
   - `https://reverse-janggi-server.onrender.com/privacy` → 개인정보처리방침 URL로 사용
4. **실기기 QA** — TestFlight 앱에서 설치
5. **심사 제출 메타데이터**
   - 부제목 예: "져야 이기는 장기"
   - 키워드: 장기, 리버스, 안티장기, 보드게임, 전략, 퍼즐, janggi
   - 카테고리: 게임 > 보드 · 연령 4+ · 개인정보 라벨 "데이터 수집 안 함"
   - 스크린샷 6.9": 홈 / 대국(강제 캡처 표시) / 튜토리얼 / 결과 화면

## 이후 업데이트 후보

- 마상 배치 선택 (상마상마 · 마상마상 · 상마마상)
- Game Center 리더보드/업적
- 대국 기보 저장 · 복기
- 판 회전 애니메이션, 기물 이동 애니메이션
