#!/usr/bin/env bash

# Import healthchecks-framework
# shellcheck disable=SC1091
source /opt/healthchecks-framework/healthchecks.sh

# Get latest log file
PFCLIENT_LOG_FILE=$(find /var/log/pfclient -type f -iname "pfclient-log_*.log" | sort | tail -1)

EXITCODE=0

# Ensure connection to beasthost
if ! check_tcp4_connection_established ANY ANY "$(get_ipv4 "$BEASTHOST")" "$BEASTPORT"; then
  EXITCODE=1
fi

# Check for abnormal service deaths
if ! check_s6_service_abnormal_death_tally ALL; then
  EXITCODE=1
fi

# Ensure data being sent to planefinder
curl \
  --location \
  --silent \
  'http://127.0.0.1:30053/ajax/stats' \
  -X 'GET' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Connection: keep-alive' \
  -H 'X-Requested-With: XMLHttpRequest' \
  > /run/pfclient_json_stats.current

if [[ -e "/run/pfclient_json_stats.previous" ]]; then
  
  master_server_bytes_out_current="$(jq .master_server_bytes_out < /run/pfclient_json_stats.current)"
  master_server_bytes_out_previous="$(jq .master_server_bytes_out < /run/pfclient_json_stats.previous)"

  if [[ "$master_server_bytes_out_current" -gt "$master_server_bytes_out_previous" ]]; then
    >&2 echo "Increase in bytes sent to master server. From $master_server_bytes_out_previous to $master_server_bytes_out_current. PASS"
  else
    >&2 echo "No increase in bytes sent to master server. From $master_server_bytes_out_previous to $master_server_bytes_out_current. FAIL"
    EXITCODE=1
  fi

fi

cp "/run/pfclient_json_stats.current" "/run/pfclient_json_stats.previous"

exit $EXITCODE
