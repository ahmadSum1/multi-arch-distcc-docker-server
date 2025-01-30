# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install distcc and compilers compatible with client's toolchain
# Update and install required packages
RUN apt-get update && \
    apt-get install -y \
        crossbuild-essential-riscv64 \
        crossbuild-essential-arm64 \
        gcc-11-riscv64-linux-gnu g++-11-riscv64-linux-gnu \
        gcc-12-riscv64-linux-gnu g++-12-riscv64-linux-gnu \
        gcc-13-riscv64-linux-gnu g++-13-riscv64-linux-gnu \
        gcc-11 g++-11 \
        gcc-12 g++-12 \
        gcc-13 g++-13 \
        gcc-11-aarch64-linux-gnu g++-11-aarch64-linux-gnu \
        gcc-12-aarch64-linux-gnu g++-12-aarch64-linux-gnu \
        gcc-13-aarch64-linux-gnu g++-13-aarch64-linux-gnu \
        make cmake python3 git nano wget curl \
        distcc gcc g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure distcc to allow your VPN/subnet
# CMD ["distccd", "--daemon", "--no-detach", "--allow", "172.22.0.0/16", "--allow", "10.1.8.3", "--log-stderr", "--log-level=notice"]
CMD ["distccd", "--no-detach", "--allow-private", "--log-stderr", "--log-level=notice"]
