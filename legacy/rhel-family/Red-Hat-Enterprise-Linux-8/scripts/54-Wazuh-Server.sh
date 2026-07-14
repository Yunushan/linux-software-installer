#!/bin/bash

#54-Wazuh Server
printf "\nPlease Choose Your Desired Wazuh Server Installation\n\n1-) Wazuh Server (Assistant Installation)\n\
2-) Wazuh Server (Step-By-Step Installation)\n\nPlease Select Your Wazuh Server Version:"
read -r wazuh_server_version
sudo rm -vf /root/Downloads/wazuh-install-files.tar
if [ "$wazuh_server_version" = "1" ];then
    cd /root/Downloads
    wget -O /root/Downloads/wazuh-install.sh https://packages.wazuh.com/4.3/wazuh-install.sh
  echo "nodes:
  indexer:
    - name: node-1
      ip: 127.0.0.1
  server:
    - name: wazuh-1
      ip: 127.0.0.1
  dashboard:
    - name: dashboard
      ip: 127.0.0.1" > /root/Downloads/config.yml
    bash /root/Downloads/wazuh-install.sh --generate-config-files
    bash /root/Downloads/wazuh-install.sh --overwrite --wazuh-indexer node-1
    bash /root/Downloads/wazuh-install.sh --start-cluster
    #Wazuh Server Section
    bash /root/Downloads/wazuh-install.sh --overwrite --wazuh-server wazuh-1
    #Wazuh Dashboard Section
    bash /root/Downloads/wazuh-install.sh --overwrite --wazuh-dashboard dashboard
    sudo mkdir -pv wazuh-install-files
    tar -xvf wazuh-install-files.tar -C /root/Downloads/
    sudo touch wazuh-install-files/passwords.txt
    tar -O -xvf wazuh-install-files.tar > wazuh-install-files/passwords.txt
    sed -i -e 's/server.host: "127.0.0.1"/server.host: 0.0.0.0/g' /etc/wazuh-dashboard/opensearch_dashboards.yml
    sudo systemctl restart wazuh-dashboard
    #Wazuh SSL Certification
    #wget -O /root/Downloads/wazuh-certs-tool.sh https://packages.wazuh.com/4.3/wazuh-certs-tool.sh
    #sudo mkdir -pv /etc/wazuh-dashboard/certs/old
    #sudo mv -vf /etc/wazuh-dashboard/certs/* /etc/wazuh-dashboard/certs/old/
    #sudo rm -rvf /root/Downloads/wazuh-certificates/
    #sudo bash wazuh-certs-tool.sh -A
    #sudo cp -vf /root/Downloads/wazuh-certificates/* /etc/wazuh-dashboard/certs/
elif [ "$wazuh_server_version" = "2" ];then
    #Wazuh Indexer Section
    wget -O /root/Downloads/wazuh-certs-tool.sh https://packages.wazuh.com/4.3/wazuh-certs-tool.sh
  echo "nodes:
  indexer:
    - name: wazuh-indexer
      ip: 127.0.0.1
  server:
    - name: wazuh-server
      ip: 127.0.0.1
  dashboard:
    - name: wazuh-dashboard
      ip: 127.0.0.1" > /root/Downloads/config.yml
    bash /root/Downloads/wazuh-certs-tool.sh -A
    cd /root/Downloads/
    tar -cvf ./wazuh-certificates.tar -C ./wazuh-certificates/ .
    rm -rf ./wazuh-certificates
    sudo dnf -vy install coreutils
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
    echo -e '[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever \
    - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh.repo
    sudo dnf -vy install wazuh-indexer
    sed -i -e 's/network.host: "0.0.0.0"/network.host: "127.0.0.1"/' /etc/wazuh-indexer/opensearch.yml
    systemctl daemon-reload
    systemctl enable wazuh-indexer
    systemctl start wazuh-indexer
    #Cluster installation
    /usr/share/wazuh-indexer/bin/indexer-security-init.sh
    curl -k -u admin:admin https://127.0.0.1:9200
    curl -k -u admin:admin https://127.0.0.1:9200/_cat/nodes?v
    #Wazuh Server Section
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
    echo -e '[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever \
    - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh.repo
    sudo dnf -vy install wazuh-manager
    systemctl daemon-reload
    systemctl enable wazuh-manager
    systemctl start wazuh-manager
    sudo dnf -vy install filebeat
    wget -O /etc/filebeat/filebeat.yml https://packages.wazuh.com/4.3/tpl/wazuh/filebeat/filebeat.yml
    sed -i  '1i- 127.0.0.1:9200' /etc/filebeat/filebeat.yml
    sed -i '1ioutput.elasticsearch.hosts:' /etc/filebeat/filebeat.yml
    filebeat keystore create
    echo admin | filebeat keystore add username --stdin --force
    echo admin | filebeat keystore add password --stdin --force
    curl -so /etc/filebeat/wazuh-template.json \
    https://raw.githubusercontent.com/wazuh/wazuh/4.3/extensions/elasticsearch/7.x/wazuh-template.json
    chmod go+r /etc/filebeat/wazuh-template.json
    curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.2.tar.gz | tar -xvz -C /usr/share/filebeat/module
    NODE_NAME=wazuh-server
    mkdir /etc/filebeat/certs
    tar -xf ./wazuh-certificates.tar -C /etc/filebeat/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./root-ca.pem
    mv -n /etc/filebeat/certs/$NODE_NAME.pem /etc/filebeat/certs/filebeat.pem
    mv -n /etc/filebeat/certs/$NODE_NAME-key.pem /etc/filebeat/certs/filebeat-key.pem
    chmod 500 /etc/filebeat/certs
    chmod 400 /etc/filebeat/certs/*
    chown -R root:root /etc/filebeat/certs
    systemctl daemon-reload
    systemctl enable filebeat
    systemctl start filebeat
    filebeat test output
    WAZUH_KEY=$(openssl rand -hex 16)
    systemctl restart wazuh-manager
    #Wazuh Dashboard Section
    sudo dnf -vy install libcap
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
    echo -e '[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever \
    - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh.repo
    sudo dnf -vy install wazuh-dashboard
    NODE_NAME=wazuh-dashboard
    mkdir /etc/wazuh-dashboard/certs
    tar -xf ./wazuh-certificates.tar -C /etc/wazuh-dashboard/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./root-ca.pem
    mv -n /etc/wazuh-dashboard/certs/$NODE_NAME.pem /etc/wazuh-dashboard/certs/dashboard.pem
    mv -n /etc/wazuh-dashboard/certs/$NODE_NAME-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
    chmod 500 /etc/wazuh-dashboard/certs
    chmod 400 /etc/wazuh-dashboard/certs/*
    chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs
    systemctl daemon-reload
    systemctl enable wazuh-dashboard
    systemctl start wazuh-dashboard
    TOKEN=$(curl -u wazuh-wui:wazuh-wui -k -X GET "https://localhost:55000/security/user/authenticate?raw=true")
    curl -k -X PUT "https://localhost:55000/security/users/1" -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' -d'
    {
      "password": "SuperS3cretPassword!"
    }'
    curl -k -X PUT "https://localhost:55000/security/users/2" -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' -d'
    {
      "password": "SuperS3cretPassword!"
    }'
    #systemctl restart wazuh-dashboard
else
    echo "Out of options please choose between 1-2"
fi