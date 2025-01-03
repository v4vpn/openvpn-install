#!/bin/bash

# بررسی دسترسی ریشه
if [[ "$EUID" -ne 0 ]]; then
    echo "لطفاً این اسکریپت را با دسترسی root اجرا کنید."
    exit 1
fi

# به‌روزرسانی و نصب ابزارهای موردنیاز
echo "به‌روزرسانی سرور..."
apt update && apt upgrade -y
echo "نصب OpenVPN و EasyRSA..."
apt install openvpn easy-rsa ufw -y

# آماده‌سازی EasyRSA
echo "ایجاد دایرکتوری EasyRSA..."
make-cadir ~/easy-rsa
cd ~/easy-rsa

# تولید CA
echo "ایجاد گواهینامه CA..."
./easyrsa init-pki
./easyrsa build-ca nopass

# تولید کلید سرور
echo "ایجاد کلید سرور..."
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# تولید کلید Diffie-Hellman
echo "ایجاد کلید Diffie-Hellman..."
./easyrsa gen-dh

# کپی فایل‌ها به OpenVPN
echo "انتقال فایل‌ها به دایرکتوری OpenVPN..."
cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem /etc/openvpn/

# ایجاد فایل تنظیمات سرور
echo "ایجاد فایل تنظیمات سرور..."
cat <<EOF > /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
push "redirect-gateway def1 bypass-dhcp"
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status /var/log/openvpn-status.log
verb 3
EOF

# فعال‌سازی IP Forwarding
echo "فعال‌سازی IP Forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# تنظیم فایروال
echo "تنظیم فایروال..."
ufw allow 1194/udp
ufw allow OpenSSH
ufw enable

# راه‌اندازی سرویس OpenVPN
echo "راه‌اندازی سرویس OpenVPN..."
systemctl start openvpn@server
systemctl enable openvpn@server

# تولید کلید کلاینت
echo "ایجاد کلید کلاینت..."
cd ~/easy-rsa
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
cp pki/ca.crt pki/issued/client1.crt pki/private/client1.key /etc/openvpn/

# ایجاد فایل پیکربندی کلاینت
echo "ایجاد فایل پیکربندی کلاینت..."
cat <<EOF > ~/client1.ovpn
client
dev tun
proto udp
remote $(curl -s ifconfig.me) 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client1.crt
key client1.key
remote-cert-tls server
cipher AES-256-CBC
verb 3
EOF

# نمایش پیام موفقیت
echo "نصب و کانفیگ OpenVPN با موفقیت انجام شد!"
echo "فایل کلاینت در مسیر ~/client1.ovpn موجود است."
