on adding folder items to this_folder after receiving added_items
	set timestamp to do shell script "date +%s"
	repeat with i from 1 to length of added_items
		set current_item to item i of added_items
		set the item_path to the quoted form of the POSIX path of current_item

		try
			do shell script "~/.scripts/folder-action-downloads-airdrop-move " & item_path & space & timestamp
		on error
			return
		end try
	end repeat

	set dst to (POSIX file ((POSIX path of (path to home folder)) & "Library/Mobile Documents/com~apple~CloudDocs/airdrop") as alias)
	
	tell application "Finder"
		open dst
		set w to front window
		set index of w to 1
	end tell
end adding folder items to

