#!/bin/sh
set -eu
CODEX_HOME=${CODEX_HOME:-"$HOME/.codex"}
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
    CODEX_HOME=$(cygpath -w "$CODEX_HOME")
    ;;
esac
export CODEX_HOME

run_python - <<'PY'
import base64,hashlib,json,os,pathlib,shutil,time
home=pathlib.Path(os.environ['CODEX_HOME']).expanduser(); sf=home/'.subagents_configs-state.json'
def h(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def backup(p):
 stamp=time.strftime('%Y%m%d%H%M%S'); out=p.with_name(p.name+'.subagents_configs.bak-'+stamp); n=1
 while out.exists(): out=p.with_name(p.name+'.subagents_configs.bak-'+stamp+f'-{n}'); n+=1
 shutil.copy2(p,out); print('backup:',out)
try: state=json.loads(sf.read_text())
except (FileNotFoundError,json.JSONDecodeError): print('No Codex installer state; nothing removed safely'); state={}
for item in state.get('files',{}).values():
 p=pathlib.Path(item['target'])
 if not p.exists() or h(p)!=item['installed_hash']: print('preserved modified/missing:',p); continue
 if item['ownership']=='created': p.unlink(); print('removed:',p)
 elif item['ownership']=='replaced' and item.get('backup'): shutil.copy2(item['backup'],p); print('restored:',p)
 else: print('preserved pre-existing:',p)
g=state.get('global',{}); p=pathlib.Path(g['target']) if g.get('target') else None
if p and p.exists() and g.get('ownership')=='managed':
 block=g['block'].encode(); data=p.read_bytes(); pos=data.find(block)
 if pos>=0:
  backup(p); before=base64.b64decode(g.get('before','')); a=before.find(block[:len(b'# BEGIN subagents_configs')]); e=before.find(b'# END subagents_configs',a)
  expected=before[:a]+block+before[e+len(b'# END subagents_configs'):] if a>=0 and e>=a else before+(b'\n\n' if before else b'')+block+b'\n'
  original=base64.b64decode(g.get('original_segment',''))
  p.write_bytes(before if before and data==expected else data[:pos]+original+data[pos+len(block):]); print('removed exact managed block:',p)
 else: print('preserved AGENTS.md: managed block changed or missing')
sf.unlink(missing_ok=True)
PY
echo "Codex subagents uninstalled from $CODEX_HOME"
