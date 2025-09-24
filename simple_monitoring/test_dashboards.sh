#!/bin/bash
set -e

echo ">>> Starting CPU load with 'yes'..."
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
LOAD_PIDS="$!"

echo "Load started. Check Netdata dashboard for CPU spikes."
echo "Use 'killall yes' to stop load."
