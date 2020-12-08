FROM centos:centos7

RUN yum install -y epel-release && \
    yum clean all && \
    yum install -y redhat-rpm-config \
    make automake autoconf gcc gcc-c++ \
    libstdc++ libstdc++-devel \
    java-1.8.0-openjdky wget curl \
    xmlstarlet git x11vnc gettext tar \
    xorg-x11-server-Xvfb openbox xterm \
    net-tools python3-pip unzip \
    firefox nss_wrapper java-1.8.0-openjdk-headless \
    java-1.8.0-openjdk-devel nss_wrapper git && \
	yum update -y && \
    yum clean all

RUN pip3 install --upgrade pip zapcli python-owasp-zap-v2.4
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

RUN mkdir -p /var/lib/jenkins/.vnc
RUN mkdir -p /zap && mkdir -p /zap/wrk

WORKDIR /zap

ENV ZAP_PORT 8080
ENV IS_CONTAINERIZED true
ENV HOME /var/lib/jenkins
ENV PATH $JAVA_HOME/bin:/zap:$PATH
ENV ZAP_PATH /zap/zap.sh
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

COPY zap* CHANGELOG.md /zap/
COPY webswing.config /zap/webswing/
COPY configuration/* /var/lib/jenkins/
COPY configuration/run-jnlp-client /usr/local/bin/run-jnlp-client
COPY policies /var/lib/jenkins/.ZAP/policies/
COPY .xinitrc /var/lib/jenkins/
COPY scripts /zap/.ZAP_D/scripts/
COPY .xinitrc /zap/

RUN curl -s https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget -nv --content-disposition -i - -O - | tar zxv && \
		cp -R ZAP*/* . &&  \
		rm -R ZAP* && \
		# Setup Webswing
		curl -s -L https://storage.googleapis.com/builds.webswing.org/releases/webswing-2.5.12.zip > webswing.zip && \
		unzip webswing.zip && \
		rm webswing.zip && \
		mv webswing-* webswing && \
		# Accept ZAP license
		touch AcceptedLicense

RUN chown 0:0 /zap -R && \
    chown 0:0 -R /var/lib/jenkins && \
    chmod 777 /var/lib/jenkins -R && \
    chmod 777 /zap -R

WORKDIR /var/lib/jenkins

# Run the Jenkins JNLP client
ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]