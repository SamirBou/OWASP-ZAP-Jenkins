# This dockerfile builds the zap stable release
FROM centos:centos7

RUN yum install -y epel-release && \
	yum clean all && \
	yum install -y redhat-rpm-config \
	make automake autoconf gcc g++ gcc-c++ \
	libstdc++ libstdc++-devel openjdk-8-jdk \
	java-1.8.0-openjdk wget curl xvfb \
	xmlstarlet git x11vnc gettext tar unzip \
	xorg-x11-server-Xvfb openbox xterm \
	net-tools python3-pip python3-pip \
	firefox nss_wrapper java-1.8.0-openjdk-headless \
	java-1.8.0-openjdk-devel nss_wrapper git && \
	yum clean all && \
	pip3 install --upgrade pip && \
	pip3 install zapcli && \
	pip3 install python-owasp-zap-v2.4 && \
	pip install --upgrade pip && \
	pip install zapcli && \
	pip install python-owasp-zap-v2.4 && \
	mkdir -p /zap/wrk && \
	mkdir -p /var/lib/jenkins/.vnc && \
	yum update -y

ADD zap /zap/

WORKDIR /zap

# Download and expand the latest stable release
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


COPY configuration/* /var/lib/jenkins/
COPY configuration/run-jnlp-client /usr/local/bin/run-jnlp-client

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/zap/:$PATH
ENV ZAP_PATH /zap/zap.sh
ENV ZAP_PORT 8080
ENV HOME /var/lib/jenkins

COPY zap* CHANGELOG.md /zap/
COPY policies /var/lib/jenkins/.ZAP/policies/
COPY .xinitrc /var/lib/jenkins/
COPY webswing.config /zap/webswing/
COPY scripts /var/lib/jenkins/.ZAP_D/scripts/
ADD webswing.config /zap/webswing-2.5/webswing.config

RUN chown root:root /zap -R && \
	chown root:root -R /var/lib/jenkins && \
	chmod 777 /var/lib/jenkins -R && \
	chmod 777 /zap -R && \
	chmod 777 /var/lib/jenkins/.xinitrc

WORKDIR /var/lib/jenkins

# Run the Jenkins JNLP client
ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]
