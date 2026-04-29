#!/bin/bash
set -euo pipefail

cleanup_and_reward() {
    local exit_code=$?
    mkdir -p /logs/verifier
    if [ "${exit_code}" -eq 0 ]; then
        echo 1 > /logs/verifier/reward.txt
    else
        echo 0 > /logs/verifier/reward.txt
    fi
    exit "${exit_code}"
}
trap cleanup_and_reward EXIT

STDOUT_LOG=$(mktemp)
STDERR_LOG=$(mktemp)
export STDOUT_LOG STDERR_LOG

cd "/app/pydantic-assessment" || { echo "ERROR: /app/pydantic-assessment missing"; exit 1; }

# Instead of git apply (which can fail on patch formatting), materialize the test file directly.
python3 - <<'PY'
import json
import os

with open('/tests/config.json') as f:
    cfg = json.load(f)

patch = cfg.get('test_patch', '')
if not patch.strip():
    raise SystemExit(0)

# Our test_patch always contains the full content for tests/test_alias_path_bytes.py.
# Extract everything after the "+++ b/<path>" line and strip leading "+" from added lines.
lines = patch.splitlines()

target_path = None
for i, line in enumerate(lines):
    if line.startswith('+++ b/'):
        target_path = line[len('+++ b/'):]
        start = i + 1
        break

if not target_path:
    raise RuntimeError('Could not find target file path in test_patch (expected a +++ b/... line).')

out_lines = []
for line in lines[start:]:
    # skip diff metadata/hunk headers
    if line.startswith('@@') or line.startswith('diff ') or line.startswith('new file mode') or line.startswith('--- '):
        continue
    # only take added lines; ignore context/removals (this is a new-file patch)
    if line.startswith('+'):
        out_lines.append(line[1:] + '\n')

os.makedirs(os.path.dirname(target_path), exist_ok=True)
with open(target_path, 'w', encoding='utf-8') as f:
    f.writelines(out_lines)

print(f'Wrote test file: {target_path}')
PY

TEST_FILES=$(python3 - <<'PY'
import json
with open('/tests/config.json') as f:
    cfg = json.load(f)
tf = cfg.get('selected_test_files_to_run') or []
if isinstance(tf, str):
    import json as _j
    tf = _j.loads(tf)
print(','.join(tf))
PY
)

set +e
if [ -n "$TEST_FILES" ]; then
    bash /tests/run_script.sh "$TEST_FILES" > "$STDOUT_LOG" 2> "$STDERR_LOG"
else
    bash /tests/run_script.sh > "$STDOUT_LOG" 2> "$STDERR_LOG"
fi
set -e

python3 /tests/parser.py "$STDOUT_LOG" "$STDERR_LOG" /tmp/output.json

mkdir -p /logs/verifier
cp /tmp/output.json /logs/verifier/output.json 2>/dev/null || true
cp "$STDOUT_LOG" /logs/verifier/run-script-stdout.txt 2>/dev/null || true
cp "$STDERR_LOG" /logs/verifier/run-script-stderr.txt 2>/dev/null || true

python3 - << 'PYEOF'
import json, sys

with open('/tmp/output.json') as f:
    results = json.load(f)
with open('/tests/config.json') as f:
    cfg = json.load(f)

ftp = set(cfg.get('fail_to_pass') or [])
ptp = set(cfg.get('pass_to_pass') or [])
passed = {t['name'] for t in results.get('tests', []) if t.get('status') == 'PASSED'}

required = ftp | ptp
ok = required <= passed

print(f"required tests : {len(required)}")
print(f"passed tests   : {len(passed)}")
print(f"required passed: {len(required & passed)}")
if ok:
    print("\nRESULT: PASSED")
    sys.exit(0)

missing = required - passed
print(f"\nRESULT: FAILED\nmissing: {sorted(missing)}")
sys.exit(1)
PYEOF
