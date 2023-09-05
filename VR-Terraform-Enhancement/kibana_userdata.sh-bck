#!/bin/bash
yum update -y
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.1.2-x86_64.rpm
sudo rpm --install kibana-8.1.2-x86_64.rpm
private_ip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "server.host: "$private_ip"">> /etc/kibana/kibana.yml
echo "server.port: "5601""  >> /etc/kibana/kibana.yml
echo "elasticsearch.hosts: [\"http://${elasticsearch}:9200\"]"  >> /etc/kibana/kibana.yml
systemctl enable --now kibana