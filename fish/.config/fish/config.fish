function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

function bind_bang
    switch (commandline -t)[-1]
        case "!"
            commandline -t -- $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function bind_dollar
    switch (commandline -t)[-1]
        case "!"
            commandline -f backward-delete-char history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

function fish_user_key_bindings
    bind ! bind_bang
    bind '$' bind_dollar
end

function fish_user_key_bindings
    fish_vi_key_bindings

    bind -M insert \cr history-pager
    bind -M insert \cp up-or-search
    bind -M insert \cn down-or-search
    bind -M insert ! bind_bang
    bind -M insert '$' bind_dollar
end

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship

    starship init fish | source
    if not set -q TMUX
        if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
            cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        end
    end

    # starship init fish | source
    # if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    #     cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    # end

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias rg grep

    # fzf.fish plugin
    fzf_configure_bindings --history= --directory=\ct --variables=\e\cv
    set fzf_fd_opts --hidden --max-depth 5

    # Setup zoxide
    zoxide init fish | source
end

export MANPAGER='nvim +Man!'
export LIBVA_DRIVER_NAME=iHD
export EZA_COLORS="*.sv=35;1"
