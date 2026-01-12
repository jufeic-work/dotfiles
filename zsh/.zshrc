# User configuration
export KERNEL=$(uname)
if [[ $KERNEL == "Darwin" ]]; then
  # macos
  export CLIPBOARD="pbcopy"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # linux
  if [ -n "$WSL_INTEROP" ]; then
    # wsl
    export CLIPBOARD="clip.exe"
		alias open="powershell.exe start explorer.exe"
  else
    # no wsl
    export CLIPBOARD="xclip -selection clipboard"
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# avoid duplicates on path
typeset -U path
# so that we can call functions with $() in the prompt in themes
setopt PROMPT_SUBST
set -o pipefail
export FZF_DEFAULT_OPTS="--exact"
if [[ $TERM_PROGRAM == "tmux" ]]; then
	export FZF_CTRL_R_OPTS="--tmux=60% --color='bg:#292C34'"
fi
# old: solarized
export BAT_THEME="TwoDark"
export RG_DIRS="$HOME/dotfiles $HOME/hda $HOME/dev $HOME/work"
# use nvim as the pager for the 'man' command instead of less
# q works to exit like in less
export MANPAGER='nvim +Man!'
# export MANPAGER='bat -lman -pp'
# export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
# enable syntax highlighting for help page of commands
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

export LIMA_INSTANCE="bpf"
export LIMA_WORKDIR="/home/julius"

# history
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=200000
export SAVEHIST=$HISTSIZE

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt INC_APPEND_HISTORY
# if a line has no trailing newline char like with echo -n 'something' and PROMPT_SP
# is not disabled, zsh will print a % or # instead of the missing newline char
# to avoid the % char e.g. if tmux sends keys before completely loaded
# but it is recommended not to disable PROMPT_SP or PROMPT_CR as it can cause
# disappearing of lines without trailing newline
# unsetopt PROMPT_SP
# the default % or # can be changed by setting this shell parameter
# PROMPT_EOL_MARK=''
# PROMPT_EOL_MARK='%K{red} '
# to avoid the beep sound in the terminal
unsetopt BEEP

autoload -U colors && colors

# theme
export ZSH=$HOME/.zsh
fpath+=$ZSH/completion
source $ZSH/themes/jjcol.zsh-theme

# Preferred editor for local and remote sessions
export EDITOR='nvim'

# !alias
alias v=nvim
alias vi=nvim
alias vim=nvim
alias k=kubectl
alias docker=podman
alias lg=lazygit
alias week='date +%V'
alias ll='ls -lAhFG --color'
alias rm='rm -I'
alias ghrf='gh repo fork --clone --default-branch-only'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
-() {
  cd -
}

podman() {
	if [ "$1" = "run" ]; then
		shift
		# need to use the command utility so that the "podman" command is
		# not interpreted as call to this function again -> recursive
		command podman run --cidfile="$(pwd)"/.cid-"$(basename $(tmux display-message -p '#{pane_tty}'))" "$@"
	else
		command podman "$@"
	fi
}

# load this module to be able to bind keys for selecting stuff from completion menu
zmodload zsh/complist
bindkey -v
export KEYTIMEOUT=1
bindkey -M viins "^?" backward-delete-char
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# bindkey -M vicmd -r 's'
# surrounding functionality
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -a cs change-surround
bindkey -a ds delete-surround
# bindkey -a ys add-surround
# bindkey -M vicmd cs change-surround
# bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround

# visually select inside quotes/brackets functionality
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km -- $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km -- $c select-bracketed
  done
done

cursor_mode() {
  cursor_block='\e[2 q'
  cursor_beam='\e[6 q'

  zle-keymap-select() {
    if [[ ${KEYMAP} == vicmd ]] ||
	[[ $1 = 'block' ]]; then
	echo -ne $cursor_block
    elif [[ ${KEYMAP} == main ]] ||
	  [[ ${KEYMAP} == viins ]] ||
	  [[ ${KEYMAP} = '' ]] ||
	  [[ $1 = 'beam' ]]; then
	echo -ne $cursor_beam
    fi
  }

  zle-line-init() {
    echo -ne $cursor_beam
  }

  zle -N zle-keymap-select
  zle -N zle-line-init
}

cursor_mode

vi-yank-clipboard() {
	zle vi-yank
	echo -n "$CUTBUFFER" | $CLIPBOARD
}

zle -N vi-yank-clipboard
# yy still only yanks the current line; so for multiline commands one has to
# press V, highlight everything and press y
bindkey -M vicmd 'y' vi-yank-clipboard

# this function is to open playground main file in go to try out things very quick
test-go() {
	mkdir -p $HOME/dev/go/test
	truncate -s 0 $HOME/dev/go/test/main.go
	echo -e 'package main\n\nfunc main() {\n\n}' > $HOME/dev/go/test/main.go
	code $HOME/dev/go/test -g "$HOME/dev/go/test/main.go:4"
}

path=("$HOME/.scripts" $path)

[ -f ~/.secrets ] && source ~/.secrets

