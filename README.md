# openvpn-install
آموزش نصب و پیکربندی OpenVPN روی سرور مجازی Ubuntu برای ایجاد اتصال امن VPN. گام‌به‌گام نحوه راه‌اندازی OpenVPN، تنظیمات سرور و کلاینت، و نکات امنیتی با کدهای لازم. برای سوالات بیشتر، راه‌های ارتباطی در انتهای مقاله موجود است.

---

## **آموزش OpenVPN: نحوه نصب و کانفیگ OpenVPN روی سرور مجازی با Ubuntu**

OpenVPN یک راه‌حل محبوب و امن برای ایجاد شبکه‌های خصوصی مجازی (VPN) است. این مقاله به‌طور کامل به شما آموزش می‌دهد که چگونه OpenVPN را روی یک سرور مجازی با سیستم‌عامل **Ubuntu** نصب و پیکربندی کنید. با این راهنمای گام‌به‌گام، شما می‌توانید یک VPN امن و قابل اعتماد راه‌اندازی کنید تا از آن برای محافظت از ترافیک اینترنتی خود استفاده کنید.

### **پیش‌نیازهای نصب OpenVPN**
برای شروع نصب OpenVPN، شما نیاز به موارد زیر دارید:

- **سرور مجازی با سیستم‌عامل Ubuntu**: نسخه‌های ۲۰.۰۴ یا ۲۲.۰۴ Ubuntu به‌طور کامل از OpenVPN پشتیبانی می‌کنند.
- **دسترسی به ریشه (Root) یا دسترسی sudo**: برای نصب و پیکربندی نرم‌افزارها به دسترسی‌های سطح بالا نیاز دارید.
- **آدرس IP عمومی سرور**: برای تنظیمات مربوط به ارتباطات VPN به آدرس IP سرور نیاز دارید.

---

### **مراحل نصب و کانفیگ OpenVPN روی سرور مجازی**

#### **۱. به‌روزرسانی و نصب ابزارهای موردنیاز**
در اولین مرحله، باید اطمینان حاصل کنید که همه بسته‌ها و نرم‌افزارهای موجود بر روی سرور شما به‌روز هستند. این کار را با اجرای دستورات زیر انجام دهید:
```bash
sudo apt update && sudo apt upgrade -y
```
سپس، OpenVPN و ابزارهای موردنیاز مانند EasyRSA برای مدیریت گواهینامه‌ها را نصب کنید:
```bash
sudo apt install openvpn easy-rsa ufw -y
```

#### **۲. آماده‌سازی EasyRSA و ساخت گواهینامه‌های SSL**
EasyRSA ابزاری است که به شما اجازه می‌دهد گواهینامه‌های SSL موردنیاز برای ایجاد ارتباطات امن را تولید کنید. برای شروع، دایرکتوری جدیدی برای EasyRSA ایجاد کرده و وارد آن شوید:
```bash
make-cadir ~/easy-rsa
cd ~/easy-rsa
```
سپس با اجرای دستورات زیر گواهینامه‌ها را تولید کنید:
```bash
./easyrsa init-pki
./easyrsa build-ca nopass
```

#### **۳. تولید کلیدهای سرور**
برای تولید کلیدهای سرور از دستور زیر استفاده کنید:
```bash
./easyrsa gen-req server nopass
./easyrsa sign-req server server
```

#### **۴. تولید کلید Diffie-Hellman**
این گواهینامه برای تبادل امن کلیدها در اتصال VPN استفاده می‌شود:
```bash
./easyrsa gen-dh
```

#### **۵. پیکربندی سرور OpenVPN**
فایل پیکربندی پیش‌فرض OpenVPN را کپی کرده و ویرایش کنید:
```bash
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gunzip /etc/openvpn/server.conf.gz
sudo nano /etc/openvpn/server.conf
```
در این فایل تنظیمات، مقادیر مربوط به گواهینامه‌ها و کلیدها را مطابق با مسیر فایل‌های تولید شده تنظیم کنید:
```bash
ca ca.crt
cert server.crt
key server.key
dh dh.pem
```

#### **۶. فعال‌سازی IP Forwarding و NAT**
برای اینکه سرور شما به‌عنوان یک روتر عمل کند، باید IP forwarding را فعال کنید. فایل تنظیمات سیستم را باز کرده و آن را ویرایش کنید:
```bash
sudo nano /etc/sysctl.conf
```
مقدار زیر را پیدا کرده و از حالت comment خارج کنید:
```bash
net.ipv4.ip_forward=1
```
سپس تغییرات را اعمال کنید:
```bash
sudo sysctl -p
```

#### **۷. تنظیم فایروال**
برای محافظت از سرور و فعال کردن دسترسی به OpenVPN، فایروال UFW را پیکربندی کنید:
```bash
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH
sudo ufw enable
```

#### **۸. راه‌اندازی و فعال‌سازی سرویس OpenVPN**
پس از پیکربندی تمامی فایل‌ها، سرویس OpenVPN را راه‌اندازی کرده و آن را برای شروع خودکار در زمان راه‌اندازی سرور فعال کنید:
```bash
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
```

#### **۹. تولید کلیدهای کلاینت**
برای هر کلاینتی که قصد اتصال به سرور VPN را دارد، باید یک کلید منحصر به فرد تولید کنید. دستور زیر را برای تولید کلید کلاینت وارد کنید:
```bash
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```

#### **۱۰. ایجاد فایل پیکربندی کلاینت**
یک فایل پیکربندی برای اتصال کلاینت به سرور ایجاد کنید:
```bash
cat <<EOF > ~/client1.ovpn
client
dev tun
proto udp
remote <YOUR_SERVER_IP> 1194
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
```

---

**با استفاده از این مراحل، شما می‌توانید به راحتی OpenVPN را روی سرور Ubuntu نصب و پیکربندی کنید. حالا می‌توانید با استفاده از فایل پیکربندی کلاینت، به VPN متصل شوید و از یک اتصال امن و پایدار بهره‌مند شوید.**

اگر در هر مرحله با مشکل یا سوالی مواجه شدید، می‌توانید از طریق روش‌ ارتباطی زیر با ما تماس بگیرید.

---

### **راه‌ ارتباطی**

- **تلگرام**: [@v2makers_admin](https://t.me/v2makers_admin)

---

با استفاده از این راهنمای گام‌به‌گام و اسکریپت نصب خودکار، نصب و پیکربندی OpenVPN به آسانی انجام می‌شود. امیدواریم این آموزش به شما کمک کند تا یک شبکه امن و پایدار بسازید و از اطلاعات خود محافظت کنید.
