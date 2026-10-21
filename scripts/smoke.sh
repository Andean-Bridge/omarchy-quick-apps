#!/usr/bin/env bash
set -euo pipefail

# Pass a different extracted Omarchy shell directory to check its QML modules.
task_source=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
task_shell=${1:-${OMARCHY_PATH:-/usr/share/omarchy}/shell}
[[ -d "$task_shell/Commons" && -d "$task_shell/Ui" ]] || { echo "Expected an Omarchy shell directory" >&2; exit 1; }
task_shell=$(cd -- "$task_shell" && pwd)
task_fixture=$(mktemp -d)
trap 'rm -rf -- "$task_fixture"' EXIT
cp -- "$task_source/tests/smoke.qml" "$task_fixture/shell.qml"
# Links are only in the disposable test harness, never the plugin package.
ln -s -- "$task_shell/Commons" "$task_fixture/Commons"
ln -s -- "$task_shell/Ui" "$task_fixture/Ui"
ln -s -- "$task_shell/services" "$task_fixture/services"
mkdir -p -- "$task_fixture/state" "$task_fixture/config"
QUICK_APPS_SOURCE="$task_source" QUICK_APPS_OMARCHY="${task_shell%/shell}" \
  XDG_STATE_HOME="$task_fixture/state" XDG_CONFIG_HOME="$task_fixture/config" \
  timeout 15s qs --no-color -p "$task_fixture" > "$task_fixture/output.log" 2>&1 || { cat "$task_fixture/output.log"; exit 1; }
cat "$task_fixture/output.log"
grep -q 'QUICK_APPS_SMOKE_PASSED' "$task_fixture/output.log"
if grep -Eq 'QUICK_APPS_SMOKE_FAIL|TypeError|ReferenceError|SyntaxError|Unable to assign|Cannot assign' "$task_fixture/output.log"; then exit 1; fi
[[ $(stat -c '%a' "$task_fixture/state/omarchy/quick-apps") == 700 ]] || { echo "History directory must be owner-only" >&2; exit 1; }
