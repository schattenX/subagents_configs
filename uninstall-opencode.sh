#!/bin/sh
set -eu
OPENCODE_HOME=${OPENCODE_HOME:-"$HOME/.config/opencode"}
python_probe() {
  case "$1" in
    py)
      py -3 -c 'import sys; print("__subagents_configs_python_ok__" if sys.version_info >= (3, 8) else "__subagents_configs_python_old__")'
      ;;
    *)
      "$1" -c 'import sys; print("__subagents_configs_python_ok__" if sys.version_info >= (3, 8) else "__subagents_configs_python_old__")'
      ;;
  esac
}

if [ "$(python_probe python3 2>/dev/null)" = "__subagents_configs_python_ok__" ]; then
  PYTHON=python3
elif [ "$(python_probe python 2>/dev/null)" = "__subagents_configs_python_ok__" ]; then
  PYTHON=python
elif [ "$(python_probe py 2>/dev/null)" = "__subagents_configs_python_ok__" ]; then
  PYTHON=py
else
  echo "error: no usable Python 3.8+ interpreter found; tried python3, python, and Windows py -3" >&2
  exit 1
fi

run_python() {
  if [ "$PYTHON" = "py" ]; then
    py -3 "$@"
  else
    "$PYTHON" "$@"
  fi
}

PYTHON_PLATFORM=$(run_python -c 'import sys; print(sys.platform)' 2>/dev/null) || {
  echo "error: selected Python interpreter could not report sys.platform" >&2
  exit 1
}
case "$(uname -s 2>/dev/null || echo unknown):$PYTHON_PLATFORM" in
  MINGW*:win32|MSYS*:win32|CYGWIN*:win32)
    command -v cygpath >/dev/null 2>&1 || {
      echo "error: cygpath is required for Windows-native Python under Git Bash/MSYS/Cygwin" >&2
      exit 1
    }
    OPENCODE_HOME=$(cygpath -w "$OPENCODE_HOME")
    ;;
esac
export OPENCODE_HOME

run_python - <<'PY'
import base64, hashlib, json, os, pathlib, shutil, time

home = pathlib.Path(os.environ["OPENCODE_HOME"]).expanduser()
state_file = home / ".subagents_configs-opencode-state.json"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def backup(path):
    stamp = time.strftime("%Y%m%d%H%M%S")
    target = path.with_name(path.name + ".subagents_configs.bak-" + stamp)
    index = 1
    while target.exists():
        target = path.with_name(path.name + ".subagents_configs.bak-" + stamp + f"-{index}")
        index += 1
    shutil.copy2(path, target)
    print("backup:", target)

try:
    state = json.loads(state_file.read_text())
except (FileNotFoundError, json.JSONDecodeError):
    print("No OpenCode installer state; nothing removed safely")
    state = {}

for item in state.get("files", {}).values():
    path = pathlib.Path(item["target"])
    if not path.exists() or digest(path) != item["installed_hash"]:
        print("preserved modified/missing:", path)
    elif item["ownership"] == "created":
        path.unlink()
        print("removed:", path)
    elif item["ownership"] == "replaced" and item.get("backup"):
        shutil.copy2(item["backup"], path)
        print("restored:", path)
    else:
        print("preserved pre-existing:", path)

global_state = state.get("global", {})
path = pathlib.Path(global_state["target"]) if global_state.get("target") else None
if path and path.exists() and global_state.get("ownership") == "managed":
    block = global_state["block"].encode()
    data = path.read_bytes()
    position = data.find(block)
    if position >= 0:
        backup(path)
        original = base64.b64decode(global_state.get("original_segment", ""))
        updated = data[:position] + original + data[position + len(block):]
        if not base64.b64decode(global_state.get("before", "")) and not updated.strip():
            path.unlink()
        else:
            path.write_bytes(updated)
        print("removed exact managed block:", path)
    else:
        print("preserved AGENTS.md: managed block changed or missing")

state_file.unlink(missing_ok=True)
PY
echo "OpenCode subagents uninstalled from $OPENCODE_HOME"
