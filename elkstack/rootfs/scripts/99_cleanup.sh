#!/bin/bash
# =============================================================================
#   CleanUp the base environment
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
service_name="cleanup"

## Main ----------------------------------------------------------------------
exec_command "cleanup unnecessary files ..."  rm -rf /etc/service; \
rm -rf /usr/share/doc-base/*; \
rm -rf /usr/share/man/*; \
rm -rf /usr/share/man-db/*; \
rm -rf /usr/share/groff/*; \
rm -rf /usr/share/info/*; \
rm -rf /usr/share/lintian/*; \
rm -rf /usr/share/linda/*; \
rm -rf /var/cache/man/*; \
rm -rf /var/lib/initramfs-tools; \
rm -rf /var/share/initramfs-tools; \
rm -rf /usr/lib/initramfs-tools; \
rm -rf /etc/initramfs-tools

[ -d /usr/share/locale ] && find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' |xargs rm -rf
[ -d /usr/share/i18n/charmaps ] && find /usr/share/i18n/charmaps -mindepth 1 -maxdepth 1 |xargs rm -rf

exec_command "cleanup unnecessary package cache and compress files ..." rm -rf /var/lib/{cache,log}; \
rm -rf /usr/src/*

exec_command "cleanup all extra Log files and zero out the rest ..." rm -rf /var/log/*; \
rm -rf "${script_path}"