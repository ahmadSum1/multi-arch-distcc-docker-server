# Multi-arch `distcc` Docker Server Setup

A Dockerized `distcc` server to distribute C/C++ compilation across a network. It can support multiple architectures. Designed for use in a VPN environment.

## Features

- 🐳 Dockerized `distccd` server (Ubuntu 24.04 base)
- 🔒 IP-based access control
- 🔄 Automatic compiler version alignment
- 📊 Logging integration
- 💻 Client configuration templates

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


