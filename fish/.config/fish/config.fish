function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    enable_transience
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
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias yay paru
    alias tldrQuery 'tldr -l | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr'
    alias lg lazygit

    # fzf.fish plugin
    fzf_configure_bindings --history= --directory=\ct --variables=\e\cv
    set fzf_fd_opts --hidden --max-depth 5

    # Setup zoxide
    zoxide init fish | source
end

set -gx SUDO_PROMPT (set_color -u -o red)"[sudo]"(set_color -u cyan) "Enter password %p:  "(set_color normal)
export MANPAGER='nvim +Man!'
export LIBVA_DRIVER_NAME=iHD
export EZA_COLORS="*.txt=35:*.md=35:*.kdl=33:*.sv=33"
