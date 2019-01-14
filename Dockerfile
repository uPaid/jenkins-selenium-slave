FROM java

ARG user=jenkins
ARG MAVEN_VERSION=3.6.0
ARG MAVEN_BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries
ARG CHROME_VERSION="google-chrome-stable"

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${MAVEN_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV JENKINS_HOME /home/jenkins
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$JENKINS_HOME/.m2"


RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION} \
    openssh-server git xvfb \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && apt-get clean

RUN useradd -d "$JENKINS_HOME" -m -s /bin/bash ${user}
RUN sed -i 's|session required pam_loginuid.so|session optional pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN echo "jenkins:jenkins" | chpasswd
RUN mkdir /home/jenkins/.ssh ; chmod 700 /home/jenkins/.ssh ; printf "Host review.upaid.pl\n  KexAlgorithms +diffie-hellman-group1-sha1" >/home/jenkins/.ssh/config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
