set fish_greeting

fish_add_path $HOME/.local/bin

starship init fish | source

if type -q mise
    mise activate fish | source
end

direnv hook fish | source

alias cat="bat"
alias l="ls -alh"
alias la="ls -lAh"
alias ll="ls -l"
