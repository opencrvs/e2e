#!/bin/bash

CONFIG_FILE="/etc/login-alert.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file $CONFIG_FILE not found. Exiting."
    exit 1
fi

TIMESTAMP_FILE="/var/lib/login-alert-last-check"

HOSTNAME=$(hostname)

exec 1> >(logger -t login-alert -p user.info)
exec 2> >(logger -t login-alert -p user.err)

[ ! -f "$TIMESTAMP_FILE" ] && date +%T > $TIMESTAMP_FILE && echo "Initialized timestamp file" && exit 0

START_TIME=$(cat "$TIMESTAMP_FILE")

NEW_LOGINS=$(ausearch -if /var/log/audit/audit.log --start $START_TIME -m USER_LOGIN | grep 'res=success')

if [ ! -z "$NEW_LOGINS" ]; then
    echo "Sending email to $EMAIL_TO"

    BODY="<html>
    <body>
    <p>New login detected on host $HOSTNAME:</p>
    <pre>$NEW_LOGINS</pre>
    </body>
    </html>"

    EMAIL_FILE=$(mktemp)
    cat >"$EMAIL_FILE" <<EOF
From: $EMAIL_FROM
To: $EMAIL_TO
Subject: [Alert] New SSH Login on $HOSTNAME
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

$BODY
EOF
    # Build the curl command based on SMTP_SECURE
    CURL_OPTS=(
        --url "smtp://$SMTP_SERVER:$SMTP_PORT"
        --mail-from "$EMAIL_FROM"
        --mail-rcpt "$EMAIL_TO"
        --upload-file "$EMAIL_FILE"
        --user "$SMTP_USER:$SMTP_PASS"
        --silent --show-error
    )

    if [[ "$SMTP_SECURE" == "true" ]]; then
        CURL_OPTS+=(--ssl)
    fi

    curl "${CURL_OPTS[@]}"
    rm "$EMAIL_FILE"
fi
date +%T > $TIMESTAMP_FILE
