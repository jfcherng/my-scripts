### Usage:
### In your '~/.tcshrc', add the following line:
###     alias precmd "source PATH_OF_THIS_FILE"
### And then do $ source ~/.tcshrc

# Reset
set Color_Off="%{\033[0m%}"       # Text Reset

# Regular Colors
set Black="%{\033[0;30m%}"        # Black
set Red="%{\033[0;31m%}"          # Red
set Green="%{\033[0;32m%}"        # Green
set Yellow="%{\033[0;33m%}"       # Yellow
set Blue="%{\033[0;34m%}"         # Blue
set Purple="%{\033[0;35m%}"       # Purple
set Cyan="%{\033[0;36m%}"         # Cyan
set White="%{\033[0;37m%}"        # White

# Bold
set BBlack="%{\033[1;30m%}"       # Black
set BRed="%{\033[1;31m%}"         # Red
set BGreen="%{\033[1;32m%}"       # Green
set BYellow="%{\033[1;33m%}"      # Yellow
set BBlue="%{\033[1;34m%}"        # Blue
set BPurple="%{\033[1;35m%}"      # Purple
set BCyan="%{\033[1;36m%}"        # Cyan
set BWhite="%{\033[1;37m%}"       # White

# Underline
set UBlack="%{\033[4;30m%}"       # Black
set URed="%{\033[4;31m%}"         # Red
set UGreen="%{\033[4;32m%}"       # Green
set UYellow="%{\033[4;33m%}"      # Yellow
set UBlue="%{\033[4;34m%}"        # Blue
set UPurple="%{\033[4;35m%}"      # Purple
set UCyan="%{\033[4;36m%}"        # Cyan
set UWhite="%{\033[4;37m%}"       # White

# Background
set On_Black="%{\033[40m%}"       # Black
set On_Red="%{\033[41m%}"         # Red
set On_Green="%{\033[42m%}"       # Green
set On_Yellow="%{\033[43m%}"      # Yellow
set On_Blue="%{\033[44m%}"        # Blue
set On_Purple="%{\033[45m%}"      # Purple
set On_Cyan="%{\033[46m%}"        # Cyan
set On_White="%{\033[47m%}"       # White

# High Intensty
set IBlack="%{\033[0;90m%}"       # Black
set IRed="%{\033[0;91m%}"         # Red
set IGreen="%{\033[0;92m%}"       # Green
set IYellow="%{\033[0;93m%}"      # Yellow
set IBlue="%{\033[0;94m%}"        # Blue
set IPurple="%{\033[0;95m%}"      # Purple
set ICyan="%{\033[0;96m%}"        # Cyan
set IWhite="%{\033[0;97m%}"       # White

# Bold High Intensty
set BIBlack="%{\033[1;90m%}"      # Black
set BIRed="%{\033[1;91m%}"        # Red
set BIGreen="%{\033[1;92m%}"      # Green
set BIYellow="%{\033[1;93m%}"     # Yellow
set BIBlue="%{\033[1;94m%}"       # Blue
set BIPurple="%{\033[1;95m%}"     # Purple
set BICyan="%{\033[1;96m%}"       # Cyan
set BIWhite="%{\033[1;97m%}"      # White

# High Intensty backgrounds
set On_IBlack="%{\033[0;100m%}"   # Black
set On_IRed="%{\033[0;101m%}"     # Red
set On_IGreen="%{\033[0;102m%}"   # Green
set On_IYellow="%{\033[0;103m%}"  # Yellow
set On_IBlue="%{\033[0;104m%}"    # Blue
set On_IPurple="%{\033[10;95m%}"  # Purple
set On_ICyan="%{\033[0;106m%}"    # Cyan
set On_IWhite="%{\033[0;107m%}"   # White

# prompt
setenv GIT_BRANCH_CMD "sh -c 'git branch --no-color 2> /dev/null' | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'"
git diff --exit-code >& /dev/null
set not_staged=$?
git diff --cached --exit-code >& /dev/null
set not_committed=$?
git status >& /dev/null && set untracked_files=`git ls-files --other --exclude-standard --directory --no-empty-directory`
if ( $not_staged ) then
  #if any file is not staged, show red color.
  set GIT_BRANCH_COLOR="${Red}"
else if ( $not_committed ) then
  #else if any file is not commited, show bright red color.
  set GIT_BRANCH_COLOR="${IRed}"
else if ( "empty$untracked_files" != "empty" ) then
  #else if any file is untracked, show yellow color.
  set GIT_BRANCH_COLOR="${Yellow}"
else
  #else, show green color.
  set GIT_BRANCH_COLOR="${Green}"
endif
set prompt="[%n@%m ${IYellow}%c${Color_Off}]${GIT_BRANCH_COLOR}`$GIT_BRANCH_CMD`${Color_Off}$ "
