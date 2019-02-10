FROM binhex/arch-int-openvpn:latest
MAINTAINER notryanfraser

# additional files
##################

# add supervisor conf file for app
ADD build/*.conf /etc/supervisor/conf.d/

# add bash scripts to install app
ADD build/root/*.sh /root/

# add bash script to setup iptables
ADD run/root/*.sh /root/

# add bash script to run transmission
ADD run/nobody/*.sh /home/nobody/

# add python script to configure transmission
ADD run/nobody/*.py /home/nobody/

# add pre-configured config files for transmission
ADD config/nobody/ /home/nobody/

# install app
#############

# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh /home/nobody/*.sh /home/nobody/*.py && \
	/bin/bash /root/install.sh

# docker settings
#################

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /data to host defined data path (used to store data from app)
VOLUME /data

# expose port for transmission webui
EXPOSE 9091

# expose port for privoxy
EXPOSE 8118

# expose port for transmission incoming port (used only if VPN_ENABLED=no)
EXPOSE 51413
EXPOSE 51413/udp

# set permissions
#################

# run script to set uid, gid and permissions
CMD ["/bin/bash", "/root/init.sh"]