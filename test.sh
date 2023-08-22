#!/bin/bash
echo "Mounika shell script starts"

# Set environment variables
export MOSQUITTO_CONTAINER_NAME=mosquitto
export MOSQUITTO_ADMIN_USER=admin-user
export MOSQUITTO_ADMIN_PASSWORD=xxxxx
export CEDALO_ADMIN_USER=admin
export CEDALO_ADMIN_PASSWORD=xxxxx
export MOSQUITTO_HOSTNAME=cse-plant1-uns.magna.global

# Step 1: Create Mosquitto container
docker run -d \
  --name $MOSQUITTO_CONTAINER_NAME \
  -p 8883:8883 \
  -p 443:443 \
  --volume /opt/mosquitto/certs:/mosquitto/certs \
  --volume /opt/mosquitto/data:/mosquitto/data \
  --volume /opt/mosquitto/config:/mosquitto/config \
  --restart unless-stopped  \
  eclipse-mosquitto

# Step 2: Create Mosquitto Admin User
docker exec -t $MOSQUITTO_CONTAINER_NAME sh -c "mosquitto_ctrl dynsec init /mosquitto/config/dynamic-security.json $MOSQUITTO_ADMIN_USER $MOSQUITTO_ADMIN_PASSWORD"

# Step 3: Restart Mosquitto Container
docker restart $MOSQUITTO_CONTAINER_NAME

# Step 4: Create Cedalo Container
docker run -d \
  --volume /opt/mosquitto/certs/magna_global_fullchain.pem:/management-center/certs/magna_global_fullchain.pem \
  --name cedalo-management-center \
  -p 8088:8088 \
  --env CEDALO_MC_BROKER_ID=mosquitto \
  --env CEDALO_MC_BROKER_NAME=Mosquitto \
  --env CEDALO_MC_BROKER_URL="mqtts://${MOSQUITTO_HOSTNAME}:8883" \
  --env CEDALO_MC_BROKER_USERNAME=$MOSQUITTO_ADMIN_USER \
  --env CEDALO_MC_BROKER_PASSWORD=$MOSQUITTO_ADMIN_PASSWORD \
  --env CEDALO_MC_USERNAME=$CEDALO_ADMIN_USER \
  --env CEDALO_MC_PASSWORD=$CEDALO_ADMIN_PASSWORD \
  --env NODE_EXTRA_CA_CERTS=/management-center/certs/magna_global_fullchain.pem \
  --restart unless-stopped  \
  cedalo/management-center:2.3.13
  
echo "Mounika shell script Ends"
