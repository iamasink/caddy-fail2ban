#!/bin/bash

set -euo pipefail

fail2ban-server
sleep 1

output=$(curl --fail --max-time 15 http://127.0.0.1)
if [ "$output" != "ok" ]; then
  echo "Expected 'ok' output, got '${output}'"
  exit 1
fi

fail2ban-client set caddy_test banip 127.0.0.1
# Wait for inotify to tell caddy to reload list
sleep 1

set +e
curl --max-time 15 http://127.0.0.1
curl_exit_code=$?
set -e

if [ "$curl_exit_code" -ne 52 ]; then
  echo "Expected curl exit code 52 for a banned IP, got ${curl_exit_code}"
  exit 1
fi

fail2ban-client set caddy_test unbanip 127.0.0.1
sleep 1

output=$(curl --fail --max-time 15 http://127.0.0.1)
if [ "$output" != "ok" ]; then
  echo "Expected 'ok' output after unban, got '${output}'"
  exit 1
fi

echo "Success!"
exit 0
