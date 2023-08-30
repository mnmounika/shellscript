#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
docker version
rm get-docker.sh

# Generate certificate
CSR_countryName="..."
CSR_stateOrProvinceName="..."
CSR_localityName="..."
CSR_organizationalUnitName="..."
CSR_commonName="..."

echo "Cert creation starts" 
openssl req \
    -nodes \
    -newkey rsa:2048 \
    -subj "/C=$CSR_countryName/ST=$CSR_stateOrProvinceName/L=$CSR_localityName/O=Magna International/OU=$CSR_organizationalUnitName/CN=$CSR_commonName" \
    -addext "keyUsage = digitalSignature, keyEncipherment" \
    -addext "extendedKeyUsage = serverAuth, clientAuth" \
    -addext "subjectAltName = DNS:$CSR_commonName" \
    -keyout $CSR_commonName.key \
    -out $CSR_commonName.csr
echo "::$CSR_commonName.key got created"
echo "::$CSR_commonName.csr got created"
echo "pwd"
pwd
ls -lrt
echo "Cert creation ends"

# Create directory certs
sudo mkdir -p /opt/mosquitto/certs
sudo cp -R $CSR_commonName.key /opt/mosquitto/certs/
ls /opt/mosquitto/certs

# Create directory config,data
sudo mkdir -p /opt/mosquitto/config
sudo mkdir -p /opt/mosquitto/data
ls /opt/mosquitto/
echo "Directory creation success"

# Create .conf file
sudo bash -c 'cat > /opt/mosquitto/config/mosquitto.conf << EOF
per_listener_settings false
plugin /usr/lib/mosquitto_dynamic_security.so
plugin_opt_config_file /mosquitto/config/dynamic-security.json
persistence true
persistence_location /mosquitto/data
log_dest topic
log_dest stdout
log_timestamp true
log_timestamp_format %Y-%m-%dT%H:%M:%S%z
log_type all

# MQTT Listener
listener 8883
protocol mqtt
certfile /mosquitto/certs/'"$CSR_commonName"'.pem
keyfile /mosquitto/certs/'"$CSR_commonName"'.key
cafile /mosquitto/certs/magna_global_fullchain.pemn
# minimum version of the TLS protocol
tls_version tlsv1.2

# Websocket Listener
listener 443
protocol websockets
certfile /mosquitto/certs/'"$CSR_commonName"'.pem
keyfile /mosquitto/certs/'"$CSR_commonName"'.key
cafile /mosquitto/certs/magna_global_fullchain.pem
# minimum version of the TLS protocol
tls_version tlsv1.2
EOF'
echo "File creation has been completed!!!"

# Run script file
chmod +x ./test.sh
./test.sh
