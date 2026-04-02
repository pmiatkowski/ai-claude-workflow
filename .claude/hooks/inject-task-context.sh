#!/usr/bin/env bash
# UserPromptSubmit hook — injects active task context into Claude's session.
# Uses Python+PyYAML for robust parsing, with grep fallback.

STATE_FILE=".temp/tasks/state.yml"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# --- Detect available Python binary ---
PYTHON_BIN=""
for cmd in python3 python; do
  if command -v "$cmd" &>/dev/null && "$cmd" -c "import yaml" 2>/dev/null; then
    PYTHON_BIN="$cmd"
    break
  fi
done

# --- Parse state.yml via Python (robust) or grep (fallback) ---

parse_with_python() {
  local tmperr result rc
  tmperr=$(mktemp)
  result=$("$PYTHON_BIN" -c "
import yaml, json, sys

with open('$STATE_FILE') as f:
    state = yaml.safe_load(f)

if not state or state.get('active_task') in (None, 'null', 'none'):
    sys.exit(1)

tp = state.get('task_path', '')
pf = state.get('phase_files', [])
vm = state.get('verification_mode', 'per_phase')
cs = state.get('constraints', {})

# Format constraints
c_lines = []
for inv in cs.get('invariants', []):
    c_lines.append(f\"  - [I] {inv.get('constraint', inv) if isinstance(inv, dict) else inv}\")
for dec in cs.get('decisions', []):
    c_lines.append(f\"  - [D] {dec.get('constraint', dec) if isinstance(dec, dict) else dec}\")
for disc in cs.get('discovered', []):
    c_lines.append(f\"  - [*] {disc.get('constraint', disc) if isinstance(disc, dict) else disc}\")

ctx_parts = [
    'ACTIVE TASK CONTEXT:',
    f\"- Task: {state['active_task']}\",
    f\"- Status: {state.get('status', 'unknown')}\",
    f\"- Path: {tp}\",
    f\"- PRD: {tp}/prd.md\",
    f\"- Plan: {tp}/plan.md\",
    f\"- Verification Mode: {vm}\",
]
if pf:
    ctx_parts.append(f\"- Phase Files: {', '.join(pf)}\")
if c_lines:
    ctx_parts.append('\\nCONSTRAINTS:')
    ctx_parts.extend(c_lines)
ctx_parts.append('\\nAlways read state.yml and relevant task files before acting on any /task-* command.')
ctx_parts.append('IMPORTANT: Check constraints before making changes. Invariants must NEVER be violated.')

# Banner to stderr
print(f\"Active task: {state['active_task']} (status: {state.get('status')}, mode: {vm})\", file=sys.stderr)

# JSON to stdout
print(json.dumps({'additionalContext': '\\n'.join(ctx_parts)}))
" 2>"$tmperr")
  rc=$?
  if [[ $rc -eq 0 ]]; then
    cat "$tmperr" >&2
    rm -f "$tmperr"
    echo "$result"
    return 0
  else
    rm -f "$tmperr"
    return 1
  fi
}

parse_with_grep() {
  active_task=$(grep "^active_task:" "$STATE_FILE" | head -1 | sed 's/^active_task:[[:space:]]*//' | tr -d '"')
  status=$(grep "^status:" "$STATE_FILE" | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '"')
  task_path=$(grep "^task_path:" "$STATE_FILE" | head -1 | sed 's/^task_path:[[:space:]]*//' | tr -d '"')
  vm=$(grep "^verification_mode:" "$STATE_FILE" | head -1 | sed 's/^verification_mode:[[:space:]]*//' | tr -d '"')

  if [[ -z "$active_task" || "$active_task" == "null" || "$active_task" == "none" ]]; then
    exit 0
  fi

  # Extract phase_files
  pf_list=""
  in_pf=0
  while IFS= read -r line; do
    if [[ "$line" == "phase_files:" ]]; then in_pf=1; continue; fi
    if [[ $in_pf -eq 1 ]]; then
      [[ "$line" =~ ^[a-zA-Z] ]] && break
      f=$(echo "$line" | sed 's/^[[:space:]]*- //' | tr -d '"')
      [[ -n "$f" ]] && pf_list="${pf_list:+$pf_list, }$f"
    fi
  done < "$STATE_FILE"

  # Extract constraints (simple text extraction)
  c_block=""
  in_inv=0; in_dec=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*invariants: ]]; then in_inv=1; in_dec=0; continue; fi
    if [[ "$line" =~ ^[[:space:]]*decisions: ]]; then in_dec=1; in_inv=0; continue; fi
    if [[ "$line" =~ ^[[:space:]]*discovered: ]]; then in_dec=0; in_inv=0; continue; fi
    if [[ $in_inv -eq 1 || $in_dec -eq 1 ]] && [[ "$line" =~ ^[[:space:]]+- ]]; then
      c_text=$(echo "$line" | sed 's/^[[:space:]]*- //' | sed 's/.*constraint:[[:space:]]*//' | tr -d '"')
      [[ -n "$c_text" ]] && c_block="${c_block}\\n  - $c_text"
    fi
    [[ "$line" =~ ^[a-z] ]] && { in_inv=0; in_dec=0; }
  done < "$STATE_FILE"

  echo "Active task: $active_task (status: $status, mode: ${vm:-per_phase})" >&2

  ctx="ACTIVE TASK CONTEXT:\\n- Task: ${active_task}\\n- Status: ${status}\\n- Path: ${task_path}\\n- PRD: ${task_path}/prd.md\\n- Plan: ${task_path}/plan.md\\n- Verification Mode: ${vm:-per_phase}"
  [[ -n "$pf_list" ]] && ctx="${ctx}\\n- Phase Files: ${pf_list}"
  [[ -n "$c_block" ]] && ctx="${ctx}\\n\\nCONSTRAINTS:${c_block}"
  ctx="${ctx}\\n\\nAlways read state.yml and relevant task files before acting on any /task-* command.\\nIMPORTANT: Check constraints before making changes. Invariants must NEVER be violated."

  printf '{"additionalContext":"%s"}' "$ctx"
}

# Try Python first (if available), fall back to grep
if [[ -n "$PYTHON_BIN" ]]; then
  parse_with_python || parse_with_grep
else
  parse_with_grep
fi
