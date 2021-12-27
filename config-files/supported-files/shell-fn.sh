#!/bin/bash
#
# This function will be used to prompy Yes ot No from user. It'll continue prompting for Y or N unless valid response is received.
#
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
# This function will display the options and seek user input
#
promptOpt () {
    local optType="$1"      # Save first argument in a variable
    shift                   # Shift all arguments to the left (original $1 gets lost)
    local optChoice=("$@")  # Rebuild the array with rest of arguments
    PS3="Please enter your choice of ${optType}: "
    select userOption in "${optChoice[@]}"; do
        if [ "${REPLY}" -ge 1 ] && [ "${REPLY}" -le $# ]; then
            echo "The selected ${optType} is ${userOption}"
            break;
        else
            echo "Wrong selection: Select any number from 1-$#"
        fi
    done
}
#
# Get validated password
#
promptPassword () {
    while true; do
        read -s -p "Enter password   : " newUserPass
        echo ""
        read -s -p "Re-enter password: " newUserPassConfirm
        echo ""
        if [ -z "${newUserPass}" ] || [ "${newUserPass}" != "${newUserPassConfirm}" ]; then
            echo "Password is blank or do not match. Try again"
        else
            break
        fi
    done
}
#
# This function will read the input file and copy the entries to a single line to be processed by batch. This will skip any comment lines (beginning with '#')
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