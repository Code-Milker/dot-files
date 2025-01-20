#kj Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/tylerfischer/.zsh/completions:"* ]]; then export FPATH="/Users/tylerfischer/.zsh/completions:$FPATH"; fi
. "/Users/tylerfischer/.deno/env"
# Initialize zsh completions (added by deno install script)
autoload -Uz compinit
compinit


fcd() {
  dir=$(find ~/notes ~/projects ~/documents ~/downloads -type d -maxdepth 3 \
    -not -path "*/node_modules/*" \
    -not -path "*/.*" \
    -print 2>/dev/null | fzf --height 40%) &&
  cd "$dir"
}


alias reload="source /Users/tylerfischer/.config/zsh/.zshrc"
