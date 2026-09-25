#!/usr/bin/env bash
# install-args.sh — regression tests for installer CLI precedence + dry-run UX.
# Follows repo convention: bash scripts under tests/, exit non-zero on failure.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN="$ROOT/install/main.sh"
FAIL=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=1; }

# Test 1: --profile standard must survive non-interactive dry-run (no -y).
# Bug: choose_profile() overwrote CLI value with ui_choose default (minimal).
out="$(printf 'n\n' | timeout 60 bash "$MAIN" --dry-run --profile standard 2>&1)"; rc=$?
if [[ "$out" == *'profile : standard'* ]]; then
    pass "cli --profile standard preserved without -y"
else
    printf '%s' "$out" > /tmp/install-args-t1-fail.log
    fail "cli --profile standard preserved without -y (rc=$rc)"
fi

# Test 2: README quick-start must not abort on dry-run without -y.
# Expected: dry-run completes (or at least does not die with 'aborted by user'
# when stdin is closed). We feed 'y' — the point is the profile must still hold.
out2="$(printf 'y\n' | timeout 60 bash "$MAIN" --dry-run --profile standard 2>&1)"; rc=$?
if [[ "$out2" == *'aborted by user'* ]]; then
    fail "dry-run preview aborts even with y on stdin (rc=$rc)"
else
    pass "dry-run preview does not abort with y on stdin"
fi

# Test 3: --dry-run -y prints plan with requested profile.
out3="$(timeout 60 bash "$MAIN" --dry-run --profile standard -y 2>&1)"; rc=$?
if [[ "$out3" == *'profile : standard'* ]]; then
    pass "dry-run -y keeps --profile standard"
else
    fail "dry-run -y keeps --profile standard (rc=$rc)"
fi

# Test 4: no DEBUG leftovers in main.sh.
if grep -q 'DEBUG:' "$MAIN"; then
    fail "DEBUG leftovers present in install/main.sh"
else
    pass "no DEBUG leftovers in install/main.sh"
fi

# Test 5: ui_confirm plain + closed stdin uses default=yes (no hang/abort).
# Sources ui.sh with stdin from /dev/null; default yes must succeed.
out5="$(bash -c 'source "'"$ROOT"'/install/lib/common.sh"; source "'"$ROOT"'/install/lib/ui.sh"; UI_BACKEND=plain; if ui_confirm "Proceed?" yes </dev/null; then echo CONFIRM_YES; else echo CONFIRM_NO; fi' 2>&1 || true)"
if [[ "$out5" == *'CONFIRM_YES'* ]]; then
    pass "ui_confirm plain defaults to yes on closed stdin"
else
    fail "ui_confirm plain defaults to yes on closed stdin (got: $out5)"
fi

# Test 6: no bare '[[ ... ]] && ...' as a function tail in main.sh (set -e kill).
# Regression: summarize() ended with '[[ "$DRY_RUN" == "1" ]] && warn ...'
# which returns 1 on real installs, aborting the installer right after Plan.
if grep -Eq '^[[:space:]]+\[\[ .* \]\] && ' "$MAIN"; then
    fail "bare '[[ ... ]] && ...' statement in install/main.sh (set -e abort risk)"
else
    pass "no bare '[[ ... ]] && ...' in install/main.sh"
fi

# Test 7: the fish shell choice links a config that silences the stock greeting.
fish_conf="$ROOT/config/shell/config.fish"
if [[ -f "$fish_conf" ]] \
    && grep -Eq '^[[:space:]]*set[[:space:]]+(-g[[:space:]]+)?fish_greeting[[:space:]]+""' "$fish_conf" \
    && grep -Fq 'fish)' "$ROOT/install/lib/link.sh" \
    && grep -Fq 'config.fish' "$ROOT/install/lib/link.sh"; then
    pass "fish config silences the greeting and is linked by the installer"
else
    fail "fish config silences the greeting and is linked by the installer"
fi

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== install-args: all pass ==="
else
    echo "=== install-args: FAILURES ==="
fi
exit "$FAIL"
