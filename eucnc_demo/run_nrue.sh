#!/bin/bash

log_file="/tmp/nrue.log"

# Trap Ctrl-C to clean up if needed
cleanup() {
  echo "[INFO] Caught Ctrl-C, terminating nr-uesoftmodem..."
  [[ -n "$ue_pid" ]] && kill -9 "$ue_pid" 2>/dev/null
  wait "$ue_pid" 2>/dev/null
  exit 0
}
trap cleanup SIGINT

# Move into the correct directory
cd ~/openairinterface5g-edaf/cmake_targets/ran_build/build || {
  echo "[ERROR] Failed to enter OAI build directory"
  exit 1
}

# Start nr-uesoftmodem with full command
echo "[INFO] Starting nr-uesoftmodem..."
./nr-uesoftmodem \
  --band 41 -C 2593350000 -r 106 --numerology 1 --ssb 516 --sa -E \
  --uicc0.imsi 001010000000001 \
  --uicc0.dnn oai \
  --uicc0.nssai_sst 1 \
  --uicc0.nssai_sd 16777215 \
  --uicc0.opc c42449363bbad02b66d16bc975d77cc1 \
  --uicc0.key fec86ba6eb707ed08905757b1bb44b8f \
  --usrp-args "mgmt_addr=10.30.10.10,addr=10.30.10.10" \
  --ue-fo-compensation --ue-rxgain 120 --ue-txgain 20 --ue-max-power 0 \
  --edaf-addr 130.237.11.115:50011 \
  2>&1 | tee "$log_file" &
ue_pid=$!

echo "[INFO] nr-uesoftmodem started (PID $ue_pid), logging to $log_file"
echo "[INFO] Press Ctrl-C to stop."

# Wait for the process to finish
wait $ue_pid
