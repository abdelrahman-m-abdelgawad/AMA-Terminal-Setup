#!/usr/bin/env bash
set -euo pipefail

STARSHIP_FILE="$HOME/.config/starship.toml"
BACKUP_DIR="$HOME/.config/ama/backups"
TEST_ROOT="$HOME/Terminal-Lab/Git-States-Test"

mkdir -p "$BACKUP_DIR" "$TEST_ROOT"

if [[ ! -f "$STARSHIP_FILE" ]]; then
  echo "starship.toml not found: $STARSHIP_FILE" >&2
  exit 1
fi

cp "$STARSHIP_FILE" "$BACKUP_DIR/starship.toml.before-git-states.$(date +%Y%m%d-%H%M%S)"

python3 - <<'PY'
from pathlib import Path
from datetime import datetime
import re
import shutil
import tomllib
import sys

p = Path.home() / ".config/starship.toml"
text = p.read_text(encoding="utf-8")
backup = p.with_name(f"starship.toml.git-states-{datetime.now():%Y%m%d-%H%M%S}")
shutil.copy2(p, backup)

pattern = re.compile(r'(?ms)^\[git_status\]\s*.*?(?=^\[|\Z)')
replacement = """[git_status]
style = 'bold ama_green'
format = '[$up_to_date$conflicted$stashed$modified$staged$renamed$deleted$untracked$ahead_behind ]($style)'
up_to_date = '✔'
conflicted = '✖'
stashed = '⚑'
modified = '!'
staged = '+'
renamed = '»'
deleted = '✘'
untracked = '?'
ahead = '⇡'
behind = '⇣'
diverged = '⇕'
"""

if not pattern.search(text):
    sys.exit('ERROR: [git_status] block was not found.')

new_text = pattern.sub(replacement, text, count=1)
try:
    tomllib.loads(new_text)
except Exception as exc:
    sys.exit(f'ERROR: TOML validation failed; original preserved.\n{exc}')

p.write_text(new_text, encoding='utf-8')
print(f'Starship updated successfully. Backup: {backup}')
PY

make_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.name "AMA Robotics"
  git -C "$dir" config user.email "ama@local"
}

# 1) CLEAN
CLEAN="$TEST_ROOT/01-clean"
rm -rf "$CLEAN"
make_repo "$CLEAN"
( cd "$CLEAN" && echo "clean repo" > readme.txt && git add readme.txt && git commit -q -m "init" )

# 2) UNTRACKED
UNTRACKED="$TEST_ROOT/02-untracked"
rm -rf "$UNTRACKED"
make_repo "$UNTRACKED"
( cd "$UNTRACKED" && echo "base" > tracked.txt && git add tracked.txt && git commit -q -m "init" && echo "new file" > untracked.txt )

# 3) STAGED
STAGED="$TEST_ROOT/03-staged"
rm -rf "$STAGED"
make_repo "$STAGED"
( cd "$STAGED" && echo "base" > tracked.txt && git add tracked.txt && git commit -q -m "init" && echo "staged content" > staged.txt && git add staged.txt )

# 4) MODIFIED
MODIFIED="$TEST_ROOT/04-modified"
rm -rf "$MODIFIED"
make_repo "$MODIFIED"
( cd "$MODIFIED" && printf "line 1\nline 2\n" > file.txt && git add file.txt && git commit -q -m "init" && sed -i 's/line 2/line 2 modified/' file.txt )

# Remote seed
REMOTE="$TEST_ROOT/remote.git"
rm -rf "$REMOTE"
git init --bare -q "$REMOTE"

SEED="$TEST_ROOT/_seed"
rm -rf "$SEED"
make_repo "$SEED"
( cd "$SEED" && echo seed > base.txt && git add base.txt && git commit -q -m "seed" && git remote add origin "$REMOTE" && git push -q -u origin main )
git -C "$REMOTE" symbolic-ref HEAD refs/heads/main

# 5) AHEAD
AHEAD="$TEST_ROOT/05-ahead"
rm -rf "$AHEAD"
git clone -q "$REMOTE" "$AHEAD"
git -C "$AHEAD" checkout -B main origin/main
git -C "$AHEAD" config user.name "AMA Robotics"
git -C "$AHEAD" config user.email "ama@local"
( cd "$AHEAD" && git commit --allow-empty -q -m "ahead commit" )

# 6) BEHIND
BEHIND="$TEST_ROOT/06-behind"
rm -rf "$BEHIND"
git clone -q "$REMOTE" "$BEHIND"
git -C "$BEHIND" checkout -B main origin/main
git -C "$BEHIND" config user.name "AMA Robotics"
git -C "$BEHIND" config user.email "ama@local"

TMP_BEHIND_PUSH="$TEST_ROOT/_behind_push"
rm -rf "$TMP_BEHIND_PUSH"
git clone -q "$REMOTE" "$TMP_BEHIND_PUSH"
git -C "$TMP_BEHIND_PUSH" config user.name "AMA Robotics"
git -C "$TMP_BEHIND_PUSH" config user.email "ama@local"
( cd "$TMP_BEHIND_PUSH" && echo "remote advance" > behind.txt && git add behind.txt && git commit -q -m "remote advance" && git push -q origin main )
git -C "$BEHIND" fetch -q origin main

# 7) DIVERGED
DIVERGED="$TEST_ROOT/07-diverged"
rm -rf "$DIVERGED"
git clone -q "$REMOTE" "$DIVERGED"
git -C "$DIVERGED" checkout -B main origin/main
git -C "$DIVERGED" config user.name "AMA Robotics"
git -C "$DIVERGED" config user.email "ama@local"
( cd "$DIVERGED" && echo "local diverge" > diverged-local.txt && git add diverged-local.txt && git commit -q -m "local diverge" )

TMP_DIVERGE_PUSH="$TEST_ROOT/_diverge_push"
rm -rf "$TMP_DIVERGE_PUSH"
git clone -q "$REMOTE" "$TMP_DIVERGE_PUSH"
git -C "$TMP_DIVERGE_PUSH" config user.name "AMA Robotics"
git -C "$TMP_DIVERGE_PUSH" config user.email "ama@local"
( cd "$TMP_DIVERGE_PUSH" && echo "remote diverge" > diverged-remote.txt && git add diverged-remote.txt && git commit -q -m "remote diverge" && git push -q origin main )
git -C "$DIVERGED" fetch -q origin main

# 8) CONFLICT
CONFLICT="$TEST_ROOT/08-conflict"
rm -rf "$CONFLICT"
git clone -q "$REMOTE" "$CONFLICT"
git -C "$CONFLICT" checkout -B main origin/main
git -C "$CONFLICT" config user.name "AMA Robotics"
git -C "$CONFLICT" config user.email "ama@local"
( cd "$CONFLICT" && printf "same line\n" > clash.txt && git add clash.txt && git commit -q -m "base" && git checkout -q -b feature && printf "feature version\n" > clash.txt && git add clash.txt && git commit -q -m "feature change" && git checkout -q main && printf "main version\n" > clash.txt && git add clash.txt && git commit -q -m "main change" && git merge feature >/dev/null 2>&1 || true )

echo "Done. Test lab created at: $TEST_ROOT"
