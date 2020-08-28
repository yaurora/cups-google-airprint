From phusion/baseimage:0.11
MAINTAINER yaurora

ENV HOME="/root" LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8" DEBIAN_FRONTEND="noninteractive" TERM="xterm"

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

RUN apt-get update -qy \
&& apt-get upgrade -qy \
&& apt-get install --no-install-recommends -qy \
	avahi-daemon \
	avahi-utils \
	bzr \
	cups \
	cups-pdf \
	cups-filters \
	google-cloud-print-connector \
	inotify-tools \
	libcups2 \
	libavahi-client3 \
	libnss-mdns \
	libsnmp30 \
	hplip \
	python-cups \
	python \
	whois \	
&& apt-get -qq -y autoclean \
&& apt-get -qq -y autoremove \
&& apt-get -qq -y clean


COPY init.sh airprint-generate.py /tmp/
RUN rm -rf /etc/service/sshd /etc/service/cron /etc/service/syslog-ng /etc/my_init.d/00_regen_ssh_host_keys.sh /var/lib/apt/lists/* /var/tmp/* || true \
&& mv -f /usr/lib/cups/backend/parallel /usr/lib/cups/backend-available/ || true \
&& mv -f /usr/lib/cups/backend/serial /usr/lib/cups/backend-available/ || true \
&& chmod +x /tmp/init.sh && chmod +x /tmp/airprint-generate.py && /tmp/init.sh

# Export volumes
VOLUME /config /etc/cups/ /var/log/cups /var/spool/cups /var/cache/cups
EXPOSE 631
