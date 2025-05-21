#!/bin/bash

# 设置默认挂载目录（如果未通过环境变量指定）
HOST_CONFIG_DIR=${CUPS_CONFIG_DIR:-./cups-config}

# 检查 /etc/cups 是否挂载为主机目录
if mountpoint -q /etc/cups; then
    echo "Detected /etc/cups as a bind mount."
    echo "Host configuration directory: $HOST_CONFIG_DIR"
else
    echo "Error: /etc/cups is not mounted as a host directory."
    echo "Please specify a bind mount in docker-compose.yml (e.g., - ./cups-config:/etc/cups)."
    exit 1
fi

# 检查 /etc/cups 是否为空（即挂载目录是否为空）
if [ ! -f /etc/cups/cupsd.conf ]; then
    echo "Notice: Host directory ($HOST_CONFIG_DIR) is empty or missing required configuration files (e.g., cupsd.conf)."
    echo "Writing default CUPS configuration to $HOST_CONFIG_DIR..."
    # 从 /etc/cups-bak 复制默认配置
    cp -rp /etc/cups-bak/* /etc/cups/
    if [ $? -ne 0 ]; then
        echo "Error: Failed to write default configuration to $HOST_CONFIG_DIR."
        exit 1
    fi
    echo "Successfully wrote default configuration to $HOST_CONFIG_DIR."
else
    echo "Found existing configuration in $HOST_CONFIG_DIR, proceeding with startup..."
fi

# 设置权限，确保 cupsuser 可以访问
# 由于 /etc/cups 是绑定挂载，chmod 和 chown 会直接作用于主机上的目录
chmod -R 755 /etc/cups
chown -R cupsuser:cupsuser /etc/cups
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions on $HOST_CONFIG_DIR."
    exit 1
fi
echo "Permissions for $HOST_CONFIG_DIR set to cupsuser:cupsuser (UID 1000, GID 1000)."

# 启动 cupsd
exec /usr/sbin/cupsd -f