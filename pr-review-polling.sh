#!/usr/bin/bash

STATUSFILE=~/.pr-reviews
CONFFILE=~/.config/github.conf

TOKEN=$(cat $CONFFILE)|| { echo "Cannot read $CONFFILE"; exit 1;  }
Q="is:open+is:pr+assignee:@me+user-review-requested:@me"

github_query() {
    local QUERY="$1"
    
    CURL_RESPONSE=$(curl --silent --show-error --fail -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/search/issues?q=$QUERY" 2>&1)

    CURL_CMD_STATUS=$?
    if [ $CURL_CMD_STATUS -ne 0 ]; then
        systemd-cat echo "Curl failed with status $CURL_CMD_STATUS"
        systemd-cat echo "Check your github token. You can update this by running the install.sh script"
        exit 1;
    fi
    echo $CURL_RESPONSE
}

while true
do
    systemd-cat echo "Begin checking PRs for Reviews"
    GITHUB_RESPONSE=$(github_query "$Q")
    TOTAL=$(echo $GITHUB_RESPONSE | jq '.total_count')

    if [ -z "${GITHUB_RESPONSE}" ]; then
        systemd-cat echo "Github query failed, sleeping"
        sleep 30
        continue
    fi

    if [ -z "${TOTAL}" ]; then
        systemd-cat echo "Github query failed, didn't find total, sleeping"
        sleep 30
        continue
    fi

    if [ $TOTAL -ne 0 ]; then
        systemd-cat echo "Filling file with urls"
        echo $GITHUB_RESPONSE | jq '.items.[] | .title + "    " + .url' | sed 's/api.//' | sed 's/repos\///' | sed 's/issues/pull/' | sed 's/"//g' > $STATUSFILE
        dunstify -A "cat ~/.pr-reviews | dmenu | awk -F'    ' '{print \$2}' | xargs firefox",ACCEPT "You have $TOTAL PR(s) needing review!" | /bin/bash
        systemd-cat echo "sleeping 60"
        sleep 60
        continue
    else
        NUM=$(wc -l <$STATUSFILE)
        systemd-cat echo "$NUM found in status file"
        if [ $NUM -ne 0 ]; then
            notify-send "PR Status" "All PRs have now been reviewed! 🎉"
            systemd-cat echo "Clearing file"
            : > $STATUSFILE
        fi
    fi
    systemd-cat echo "Finished checking PRs for Reviews. Sleeping 30s"
    sleep 30
done

