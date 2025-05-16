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

Check the NLMT connects to EDAF on the logs.
