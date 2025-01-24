FROM python:latest

USER root

RUN apt-get update && \
    apt-get install -y \
    python3-pip \
    python3-dev \
    build-essential \
    wget \
    curl \
    jq \
    sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install the appropriate package for the system architecture
RUN ARCH=$(dpkg --print-architecture) && \
    download_url=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | \
    jq -r --arg ARCH "$ARCH" '.assets[] | select(.name | contains($ARCH + ".deb")).browser_download_url') && \
    wget -O code-server.deb $download_url && \
    dpkg -i code-server.deb && \
    rm code-server.deb

RUN mkdir -p /etc/sudoers.d && \
    adduser --gecos '' --disabled-password coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd


# Copy the VS Code extension folder preserving its name
COPY vsix_downloads/ vsix_downloads/

# Make sure installs for coder user
USER coder

# Copy the installation script
COPY install_vsix.sh .


# Run the installation script (it will look for the vsix_downloads folder in the current directory)
RUN bash install_vsix.sh

USER root
# Clean up the copied resources after installation
RUN rm -rf vsix_downloads install_vsix.sh

USER coder
# Upgrade pip and install pip packages
RUN python3 -m pip install --upgrade --no-cache pip
RUN python3 -m pip install --no-cache numpy matplotlib ipykernel
RUN python3 -m pip install --no-cache pandas scipy

EXPOSE 8080

# Copy VS Code settings (ensure the destination directory exists)
RUN mkdir -p /home/coder/.local/share/code-server/User
COPY settings.json /home/coder/.local/share/code-server/User/settings.json

# Set up the project directory
ARG START_DIR=/home/coder/project
USER root

RUN sudo mkdir -p $START_DIR && \
    sudo chown -R coder:coder $START_DIR && \
    sudo chmod -R 755 $START_DIR

USER coder

WORKDIR $START_DIR

ENTRYPOINT ["/usr/bin/code-server", "--bind-addr", "0.0.0.0:8080", ".", "--auth", "none"]
