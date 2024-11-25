#!/bin/bash
sudo apt update
sudo wget https://releases.hashicorp.com/consul/1.17.3/consul_1.17.3_linux_amd64.zip
sudo apt install unzip -y
sudo unzip consul_1.17.3_linux_amd64.zip
sudo mv consul /usr/bin/
sudo cat <<EOT>> /etc/systemd/system/consul.service
[Unit]
Description=Consul 
Documentation=https://www.consul.io/
[Service]
ExecStart=/usr/bin/consul agent -server -ui -data-dir=/temp/consul -bootstrap-expect=1 -node=vault -bind=$(hostname -i) -config-dir=/etc/consul.d/ 
ExecReload=/bin/kill -HUP $MAINPID 
LimitNOFILE=65536 
[Install]
WantedBy=multi-user.target
EOT
sudo mkdir /etc/consul.d
sudo cat <<EOT>> /etc/consul.d/ui.json
{
    "addresses":{
    "http": "0.0.0.0"
    }
}
EOT
sudo systemctl daemon-reload
sudo systemctl start consul
sudo systemctl enable consul
sudo apt update
sudo wget https://releases.hashicorp.com/vault/1.15.6/vault_1.15.6_linux_amd64.zip
sudo unzip vault_1.15.6_linux_amd64.zip
sudo mv vault /usr/bin/
sudo mkdir /etc/vault/
sudo cat <<EOT>> /etc/vault/config.hcl
storage "consul" {
        address = "127.0.0.1:8500"
        path ="vault/"
}
listener "tcp"{
          address = "0.0.0.0:8200"
          tls_disable = 1
}
seal "awskms" {
  region     = "${aws_region}"
  kms_key_id = "${kms_key}"
}
ui = true
EOT
sudo cat <<EOT>> /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://www.vault.io/
[Service]
ExecStart=/usr/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOT
sudo systemctl daemon-reload
export VAULT_ADDR="http://localhost:8200"
cat << EOT > /etc/profile.d/vault.sh
export VAULT_ADDR="http://localhost:8200"
export VAULT_SKIP_VERIFY=true
EOT
vault -autocomplete-install
complete -C /usr/bin/vault vault
sudo systemctl start vault
sudo systemctl enable vault
sleep 30

#Set vault token/secret username and password
echo $(vault operator init) > /home/ubuntu/output.txt
sudo chown ubuntu:ubuntu /home/ubuntu/output.txt
export token_content=$(cat /home/ubuntu/output.txt|grep -o 'hvs\.[A-Za-z0-9]\{24\}')
echo $token_content > /home/ubuntu/token.txt
sudo chown ubuntu:ubuntu /home/ubuntu/token.txt

#login to vault with the token rom cmd line
vault login $token_content

vault secrets enable -path=secret/ kv
vault kv put secret/database username=petclinic password=petclinic
vault kv put secret/newrelic NEW_RELIC_API_KEY="NRAK-HT4BH2DUV9UXVFLS3T967UDSA3K" NEW_RELIC_ACCOUNT_ID="4566826"
sudo hostnamectl set-hostname vault