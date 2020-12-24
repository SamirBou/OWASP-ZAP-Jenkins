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

RUN useradd -u 1001 -g 0 -m zap
# USER 1001

RUN mkdir /home/zap/wrk

WORKDIR /home/zap

ENV ZAP_PORT 8080
ENV IS_CONTAINERIZED true
ENV HOME /home/zap
ENV PATH $JAVA_HOME/bin:/home/zap:$PATH
ENV ZAP_PATH /home/zap/zap.sh
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

COPY --chown=1001:0 zap* CHANGELOG.md /home/zap/
COPY --chown=1001:0 webswing.config /home/zap/webswing/
COPY --chown=1001:0 policies /home/zap/.ZAP/policies/
COPY --chown=1001:0 .xinitrc /home/zap/
COPY --chown=1001:0 scripts /home/zap/.ZAP_D/scripts/

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
    
RUN chown 1001:0 /home/zap -R

USER 1001
