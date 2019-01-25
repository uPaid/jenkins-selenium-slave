FROM ubuntu:18.04

ARG user=jenkins
ARG MAVEN_VERSION=3.6.0
ARG JAVA_BASE_URL=https://download.oracle.com/otn-pub/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jdk-8u202-linux-x64.tar.gz
ARG MAVEN_BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries
ARG CHROME_VERSION="google-chrome-stable"
ARG FIREFOX_VERSION="firefox"

ENV JENKINS_HOME /home/jenkins
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$JENKINS_HOME/.m2"

# install necessary packages
RUN apt-get update -qy \
  && apt-get -qy install curl gnupg openssh-server git xvfb

# install java
RUN mkdir -p /usr/lib/jvm && cd /usr/lib/jvm/ \
  && wget -q --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "${JAVA_BASE_URL}" \
  -O jdk-8u202-linux-x64.tar.gz \
  && tar -xzvf jdk-8u202-linux-x64.tar.gz \
  && rm -r jdk-8u202-linux-x64.tar.gz \
  && cd /
ENV JAVA_HOME /usr/lib/jvm/jdk1.8.0_202
ENV PATH ${PATH}:/usr/lib/jvm/jdk1.8.0_202/bin
RUN echo "PATH=\"${PATH}\"" > /etc/environment && echo "JAVA_HOME=${JAVA_HOME}" >> /etc/environment

# install maven
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${MAVEN_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# install firefox
RUN apt-get -qy install ${FIREFOX_VERSION} \
  && apt-get clean

# install chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qy \
  && apt-get -qy install ${CHROME_VERSION} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && apt-get clean

RUN useradd -d "$JENKINS_HOME" -m -s /bin/bash ${user}
RUN sed -i 's|session required pam_loginuid.so|session optional pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN echo "jenkins:jenkins" | chpasswd
RUN mkdir /home/jenkins/.ssh ; chmod 700 /home/jenkins/.ssh ; printf "Host review.upaid.pl\n  KexAlgorithms +diffie-hellman-group1-sha1" >/home/jenkins/.ssh/config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
