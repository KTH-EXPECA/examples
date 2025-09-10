# Install and Run Latency Prediction Demo

After running Openairinterface EDAF successfully, check in the edaf_main bucket in the influxDB if you can find packet_decomposed _measurement and _field app.e2e_delay. If they are being pushed, it means EDAF setup is complete.

## Start ML and Prediction

Next, we need to install wireless-pr3d packate to run live training and prediction of tail latency.

On the gnb server, run
```
git clone https://github.com/samiemostafavi/wireless-pr3d.git
cd wireless-pr3d; git checkout develop; cd demo;
python3 -V
```
If you have Python 3.8 or 3.9, it is fine, otherwise, you need to install Python 3.9 for this to work. Then, make a virtual environment:
```
pip install virtualenv
python3 -m virtualenv ./venv
source venv/bin/activate
pip install -Ur requirements.txt
```

Then, pick a config file for example start with GMM models: `conf_gmm_30m.json`. Modify it with the new influxDB token and address. You can read the token on the influxDB server by:
```
cat /EDAF/influx_auth.json | grep "token"
```

Once your config json is ready, to start training and evaluation, start a screen session and run the following commands.

Model 1:
```
screen -S pr3d1
cd ~/wireless-pr3d/demo
source venv/bin/activate
vim conf_gmm_30m.json
python main.py --conf conf_gmm_30m.json
```

Model 2:
```
screen -S pr3d2
cd ~/wireless-pr3d/demo
source venv/bin/activate
vim conf_gmevm_30m.json
python main.py --conf conf_gmevm_30m.json
```

Model 3:
```
screen -S pr3d3
cd ~/wireless-pr3d/demo
source venv/bin/activate
vim conf_gmm_2h.json
python main.py --conf conf_gmm_2h.json
```

Model 4:
```
screen -S pr3d4
cd ~/wireless-pr3d/demo
source venv/bin/activate
vim conf_gmevm_2h.json
python main.py --conf conf_gmevm_2h.json
```

In order to check if they work, in influxDB you can check the pr3d bucket. For each model we have `<model_name>_quants` and `<model_name>_probs` being pushed.


## Start Grafana

Start a Grafana session
```
screen -S grafana
```

Create a folder and a docker volume to store data
```
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards/json
docker volume create grafana-data
```

Create the datasource for InfluxDB (use the token from above, and ip address):
```
cat > grafana/provisioning/datasources/influxdb-v2.yml <<'YAML'
apiVersion: 1
datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://130.237.11.114:8086
    jsonData:
      version: Flux
      organization: expeca
      defaultBucket: edaf_main
    secureJsonData:
      token: KbzK2RJ_zrLAh_VpFlRl9kTXKHpLgYwIc-0ortchzqwHkDscvJmbJAtQTaE-TXoDGh-OKsF4xaNcWszJ5E9ABw==
    isDefault: true
YAML
```

Download dashboards
```
wget -P grafana/provisioning/dashboards/json/ https://raw.githubusercontent.com/KTH-EXPECA/examples/refs/heads/main/eucnc_demo/Pr3d%20-%20Predictions.json
wget -P grafana/provisioning/dashboards/json/ https://raw.githubusercontent.com/KTH-EXPECA/examples/refs/heads/main/eucnc_demo/EDAF%20Delay%20Decomposition%20Dashboard.json
```

Add a dashboard provider:
```
cat > grafana/provisioning/dashboards/dashboards.yml <<'YAML'
apiVersion: 1
providers:
  - name: 'influx-dashboards'
    orgId: 1
    folder: 'Influx Dashboards'   # folder in Grafana (create/uses)
    type: file
    allowUiUpdates: true          # you can edit in UI; changes persist
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards/json
      # foldersFromFilesStructure: true  # enable if you use subfolders
YAML
```

Run Grafana:
```
docker run -d --name grafana -p 3000:3000 \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=expeca \
  -v grafana-data:/var/lib/grafana \
  -v "$PWD/grafana/provisioning:/etc/grafana/provisioning:ro" \
  grafana/grafana:latest
```
Now you can check on `130.237.11.114:3000` the dashboard, login with userpass and open the dashboards. Each panel may need a refresh to show the data (just click edit, re-select datasource and wait).


Stop and delete everything:
```
docker rm -f grafana
docker volume rm grafana-data
rm grafana/provisioning/datasources/influxdb-v2.yml
```


