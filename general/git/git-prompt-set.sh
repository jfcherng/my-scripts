#!/usr/bin/env bash
#  Customize BASH PS1 prompt to show current GIT repository and branch.
#  by Mike Stewart - http://MediaDoneRight.com

#  SETUP CONSTANTS
#  Bunch-o-predefined colors.  Makes reading code easier than escape sequences.
#  I don't remember where I found this.  o_O

# Reset
Color_Off="\[\033[0m\]" # Text Reset

# Regular Colors
Black="\[\033[0;30m\]"  # Black
Red="\[\033[0;31m\]"    # Red
Green="\[\033[0;32m\]"  # Green
Yellow="\[\033[0;33m\]" # Yellow
Blue="\[\033[0;34m\]"   # Blue
Purple="\[\033[0;35m\]" # Purple
Cyan="\[\033[0;36m\]"   # Cyan
White="\[\033[0;37m\]"  # White

# Bold
BBlack="\[\033[1;30m\]"  # Black
BRed="\[\033[1;31m\]"    # Red
BGreen="\[\033[1;32m\]"  # Green
BYellow="\[\033[1;33m\]" # Yellow
BBlue="\[\033[1;34m\]"   # Blue
BPurple="\[\033[1;35m\]" # Purple
BCyan="\[\033[1;36m\]"   # Cyan
BWhite="\[\033[1;37m\]"  # White

# Underline
UBlack="\[\033[4;30m\]"  # Black
URed="\[\033[4;31m\]"    # Red
UGreen="\[\033[4;32m\]"  # Green
UYellow="\[\033[4;33m\]" # Yellow
UBlue="\[\033[4;34m\]"   # Blue
UPurple="\[\033[4;35m\]" # Purple
UCyan="\[\033[4;36m\]"   # Cyan
UWhite="\[\033[4;37m\]"  # White

# Background
On_Black="\[\033[40m\]"  # Black
On_Red="\[\033[41m\]"    # Red
On_Green="\[\033[42m\]"  # Green
On_Yellow="\[\033[43m\]" # Yellow
On_Blue="\[\033[44m\]"   # Blue
On_Purple="\[\033[45m\]" # Purple
On_Cyan="\[\033[46m\]"   # Cyan
On_White="\[\033[47m\]"  # White

# High Intensty
IBlack="\[\033[0;90m\]"  # Black
IRed="\[\033[0;91m\]"    # Red
IGreen="\[\033[0;92m\]"  # Green
IYellow="\[\033[0;93m\]" # Yellow
IBlue="\[\033[0;94m\]"   # Blue
IPurple="\[\033[0;95m\]" # Purple
ICyan="\[\033[0;96m\]"   # Cyan
IWhite="\[\033[0;97m\]"  # White

# Bold High Intensty
BIBlack="\[\033[1;90m\]"  # Black
BIRed="\[\033[1;91m\]"    # Red
BIGreen="\[\033[1;92m\]"  # Green
BIYellow="\[\033[1;93m\]" # Yellow
BIBlue="\[\033[1;94m\]"   # Blue
BIPurple="\[\033[1;95m\]" # Purple
BICyan="\[\033[1;96m\]"   # Cyan
BIWhite="\[\033[1;97m\]"  # White

# High Intensty backgrounds
On_IBlack="\[\033[0;100m\]"  # Black
On_IRed="\[\033[0;101m\]"    # Red
On_IGreen="\[\033[0;102m\]"  # Green
On_IYellow="\[\033[0;103m\]" # Yellow
On_IBlue="\[\033[0;104m\]"   # Blue
On_IPurple="\[\033[10;95m\]" # Purple
On_ICyan="\[\033[0;106m\]"   # Cyan
On_IWhite="\[\033[0;107m\]"  # White

# Various variables you might want for your PS1 prompt instead
Time12h="\T"
Time12a="\@"
PathShort="\W"
PathFull="\w"
NewLine="\n"
Jobs="\j"
Username="\u"
HostnameShort="\h"
HostnameFull="\H"
Dollar='$'

# This PS1 snippet was adopted from code for MAC/BSD I saw from:
# http://allancraig.net/index.php?option=com_content&view=article&id=108:ps1-export-command-for-git&catid=45:general&Itemid=96
# Re-written by Jack Cherng <jfcherng@gmail.com> for performance under Windows

export PS1="[${Username}@${HostnameShort} ${IYellow}${PathShort}${Color_Off}]"'\
$( \
    { \
        # from git rev-parse
        read _is_bare; \
        read _is_shallow; \
        read _is_in_git_dir; \
        read _is_in_work_tree; \
        # from git status
        read _st_oid; \
        read _st_head; \
        read -d "" _st; \
    } <<< "$( \
        git rev-parse \
            --is-bare-repository \
            --is-shallow-repository \
            --is-inside-git-dir \
            --is-inside-work-tree \
            2>/dev/null \
        && git status --porcelain=2 --branch 2>/dev/null \
    )"; \
\
    # not git-managed
    [[ -z $_is_bare ]] && exit; \
    # early stop if bare repository
    [[ $_is_bare == "true" ]] && echo -n "('${BICyan}'bare'${Color_Off}')" && exit; \
    # early stop if in .git repository
    [[ $_is_in_git_dir == "true" ]] && echo -n "('${BICyan}'git-dir'${Color_Off}')" && exit; \
    # early stop if not in work tree directory
    [[ $_is_in_work_tree == "false" ]] && exit; \
\
    # "upstream" and "ab" are not present if non-detached HEAD
    [[ ${_st} =~ ^\\# ]] && { read _st_upstream; read -d "" _st; } <<< "${_st}"; \
    [[ ${_st} =~ ^\\# ]] && { read _st_ab; read -d "" _st; } <<< "${_st}"; \
\
    [[ ${_st_oid} =~ \.oid\ ([^\r\n]*) ]] && _branch_oid="${BASH_REMATCH[1]}"; \
    [[ ${_st_head} =~ \.head\ ([^\r\n]*) ]] && _branch_name="${BASH_REMATCH[1]}"; \
    [[ ${_st_upstream} =~ \.upstream\ ([^\r\n]*) ]] && _branch_upstream="${BASH_REMATCH[1]}"; \
    [[ ${_st_ab} =~ \.ab\ ([^\r\n]*) ]] && _branch_ab="${BASH_REMATCH[1]}"; \
\
    [[ ${_is_shallow} == "true" ]] \
        && shallow_sign="'${BICyan}'!'${Color_Off}'" \
        || shallow_sign=; \
\
    [[ ${_st} =~ ^[^#] ]] \
        && branch_name="'${BIRed}'${_branch_name}'${Color_Off}'" \
        || branch_name="'${BIGreen}'${_branch_name}'${Color_Off}'"; \
\
    if [[ ${_branch_oid} == "(initial)" ]]; then \
        # there is no commit yet
        branch_status="('${BICyan}'initial'${Color_Off}')"; \
    else \
        [[ ${_branch_ab} =~ \\+([0-9]+)\ -([0-9]+) ]] && branch_status="'${BIGreen}'>${BASH_REMATCH[1]}'${Color_Off}${BIRed}'<${BASH_REMATCH[2]}'${Color_Off}'"; \
        branch_status="${branch_status/'${BIGreen}'>0'${Color_Off}'/}"; \
        branch_status="${branch_status/'${BIRed}'<0'${Color_Off}'/}"; \
    fi; \
\
    echo -n "(${branch_name})${shallow_sign}${branch_status}"; \
)'"${Dollar} "
