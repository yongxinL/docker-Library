#!/bin/bash
# =============================================================================
#   install Elastic Kibana 6.x
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
install_name="kibana"
install_version="6.8.18"
nodejs_version="10.24.1-r0"
install_url="https://artifacts.elastic.co/downloads/kibana"

## Main ----------------------------------------------------------------------
exec_command "Installing prerequisties ..." ${package_cmd_install} \
    nodejs=${nodejs_version} --repository="http://dl-cdn.alpinelinux.org/alpine/v3.10/main/"

exec_command "Installing ${install_name} ..." \
    curl -sSL -o /tmp/kibana.tar.gz ${install_url}/${install_name}-${install_version}-linux-x86_64.tar.gz; \
    tar -xzf /tmp/kibana.tar.gz -C /usr/share/; \
    mv /usr/share/kibana-${install_version}-linux-x86_64 /usr/share/kibana; \
    adduser -D -h /usr/share/kibana kibana; \
    chown -R kibana:kibana /usr/share/kibana; \
    rm /tmp/kibana.tar.gz;

if [ ! -z $(which node) ]; then
    bundled='NODE="${DIR}/node/bin/node"'
    systemd='NODE="'$(which node)'"'
    exec_command "Replacing boundled nodejs with alpine version ..." \
        sed -i "s|${bundled}|${systemd}|g" /usr/share/kibana/bin/kibana-plugin; \
        sed -i "s|${bundled}|${systemd}|g" /usr/share/kibana/bin/kibana; \
        rm -rf /usr/share/kibana/node;
fi

exec_command "Configuring start service on boot in container ..." \
    [ ! -d /etc/services.d/kibana ] && mkdir -p /etc/services.d/kibana; \
    cp ${script_path}/conf.d/kibana/services.d/* /etc/services.d/kibana/; \
    cp ${script_path}/conf.d/kibana/config/* /usr/share/kibana/config/; \
    chmod +x /etc/services.d/*;
