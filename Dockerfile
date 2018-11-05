FROM tat2bu/jenkins-docker-dotnetcore
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
