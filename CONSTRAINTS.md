# Constraints

Last reviewed: 2026-11-07

## Floor (always enforced)
- No new suppression comments (`shellcheck disable`, `# noqa`).
- No silent failures in the wrapper (`set -eu` stays; no `|| true` on the token lookup).
- No skipped or deleted tests without a reason in the commit message.
- Never print or commit tokens (`.env.hermes` values).
- This file is not weakened to make a change pass.

## Enforced with numbers
| Dimension | Rule | Checked by | Runs at |
|---|---|---|---|
| Parser tests | all PASS, exit 0 | `sh tests/parse.sh` | every change |

## Measured, not yet enforced (ratchets)
| Metric | Today | Command | Direction |
|---|---|---|---|
| Suppression comments | 0 | `git grep -nE "@ts-ignore|@ts-expect-error|eslint-disable|biome-ignore|# noqa|# type: ignore|phpcs:ignore" -- ":!node_modules" ":!vendor" ":!dist" ":!package-lock.json" | wc -l` | must not grow |
| Skipped/only tests | 0 | `git grep -nE "\.skip\(|\bxit\(|\.only\(|skip:" -- ":!node_modules" ":!package-lock.json" | wc -l` | must not grow |
| Parser tests | 5 PASS, 0 FAIL | `sh tests/parse.sh` | must not fall |
| Lint / build | none configured | n/a | n/a |

## Exceptions
| ID | Rule | Path | Reason | Expires |
|---|---|---|---|---|
