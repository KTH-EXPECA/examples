# Start containers

Use the sdr image that already includes compiled OAI EDAF and gnb config files:
```
samiemostafavi/sshd-dind-oai
```
Run 2 of them one for gnb and one for UE.

# Bring up InfluxDB

```
docker run -d \
  --name=influxdb \
  -p 8086:8086 \
  -v influxdb-storage:/var/lib/influxdb2 \
  influxdb:2.7
```

```
docker exec -it influxdb influx setup \
  --username edaf \
  --password 4c5f28e30698bf883e18193 \
  --org expeca \
  --bucket edaf_raw \
  --retention 0 \
  --force
```

Then you can login via user `edaf` and password `4c5f28e30698bf883e18193`

Get the influx_auth file
```
mkdir /EDAF/
docker exec influxdb influx auth list --json > /EDAF/influx_auth.json
```

To check the size of influxDB:
```
docker system df -v | grep "influxdb-storage"
```

To clean up influxDB:
```
docker rm influxdb -f
docker volume rm influxdb-storage
rm /EDAF/influx_auth.json
```

# Bring up 5G core network

```
cd ~/oai-cn5g
curl -o ~/oai-cn5g/database/oai_db.sql https://raw.githubusercontent.com/KTH-EXPECA/examples/main/openairinterface/oai_db_nrue.sql
curl -o ~/oai-cn5g/docker-compose.yaml https://raw.githubusercontent.com/KTH-EXPECA/examples/main/openairinterface/docker-compose.yaml
docker compose pull
docker compose up -d
```
Check IP address of gnb machine. Here it is `192.168.70.129` and we run EDAF server in here.

# Run EDAF server

Make sure you have Python 3.9 installed on the server.

Install libsqlite3 and pip:
```
apt-get update
apt-get install libsqlite3-dev
apt install python3-pip
```

Clone EDAF repo and checkout to develop
```
git clone https://github.com/samiemostafavi/edaf.git
cd edaf
git checkout develop
```

Install dependencies
```
pip install -Ur requirements.txt
```

Fix the configurations in `edaf/api/server.py` file:
```
MAX_L1_UPF_DEPTH = 40 # lines in one page
QPROC_SLEEP_UPF_S = 0.5 # how often read one page and process it

MAX_L1_GNB_DEPTH = 5000 # lines in one page
QPROC_SLEEP_GNB_S = 0.5 # how often read one page and process it

MAX_L1_UE_DEPTH = 2500 # lines in one page
QPROC_SLEEP_UE_S = 0.5 # how often read one page and process it

LOGGING_PERIOD_SEC = 2

PACKETS_DECOMPOSE_WINDOW_MS = 2000 # history window duration in seconds
PACKETS_DECOMPOSE_SLEEP_S = 0.1 # while loop sleep duration in seconds

org = "expeca"
raw_bucket = "edaf_raw"
main_bucket = "edaf_main"
influx_db_address = "http://0.0.0.0:8086"
auth_info_addr = "/EDAF/influx_auth.json"
```


Run edaf:
```
python edaf.py
```

# Run NLMT server

We run it in a screen session in GNB machine:
```
wget https://raw.githubusercontent.com/samiemostafavi/nlmt/master/nlmt
chmod +x nlmt
screen -S nlmt
/bin/sh -c 'while true; do ./nlmt server -n 0.0.0.0:50009 -i 0 -d 0 -l 0; sleep 1; done'
```
Check the NLMT connects to EDAF server in the logs.

# Run gnb (SDR-03)

Modify gnb config for band 41:
```
vim ~/openairinterface5g-edaf/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band41.fr1.106PRB.usrpb210.conf
```
Modify the SDR address, and add the following in the same level as `Active_gNBs` and `Asn1_verbosity`:
```
edaf_addr = "0.0.0.0:50015";
```

The gain configurations should be:
```
RUs = (
{
  local_rf       = "yes"
  nb_tx          = 1
  nb_rx          = 1
  att_tx         = 0;
  att_rx         = 0;
  bands          = [41];
  max_pdschReferenceSignalPower = -27;
  max_rxgain                    = 114;
  eNB_instances  = [0];
  #beamforming 1x4 matrix:
  bf_weights = [0x00007fff, 0x0000, 0x0000, 0x0000];
  clock_src = "internal";
  #sl_ahead = 2;
  sdr_addrs="mgmt_addr=10.30.10.6,addr=10.30.10.6";
}
```

Execute gnb:
```
cd ~/openairinterface5g-edaf/cmake_targets/ran_build/build
./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band41.fr1.106PRB.usrpb210.conf --sa -E --gNBs.[0].min_rxtxtime 6 --MACRLCs.[0].dl_max_mcs 20 --MACRLCs.[0].ul_max_mcs 20
```
Check that gNB connects to EDAF server in the logs.


# Run ue (SDR-05)

Run nrUE via the script:
```
wget https://raw.githubusercontent.com/KTH-EXPECA/examples/refs/heads/main/eucnc_demo/nrue_retry.sh
chmod +x nrue_retry.sh
screen -S nrue
./nrue_retry.sh
```

Or execute `nr-uesoftmodem` manually:
```
cd ~/openairinterface5g-edaf/cmake_targets/ran_build/build
./nr-uesoftmodem --band 41 -C 2593350000 -r 106 --numerology 1 --ssb 516 --sa -E --uicc0.imsi 001010000000001 --uicc0.dnn oai --uicc0.nssai_sst 1 --uicc0.nssai_sd 16777215  --uicc0.opc c42449363bbad02b66d16bc975d77cc1  --uicc0.key fec86ba6eb707ed08905757b1bb44b8f --usrp-args "mgmt_addr=10.30.10.10,addr=10.30.10.10" --ue-fo-compensation --ue-rxgain 120 --ue-txgain 22 --ue-max-power 0 --edaf-addr 130.237.11.115:50011
```
Check that UE connects to EDAF server in the logs.

NOTE: here we use `-ue-txgain 22` which means the attenuation will be 22 dbs on the tx of the UE. This will give us an MCS index in the range of 13 to 15.


# Run NLMT client 

Prepare NLMT client
```
wget https://raw.githubusercontent.com/samiemostafavi/nlmt/master/nlmt
chmod +x nlmt
```

Run NLMT client runner script
```
wget https://raw.githubusercontent.com/KTH-EXPECA/examples/refs/heads/main/eucnc_demo/nlmt_client_retry.sh
chmod +x nlmt_client_retry.sh
screen -S nlmt
./nlmt_client_retry.sh
```

Alternative: If UE connects and gets an IP, instead of the NLMT client runner, you can run the following:
```
ip route add 192.168.70.128/26 via 10.0.0.1
./nlmt client --tripm=oneway -i 50ms -g edaf1/test -l 100 -m 1 -d 5m -o d --outdir=/tmp/ 192.168.70.129
```
With the configuration above (edaf buffer sizes etc), it is very important to have periodicity of 50ms and packet size of 100B.

