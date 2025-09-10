# Install and Run Latency Prediction Demo

After running Openairinterface EDAF successfully, check in the edaf_main bucket in the influxDB if you can find packet_decomposed _measurement and _field app.e2e_delay. If they are being pushed, it means EDAF setup is complete.

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



