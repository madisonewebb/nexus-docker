FROM alpine:3.17

# Install OpenJDK 8 and required packages
RUN apk add --no-cache \
    openjdk8-jre \
    curl \
    tar \
    bash
    
# Use the x86_64 version instead of aarch64
RUN curl -fsSL "https://download.sonatype.com/nexus/3/nexus-3.41.1-01-unix.tar.gz" -o /tmp/nexus.tar.gz
RUN mkdir -p /opt

RUN tar -xvzf /tmp/nexus.tar.gz -C /opt
RUN mv /opt/nexus-3.41.1-01 /opt/nexus
# Create data directory structure
RUN mkdir -p /nexus-data/etc /nexus-data/log /nexus-data/tmp

RUN adduser -D -h /opt/nexus -s /sbin/nologin nexus
RUN chown -R nexus:nexus /opt/nexus
RUN chown -R nexus:nexus /nexus-data

# Configure Nexus to use system Java instead of bundled Java
RUN sed -i 's@^# INSTALL4J_JAVA_HOME_OVERRIDE=.*@INSTALL4J_JAVA_HOME_OVERRIDE="/usr/lib/jvm/java-1.8-openjdk"@' /opt/nexus/bin/nexus

# Configure Nexus to use the data directory
RUN sed -i 's@# application-directory=.*@application-directory=/nexus-data@' /opt/nexus/etc/nexus-default.properties \
    && sed -i 's@# nexus-context-path=.*@nexus-context-path=/@' /opt/nexus/etc/nexus-default.properties

# Optimize JVM settings for containers
RUN sed -i 's/-Xms2703m/-Xms1200m/g' /opt/nexus/bin/nexus.vmoptions \
    && sed -i 's/-Xmx2703m/-Xmx1200m/g' /opt/nexus/bin/nexus.vmoptions \
    && sed -i 's/-XX:MaxDirectMemorySize=2703m/-XX:MaxDirectMemorySize=2g/g' /opt/nexus/bin/nexus.vmoptions \
    && echo "-Djava.util.prefs.userRoot=/nexus-data/javaprefs" >> /opt/nexus/bin/nexus.vmoptions \
    && echo "-Dkaraf.data=/nexus-data" >> /opt/nexus/bin/nexus.vmoptions \
    && echo "-Djava.io.tmpdir=/nexus-data/tmp" >> /opt/nexus/bin/nexus.vmoptions

USER nexus

EXPOSE 8081
VOLUME /nexus-data

ENV NEXUS_DATA="/nexus-data" \
    NEXUS_HOME="/opt/nexus" \
    SONATYPE_WORK="/nexus-data"

WORKDIR ${NEXUS_HOME}

CMD ["/opt/nexus/bin/nexus", "run"]


