# cups-google-airprint
CUPS with Google Cloud Print support, supports HP and many other printers. 
Docker image is based on phusion/baseimage:master branch.

# Deployment

## Deploy with Docker
**Special notes for Synology users:**
Since synology has it's own implementation of CUPS, which starts automatically with OS boot. It's necessary to disable it berfore we get started, or you can try other port than 631 to avoid port conflicts. Plus, system level "Bonjour Service discovery --> Printer sharing via Bonjour" must be enabled.

### To stop CUPS:
```shell
synoservice --hard-disable cupsd
synoservice --hard-disable cups-lpd
synoservicecfg --hard-disable cupsd
synoservicecfg --hard-disable cups-lpd
synoservicectl --stop cups-lpd
synoservicectl --stop cupsd
```

### Also edit /usr/share/init/cups-service-handler.conf with root privilidge and make sure below 3 lines are commented out, otherwise you can never stop them since they will always start themselves once a printer is detected.
```shell
if [ ${PRINTER_NUM} -gt 0 ]; then
        #echo "Printer exist. Start cupsd and cups-lpd." || true
        #/usr/syno/sbin/synoservice --start cupsd || true
        #/usr/syno/sbin/synoservice --start cups-lpd || true
fi
```

### Due to fw issues some users may not be able to use the cloud mode of "google cloud print (gcp)", so only local mode is enabled by default. However, this can be easily changed via config file.


Just change it from:
```json
{ "local_printing_enable": true, "cloud_printing_enable": false, "log_level": "INFO", "log_file_name": "/tmp/cloud-print-connector" }
```
to
```json
{ "local_printing_enable": true, "cloud_printing_enable": true, "log_level": "INFO", "log_file_name": "/tmp/cloud-print-connector" }
```
then restart the container and you are ready to move on the next.

### Other requirement
#### Host networking (--net="host") appears to be needed for GCP and Avahi to work. On synology NAS, ensure the cups service on Synology OS was disabled. Check the Synology documents for how to disable it. Otherwise, there will be conflicts between the OS and container.

#### privileged (--privileged="true")

#### Data persistence
Default configuration file for gcp is generated in /config/gcp/gcp-cups-connector.config.json. So if you need the config to be persistent, remember to map this folder to some persistent storage.
CUPS uses the /config folder to store it's configuration files.

### A quick startup command: 
```shell
docker run -d --name="airprint" \
--restart=always \
--net=host --privileged="true" \
-e CUPS_USER_ADMIN=print \
-e CUPS_USER_PASSWORD=password \
-v /volume1/docker/airprint/config:/config \
-v /dev/bus/usb:/dev/bus/usb \
yaurora/cups-google-airprint:primary
```


### Or if you don't want to use the host network and to expose mandatory ports (not tested), use:

```shell
docker run -d --name="airprint" \
--restart=always \
--net=bridge --privileged="true" \
-p 631:631 \ # you can try other ports but I didn't test it
-p 5353:5353 \
-e CUPS_USER_ADMIN=print \
-e CUPS_USER_PASSWORD=password \
-v /volume1/docker/airprint/config:/config \
-v /dev/bus/usb:/dev/bus/usb \
yaurora/cups-google-airprint:primary
```

## Deploy with Ansible
ansible-playbook install_cups.yml 

Project source: https://github.com/yaurora/cups-google-airprint
