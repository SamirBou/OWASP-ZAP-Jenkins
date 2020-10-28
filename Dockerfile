# This dockerfile builds the zap stable release
FROM centos:centos7

RUN yum install -y epel-release && \
	yum install -y redhat-rpm-config \
	make automake autoconf gcc g++ gcc-c++ \
	libstdc++ libstdc++-devel openjdk-8-jdk \
	java-1.8.0-openjdk wget curl xvfb \
	xmlstarlet git x11vnc gettext tar unzip \
	xorg-x11-server-Xvfb openbox xterm \
	net-tools python-pip python3-pip \
	firefox nss_wrapper java-1.8.0-openjdk-headless \
	java-1.8.0-openjdk-devel nss_wrapper git && \
	yum clean all && \
	mkdir -p /zap/wrk && \
	mkdir -p /var/lib/jenkins/.vnc

RUN pip install --upgrade pip zapcli python-owasp-zap-v2.4
RUN pip3 install --upgrade pip zapcli python-owasp-zap-v2.4

ADD zap /zap/

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/zap/:$PATH
ENV ZAP_PATH /zap/zap.sh
ENV ZAP_PORT 8080
ENV HOME /var/lib/jenkins

WORKDIR /zap

# Download and expand the latest stable release 
RUN curl -s https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget -nv --content-disposition -i - -O - | tar zxv && \
	cp -R ZAP*/* . &&  \
	rm -R ZAP* && \
	# Setup Webswing
 	curl -s -L https://bitbucket.org/meszarv/webswing/downloads/webswing-2.3-distribution.zip | jar -x && \
	# Accept ZAP license
	touch AcceptedLicense && \

COPY configuration/* /var/lib/jenkins/
COPY configuration/run-jnlp-client /usr/local/bin/run-jnlp-client
COPY zap* CHANGELOG.md /zap/
COPY policies /var/lib/jenkins/.ZAP/policies/
COPY .xinitrc /var/lib/jenkins/
COPY webswing.config /zap/webswing/
COPY scripts /var/lib/jenkins/.ZAP_D/scripts/
ADD webswing.config /zap/webswing-2.3/webswing.config

RUN chown root:root /zap -R && \
	chown root:root -R /var/lib/jenkins && \
	chmod 777 /var/lib/jenkins -R && \
	chmod 777 /zap -R && \
	chmod 777 /home/zap/.xinitrc

WORKDIR /var/lib/jenkins

# Run the Jenkins JNLP client
ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]
