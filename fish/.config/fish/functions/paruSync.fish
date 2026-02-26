function paruSync
    set keyword $argv

    if test -z "$keyword"
        read -P (set_color -o blue)"::"(set_color -o normal)" Search AUR: " keyword
    end

    if test -n "$keyword"
        paru -Ssq "$keyword" | fzf --multi --preview 'paru -Si {1}' | xargs -ro paru -S
    end
end
