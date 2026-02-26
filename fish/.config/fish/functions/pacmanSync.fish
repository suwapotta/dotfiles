function pacmanSync
    pacman -Slq | fzf --multi --query "$argv" --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S
end
