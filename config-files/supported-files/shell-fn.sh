#!/bin/bash
prompt () {
    while true; do
        read -p "$1 (y/N): " userResponse
        case $userResponse in
            [YNyn])
                break;;
            *)
                echo "Please answer in Y/N"
        esac
    done
    # I use Mac to develop it. On Bash version >4, ${userResponse^^} is better option
    userResponse=$(echo "${userResponse}" | tr '[:lower:]' '[:upper:]')
}
#
promptOpt () {
    local optType="$1"      # Save first argument in a variable
    shift                   # Shift all arguments to the left (original $1 gets lost)
    local optChoice=("$@")  # Rebuild the array with rest of arguments
    PS3="Please enter your choice of ${optType}: "
    select userOption in "${optChoice[@]}"; do
        if [ 1 -le "${REPLY}" ] && [ "${REPLY}" -le $# ]; then
            echo "The selected ${optType} is ${userOption}"
            break;
        else
            echo "Wrong selection: Select any number from 1-$#"
        fi
    done
}
#
copyFile () {
    while read line; do  
        if ! [ -z "${line}" ]; then
            if [ "${line:0:1}" != "#" ]; then
                echo "${line}" >> "$2"
            fi
        fi
    done <"$1/$2"
}