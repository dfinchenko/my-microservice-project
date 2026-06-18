#!/usr/bin/env bash
#

set -e

# Docker
if command -v docker &>/dev/null; then
    echo "Docker уже встановлено: $(docker --version)"
else
    echo "Встановлюю Docker..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    . /etc/os-release
    sudo curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    echo "Docker встановлено: $(docker --version)"
fi

# Docker Compose
if docker compose version &>/dev/null; then
    echo "Docker Compose уже встановлено: $(docker compose version)"
else
    echo "Встановлюю Docker Compose..."
    sudo apt-get install -y docker-compose-plugin
    echo "Docker Compose встановлено: $(docker compose version)"
fi

# Python 3 і pip
if command -v python3 &>/dev/null; then
    echo "Python уже встановлено: $(python3 --version)"
else
    echo "Встановлюю Python..."
    sudo apt-get install -y python3
    echo "Python встановлено: $(python3 --version)"
fi

if command -v pip3 &>/dev/null; then
    echo "pip уже встановлено: $(pip3 --version)"
else
    echo "Встановлюю pip..."
    sudo apt-get install -y python3-pip
    echo "pip встановлено: $(pip3 --version)"
fi

# Django
if python3 -c "import django" &>/dev/null; then
    echo "Django уже встановлено: $(python3 -c 'import django; print(django.get_version())')"
else
    echo "Встановлюю Django..."
    sudo -H pip3 install django 2>/dev/null || sudo -H pip3 install --break-system-packages django
    echo "Django встановлено: $(python3 -c 'import django; print(django.get_version())')"
fi