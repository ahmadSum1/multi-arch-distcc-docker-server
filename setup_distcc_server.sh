#!/bin/bash

# Define variables
USERNAME=$(whoami)
IMAGE_NAME="${USERNAME}-distcc-server"
SERVICE_NAME="${USERNAME}-distccd"

# Step 1: Build the Docker Image
echo "Building the Docker image..."
docker build -t $IMAGE_NAME .
if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

echo "Docker image built successfully."

# Step 2: Create the systemd service
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
echo "Creating systemd service file at $SERVICE_FILE..."

cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Distcc Docker Container
After=network-online.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes

# Start the container in detached mode with Docker's restart policy
ExecStart=/usr/bin/docker run --name $SERVICE_NAME \
    --network host \
    --restart unless-stopped \
    -d \
    $IMAGE_NAME

# Stop & remove container on service stop
ExecStop=/usr/bin/docker stop $SERVICE_NAME
ExecStopPost=/usr/bin/docker rm $SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable and start the service
echo "Enabling and starting the $SERVICE_NAME service..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Verify status
echo "Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager
