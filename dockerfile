# vim:set ft=dockerfile:
FROM debian:bullseye
ARG TOKEN
# Source Dockerfile:
# https://github.com/docker-library/postgres/blob/master/9.4/Dockerfile

# explicitly set user/group IDs
RUN groupadd -r freeswitch --gid=999 && useradd -r -g freeswitch --uid=999 freeswitch
RUN apt update; apt  -y install gnupg

# grab gosu for easy step-down from root
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 0xBB7576AC
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.14/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.14/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && apt-get purge -y --auto-remove ca-certificates wget

# make the "en_US.UTF-8" locale so freeswitch will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# https://files.freeswitch.org/repo/deb/freeswitch-1.*/dists/bullseye/main/binary-amd64/Packages

ENV FS_MAJOR 1.10

RUN sed -i "s/bullseye main/bullseye main contrib non-free/" /etc/apt/sources.list

# https://freeswitch.org/confluence/display/FREESWITCH/Debian+8+bullseye#Debian8bullseye-InstallingfromDebianpackages

#RUN apt-get update && apt-get install -y curl \
#    && curl https://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add - \
#    && echo "deb http://files.freeswitch.org/repo/deb/freeswitch-$FS_MAJOR/ bullseye main" > /etc/apt/sources.list.d/freeswitch.list \
#    && apt-get purge -y --auto-remove curl
 
RUN apt-get update && apt-get install -y gnupg2 wget lsb-release
 
RUN wget --http-user=signalwire --http-password=${TOKEN} -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg
 
RUN echo "machine freeswitch.signalwire.com login signalwire password ${TOKEN}" > /etc/apt/auth.conf
RUN chmod 600 /etc/apt/auth.conf
RUN echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
RUN echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list
 
# you may want to populate /etc/freeswitch at this point.
# if /etc/freeswitch does not exist, the standard vanilla configuration is deployed
RUN apt-get update && apt-get install -y freeswitch-meta-all
#RUN apt-get update && apt-get install -y freeswitch-all \
#    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clean up
RUN apt-get autoremove

COPY docker-entrypoint.sh /
## Ports
# Open the container up to the world.
### 8021 fs_cli, 5060 5061 5080 5081 sip and sips, 64535-65535 rtp
EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5061/tcp 5061/udp 5081/tcp 5081/udp
EXPOSE 7443/tcp
EXPOSE 5070/udp 5070/tcp
EXPOSE 64535-65535/udp
EXPOSE 16384-32768/udp


# Volumes
## Freeswitch Configuration
VOLUME ["/etc/freeswitch"]
## Tmp so we can get core dumps out
VOLUME ["/tmp"]

# Limits Configuration
COPY    freeswitch.limits.conf /etc/security/limits.d/

# Healthcheck to make sure the service is running
SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

## Add additional things here

##

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["freeswitch"]
