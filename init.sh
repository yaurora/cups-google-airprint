mkdir -p /etc/my_init.d
cp /tmp/airprint-generate.py /opt/

cat <<'EOT' >/etc/my_init.d/config.sh
#!/bin/bash
mkdir -p /config/cups /config/spool /config/logs /config/cache /config/cups/ssl /config/cups/ppd /config/gcp /config/avahi

# Copy missing config files
cd /etc/cups
for f in *.conf ; do
  if [ ! -f "/config/cups/${f}" ]; then
    cp ./${f} /config/cups/
  fi
done
EOT
chmod +x /etc/my_init.d/config.sh


# Add cups to runit
mkdir -p /etc/service/cups
cat <<'EOT' >/etc/service/cups/run
#!/bin/sh
if [ -n $CUPS_USER_ADMIN ]; then
  if [ $(grep -ci $CUPS_USER_ADMIN /etc/shadow) -eq 0 ]; then
    useradd $CUPS_USER_ADMIN -G root,lpadmin -M --password $(openssl passwd -1 $CUPS_USER_PASSWORD)
    #Or even better, encrypt the pass with salt
    #useradd $CUPS_USER_ADMIN -G root,lpadmin -M --password $(openssl passwd -1 -salt $(openssl rand -hex 8) $CUPS_USER_PASSWORD)

  fi
fi
exec /usr/sbin/cupsd -f -c /config/cups/cupsd.conf -s /config/cups/cups-files.conf
EOT
chmod +x /etc/service/cups/run


# Add AirPrint to runit
mkdir -p /etc/service/airprint
cat <<'EOT' > /etc/service/airprint/run
#!/bin/bash

while [[ $(curl -sk localhost:631 >/dev/null; echo $?) -ne 0 ]]; do
  sleep 1
done
cupsctl --remote-admin --remote-any --share-printers
/opt/airprint-generate.py -d /config/avahi

inotifywait -m /config/cups/ppd -e create -e moved_to -e close_write|
    while read path action file; do
        echo "Printer ${file} modified, reloading Avahi services."
        /opt/airprint-generate.py -d /config/avahi
    done
EOT

cat <<'EOT' > /etc/service/airprint/finish
#!/bin/bash
rm -rf /config/avahi/AirPrint*
EOT
chmod +x /etc/service/airprint/*


# make avahi autostart
cat <<'EOT' >/etc/my_init.d/avahi.sh
#!/bin/bash
mkdir -p /run/avahi-daemon
chown -R avahi:avahi /run/avahi-daemon/
service dbus restart
rm -f /run/avahi-daemon/pid
exec avahi-daemon -D --no-chroot
EOT
chmod +x /etc/my_init.d/avahi.sh

# make gcp autostart
mkdir -p /etc/service/gcp
cat <<'EOT' >/etc/service/gcp/run
#!/bin/sh
rm -f /tmp/cloud-print-connector-monitor.sock
if [ ! -f /config/gcp/gcp-cups-connector.config.json ]
  then
    cd /config/gcp
    gcp-connector-util init --local-printing-enable --cloud-printing-enable=false
fi
exec gcp-cups-connector --config-filename /config/gcp/gcp-cups-connector.config.json
EOT
chmod +x /etc/service/gcp/run
