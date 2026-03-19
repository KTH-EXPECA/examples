# Gnb-and-Core-in-One Setup

Run these instructions if you start from `samiemostafavi/sshd-dind-oai` container at ExPECA testbed, and have it connected to an SDR already with the address `10.30.10.6` (see "vim" or "sed" command below if another address is used) and a 10Gbps SFP connection.

## Core Network

The following instructions are taken from [NR_SA_Tutorial_OAI_CN5G](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_OAI_CN5G.md). Check if there is any updates.


1) Download core network
```
cd ~/oai-cn5g
docker compose pull
```

2) Run core network
```
docker compose up -d
```

## GNodeB

Following instructions are the instructions in sections 3.1 and 3.2 and 4.1 and 4.2 in [NR_SA_Tutorial_COTS_UE](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_COTS_UE.md)
In section 3.1, we use git checkout v4.3.0.0 instead of git checkout v4.6.0.0.

1) Modify gnb configuration file

Modify the USRP address (e.g. 10.30.10.6) in the line with `sdr_addrs=`. Replace the "band78" part in the file name to match your chosen frequency band.
```
uhd_find_devices
# Note the printed address

vim ~/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf
```

2) Run gnb
```
cd ~/openairinterface5g/cmake_targets/ran_build/build
./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --sa --usrp-tx-thread-config 1 -E
```


# Data transfer test with iperf3

In order to see the logs for the core AMF service, use docker logs (when the IMSI has been received, we are ready for test):
```
docker logs oai-amf
```

To test the SDR data transfer, you can use iperf3 command. 
From the GNodeB:
```
iperf3 -s
```

From the Advantech router end node container (129.168.70.129 is the core network gateway address):
```
iperf3 -c 192.168.70.129 -u -b 10M --get-server-output
iperf3 -c 192.168.70.129 -u -b 10M -R --get-server-output
```


# How to Debug 5G Core

In order to debug the sctp messages between the core and gnb, while running the core, use tcpdump:
```
tcpdump -i any sctp -w rec.pcap
```

Read the produced pcap file via
```
tshark -r rec.pcap -Y ngap
```
Or to see the contents of the messages
```
tshark -r rec.pcap -Y ngap -V
```

