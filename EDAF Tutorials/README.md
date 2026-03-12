This folder primarily contains the instructions to run EDAF measurements using the ExPECA testbed infrastructure. 

What is EDAF? 
- Brief description
  - What it is?
  - What it provides?
- Repo link

EDAF is primarily a tool to log traces from the openairinterface5g software stack. 

We will be using one worker for gnb and core and one worker for UE in this tutorial.
1. Reserve workers, create and start appropriate 5g containers
2. Establish 5g connection
3. Use the traffic generator ditg to send packets
4. Once done, stop the connection, delete containers and unreserve resources.


To run an EDAF measurement, please follow the steps below:

1. Reserve the 2 workers (1 for gnb and core, 1 for UE).
2. Reserve 2 SDRs (1 for gnb, 1 for UE)
3. Create the gnb+core container (you can use the container: samiemostafavi/sshd-dind-oai)
4. Create the UE container (you can use the container: samiemostafavi/sshd-dind-oai)
   The container "samiemostafavi/sshd-dind-oai" has all the oai 5g files required to run as gnb or UE.

You can use the python notebook reserveResources.ipynb to execute the above steps. The reserveResources.ipynb notebook additionally also creates the container and assigns public address to them.
Having a public address allows us to perform an ssh into the container. This is particularly useful and handy for running 5g.
After the above, you will have to login separately to the gnb and UE side to setup the connection.

Using the public address login to the gnb+core container

```
ssh root@<public_ip_address>
```
### At gnB+core side
Start the core by first navigating to the ```oai-cn5g``` folder and starting the docker containers associated to the core network
```
cd ~/oai-cn5g
docker-compose up -d
```
Refer ____ for more details.
Once the core network is running, we need to first find the ip address of the SDR that will act as our radio head for the gnb. To get the address, perform the following:
```
uhd_find_devices
```
Before starting the gnb, identify the appropriate gnb configuration files
```
vi ~/openairinterface5g-edaf/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band77.fr1.106PRB.usrpb210.conf
```
Modify the sdr address in the line ```sdr_addrs="mgmt_addr=10.30.10.20,addr=10.30.10.20;``` according to the output obtained from the ```uhd_find_devices``` command. Save and exit.

Now start the gnb process
```
cd ~/openairinterface5g-edaf/cmake_targets/ran_build/build/
./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band77.fr1.106PRB.usrpb210.conf --sa --usrp-tx-thread-config 1 -E --MACRLCs.[0].dl_max_mcs 20 --MACRLCs.[0].ul_max_mcs 20 --gNBs.[0].min_rxtxtime 6 --MACRLCs.[0].ulsch_max_frame_inactivity 100
```
   


