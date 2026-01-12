#!/usr/bin/env bash

# Download script
# Download file content, store in memory and pass to a new bash as string with
# commands to execute.
# Use for manual commands e.g. copied from README
# Conventionally, use _ for arg0
/bin/bash -c "$(curl -fsSL <url>/install.sh)" <arg0> <arg1>
# Download file content as file stream. Bash uses process substitution and
# creates a temporary file descriptor
# under /dev/fd/<nr> and reads from it like a normal local script file.
# Use for commands inside a script.
/bin/bash <(curl -fsSL <url>/install.sh)

echo <(echo "hello") # /dev/fd/11

# output from subshell is returned as string
echo "$(echo "hello world")" # hello world

# quoting
# relevant is the outer quote. Here, "" allow variable expansion. '' are treated literally
echo "'$HOME'" # '/Users/julius'
# Here, '' treats everything literally when not used inside "" itself and allows no
# variable expansion.
echo '"$HOME"' # "$HOME"
# sometimes you need to quote
echo ""$HOME"" # /Users/julius
echo "\"$HOME\"" # "/Users/julius"


