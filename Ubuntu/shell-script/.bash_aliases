scriptDir=/opt/shell-script

### my settings
source "$scriptDir/git-prompt.sh"
source "$scriptDir/git-prompt-set.sh"
source "$scriptDir/git-completion.bash"

export PATH="/opt/sublime_text/bin_linux:$PATH"

alias ll='ls -alFh --color=auto'
alias grep='grep -n --color=auto'
alias g='git'
alias ssh='ssh -c aes128-gcm@openssh.com,aes128-ctr,arcfour,blowfish-cbc -XC'
alias cls="echo -ne '\0033\0143'"
alias fixpaste='printf "\e[?2004l"'
alias rg='rg --no-heading --follow'

alias cdtf="cd ~/Desktop/repo/tensorflow"

fixpaste

