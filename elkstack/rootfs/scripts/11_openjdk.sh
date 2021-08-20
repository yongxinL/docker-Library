#!/bin/bash
# =============================================================================
#   install openjdk8
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
install_name="openjdk"

## Main ----------------------------------------------------------------------
exec_command "Installing ${install_name} ..." ${package_cmd_install} \
	openjdk8-jre

exec_command "Updating permission ..." \
    grep -qE '^export JAVA_HOME=' /etc/profile || echo 'export JAVA_HOME="'$(dirname $(dirname $(readlink -f $(which java))))'"' >> /etc/profile;