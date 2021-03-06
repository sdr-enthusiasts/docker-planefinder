#!/usr/bin/env bash

# Import healthchecks-framework
# shellcheck disable=SC1091
source /opt/healthchecks-framework/healthchecks.sh

# Get latest log file
PFCLIENT_LOG_FILE=$(find /var/log/pfclient -type f -iname "pfclient-log_*.log" | sort | tail -1)

EXITCODE=0

# Healthy if a successful updated has been reported from now to this many seconds ago
CHECK_PERIOD_SECONDS=300

# Pull info from logs and perform calculations
TIMESTAMP_NOW=$(date --utc +%s.%N)
LASTLOG_UPDATES_SENT=$(grep --binary-files=text -P "Successfully sent \d+ aircraft updates across \d+ packets" "$PFCLIENT_LOG_FILE" | tail -1 | tr -s " ")
LASTLOG_TIMESTAMP=$(date --utc --date="$(echo "$LASTLOG_UPDATES_SENT" | cut -d ' ' -f 1,2)" +%s.%N)
LASTLOG_NUMBER_UPDATES=$(echo "$LASTLOG_UPDATES_SENT" | grep -oP "Successfully sent \K\d+")
SUCCESSFUL_SENT_UPDATES=$(echo "($TIMESTAMP_NOW - $LASTLOG_TIMESTAMP) < $CHECK_PERIOD_SECONDS" | bc)

# check to make sure we've sent updates recently
if [[ "$SUCCESSFUL_SENT_UPDATES" -ne 1 ]]; then
    echo "No updates sent in past $CHECK_PERIOD_SECONDS seconds. UNHEALTHY"
    EXITCODE=1
else
    if [[ "$LASTLOG_NUMBER_UPDATES" -lt 1 ]]; then
        echo "No updates sent in past $CHECK_PERIOD_SECONDS seconds. UNHEALTHY"
        EXITCODE=1
    else
        echo "$(echo "$LASTLOG_UPDATES_SENT" | cut -d ']' -f 2 | tr -s ' ' | cut -d ' ' -f 2-). HEALTHY"
    fi
fi

# Ensure connection to beasthost
if ! check_tcp4_connection_established ANY ANY "$(get_ipv4 "$BEASTHOST")" "$BEASTPORT"; then
  EXITCODE=1
fi

# Check for abnormal service deaths
if ! check_s6_service_abnormal_death_tally ALL; then
  EXITCODE=1
fi

exit $EXITCODE
