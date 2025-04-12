#!/bin/bash
# ==========================================
# Color
# install stunnel 5

# Link Hosting Kalian Untuk Stunnel5
akbarvpnnnn="raw.githubusercontent.com/AmineBaggarii/MANTAPV3/main/stunnel5"

# Install required dependencies
apt-get update
apt-get install -y build-essential libssl-dev zlib1g-dev wget unzip libsystemd-dev libwrap0-dev

# Create necessary directories
mkdir -p /etc/stunnel5
mkdir -p /usr/local/etc/stunnel

# Download and extract stunnel5
cd /root/
wget -q -O stunnel5.zip "https://raw.githubusercontent.com/AmineBaggarii/MANTAPV3/main/stunnel5/stunnel5.zip"
unzip -o stunnel5.zip
cd /root/stunnel
chmod +x configure

# Configure with all required options
./configure \
    --with-ssl=/usr/lib/ssl \
    --with-systemd=/usr/lib/systemd/system \
    --with-threads=pthread \
    --with-libwrap \
    --prefix=/usr/local \
    --sysconfdir=/etc/stunnel5

make
make install
cd /root
rm -r -f stunnel
rm -f stunnel5.zip

# Create SSL certificates if they don't exist
if [ ! -f /etc/xray/xray.crt ] || [ ! -f /etc/xray/xray.key ]; then
    openssl req -new -x509 -days 3650 -nodes -out /etc/xray/xray.crt -keyout /etc/xray/xray.key -subj "/C=ID/ST=ID/L=ID/O=ID/OU=ID/CN=ID"
fi

# Create stunnel5 configuration
cat > /etc/stunnel5/stunnel5.conf <<-END
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 53
connect = 127.0.0.1:109

[ssh]
accept = 777
connect = 127.0.0.1:8000
END

# Create systemd service
cat > /etc/systemd/system/stunnel5.service << END
[Unit]
Description=Stunnel5 Service
Documentation=https://stunnel.org
After=syslog.target network-online.target

[Service]
ExecStart=/usr/local/bin/stunnel /etc/stunnel5/stunnel5.conf
Type=forking
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END

# Set permissions
chmod 600 /etc/xray/xray.key
chmod 644 /etc/xray/xray.crt
chmod 644 /etc/stunnel5/stunnel5.conf

# Create symlink
ln -sf /usr/local/bin/stunnel /usr/local/bin/stunnel5

# Remove unnecessary files
rm -r -f /usr/local/share/doc/stunnel/
rm -r -f /usr/local/etc/stunnel/
rm -f /usr/local/bin/stunnel3
rm -f /usr/local/bin/stunnel4

# Reload systemd and start service
systemctl daemon-reload
systemctl enable stunnel5
systemctl start stunnel5

# Verify installation
if systemctl is-active --quiet stunnel5; then
    echo "Stunnel5 has been successfully installed and started!"
else
    echo "Stunnel5 installation failed. Check the logs with: journalctl -u stunnel5"
    exit 1
fi
