#!/bin/bash -ex

# 检查并创建 CUPS 管理员用户
if [ $(grep -ci $CUPSADMIN /etc/shadow) -eq 0 ]; then
    echo "Creating CUPS admin user: $CUPSADMIN"
    useradd -r -G lpadmin -M $CUPSADMIN

    # 设置密码
    echo "Setting password for $CUPSADMIN"
    echo $CUPSADMIN:$CUPSPASSWORD | chpasswd

    # 设置时区
    echo "Setting timezone to $TZ"
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
else
    echo "CUPS admin user $CUPSADMIN already exists, skipping user creation."
fi

# 运行 USB 权限检查脚本
echo "Checking USB permissions..."
/check-usb-permissions.sh
USB_CHECK_EXIT_CODE=$?
if [ $USB_CHECK_EXIT_CODE -ne 0 ]; then
    echo "USB permissions check failed. Exiting..."
    exit $USB_CHECK_EXIT_CODE
fi

# 运行配置目录初始化脚本
echo "Initializing configuration directory..."
/init-cups-config.sh
CONFIG_INIT_EXIT_CODE=$?
if [ $CONFIG_INIT_EXIT_CODE -ne 0 ]; then
    echo "Configuration directory initialization failed. Exiting..."
    exit $CONFIG_INIT_EXIT_CODE
fi
