FROM java:8

# Setup useful environment variables
ENV BAMBOO_HOME     /var/atlassian/bamboo
ENV BAMBOO_INSTALL  /opt/atlassian/bamboo
ENV BAMBOO_VERSION  5.10.3

# Install Atlassian Bitbucket and helper tools and setup initial home
# directory structure.
RUN set -x \
    && apt-get update --quiet \
    && apt-get install --quiet --yes --no-install-recommends libtcnative-1 git-core xmlstarlet \
    && apt-get clean \
    && mkdir -p               "${BAMBOO_HOME}/lib" \
    && chmod -R 700           "${BAMBOO_HOME}" \
    && chown -R daemon:daemon "${BAMBOO_HOME}" \
    && mkdir -p               "${BAMBOO_INSTALL}" \
    && curl -Ls               "https://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz" | tar -zx --directory  "${BAMBOO_INSTALL}" --strip-components=1 --no-same-owner \
    && curl -Ls                "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz" | tar -xz --directory "${BAMBOO_INSTALL}/lib" --strip-components=1 --no-same-owner "mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar" \
    && chmod -R 700           "${BAMBOO_INSTALL}/conf" \
    && chmod -R 700           "${BAMBOO_INSTALL}/logs" \
    && chmod -R 700           "${BAMBOO_INSTALL}/temp" \
    && chmod -R 700           "${BAMBOO_INSTALL}/work" \
    && chown -R daemon:daemon "${BAMBOO_INSTALL}/conf" \
    && chown -R daemon:daemon "${BAMBOO_INSTALL}/logs" \
    && chown -R daemon:daemon "${BAMBOO_INSTALL}/temp" \
    && chown -R daemon:daemon "${BAMBOO_INSTALL}/work" \
    && sed --in-place         's/^# umask 0027$/umask 0027/g' "${BAMBOO_INSTALL}/bin/setenv.sh" \
    && xmlstarlet             ed --inplace \
        --delete              "Server/Service/Engine/Host/@xmlValidation" \
        --delete              "Server/Service/Engine/Host/@xmlNamespaceAware" \
                              "${BAMBOO_INSTALL}/conf/server.xml" \
    && touch -d "@0"          "${BAMBOO_INSTALL}/conf/server.xml"

    # && ln --symbolic          "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BAMBOO_INSTALL}/lib/native/libtcnative-1.so" \
# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
USER daemon:daemon

# Expose default HTTP and SSH ports.
EXPOSE 8085 54663

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["/var/atlassian/bamboo","/opt/atlassian/bamboo/logs"]

# Set the default working directory as the Bitbucket home directory.
WORKDIR /var/atlassian/bamboo

COPY "docker-entrypoint.sh" "/"
ENTRYPOINT ["/docker-entrypoint.sh"]

# Run Atlassian Bitbucket as a foreground process by default.
CMD ["/opt/atlassian/bamboo/bin/catalina.sh", "run"]