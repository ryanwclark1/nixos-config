#!/usr/bin/env bash

# Set default FZF options
FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --header='Select clipboard history. Press TAB to mark multiple items.'"

# Get the script's directory
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
source "$CURRENT_DIR/.envs"

# Determine which clipboard manager is available
if command -v cliphist &>/dev/null; then
    CLIPBOARD_TOOL="cliphist"
elif command -v copyq &>/dev/null; then
    CLIPBOARD_TOOL="copyq"
else
    CLIPBOARD_TOOL="tmux"
fi

# Determine action mode
if [[ "$CLIPBOARD_TOOL" == "tmux" ]]; then
    action="buffer"
elif [[ -z "$1" ]]; then
    action="system"
else
    action="$1"
fi

# Handle clipboard history selection
if [[ "$action" == "system" ]]; then
    if [[ "$CLIPBOARD_TOOL" == "cliphist" ]]; then
        # Get clipboard history using cliphist
        contents="[cancel]\n$(cliphist list | nl -w2 -s': ')"
        
        # Select entry using fzf
        selected_index=$(printf "%s" "$contents" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS" | awk -F':' '{print $1}' | tr -d ' ')
        
        # Exit if selection is canceled
        [[ "$selected_index" == "[cancel]" || -z "$selected_index" ]] && exit
        
        # Paste selected item from cliphist
        cliphist decode "$selected_index" | tmux load-buffer - && tmux paste-buffer
    elif [[ "$CLIPBOARD_TOOL" == "copyq" ]]; then
        # Get clipboard history using copyq
        item_numbers=$(copyq count)
        contents="[cancel]\n"
        index=0
        while [ "$index" -lt "$item_numbers" ]; do
            _content="$(copyq read "$index" | tr '\n' ' ' | tr '\\n' ' ')"
            contents="${contents}copy${index}: ${_content}\n"
            index=$((index + 1))
        done
        
        # Select entry using fzf
        copyq_index=$(printf "%s" "$contents" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --preview=\"echo {} | sed -e 's/^copy//' -e 's/: .*//' | xargs -I{} copyq read {}\"" | sed -e 's/^copy//' -e 's/: .*//')
        
        # Exit if selection is canceled
        [[ "$copyq_index" == "[cancel]" || -z "$copyq_index" ]] && exit
        
        # Paste selected item from copyq
        copyq read "$copyq_index" | tmux load-buffer - && tmux paste-buffer
    fi

# Handle TMUX buffer selection if no clipboard manager is available
elif [[ "$action" == "buffer" ]]; then
    selected_buffer=$(tmux list-buffers | sed -e 's/:.*bytes//' -e '1s/^/[cancel]\n/' -e 's/: "/: /' -e 's/"$//' | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --preview=\"echo {} | sed -e 's/\[cancel\]//' -e 's/:.*$//' | head -1 | xargs tmux show-buffer -b\"" | sed 's/:.*$//')
    
    # Exit if selection is canceled
    [[ "$selected_buffer" == "[cancel]" || -z "$selected_buffer" ]] && exit
    
    # Paste the selected TMUX buffer
    tmux paste-buffer -b "$selected_buffer"
fi
