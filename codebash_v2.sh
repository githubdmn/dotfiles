#!/usr/bin/env bash
# ~/bin/dev.sh
SESSION=code
BASE=~/projects

# window name : directory
WINDOWS=(
  "js:codejs"
  "java:codejava"
  "py:codepy"
  "go:codego"
  "bash:bash"
  "db:database"
)

# If the session already exists, just attach
tmux has-session -t "$SESSION" 2>/dev/null && exec tmux attach -t "$SESSION"

# Window 0: plain shell in your home directory
tmux new-session -d -s "$SESSION" -n main -c "$HOME"

for entry in "${WINDOWS[@]}"; do
  name="${entry%%:*}"
  dir="$BASE/${entry##*:}"
  mkdir -p "$dir"

  tmux new-window -t "$SESSION:" -n "$name" -c "$dir"

  # Left pane: nvim, right pane: regular shell
  tmux send-keys -t "$SESSION:$name" 'nvim .' C-m
  tmux split-window -h -t "$SESSION:$name" -c "$dir"
  tmux select-pane -t "$SESSION:$name" -L   # focus back on nvim
done

tmux select-window -t "$SESSION:main"
exec tmux attach -t "$SESSION"

