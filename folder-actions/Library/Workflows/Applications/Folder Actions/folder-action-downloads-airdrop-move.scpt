on adding folder items to this_folder after receiving added_items
	repeat with i from 1 to length of added_items
		set current_item to item i of added_items
		set the item_path to the quoted form of the POSIX path of current_item
		do shell script "~/.scripts/folder-action-downloads-airdrop-move " & item_path
	end repeat
end adding folder items to

