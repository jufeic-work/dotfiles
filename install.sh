#!/usr/bin/env bash

# TODO: Alternative would be to just use the correct branch already in the
# install script.
# install.sh - Install script for dotfiles
#
# Usage:
	# ./install.sh [all]
#
# Arguments:
	# all:
		# Optional. If provided, macOS is assumed as platform
		# but all others are pulled too.

DOTFILES_URL="https://github.com/jufeic/dotfiles.git"

cd "$HOME"
if [[ ! -d "$HOME/dotfiles" ]]; then
	echo "Cloning dotfiles"
	if [[ -z "$1" ]]; then
		git clone -b "wsl" --single-branch "$DOTFILES_URL"
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
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

if [ ! -f "$HOME/dotfiles/git/.gitconfig.local" ]; then
	cat <<- 'EOF' > "$HOME/dotfiles/git/.gitconfig.local"
	# This file is intended for git configurations that are sensitive
	# and should therefore not be part of the published ~/.gitconfig
	EOF
fi

brew bundle install --file="./brew/Brewfile"

# if zsh is not in the allowed shells, add it
if ! grep -Fxq "$(brew --prefix)/bin/zsh" /etc/shells; then
	echo "$(brew --prefix)/bin/zsh" | sudo tee -a /etc/shells
fi
sudo chsh -s "$(brew --prefix)/bin/zsh" $(whoami)
sudo ln -sf "$(brew --prefix)/bin/zsh" /bin/zsh

# WSL-specific part
# One could also check, if WSL_INTEROP env var is set.
# We use the Windows version of VS code as we run WSL without GUI. Therefore,
# it must already be installed and available via command line.
# Execute a vscode command to trigger installing the vscode server if not already installed
code --version
# change into a Windows directory before executing the cmd.exe command
# to prevent path warnings
cd "$(dirname "$(which code)")"
# make sure that the directory exists before symlinking
# mkdir -p $HOME/.vscode-server/data/Machine
# $(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t "$HOME/.vscode-server/data/Machine" -S vscode
# create Windows symlinks
# cannot use stow for vscode config, because Windows symlinks need to be created and
# not Linux symlinks.
windows_username="$(cmd.exe /c "echo %USERNAME%")"
for file in "$HOME/dotfiles/vscode"/*; do
	file_name="$(basename $file)"
	cmd.exe /c "mklink C:\\Users\\$windows_username\\AppData\\Roaming\\Code\\User\\$file_name "\
		"\\\\wsl$\\$WSL_DISTRO_NAME\\home\\$(id -un)\\dotfiles\\vscode\\$file_name"
done

# install extensions on the windows side since the installation in WSL using the code.sh is not supported
# only possible from integrated terminal in vscode or manually in the UI
code_wsl_path="$(which code)"
code_windows_path="${code_wsl_path#/mnt/}"
code_windows_path="${code_windows_path//\//\\}"
code_windows_path="$(echo "$code_windows_path" | sed 's/^\(.\)/\U\1:/')"
xargs -n 1 cmd.exe /c "$code_windows_path" --install-extension < "$HOME/dotfiles/vscode/vscode-extensions.txt"

# Default nvim config location under Unix (Linux+macOS): ~/.config/nvim
"$(brew --prefix)/bin/stow" -v 2 -d "$HOME/dotfiles" -t "$HOME" -S \
	git \
	gpg \
	lazygit \
	nvim \
	ripgrep \
	scripts \
	templates \
	tmux \
	zsh

mkdir -p "$HOME/dev" "$HOME/hda" "$HOME/work"
touch "$HOME/.zsh_history"