if [[ -z "$NO_TMUX" && $TERM_PROGRAM != "vscode" ]]; then
	if command -v tmux &> /dev/null && ( ! tmux info &> /dev/null || [ -z "$TMUX" ] ); then
		tmux attach &>/dev/null || tmux new -s '~/dev' -c "$HOME/dev"
		# tmux attach -t '~/dev' || tmux new -s '~/dev' -c "$HOME/dev"
	fi
fi

# configure completion
autoload -Uz compinit
compinit
# enables the behavior for: cd <Tab><Tab> to get an menu to select from completion
zstyle ':completion:*' menu select
# also consider dotfiles when doing e.g. vi <Tab>
_comp_options+=(globdots)

# Set up fzf key bindings like <C-r> and fuzzy completion
source <(fzf --zsh)

if command -v kind &> /dev/null; then
	source <(kind completion zsh)
fi

# either this to generate the completion functions in a file belonging to fpath
# podman completion zsh -f "$ZSH/completion/_podman"
# or directly source the output without extra file
if command -v podman &> /dev/null; then
	source <(podman completion zsh)
fi

path=($path /opt/homebrew/opt/node@20/bin)

path=(/usr/local/go/bin $path)
if command -v go &> /dev/null; then
	path=("$(go env GOPATH)/bin" $path)
fi
path=($path /usr/local/texlive/2024/bin/universal-darwin)


bd () {
  (($#<1)) && {
    printf -- 'usage: %s <name-of-any-parent-directory>\n' "${0}"
    printf -- '       %s <number-of-folders>\n' "${0}"

    return 1
  } >&2

  local requestedDestination="${1}"
  local -a parents=(${(ps:/:)"${PWD}"})
  local numParents
  local dest
  local i
  local parent

  # prepend root to the parents array
  parents=('/' "${parents[@]}")

  # Remove the current directory since it isn't a parent
  shift -p parents

  # Get the number of parent directories
  numParents="$(( ${#parents[@]}))"

  # Build dest and 'cd' to it by looping over the parents array in reverse
  dest='./'
  for i in $(seq "${numParents}" -1 1); do
    parent="${parents[${i}]}"
    dest+='../'

    if [[ "${requestedDestination}" == "${parent}" ]]; then
      cd $dest

      return $?
    fi
  done

  # If the user provided an integer, go up as many times as asked
  dest='./'
  if [[ "${requestedDestination}" == <-> ]]; then
    if [[ "${requestedDestination}" -gt "${numParents}" ]]; then
      printf -- '%s: Error: Can not go up %s times (not enough parent directories)\n' "${0}" "${requestedDestination}"
      return 1
    fi

    for i in {1.."${requestedDestination}"}; do
      dest+='../'
    done

    cd "${dest}"

    return $?
  fi

  # If the above methods fail
  printf -- '%s: Error: No parent directory named "%s"\n' "${0}" "${requestedDestination}"
  return 1
}

_bd () {
  # Get parents (in reverse order)
  local localMatcherList
  local -a parents=(${(ps:/:)"${PWD}"})
  local numParents
  local i
  local -a parentsReverse

  zstyle -s ':completion:*' 'matcher-list' 'localMatcherList'

  # prepend root to the parents array
  parents=('/' "${parents[@]}")

  # Remove the current directory since it isn't a parent
  shift -p parents

  # Get the number of parent directories
  numParents="$(( ${#parents[@]}))"

  parentsReverse=()
  for i in $(seq "${numParents}" -1 1); do
    parentsReverse+=("${parents[${i}]}")
  done

  local expl
  _wanted -V directories expl 'parent directories' \
    compadd -M "${localMatcherList}" "$@" -- "${parentsReverse[@]}"
}

# this can only be called after autoload -Uz compinit;compinit (completion initialized)
compdef _bd bd

() {
  local -a colors
  local dir_color='1;31' # hard-coded default in zsh/complist

  # check for defined zstyle
  if zstyle -a ':completion:*' list-colors colors && [[ "$#colors" -ne 0 ]]; then
    local zstyle_color="${colors[(r)di=*]#di=}"
    if [[ -n "$zstyle_color" ]]; then
        dir_color="$zstyle_color"
    fi
  else
    return
  fi

  zstyle ':completion:*:*:bd:*:directories' list-colors "=*=${dir_color}"
}

# switch to any directory in the specified locations
sd() {
	NEW_DIR=$(
		fd \
			--type d \
			-d 5 \
			--search-path=$HOME/dotfiles \
			--search-path=$HOME/dev \
			--search-path=$HOME/work \
			--search-path=$HOME/hda | \
		fzf \
			--reverse \
			--tmux 80% \
			--keep-right \
			--color='bg:#292C34' \
			--preview-window=55% \
			--preview 'ls -lAhF --color {}' \
	) || return 0
	cd $NEW_DIR
}

# switch to some subdirectory of the current directory
sdl() {
	NEW_DIR=$(
		fd \
			--type d \
			-d 8 | \
		fzf \
			--reverse \
			--tmux 80% \
			--keep-right \
			--color='bg:#292C34' \
			--preview-window=55% \
			--preview 'ls -lAhF --color {}' \
	) || return 0
	cd $NEW_DIR
}

# enable tab completion for shell aliases
zstyle ':completion:*' completer _expand_alias _complete _ignored

# zsh plugins
# the highlighting need to be sourced at the VERY end of .zshrc
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

