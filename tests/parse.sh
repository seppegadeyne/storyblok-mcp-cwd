#!/bin/sh
# Parser test for storyblok-mcp: extracts the token-parsing block and runs it on variants.
SCRIPT=$(cd "$(dirname "$0")/.." && pwd)/bin/storyblok-mcp
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT
fail=0
sed -n '/^token=\$(sed/,/sed -e .s\/\^"/p' "$SCRIPT" > "$DIR/p.sh"
TOKEN_KEY=STORYBLOK_PERSONAL_ACCESS_TOKEN
check() {
  expected="$1"; shift
  printf "$@" > "$DIR/f"
  env_file="$DIR/f"
  . "$DIR/p.sh"
  if [ "$token" = "$expected" ]; then echo "PASS [$token]"; else echo "FAIL got [$token] want [$expected]"; fail=1; fi
}
check abc123 'STORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\n'
check abc123 'export STORYBLOK_PERSONAL_ACCESS_TOKEN="abc123"\n'
check abc123 "STORYBLOK_PERSONAL_ACCESS_TOKEN='abc123'  \n"
check abc123 'STORYBLOK_PERSONAL_ACCESS_TOKEN = abc123\n'
check abc123 'X=1\r\nSTORYBLOK_PERSONAL_ACCESS_TOKEN=old\r\nSTORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\r\n'
check '' '# STORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\n'
check '' 'STORYBLOK_PERSONAL_ACCESS_TOKEN_OLD=abc123\n'
check '' 'MY_STORYBLOK_PERSONAL_ACCESS_TOKEN=abc123\n'

# End-to-end with a stub npx (no network): symlinked $HOME must stop the walk, token reaches mcp-remote via env.
mkdir -p "$DIR/home/proj" "$DIR/bin"; ln -s "$DIR/home" "$DIR/link"
printf 'STORYBLOK_PERSONAL_ACCESS_TOKEN=other\n' > "$DIR/.env.hermes"
printf '#!/bin/sh\necho "$STORYBLOK_MCP_AUTH_HEADER"\n' > "$DIR/bin/npx"; chmod +x "$DIR/bin/npx"
run() { (cd "$DIR/link/proj" && HOME="$DIR/link" PATH="$DIR/bin:$PATH" sh "$SCRIPT" 2>&1); }
case $(run) in *"no .env.hermes found"*) echo "PASS symlinked HOME stops walk";; *) echo "FAIL walk escaped symlinked HOME"; fail=1;; esac
printf 'STORYBLOK_PERSONAL_ACCESS_TOKEN=mine\n' > "$DIR/home/.env.hermes"
case $(run) in *"Bearer mine") echo "PASS token via env";; *) echo "FAIL token via env"; fail=1;; esac
exit $fail
