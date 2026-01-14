#!/usr/bin/env bash

# TODO: Alternative would be to just use the correct branch already in the
# install script.
# install.sh - Install script for dotfiles
#
# Usage:
	# ./install.sh [system]
#
# Arguments:
	# system: macos|linux|linux-headless|wsl
		# Optional. Target system to install. If omitted, macOS is assumed
		# but all others are pulled too.

DOTFILES_URL="git@github.com:jufeic-work/dotfiles.git"

cd "$HOME"
if [[ ! -d "$HOME/dotfiles" ]]; then
	echo "Cloning dotfiles"
	if [[ -n "$1" ]]; then
		git clone -b "$1" --single-branch "$DOTFILES_URL" || {
			echo "System '$1' not supported" >&2
			exit 1
		}
	else
		git clone "$DOTFILES_URL"
	fi
else
	echo "Dotfiles already cloned"
fi

if ! command -v brew &> /dev/null; then
	echo "Installing Homebrew"
	bash <(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
else
	echo "Homebrew already installed"
fi

# Execute the commands printed by the 'shellenv' command using eval to prepare the
# shell environment in this script to use the brew command directly. To
# execute the 'shellenv' command, the full path to the binary has to be provided
# since the shell environment does not know brew until now.
if [[ $(uname) == "Darwin" ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
else
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ ! -f "$HOME/dotfiles/git/.gitconfig.local" ]; then
	cat <<- 'EOF' > "$HOME/dotfiles/git/.gitconfig.local"
	# This file is intended for git configurations that are sensitive
	# and should therefore not be part of the published ~/.gitconfig
	EOF
fi

brew bundle install --file="$HOME/dotfiles/brew/Brewfile"

if [[ $(uname) == "Linux" ]]; then
	# in macos zsh is already preinstalled
	brew install zsh
	# if zsh is not in the allowed shells, add it
	if ! grep -Fxq "$(brew --prefix)/bin/zsh" /etc/shells; then
		echo "$(brew --prefix)/bin/zsh" | sudo tee -a /etc/shells
	fi
	sudo chsh -s "$(brew --prefix)/bin/zsh" $(whoami)
	sudo ln -sf "$(brew --prefix)/bin/zsh" /bin/zsh
	# wsl
	if [ -n "$WSL_INTEROP" ]; then
		# issue a code command to trigger installing the vscode server if not already installed
		code --version
		# change into a windows directory before executing the cmd.exe command
		# this will prevent path warnings
		cd "$(dirname "$(which code)")"
		# make sure that the directory exists before symlinking
		# mkdir -p $HOME/.vscode-server/data/Machine
		# $(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t "$HOME/.vscode-server/data/Machine" -S vscode
		# create windows symlinks
		windows_username="$(cmd.exe /c "echo %USERNAME%")"
		for file in "$HOME/dotfiles/vscode"/*; do
			file_name="$(basename $file)"
			cmd.exe /c "mklink C:\\Users\\$windows_username\\AppData\\Roaming\\Code\\User\\$file_name \\\\wsl$\\$WSL_DISTRO_NAME\\home\\$(id -un)\\dotfiles\\vscode\\$file_name"
		done

		# install extensions on the windows side since the installation in WSL using the code.sh is not supported
		# only possible from integrated terminal in vscode or manually in the UI
		code_wsl_path="$(which code)"
		code_windows_path="${code_wsl_path#/mnt/}"
		code_windows_path="${code_windows_path//\//\\}"
		code_windows_path="$(echo "$code_windows_path" | sed 's/^\(.\)/\U\1:/')"
		xargs -n 1 cmd.exe /c "$code_windows_path" --install-extension < $HOME/dotfiles/vscode/vscode-extensions.txt
	fi
fi

$(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t $HOME -S zsh tmux ripgrep git gpg scripts templates
# distinguish between OS and separately apply the stow vscode config
# set a different target directory for vscode config so dont try to set the whole
# path just generalize it under a vscode folder and the target is then dependent on OS
if [[ $(uname) == "Darwin" ]]; then
	# rm -rf "$HOME/Library/Application Support/lazygit/config.yml"
	$(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t "$HOME/Library/Application Support/lazygit" -S lazygit
	$(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t "$HOME" -S folder-actions
	$(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t "$HOME/Library/Application Support/Code/User" -S vscode
	xargs -n 1 code --install-extension < $HOME/dotfiles/vscode/vscode-extensions.txt
fi

mkdir -p $HOME/dev $HOME/hda $HOME/work
touch $HOME/.zsh_history
