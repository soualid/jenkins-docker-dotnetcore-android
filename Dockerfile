FROM debian:stretch

MAINTAINER Stephane Cottin <stephane.cottin@vixns.com>

# Let's start with some basic stuff.
RUN apt-get update -qq && apt-get install -qqy \
    python-setuptools \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    lxc \
    iptables

# Install syslog-stdout
RUN easy_install syslog-stdout supervisor-stdout

# Install Docker from Docker Inc. repositories.
RUN curl -sSL https://get.docker.com/ | sh

# Install Docker Compose
ENV DOCKER_COMPOSE_VERSION 1.12.0

RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# Install the wrapper script from https://raw.githubusercontent.com/docker/docker/master/hack/dind.
ADD ./dind /usr/local/bin/dind
RUN chmod +x /usr/local/bin/dind

ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Install Jenkins
RUN wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
RUN sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
RUN apt-get update && apt-get install -y openjdk-8-jdk-headless zip supervisor jenkins && rm -rf /var/lib/apt/lists/*
RUN usermod -a -G docker jenkins && mkdir /tmp/hsperfdata_jenkins
ENV JENKINS_HOME /var/lib/jenkins
VOLUME /var/lib/jenkins

# get plugins.sh tool from official Jenkins repo
# this allows plugin installation
ENV JENKINS_UC https://updates.jenkins.io

RUN curl -o /usr/local/bin/plugins.sh \
  https://raw.githubusercontent.com/jenkinsci/docker/75b17c48494d4987aa5c2ce7ad02820fda932ce4/plugins.sh && \
  chmod +x /usr/local/bin/plugins.sh

# Define additional metadata for our image.
VOLUME /var/lib/docker

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# install python tools
RUN easy_install pip

COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# copy files onto the filesystem
COPY files/ /
RUN chmod +x /docker-entrypoint /usr/local/bin/*

EXPOSE 8080

USER root
RUN curl -fsSL get.docker.com -o get-docker.sh && \
	sh get-docker.sh && \
	service docker start && \
	apt-get update && \
	apt-get -y install curl libunwind8 gettext apt-transport-https && \
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
	mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
	sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/dotnetdev.list' && \
	apt-get update && \
	apt-get -y install dotnet-sdk-2.2 && \
	export PATH=$PATH:$HOME/dotnet 

RUN cat /etc/apt/sources.list && apt-get update && apt-get install --assume-yes apt-utils
RUN apt-get install -y apt-utils lib32stdc++6 lib32z1 build-essential file
ENV ANDROID_SDK_VERSION 3859397
RUN mkdir -p /opt/android/sdk && cd /opt/android/sdk && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip && \
    unzip *tools*linux*.zip && \
    rm *tools*linux*.zip

ENV ANDROID_HOME /opt/android/sdk
ENV PATH ${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin
ADD license_accepter.sh /opt/
RUN chmod 777 /opt/license_accepter.sh
RUN /opt/license_accepter.sh $ANDROID_HOME
RUN mkdir ~/.android && touch ~/.android/repositories.cfg && sdkmanager "add-ons;addon-google_apis-google-24" "build-tools;28.0.3" "build-tools;26.0.3" "build-tools;27.0.3" "platforms;android-27" "platforms;android-26" "platform-tools" "cmake;3.6.4111459" "ndk-bundle" "platforms;android-28"
RUN /opt/license_accepter.sh $ANDROID_HOME
RUN chmod -R 777 /opt/android/sdk

# set the entrypoint
ENTRYPOINT ["/docker-entrypoint"]

CMD ["/usr/bin/supervisord"]