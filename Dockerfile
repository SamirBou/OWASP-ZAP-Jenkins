FROM centos:centos7

RUN yum install -y epel-release && \
    yum clean all && \
    yum install -y redhat-rpm-config \
    make automake autoconf gcc gcc-c++ \
    libstdc++ libstdc++-devel \
    java-1.8.0-openjdky wget curl \
    xmlstarlet git x11vnc gettext tar \
    xorg-x11-server-Xvfb openbox xterm \
    net-tools python python3 python3-pip python-pip unzip \
    firefox nss_wrapper java-1.8.0-openjdk-headless \
    java-1.8.0-openjdk-devel nss_wrapper git && \
	yum update -y && \
    yum clean all

RUN pip3 install --upgrade pip zapcli python-owasp-zap-v2.4
RUN pip install --upgrade pip zapcli python-owasp-zap-v2.4
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

RUN mkdir -p /zap/

RUN useradd -d /zap -m -s /bin/bash zap
RUN echo zap:0 | chpasswd
RUN chown -R zap:0 /zap/

WORKDIR /zap

USER zap
RUN mkdir -p /zap/.vnc

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

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/zap/:$PATH
ENV ZAP_PATH /zap/zap.sh
ENV ZAP_PORT 8080
ENV IS_CONTAINERIZED true
ENV HOME /zap/

ADD zap /zap/

COPY zap* CHANGELOG.md /zap/
COPY webswing.config /zap/webswing/
COPY policies /zap/.ZAP_D/policies/
COPY policies /home/zap/.ZAP_D/policies/
COPY scripts /home/zap/.ZAP_D/scripts/
COPY .xinitrc /zap/

USER 0
RUN chown -R zap:0 /zap

USER zap

HEALTHCHECK --retries=5 --interval=5s CMD zap-cli status