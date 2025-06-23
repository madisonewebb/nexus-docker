# Builder stage
FROM alpine:3.17 AS builder

# Install required packages for downloading and extracting
RUN apk add --no-cache curl tar

# Download and extract Nexus (ARM64 version)
RUN mkdir -p /tmp/nexus \
    && curl -fsSL "https://download.sonatype.com/nexus/3/nexus-3.81.1-01-linux-aarch_64.tar.gz" -o /tmp/nexus.tar.gz \
    && tar -xzf /tmp/nexus.tar.gz -C /tmp/nexus \
    && mv /tmp/nexus/nexus-3.81.1-01 /tmp/nexus/nexus \
    && rm -f /tmp/nexus.tar.gz \
    # Remove unnecessary files to reduce image size
    && rm -rf /tmp/nexus/nexus/jdk \
    && rm -rf /tmp/nexus/nexus/system/com/sonatype/nexus/assemblies/nexus-base-template/*/nexus-base-template-*.zip \
    && find /tmp/nexus/nexus -name '*.bat' -delete \
    && find /tmp/nexus/nexus -name '*.exe' -delete \
    && find /tmp/nexus/nexus -name '*.dll' -delete

# Final stage
FROM alpine:3.17

# Install OpenJDK 17 JRE headless (smaller than full JRE) and minimal required packages
RUN apk add --no-cache \
    openjdk17-jre-headless \
    bash \
    curl \
    && rm -rf /var/cache/apk/* \
    && rm -rf /usr/lib/jvm/java-17-openjdk/lib/src.zip \
    && rm -rf /usr/lib/jvm/java-17-openjdk/demo \
    && rm -rf /usr/lib/jvm/java-17-openjdk/man

# Set environment variables
ENV NEXUS_HOME="/opt/nexus" \
    NEXUS_DATA="/nexus-data" \
    SONATYPE_WORK="/nexus-data" \
    APP_JAVA_HOME="/usr/lib/jvm/java-17-openjdk"

# Create nexus user
RUN adduser -D -h ${NEXUS_HOME} -s /sbin/nologin nexus

# Create directories
RUN mkdir -p ${NEXUS_HOME} ${NEXUS_DATA}/etc ${NEXUS_DATA}/log ${NEXUS_DATA}/tmp

# Copy Nexus from builder stage
COPY --from=builder /tmp/nexus/nexus ${NEXUS_HOME}

# Configure Nexus to use system Java
RUN sed -i 's@^# INSTALL4J_JAVA_HOME_OVERRIDE=.*@INSTALL4J_JAVA_HOME_OVERRIDE="/usr/lib/jvm/java-17-openjdk"@' ${NEXUS_HOME}/bin/nexus \
    && sed -i 's@app_java_home=\"\$EMBEDDED_JDK\"@app_java_home="/usr/lib/jvm/java-17-openjdk"@' ${NEXUS_HOME}/bin/nexus

# Configure Nexus to use the data directory
RUN sed -i 's@# application-directory=.*@application-directory=/nexus-data@' ${NEXUS_HOME}/etc/nexus-default.properties \
    && sed -i 's@# nexus-context-path=.*@nexus-context-path=/@' ${NEXUS_HOME}/etc/nexus-default.properties

# Optimize JVM settings for containers
RUN sed -i 's/-Xms2703m/-Xms1200m/g' ${NEXUS_HOME}/bin/nexus.vmoptions \
    && sed -i 's/-Xmx2703m/-Xmx1200m/g' ${NEXUS_HOME}/bin/nexus.vmoptions \
    && sed -i 's/-XX:MaxDirectMemorySize=2703m/-XX:MaxDirectMemorySize=2g/g' ${NEXUS_HOME}/bin/nexus.vmoptions \
    && echo "-Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs" >> ${NEXUS_HOME}/bin/nexus.vmoptions \
    && echo "-Dkaraf.data=${NEXUS_DATA}" >> ${NEXUS_HOME}/bin/nexus.vmoptions \
    && echo "-Djava.io.tmpdir=${NEXUS_DATA}/tmp" >> ${NEXUS_HOME}/bin/nexus.vmoptions

# Remove unnecessary files and set permissions
RUN rm -rf ${NEXUS_HOME}/system/com/sonatype/nexus/assemblies/nexus-base-template \
    && rm -rf ${NEXUS_HOME}/system/com/sonatype/nexus/assemblies/nexus-boot-launcher \
    && rm -rf ${NEXUS_HOME}/system/org/sonatype/nexus/nexus-swagger \
    && rm -rf ${NEXUS_HOME}/system/com/sonatype/nexus/assemblies/nexus-startup-feature-installer \
    && find ${NEXUS_HOME} -name '*.js.map' -delete \
    && find ${NEXUS_HOME} -name '*.js.uncompressed.js' -delete \
    && find ${NEXUS_HOME} -name '*.css.map' -delete \
    && chown -R nexus:nexus ${NEXUS_HOME} \
    && chown -R nexus:nexus ${NEXUS_DATA}

# Expose Nexus HTTP port
EXPOSE 8081

# Set volume for persistent data
VOLUME ${NEXUS_DATA}

# Set working directory
WORKDIR ${NEXUS_HOME}

# Run as nexus user
USER nexus

# Start Nexus
CMD ["/opt/nexus/bin/nexus", "run"]


