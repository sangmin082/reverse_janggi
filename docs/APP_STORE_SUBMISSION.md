# 리버스 장기 — App Store 심사 제출 자료

App Store Connect → 리버스 장기 → **1.0 제출 준비 중** 화면의 각 칸에 그대로 붙여넣으면 됩니다.

## 0. 제출 전에 직접 할 일

| 할 일 | 이유 |
|---|---|
| Render에 서버 배포 (render.com → New → Blueprint → `reverse_janggi` 저장소) | 온라인 대전과 지원·개인정보 URL이 이 서버에 있습니다. 배포 전에는 404 |
| 배포 후 `https://reverse-janggi-server.onrender.com/` 과 `/privacy` 가 열리는지 확인 | 주소가 다르면 아래 URL과 `ReverseJanggi/Online/OnlineConfig.swift`를 같이 수정 |

## 1. 앱 정보 (앱 정보 탭)

| 항목 | 한국어 | 영어 (English (U.S.) 현지화 추가 시) |
|---|---|---|
| 이름 | 리버스 장기 | Reverse Janggi |
| 부제 (30자) | 져야 이기는 장기 | Korean chess where losing wins |
| 기본 카테고리 | 게임 → 보드 | |
| 보조 카테고리 | 게임 → 전략 | |
| 콘텐츠 권한 | 제3자 콘텐츠 없음 | |

## 2. 버전 정보 (1.0)

### 프로모션 텍스트 (170자, 심사 없이 언제든 수정 가능)

**한국어**
```
지키지 말고 버리세요. 잡을 수 있으면 반드시 잡아야 하는 장기 — 궁만 남기면 이깁니다.
```

**English**
```
Don't protect your pieces — give them away. Captures are forced, and the first to be left with only a general wins.
```

### 설명

**한국어**
```
리버스 장기는 모든 것이 거꾸로인 장기입니다.
기물은 지키는 게 아니라 버리는 것이고, 외통수는 당하는 쪽이 이깁니다.

■ 규칙은 단 하나만 기억하세요
잡을 수 있으면 반드시 잡아야 합니다. 그러니 내 기물을 일부러 상대 앞에 내밀면, 상대는 잡을 수밖에 없죠. 궁만 남기고 모든 기물을 먼저 잃으면 승리합니다.

■ 장기를 아는 사람도, 모르는 사람도
- 일곱 개의 미션으로 배우는 튜토리얼 — 직접 정답 수를 찾아야 다음으로 넘어갑니다
- 기물 이동법과 전체 규칙을 한 장에 정리한 규칙표
- 갈 수 있는 자리와 반드시 잡아야 하는 자리를 판 위에 표시

■ 혼자서, 둘이서, 멀리서
- 컴퓨터 대전: 쉬움 · 보통 · 어려움
- 함께 하기: 한 기기로 번갈아 두기
- 온라인 대전: 6자리 방코드로 친구와 한 판
- 무르기 지원

■ 리버스 장기만의 규칙
- 한(漢)이 먼저 둡니다
- 차의 캡처는 2칸 이내일 때만 강제입니다
- 외통수를 당하거나, 장군이 아닌데 궁밖에 못 움직이면(외딴 섬) 승리
- 빅장 금지, 한수쉼 없음
- 캡처 없이 50수가 지나면 점수가 낮은 쪽이 승리

광고 없음 · 로그인 없음 · 개인정보 수집 없음
```

**English**
```
Reverse Janggi is Korean chess turned upside down.
You don't protect your pieces — you give them away. And getting checkmated means you win.

■ One rule to remember
If you can capture, you must. So put a piece where your opponent can take it, and they have no choice. Lose every piece except your general first, and you win.

■ New to Janggi? No problem
- A tutorial of seven missions — find the right move to move on
- One-page rules with how every piece moves
- Legal moves and forced captures shown right on the board

■ Play solo, together, or online
- vs Computer: Easy, Normal, Hard
- Pass & Play on one device
- Online match with a 6-character room code
- Undo

■ Reverse Janggi rules
- Han moves first
- Chariot captures are forced only within 2 points
- Win by getting checkmated, or when only your general can move (lone island)
- Generals may not face each other (no bikjang), and there is no passing
- After 50 moves without a capture, the side with fewer points wins

No ads · No sign-in · No data collected
```

