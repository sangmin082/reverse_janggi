#!/usr/bin/env bash
# 새 iOS 앱 저장소에 TestFlight 시크릿 5개를 한 번에 등록한다.
# 값은 이 서버의 ~/.ios-release/ 에만 저장되고 저장소에는 올라가지 않는다.
#
#   ios-secrets setup             처음 한 번: 값을 입력받아 저장
#   ios-secrets <저장소> [--run]   시크릿 등록 (--run: 이어서 TestFlight 워크플로 실행)
#   ios-secrets list              저장된 값의 이름만 확인
#
# 저장소는 "reverse_janggi"처럼 이름만 쓰면 sangmin082/ 가 붙는다 (IOS_OWNER로 변경 가능).
set -euo pipefail

DIR="${IOS_RELEASE_DIR:-$HOME/.ios-release}"
ENV_FILE="$DIR/secrets.env"
P8_FILE="$DIR/AuthKey.p8"
OWNER="${IOS_OWNER:-sangmin082}"
NAMES=(ASC_KEY_ID ASC_ISSUER_ID MATCH_PASSWORD MATCH_GIT_BASIC_AUTHORIZATION)

die() { echo "오류: $*" >&2; exit 1; }

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

need_gh() {
  command -v gh >/dev/null || die "gh가 없습니다. 설치: https://github.com/cli/cli#installation"
  gh auth status >/dev/null 2>&1 || die "gh 로그인이 필요합니다: gh auth login"
}

value_of() {
  # secrets.env 에서 NAME=값 한 줄을 읽는다 (값에 = 가 있어도 그대로)
  local line
  line=$(grep -m1 "^$1=" "$ENV_FILE" || true)
  printf '%s' "${line#*=}"
}

cmd_setup() {
  mkdir -p "$DIR"
  chmod 700 "$DIR"
  umask 077
  : > "$ENV_FILE.tmp"
  for name in "${NAMES[@]}"; do
    local current="" value
    [ -f "$ENV_FILE" ] && current=$(value_of "$name")
    if [ -n "$current" ]; then
      read -rsp "$name (엔터 = 기존 값 유지): " value; echo
      value="${value:-$current}"
    else
      read -rsp "$name: " value; echo
    fi
    [ -n "$value" ] || die "$name 값이 비어 있습니다"
    printf '%s=%s\n' "$name" "$value" >> "$ENV_FILE.tmp"
  done
  mv "$ENV_FILE.tmp" "$ENV_FILE"

  if [ -f "$P8_FILE" ]; then
    read -rp "ASC_KEY_P8 (.p8 키)를 새로 붙여넣을까요? [y/N] " again
    [[ "$again" =~ ^[yY] ]] || { echo "저장 완료: $DIR"; return; }
  fi
  echo "ASC_KEY_P8: .p8 파일 내용 전체를 붙여넣으세요 (-----END PRIVATE KEY----- 줄에서 자동 종료)"
  : > "$P8_FILE.tmp"
  while IFS= read -r line; do
    printf '%s\n' "$line" >> "$P8_FILE.tmp"
    [[ "$line" == *"END PRIVATE KEY"* ]] && break
  done
  grep -q "BEGIN PRIVATE KEY" "$P8_FILE.tmp" || { rm -f "$P8_FILE.tmp"; die ".p8 형식이 아닙니다"; }
  mv "$P8_FILE.tmp" "$P8_FILE"
  echo "저장 완료: $DIR"
}

cmd_list() {
  [ -f "$ENV_FILE" ] || die "아직 값이 없습니다: ios-secrets setup"
  for name in "${NAMES[@]}"; do
    if [ -n "$(value_of "$name")" ]; then echo "✓ $name"; else echo "✗ $name"; fi
  done
  if [ -s "$P8_FILE" ]; then echo "✓ ASC_KEY_P8"; else echo "✗ ASC_KEY_P8"; fi
}

cmd_apply() {
  local repo="$1" run="${2:-}"
  [[ "$repo" == */* ]] || repo="$OWNER/$repo"
  [ -f "$ENV_FILE" ] && [ -s "$P8_FILE" ] || die "아직 값이 없습니다: ios-secrets setup"
  need_gh
  gh repo view "$repo" >/dev/null 2>&1 || die "저장소를 찾을 수 없습니다: $repo"

  for name in "${NAMES[@]}"; do
    local value
    value=$(value_of "$name")
    [ -n "$value" ] || die "$name 값이 없습니다: ios-secrets setup"
    printf '%s' "$value" | gh secret set "$name" -R "$repo" >/dev/null
    echo "✓ $name"
  done
  gh secret set ASC_KEY_P8 -R "$repo" < "$P8_FILE" >/dev/null
  echo "✓ ASC_KEY_P8"
  echo "$repo 에 시크릿 5개 등록 완료"

  if [ "$run" = "--run" ]; then
    gh workflow run testflight.yml -R "$repo"
    echo "TestFlight 실행 요청함 — 진행 상황: https://github.com/$repo/actions"
  fi
}

case "${1:-}" in
  ""|-h|--help|help) usage ;;
  setup) cmd_setup ;;
  list) cmd_list ;;
  *) cmd_apply "$1" "${2:-}" ;;
esac
