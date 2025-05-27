#!/bin/bash

# Config
LOG_DIR="/tmp"
CHECK_IP="192.168.70.129"
INTERFACE="oaitun_ue1"

# Cleanup on Ctrl-C
cleanup() {
  echo "[INFO] Caught Ctrl-C. Cleaning up..."
  [[ -n "$modem_pid" ]] && kill -9 "$modem_pid" 2>/dev/null
  [[ -n "$watchdog_pid" ]] && kill -9 "$watchdog_pid" 2>/dev/null
  wait "$modem_pid" 2>/dev/null
  wait "$watchdog_pid" 2>/dev/null
  exit 0
}
trap cleanup SIGINT

# Watchdog check function
run_watchdog() {
  sleep 15
  while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Check interface
    if ! ip link show "$INTERFACE" &>/dev/null; then
      echo "[$timestamp] ❌ Interface $INTERFACE does not exist"
      break
    fi

    # Check IP assigned
    ip_assigned=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [[ -z "$ip_assigned" ]]; then
      echo "[$timestamp] ❌ No IP assigned to $INTERFACE"
      break
    else
      echo "[$timestamp] ✅ $INTERFACE has IP $ip_assigned"
    fi

    # Check ping
    if ! ping -c 1 -W 1 "$CHECK_IP" &>/dev/null; then
      echo "[$timestamp] ❌ Ping to $CHECK_IP failed"
      break
    else
      echo "[$timestamp] ✅ Ping to $CHECK_IP successful"
    fi

    sleep 1
  done

  # If any check fails:
  echo "[$timestamp] ⚠️ Watchdog detected a failure. Killing nr-uesoftmodem..."
  [[ -n "$modem_pid" ]] && kill -9 "$modem_pid" 2>/dev/null
}

# Main loop
while true; do
  cd ~/openairinterface5g-edaf/cmake_targets/ran_build/build || {
    echo "[ERROR] Could not cd to build directory"
    exit 1
  }

  log_file="$LOG_DIR/nr_ue.log"
  echo "[INFO] Starting nr-uesoftmodem, logging to $log_file"

  # Launch modem in background using `script`
  setsid script -q -c "./nr-uesoftmodem \
    --band 41 -C 2593350000 -r 106 --numerology 1 --ssb 516 --sa -E \
    --uicc0.imsi 001010000000001 \
    --uicc0.dnn oai \
    --uicc0.nssai_sst 1 \
    --uicc0.nssai_sd 16777215 \
    --uicc0.opc c42449363bbad02b66d16bc975d77cc1 \
    --uicc0.key fec86ba6eb707ed08905757b1bb44b8f \
    --usrp-args \"mgmt_addr=10.30.10.10,addr=10.30.10.10\" \
    --ue-fo-compensation --ue-rxgain 120 --ue-txgain 20 --ue-max-power 0 \
    --edaf-addr 130.237.11.115:50011" "$log_file" </dev/null >/dev/null 2>&1 &
  modem_pid=$!

  # Start watchdog in background
  run_watchdog &
  watchdog_pid=$!

  # Wait for modem to finish or be killed
  wait $modem_pid

  # Clean up watchdog
  kill -9 "$watchdog_pid" 2>/dev/null
  wait "$watchdog_pid" 2>/dev/null

  echo "[INFO] Restarting modem in 3 seconds..."
  sleep 3
done
