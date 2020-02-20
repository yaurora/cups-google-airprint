# cups-google-airprint
# cups with google cloud print and airprint enabled
Based on the phusion/baseimage version 0.11.

Due to fw issues some user may not be able to use the cloud mode of "google cloud print (gcp)", so only local mode is enabled by default. However, this can be easily changed via config file.

Default configuration file for gcp is generated in /config/cloudprint/gcp-cups-connector.config.json. If you exposed a local folder to config folder to the container, for instance in my case, /volume1/docker/airprint/config, then the file is located in /volume1/docker/airprint/config/gcp-cups-connector.config.json.

Just change it from:

{
  "local_printing_enable": true,
  "cloud_printing_enable": false,
  "log_level": "INFO",
  "log_file_name": "/tmp/cloud-print-connector"
}

to 

{
  "local_printing_enable": true,
  "cloud_printing_enable": true,
  "log_level": "INFO",
  "log_file_name": "/tmp/cloud-print-connector"
}

then restart the container and you are ready to test.

General usage:

Configure mappings:
Type	|Container	|Client
Path	|/dev/bus/usb	|/dev/bus/usb
Path	|/config	|/path-in-your-container
Port	|631	|631
Variable	|CUPS_USER_ADMIN	|admin (or whatever you want - for logging in to CUPS)
Variable	|CUPS_USER_PASSWORD	|pass (or whatever you want)

Other requirements
Host networking (--net="host") appears to be needed for GCP and Avahi to work. On synology NAS, ensure the cups service on Synology OS was disabled. Check the Synology documents for how to disable it. Otherwise, there will be conflicts between the OS and container.

privileged (--privileged="true")

An example startup command:
docker run -d --name="airprint" \
--net="host" --privileged="true" \
-e TZ="Asia/Shanghai" \
-e "CUPS_USER_ADMIN"="admin" \
-e "CUPS_USER_PASSWORD"="admin" \
-v /volume1/docker/airprint/config:/config \
-v /dev/bus/usb:/dev/bus/usb \
y-aurora/cups-google-airprint
