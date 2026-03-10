#!/bin/zsh
# Captures zsh completion candidates for a given command line.
# Adapted from Valodim/zsh-capture-completion.
#
# Usage: zsh zsh_complete.zsh <completion-script> <command-line>

zmodload zsh/zpty || { echo 'error: missing module zsh/zpty' >&2; exit 1 }

local comp_script=$1
local command_line=$2

# Extract executable name and completion function from the script
local exe_name=$(sed -n 's/^#compdef //p' $comp_script)
local comp_func=$(tail -1 $comp_script)

local init_script=$(mktemp)
trap "rm -f $init_script" EXIT
cat > $init_script << 'INIT'
PROMPT=
autoload compinit
compinit -u -d /dev/null
bindkey '^I' complete-word
null-line () { echo -E - $'\0' }
compprefuncs=( null-line )
comppostfuncs=( null-line exit )
zstyle ':completion:*' list-grouped false
zstyle ':completion:*' insert-tab false
zstyle ':completion:*' list-separator ''
zmodload zsh/zutil

compadd () {
    if [[ ${@[1,(i)(-|--)]} == *-(O|A|D)\ * ]]; then
        builtin compadd "$@"
        return $?
    fi

    typeset -a __hits __dscr __tmp

    if (( $@[(I)-d] )); then
        __tmp=${@[$[${@[(i)-d]}+1]]}
        if [[ $__tmp == \(* ]]; then
            eval "__dscr=$__tmp"
        else
            __dscr=( "${(@P)__tmp}" )
        fi
    fi

    builtin compadd -A __hits -D __dscr "$@"
    setopt localoptions norcexpandparam extendedglob
    [[ -n $__hits ]] || return

    local dsuf dscr
    for i in {1..$#__hits}; do
        (( $#__dscr >= $i )) && dscr=" -- ${${__dscr[$i]}##$__hits[$i] #}" || dscr=
        echo -E - $__hits[$i]$dscr
    done
}

echo ok
INIT

zpty z zsh -f -i

local line

# Wait for init to complete
zpty -w z "source '$init_script'"
repeat 8; do
    zpty -r z line
    [[ $line == *ok* ]] && break
done

# Source the completion script and wait for it
zpty -w z "source '$comp_script'; compdef $comp_func $exe_name; echo ready"
repeat 8; do
    zpty -r z line
    [[ $line == *ready* ]] && break
done

# Send command line + Tab, then read until pty closes
zpty -w z "$command_line"$'\t'

integer tog=0
{ while zpty -r z; do :; done } | while IFS= read -r line; do
    if [[ $line == *$'\0'* ]]; then
        (( tog++ )) && return 0 || continue
    fi
    if (( tog )); then
        line=${line//$'\r'/}
        line=${line//$'\e['[0-9;]#[a-zA-Z]/}
        [[ -n $line ]] && echo -E - $line
    fi
done

exit 2
