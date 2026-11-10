# 빌드와 배포 (맥 없이 GitHub Actions로)

## 구성

| 워크플로 | 언제 | 하는 일 |
|---|---|---|
| `iOS` | 모든 푸시와 PR | 엔진 테스트, 서명 없는 앱 빌드 (시크릿 필요 없음) |
| `TestFlight` | Actions 탭에서 Run workflow, 또는 `v*` 태그 푸시 | 번들 ID 등록, 빌드 번호 결정, match 서명, 빌드, 업로드 |

서명은 다른 앱들과 같은 **fastlane match** 저장소(`sangmin082/ios-certificates`)를 씁니다.
- 기존 배포 인증서를 재사용합니다.
- 이 앱(`com.reversejanggi.game`)의 App Store 프로파일은 첫 실행 때 match가 만들어 저장소에 추가합니다.

## 필요한 시크릿 (이 저장소)

| 이름 | 값 |
|---|---|
| `ASC_KEY_ID` | App Store Connect API 키 ID |
| `ASC_ISSUER_ID` | 발급자 ID |
| `ASC_KEY_P8` | `.p8` 파일 내용 전체 (`-----BEGIN PRIVATE KEY-----`부터) |
| `MATCH_PASSWORD` | match 암호 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `사용자명:토큰`을 base64로 인코딩한 값(`printf 'sangmin082:토큰' \| base64 -w0`). 토큰은 `ios-certificates`에 쓰기 권한 필요. 줄바꿈 섞인 값·원문·토큰 단독도 Fastfile이 정리해서 받음 |

다른 앱 저장소에 넣은 값과 같습니다.

## 앱마다 하는 일

1. Actions 탭 → **TestFlight → Run workflow**를 누릅니다.
2. 처음 실행하면 번들 ID를 자동으로 등록한 뒤 "App Store Connect에 앱을 만들어 주세요"라며 멈춥니다.
   - 애플이 API로 앱 생성을 막아 두어서, 이 단계만 사람이 해야 합니다.
   - 실행 요약(Summary)에 이름, 번들 ID, SKU가 표로 나오므로 그대로 입력하면 됩니다.
3. 다시 **Run workflow**를 누르면 업로드됩니다.
4. TestFlight 앱에서 설치합니다.

빌드 번호는 TestFlight에 있는 가장 큰 번호 + 1로 자동으로 정해집니다.

## 시크릿을 한 번에 등록하기 (`scripts/ios-secrets.sh`)

값을 서버(예: 오라클 클라우드)에 한 번 저장해 두고, 새 앱마다 한 줄로 등록합니다. 값은 서버의 `~/.ios-release/`(권한 600)에만 있고 저장소에는 올라가지 않습니다.

처음 한 번 (서버에서):

```bash
# 1) gh 설치 — Ubuntu: sudo apt install -y gh / Oracle Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# 2) 로그인 — 토큰 방식 권장. Fine-grained 토큰: Repository access "All repositories",
#    권한 Secrets: Read and write, Actions: Read and write (--run 용), Metadata: Read
gh auth login
# 3) 스크립트 설치
mkdir -p ~/bin && curl -fsSL https://raw.githubusercontent.com/sangmin082/reverse_janggi/main/scripts/ios-secrets.sh -o ~/bin/ios-secrets && chmod +x ~/bin/ios-secrets
# 4) 값 입력 (화면에 보이지 않음, .p8은 붙여넣기)
~/bin/ios-secrets setup
```

새 앱마다:

```bash
~/bin/ios-secrets reverse_새앱 --run   # 시크릿 5개 등록 + TestFlight 실행
```

`--run`은 워크플로 파일이 그 저장소의 main에 있어야 동작합니다. 저장된 값 확인은 `ios-secrets list`.
