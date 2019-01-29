#!/bin/bash
# This runs INSIDE the docker container.
PATH_KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"


# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

stop()
{
  # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
  # Let's shutdown cleanly
  echo "SIGTERM caught, terminating keepalived process..."
  # Record PIDs
  pid=$(pidof keepalived)
  # Kill them
  kill -TERM $pid > /dev/null 2>&1
  # Wait till they have been killed
  wait $pid
  echo "Terminated."
  exit 0
}

interface=${KEEPALIVED_INTERFACE:-eth0}
priority=${KEEPALIVED_PRIORITY:-100}
floating_ip=${KEEPALIVED_VIRTUAL_IP:-172.16.50.5}
password=${KEEPALIVED_PASSWORD:-secret}
state=${KEEPALIVED_STATE:-BACKUP}

# Replace values in template
perl -p -i -e "s/\{\{ interface \}\}/$interface/" $PATH_KEEPALIVED_CONF
perl -p -i -e "s/\{\{ priority \}\}/$priority/" $PATH_KEEPALIVED_CONF
perl -p -i -e "s/\{\{ floating_ip \}\}/$floating_ip/" $PATH_KEEPALIVED_CONF
perl -p -i -e "s/\{\{ password \}\}/$password/" $PATH_KEEPALIVED_CONF
perl -p -i -e "s/\{\{ state \}\}/$state/" $PATH_KEEPALIVED_CONF

# Workaround: avoid container doesn't restart
rm -f /var/run/keepalived.pid /run/*

# Foreground keepalived
#/usr/sbin/keepalived -f /etc/keepalived/keepalived.conf --dont-fork --vrrp --log-detail --log-console

# This loop runs until we've started up successfully
while true; do
  # Check if Keepalived is running by recording it's PID (if it's not running $pid will be null):
  pid=$(pidof keepalived)
  # If $pid is null, do this to start or restart Keepalived:
  while [ -z "$pid" ]; do
    echo "Starting Keepalived in the background..."
    /usr/sbin/keepalived --dont-fork --dump-conf --log-console --log-detail --vrrp &
    # Check if Keepalived is now running by recording it's PID (if it's not running $pid will be null):
    pid=$(pidof keepalived)
    # If $pid is null, startup failed; log the fact and sleep for 2s
    # We'll then automatically loop through and try again
    if [ -z "$pid" ]; then
      echo "Startup of Keepalived failed, sleeping for 2s, then retrying..."
      sleep 2
    fi
  done
  # Break this outer loop once we've started up successfully
  break
done
# Wait until the Keepalived processes stop (for some reason)
wait $pid
echo "The Keepalived process is no longer running, exiting..."
# Exit with an error
exit 1


