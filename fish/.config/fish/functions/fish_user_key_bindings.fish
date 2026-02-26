function fish_user_key_bindings
    fish_vi_key_bindings

    # Insert mode navigation
    bind -M insert \cr history-pager
    bind -M insert \cp up-or-search
    bind -M insert \cn down-or-search
    bind -M insert ! bind_bang
    bind -M insert '$' bind_dollar

    # Make vi mode yanks to clipboard
    bind yy kill-whole-line yank_to_clipboard yank
    bind Y kill-whole-line yank_to_clipboard yank
    bind y,\$ kill-line yank_to_clipboard yank
    bind y,\^ backward-kill-line yank_to_clipboard yank
    bind y,0 backward-kill-line yank_to_clipboard yank
    bind y,w kill-word yank_to_clipboard yank
    bind y,W kill-bigword yank_to_clipboard yank
    bind y,i,w forward-single-char forward-single-char backward-word kill-word yank_to_clipboard yank
    bind y,i,W forward-single-char forward-single-char backward-bigword kill-bigword yank_to_clipboard yank
    bind y,a,w forward-single-char forward-single-char backward-word kill-word yank_to_clipboard yank
    bind y,a,W forward-single-char forward-single-char backward-bigword kill-bigword yank_to_clipboard yank
    bind y,e kill-word yank_to_clipboard yank
    bind y,E kill-bigword yank_to_clipboard yank
    bind y,b backward-kill-word yank_to_clipboard yank
    bind y,B backward-kill-bigword yank_to_clipboard yank
    bind y,g,e backward-kill-word yank_to_clipboard yank
    bind y,g,E backward-kill-bigword yank_to_clipboard yank
    bind y,f begin-selection forward-jump kill-selection yank_to_clipboard yank end-selection
    bind y,t begin-selection forward-jump-till kill-selection yank_to_clipboard yank end-selection
    bind y,F begin-selection backward-jump kill-selection yank_to_clipboard yank end-selection
    bind y,T begin-selection backward-jump-till kill-selection yank_to_clipboard yank end-selection
    bind y,h backward-char begin-selection kill-selection yank_to_clipboard yank end-selection
    bind y,l begin-selection kill-selection yank_to_clipboard yank end-selection
    bind y,i,b jump-till-matching-bracket and jump-till-matching-bracket and begin-selection jump-till-matching-bracket kill-selection yank_to_clipboard yank end-selection
    bind y,a,b jump-to-matching-bracket and jump-to-matching-bracket and begin-selection jump-to-matching-bracket kill-selection yank_to_clipboard yank end-selection
    bind y,i backward-jump-till and repeat-jump-reverse and begin-selection repeat-jump kill-selection yank_to_clipboard yank end-selection
    bind y,a backward-jump and repeat-jump-reverse and begin-selection repeat-jump kill-selection yank_to_clipboard yank end-selection
    bind -M visual -m default y kill-selection yank_to_clipboard yank end-selection repaint-mode

    # Paste from system clipboard (vi mode)
    bind -s p 'set -g fish_cursor_end_mode exclusive' forward-char 'set -g fish_cursor_end_mode inclusive' fish_clipboard_paste
    bind -s P fish_clipboard_paste
end
