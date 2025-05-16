
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
