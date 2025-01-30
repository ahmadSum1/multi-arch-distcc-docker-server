# Multi-arch `distcc` Docker Server Setup

A Dockerized `distcc` server to distribute C/C++ compilation across a network. It can support multiple architectures, essentially cross-compiling. Designed for use in a VPN environment.

## Features

- 🐳 Dockerized `distccd` server (Ubuntu 24.04 base) ✅
- 🔒 IP-based access control ❗
- 🔄 Automatic compiler version alignment ✅
- 📊 Logging integration ✅
- 💻 Client configuration templates ✅

## Prerequisites

- Docker installed
- Identical compiler versions on server and clients
- Network access to port `3632`

## Quick Start

### 1. Build Docker Image
```bash
docker build -t distcc-server .
```

### 2. Run Container
```bash
docker run -d \
  --name distccd \
  --network host \
  distcc-server
```

## Client Configuration

### Environment Variables (`~/.bashrc`):
```bash
# distcc (example)
export DISTCC_HOSTS="172.22.220.20/13" #{server IP}/{max number of parallel jobs}
export DISTCC_POTENTIAL_HOSTS="172.22.220.20" 
# ccache
export PATH="/usr/lib/ccache:$PATH"
export CCACHE_PREFIX="distcc"

export CC=x86_64-linux-gnu-gcc-11 #explicitly mention gcc version to avoid failures 
export CXX=x86_64-linux-gnu-g++-11

# for cross-compilation (from different riscv boards for example)
#export CC="riscv64-linux-gnu-gcc-13"
#export CXX="riscv64-linux-gnu-g++-13"


# Parallel jobs
export MAKEFLAGS="-j$(($(nproc) * 2))"
```

### Compiler Verification
Ensure matching versions:
```bash
# Server
docker exec distccd gcc --version

# Client
gcc --version
```

## Security
| IP Range          | Recommendation               |
|-------------------|------------------------------|
| `0.0.0.0/0`       | ❌ Never use in production  |
| `172.22.0.0/16`   | ✅ subnet                   |
| `10.0.0.0/8`      | ✅ For private networks     |
| `--allow-private` | ✅ For private networks     |

## Monitoring
```bash
# Server logs
docker logs -f distccd
```
### Test Compilation (ros2)
```bash
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release --parallel-workers "$(distcc -j)"
```

## Troubleshooting

### Common Issues 
1. **Recursive distcc error**:
   ```bash
   unset CCACHE_PREFIX  # Disable ccache temporarily
   ```

2. **Compiler mismatch**:
   ```bash
   docker exec distccd gcc --version  # Must match client version
   ```

3. **Connection issues**:
   ```bash
   nc -zv <server-ip> 3632  # Verify port accessibility
   ```

---

## **Setting Up `distcc` as a Systemd Service (Automatic Startup on Boot)**

To ensure that the **Dockerized `distcc` server starts automatically on boot**, follow these steps.

### **1. Disable Any Existing `distcc` Server on the Host PC**
If you previously installed `distcc` on your **host machine** (outside Docker), make sure it **doesn’t conflict** with the Docker service.

- **Check if `distcc` is running** on your host:
  ```bash
  pgrep distccd
  ```
  If you see a process ID (PID), that means `distcc` is already running.

- **If `distcc` is running, stop it:**
  ```bash
  sudo systemctl stop distccd  # If running as a systemd service
  sudo systemctl disable distccd  # Prevent it from starting at boot
  ```

- **If `distcc` was started via `cron`, remove the cron job:**
  ```bash
  crontab -e
  ```
  Look for any lines starting with `distcc` and delete them.

- **Kill any existing `distcc` processes manually (if necessary):**
  ```bash
  sudo pkill distccd
  ```

---

### **2. Create the `distcc` Systemd Service**
1. **Create a new systemd service file**:
   ```bash
   sudo nano /etc/systemd/system/distccd-docker.service
   ```
   
2. **Add the following configuration:**
   ```ini
   [Unit]
   Description=Distcc Docker Container
   After=network-online.target docker.service
   Requires=docker.service

   [Service]
   Type=oneshot
   RemainAfterExit=yes

   # Start the container in detached mode with Docker's restart policy
   ExecStart=/usr/bin/docker run --name distccd \
       --network host \
       --restart unless-stopped \
       -d \
       distcc-server

   # Stop & remove container on service stop
   ExecStop=/usr/bin/docker stop distccd
   ExecStopPost=/usr/bin/docker rm distccd

   [Install]
   WantedBy=multi-user.target
   ```

3. **Reload systemd to apply changes:**
   ```bash
   sudo systemctl daemon-reload
   ```

4. **Enable the service to start on boot:**
   ```bash
   sudo systemctl enable distccd-docker
   ```

5. **Start the service manually (first-time run):**
   ```bash
   sudo systemctl start distccd-docker
   ```

6. **Verify the service status:**
   ```bash
   sudo systemctl status distccd-docker
   ```

7. **Check if the container is running:**
   ```bash
   docker ps
   ```

---

### **3. Verify That `distcc` Is Running in Docker**
Run:
```bash
docker logs -f distccd
```
You should see `distcc` server logs, confirming it’s running.

You can also check if the container is actively listening on **port 3632** (default `distcc` port):
```bash
sudo netstat -tulnp | grep 3632
```

---

### **4. Stopping and Restarting the Service**
- **To manually stop the `distcc` service:**
  ```bash
  sudo systemctl stop distccd-docker
  ```
  _(Docker will NOT restart it automatically until you manually start it or reboot the system.)_

- **To restart the `distcc` service:**
  ```bash
  sudo systemctl restart distccd-docker
  ```

- **To completely remove the service from systemd:**
  ```bash
  sudo systemctl disable distccd-docker
  sudo rm /etc/systemd/system/distccd-docker.service
  sudo systemctl daemon-reload
  ```

---

### **5. Ensuring the Service Runs After a Reboot**
After rebooting your PC:
```bash
sudo systemctl status distccd-docker
docker ps
```
You should see the container running automatically.

---

🚀 **Now your `distcc` server will start automatically on boot and persist across crashes/reboots.** 🚀

