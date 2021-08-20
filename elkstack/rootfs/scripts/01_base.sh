#!/bin/sh
# =============================================================================
#   Setup base environment inside docker image
#   Copyright (C) 2021     George Li <yongxinl@outlook.com>
#   https://github.com/yongxinL
#
# - This is part of Family Homepage project.
#
#   Use sh instead since bash does not exist in base alpine image
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
service_name="base"

## Main ----------------------------------------------------------------------
exec_command "initializing base alpine linux ..." ${package_cmd_install} \
    ca-certificates \
    bash \
    curl

exec_command "installing s6 overlay ..." \
    curl -sSL -o /tmp/s6overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64.tar.gz; \
    tar xzf /tmp/s6overlay.tar.gz -C /; \
    rm /tmp/s6overlay.tar.gz;
