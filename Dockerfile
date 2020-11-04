FROM centos:centos7

RUN yum install -y epel-release && \
    yum clean all && \
    yum install -y redhat-rpm-config \
    make automake autoconf gcc gcc-c++ \
    libstdc++ libstdc++-devel \
    java-1.8.0-openjdk wget curl \
    xmlstarlet git x11vnc gettext tar \
    xorg-x11-server-Xvfb openbox xterm \
    net-tools python-pip3 \
    firefox nss_wrapper java-1.8.0-openjdk-headless \
    java-1.8.0-openjdk-devel nss_wrapper git && \
    yum clean all && \
		mkdir -p /zap/wrk && \
    mkdir -p /var/lib/jenkins/.vnc

RUN pip3 install --upgrade pip zapcli python-owasp-zap-v2.4

RUN useradd -d /home/zap -m -s /bin/bash jenkins
RUN echo jenkins:jenkins | chpasswd
RUN mkdir /zap && chown jenkins:jenkins /zap

WORKDIR /zap

RUN mkdir -p /zap/wrk

RUN curl -s https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget -nv --content-disposition -i - -O - | tar zxv && \
		cp -R ZAP*/* . &&  \
		rm -R ZAP* && \
		# Setup Webswing
		curl -s -L https://storage.googleapis.com/builds.webswing.org/releases/webswing-2.5.12.zip > webswing.zip && \
		unzip webswing.zip && \
		rm webswing.zip && \
		mv webswing-* webswing && \
		# Remove Webswing demos
		rm -R webswing/demo/ && \
		# Accept ZAP license
		touch AcceptedLicense

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/zap/:$PATH
ENV IS_CONTAINERIZED true
ENV ZAP_PATH /zap/zap.sh
ENV ZAP_PORT 8080
ENV HOME /var/lib/jenkins

COPY configuration/* /var/lib/jenkins/
COPY configuration/run-jnlp-client /usr/local/bin/run-jnlp-client
COPY webswing.config /zap/webswing/
COPY policies /var/lib/jenkins/.ZAP_D/policies/
COPY policies /root/.ZAP_D/policies/
COPY .xinitrc /var/lib/jenkins/
COPY scripts /var/lib/jenkins/.ZAP_D/scripts/
COPY zap* CHANGELOG.md /zap/
ADD webswing.config /zap/webswing-2.5.12/webswing.config

RUN chown jenkins:jenkins /zap -R && \
	chown jenkins:jenkins -R /var/lib/jenkins && \
	chmod 777 /var/lib/jenkins -R && \
	chmod 777 /zap -R && \
	chmod 777 /var/lib/jenkins/.xinitrc

RUN chown jenkins:jenkins /zap/* CHANGELOG.md && \
		chown jenkins:jenkins /zap/webswing/webswing.config && \
		chown jenkins:jenkins -R /var/lib/jenkins/.ZAP_D/

WORKDIR /var/lib/jenkins

# Run the Jenkins JNLP client
ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]
