# Start containers

Use the sdr image that already includes compiled EDAF and OAI code:
```
samiemostafavi/sshd-dind-oai
```
Run 2 of them one for gnb and one for UE.

# Bring up a simple InfluxDB for develop

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
  --bucket latency \
  --retention 0 \
  --force
```

Then you can login via user `edaf` and password `4c5f28e30698bf883e18193`

Get the influx_auth file
```
mkdir /EDAF/
docker exec influxdb influx auth list --json > /EDAF/influx_auth.json
```

# Bring up 5G core network

```
cd ~/oai-cn5g
curl -o ~/oai-cn5g/database/oai_db.sql https://raw.githubusercontent.com/KTH-EXPECA/examples/main/openairinterface/oai_db_nrue.sql
docker compose pull
docker compose up -d
```
Check IP address of gnb machine. Here it is `192.168.70.129` and we run EDAF server in here.

# Run EDAF server


# Run NLMT in ext-dn

```
wget https://raw.githubusercontent.com/samiemostafavi/nlmt/master/nlmt
docker cp nlmt oai-ext-dn:/usr/local/bin/
docker exec -it oai-ext-dn chmod +x /usr/local/bin/nlmt
docker exec -d oai-ext-dn /bin/sh -c 'while true; do nlmt server -n 192.168.70.129:50009 -i 0 -d 0 -l 0; sleep 1; done'
```
Check the NLMT connects to EDAF server in the logs.

# Run gnb

Modify gnb config for band 41:
```
vim ~/openairinterface5g-edaf/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band41.fr1.106PRB.usrpb210.conf
```
Modify the SDR address, and add the following in the same level as `Active_gNBs` and `Asn1_verbosity`:
```
edaf_addr = "0.0.0.0:50015";
```

Run gnb (SDR-07):
```
cd ~/openairinterface5g-edaf/cmake_targets/ran_build/build
./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band41.fr1.106PRB.usrpb210.conf --sa -E --gNBs.[0].min_rxtxtime 6 --MACRLCs.[0].dl_max_mcs 20 --MACRLCs.[0].ul_max_mcs 20
```
Check that gNB connects to EDAF server in the logs.


# Run ue (SDR-05)

```
./nr-uesoftmodem --band 41 -C 2593350000 -r 106 --numerology 1 --ssb 516 --sa -E --uicc0.imsi 001010000000001 --uicc0.dnn oai --uicc0.nssai_sst 1 --uicc0.nssai_sd 16777215  --uicc0.opc c42449363bbad02b66d16bc975d77cc1  --uicc0.key fec86ba6eb707ed08905757b1bb44b8f --usrp-args "mgmt_addr=10.30.10.10,addr=10.30.10.10" --ue-fo-compensation --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --edaf-addr 130.237.11.115:50011
```
Check that UE connects to EDAF server in the logs