### 키워드 (100자, 쉼표로 구분·공백 없이)

- 한국어: `장기,리버스,안티장기,반대장기,보드게임,전략,퍼즐,두뇌게임,2인,오프라인,한국장기,janggi`
- English: `janggi,korean chess,reverse,antichess,losing chess,board game,strategy,puzzle,2 player,offline`

### URL

| 항목 | 값 |
|---|---|
| 지원 URL | `https://reverse-janggi-server.onrender.com/` |
| 마케팅 URL | (비워 둠) |
| 개인정보처리방침 URL (앱 정보 탭) | `https://reverse-janggi-server.onrender.com/privacy` |

### 저작권

`2026 (본인 이름 또는 상호)`

### 스크린샷 (6.9" 필수, iPhone 전용 앱이라 iPad 불필요)

이미 골라서 저장소에 넣어 두었습니다 (iPhone 17 Pro Max 시뮬레이터, 1320×2868). 이 순서대로 올리면 됩니다.

| 순서 | 한국어 (`docs/screenshots/ko/`) | 영어 (`docs/screenshots/en/`) |
|---|---|---|
| 1 | `1-home.png` 홈 | `1-home.png` |
| 2 | `2-forced-capture.png` 강제 캡처 표시 | `2-game.png` |
| 3 | `3-game.png` 갈 수 있는 자리 표시 | |
| 4 | `4-tutorial.png` 튜토리얼 미션 | |
| 5 | `5-rules.png` 규칙 한 장 | |

GitHub 웹에서 파일을 열고 다운로드 버튼으로 받을 수 있습니다. 화면이 바뀌면 Actions → **UI tests**를 다시 실행해 `screenshots` 아티팩트에서 새로 고르면 됩니다.

### 빌드

TestFlight에 올라간 빌드 중 **Xcode 26(macos-26)으로 빌드된 가장 최근 빌드**를 선택합니다.
수출 규정 질문은 나오지 않습니다 (`ITSAppUsesNonExemptEncryption = NO` 설정됨).

## 3. 앱 심사 정보

- 로그인 필요: **아니요** (데모 계정 없음)
- 연락처: 이름 · 전화번호 · 이메일 직접 입력
- 메모 (영어로 붙여넣기):

```
Reverse Janggi is a variant of Korean chess (Janggi) where the goal is reversed: a player wins by losing all pieces except the general.

How to review:
- "Learn" walks through the rules in seven short missions.
- "vs Computer" plays against the built-in AI (fully offline).
- "Pass & Play" lets two people play on one device.
- "Online Match" needs two devices: create a room on one, then join with the 6-character code on the other. The relay server is a free instance and may take up to about a minute to wake up on the first connection.

The app has no accounts, ads, analytics or in-app purchases, and collects no personal data. Online play only relays moves between the two players; nothing is stored.
```

## 4. 앱 개인정보 (App Privacy 탭)

- 데이터 수집: **"아니요, 이 앱에서 데이터를 수집하지 않습니다"**
  - 온라인 대전 서버는 두 사람 사이에 수(move)만 중계하고 저장하지 않으며, 계정·분석·광고가 없습니다.
  - 앱에 넣은 `PrivacyInfo.xcprivacy`도 "추적 없음, 수집 데이터 없음"으로 되어 있습니다.

## 5. 연령 등급 (앱 정보 탭 → 연령 등급)

모든 항목 **없음/아니요** → **4+**

- 폭력·성적 콘텐츠·약물·도박 등 전부 없음
- 무제한 웹 액세스: 아니요
- 사용자 생성 콘텐츠·채팅: 아니요 (온라인 대전은 수만 주고받음)
- 경품·도박: 아니요

## 6. 가격 및 사용 가능 여부

- 가격: 원하는 가격 선택 (앱 수정 불필요)
- 판매 국가: 전체 또는 대한민국만
- 출시 방식: "이 버전을 수동으로 출시" 권장 (승인 후 원하는 때 출시)
