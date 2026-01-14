# Dotfiles
## Installation
1. Select the correct branch for your platform on the GitHub page

Supported platforms:
- macOS
- Linux
- Windows (WSL)
2. Run this shell command to install the dotfiles for your platform:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jufeic-work/dotfiles/refs/heads/macos/install.sh)"
```
3. Or run this shell command to install the dotfiles for all platforms:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jufeic-work/dotfiles/refs/heads/macos/install.sh)" _ all
```

## SSH configuration
```bash
ssh-keygen -t ed25519 -f '<path_to_private_key>' -C "$(id -un)@$(hostname -s)"
```
```bash
git config --file ~/.gitconfig.local user.signingkey '<path_to_private_key>'
```

## Prerequisites for macOS
- VS Code
- git
- curl

