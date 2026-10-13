#!/bin/sh
# Parser test for storyblok-mcp: extracts the token-parsing block and runs it on variants.
SCRIPT=$(cd "$(dirname "$0")/.." && pwd)/bin/storyblok-mcp
DIR=$(mktemp -d)
sed -n '/^token=\$(sed/,/sed -e .s\/\^"/p' "$SCRIPT" > "$DIR/p.sh"
TOKEN_KEY=STORYBLOK_PERSONAL_ACCESS_TOKEN
check() {
  expected="$1"; shift
  printf "$@" > "$DIR/f"
  env_file="$DIR/f"
  . "$DIR/p.sh"
  if [ "$token" = "$expected" ]; then echo "PASS [$token]"; else echo "FAIL got [$token] want [$expected]"; fi
}
check abc123 'STORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\n'
check abc123 'export STORYBLOK_PERSONAL_ACCESS_TOKEN="abc123"\n'
check abc123 "STORYBLOK_PERSONAL_ACCESS_TOKEN='abc123'  \n"
check abc123 'STORYBLOK_PERSONAL_ACCESS_TOKEN = abc123\n'
check abc123 'X=1\r\nSTORYBLOK_PERSONAL_ACCESS_TOKEN=old\r\nSTORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\r\n'
check '' '# STORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\n'
check '' 'STORYBLOK_PERSONAL_ACCESS_TOKEN_OLD=abc123\n'
check '' 'MY_STORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\n'
