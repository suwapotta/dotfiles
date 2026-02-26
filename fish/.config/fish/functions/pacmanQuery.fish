function pacmanQuery
    pacman -Qq | fzf --multi --query "$argv" --preview 'pacman -Qi {1}'
end
