FROM ubuntu:22.04


ARG DEBIAN_FRONTEND=noninteractive

# Install: dependencies, clean: apt cache, remove dir: cache, man, doc, change mod time of cache dir.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    software-properties-common \
    rsyslog systemd systemd-cron sudo \
    && apt-get clean \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && rm -rf /var/lib/apt/lists/* \
    && touch -d "2 hours ago" /var/lib/apt/lists
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

RUN rm -f /lib/systemd/system/systemd*udev* \
    && rm -f /lib/systemd/system/getty.target

RUN apt-get update && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg-agent python3-pip python3-apt ca-certificates gcc apt-transport-https software-properties-common sudo iproute2 openssh-server nano net-tools rsyslog udev\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && cd /usr/local/bin \
    && ln -s /usr/bin/python3 python \
    && pip3 install --upgrade pip \
    && ln -s /usr/bin/python3 /usr/bin/python

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales \
    && DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFOLD=1 apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq -y install tzdata \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN mkdir /var/run/sshd
RUN echo 'root:root' |chpasswd
RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN mkdir /root/.ssh
ENV ANSIBLE_USER=ansible SUDO_GROUP=sudo DEPLOY_GROUP=deployer
RUN set -xe \
    && adduser ${ANSIBLE_USER} \
    && groupadd -r ${DEPLOY_GROUP} \
    && usermod -aG ${SUDO_GROUP} ${ANSIBLE_USER} \
    && usermod -aG ${DEPLOY_GROUP} ${ANSIBLE_USER} \
    && sed -i "/^%${SUDO_GROUP}/s/ALL\$/NOPASSWD:ALL/g" /etc/sudoers
RUN echo "Europe/Warsaw" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/lib/systemd/systemd"]
