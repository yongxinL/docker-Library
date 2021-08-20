#!/bin/bash
# =============================================================================
#   install ElasticSearch 6.x
#   Copyright (C) 2021     George Li <yongxinl@outlook.com>
#   https://github.com/yongxinL
#
# - This is part of Family Homepage project.
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Function Library ----------------------------------------------------------
print_info "*** Checking for required libraries." 2>/dev/null ||
    source "/etc/functions.bash" 2>/dev/null ||
    source "$(dirname $(
        if [ "$(echo "${0%/*}")" != "$(echo "${0}")" ]; then cd "$(echo "${0%/*}")"; fi
        pwd
    ))/functions.bash" 2>/dev/null

if [[ $? -ne 0 ]]; then
    echo "Unable to find required function Library file, exit !!!"
    exit 1
fi

## Vars ----------------------------------------------------------------------
script_version="2021.08"
install_name="elasticsearch"
install_version="6.8.18"
install_url="https://artifacts.elastic.co/downloads/elasticsearch"

## Main ----------------------------------------------------------------------
exec_command "Installing prerequisties ..." ${package_cmd_install} \
	gnupg \
    openssl

exec_command "Installing ${install_name} ..." \
    curl -sSL -o /tmp/elasticsearch.tar.gz ${install_url}/${install_name}-${install_version}.tar.gz; \
    tar -xzf /tmp/elasticsearch.tar.gz -C /usr/share/; \
    mv /usr/share/elasticsearch-${install_version} /usr/share/elasticsearch; \
    rm -rf /usr/share/elasticsearch/modules/x-pack-ml/; \
    rm -rf /usr/share/elasticsearch/modules/x-pack-security/; \
    rm /tmp/elasticsearch.tar.gz;

exec_command "creating required user and directories ..." \
    mkdir -p /usr/share/elasticsearch/{date,logs,config,tmp,plugins}; \
    mkdir -p /usr/share/elasticsearch/config/scripts; \
    adduser -D -h /usr/share/elasticsearch elasticsearch; \
    chown -R elasticsearch:elasticsearch /usr/share/elasticsearch;

exec_command "installing additional plugins and integrations  ..." \
    grep -qE '^export JAVA_HOME=' /etc/profile || echo 'export JAVA_HOME="'$(dirname $(dirname $(readlink -f $(which java))))'"' >> /etc/profile; \
    source /etc/profile; \
    /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch analysis-phonetic; \
    /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch analysis-icu; \
    /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch ingest-attachment;

exec_command "Configuring start service on boot in container ..." \
    [ ! -d /etc/cont-init.d ] && mkdir -p /etc/cont-init.d; \
    [ ! -d /etc/services.d/elasticsearch ] && mkdir -p /etc/services.d/elasticsearch; \
    cp ${script_path}/conf.d/elasticsearch/cont-init.d/21-elasticsearch.sh /etc/cont-init.d/; \
    cp ${script_path}/conf.d/elasticsearch/services.d/* /etc/services.d/elasticsearch/; \
    cp ${script_path}/conf.d/elasticsearch/config/* /usr/share/elasticsearch/config/; \
    chmod +x /etc/cont-init.d/21-elasticsearch.sh; \
    chmod +x /etc/services.d/*;
