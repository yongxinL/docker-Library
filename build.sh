#!/bin/bash
# =============================================================================
#   build.sh - building docker image
#   Copyright (C) 2021     George Li <yongxinl@outlook.com>
#   https://github.com/yongxinL
#
# - This is part of Family Homepage project.
#
# - use this script to build docker image
#   ./build.sh /docker directory
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
debug=false
docker_cfgFile="container.conf"
docker_tplFile="Dockerfile.txt"

## Functions -----------------------------------------------------------------
#
# the parsing of the command-line
#
function parse_commandline() {
    while [ $# -gt 0 ]; do
        _key="${1}"
        case "${_key}" in
        # support whitespace as a delimiter between required argument and its value.
        # therefore, we expect the --build or -B value, so we watch for --build and -B
        -b|--build)
            [ $# -lt 2 ] && exit_fail "Missing value for the required argument '${_key}'. "
            _arg_confdir+=("${2}")
            build_docker_image "${_arg_confdir}"
            shift
            ;;
        # support the = as a delimiter between required argument and its value. therefore,
        # we expect --build=value, so we watch for --build=*. for whatever we get, we strip
        # '--build=' using the ${var##--build=} notation to get the argument value.
        --build=*)
            _arg_confdir=("${_key##--build=}")
            build_docker_image "${_arg_confdir}"
            ;;
        -r|--run)
            [ $# -lt 2 ] && exit_fail "Missing value for the required argument '${_key}'. "
            _arg_confdir+=("${2}")
            shift
            ;;
        --run=*)
            _arg_confdir=("${_key##--build=}")
            ;;
        --debug)
            debug=true
            ;;
        -h|--help)
            show_usage
            exit_success
            ;;
        # support getopt-style short arguments clustering, so as -h doesn't accept value,
        # other short options may be appened to it, so we watch for -h*.
        -h*)
            show_usage
            exit_success
            ;;
        *)
            show_usage
            exit_fail "FATA ERROR: Got an unexpected argument '${1}'"
            ;;
        esac
        shift
    done
}

# return script help
#
function show_usage() {
    echo ""
    echo "Usage: $0 {--debug} [-b|--build <dir>] [-r|--run <dir>] [-h|--help]"
    echo "This script will load the supported configure files from <directory>, and build the docker image"
    echo "version: ${script_version}"
    echo ""
    echo "-b, --build: directory include docker configure files"
    echo "-r,   --run: directory include docker configure files"
    echo "    --debug: output verbose messing for building"
    echo "-h,  --help: prints help"
}

# return docker image ID if exists
#
function get_docker_imageid() {
    local _repo=(${1//:/ })
    local _tag=${_repo[1]:latest}

    echo $(docker images --format="{{.Repository}} {{.Tag}} {{.ID}}" | awk -v name="${_repo[0]}" -v tag="${_tag}" '($1 == name) && ($2 == tag) {print $3}')
}

# remove container if exists
#
function remove_docker_containers() {
    local _repo=(${1//:/ })
    local _tag=${_repo[1]:latest}
    local _ids=$(docker ps -a | awk -v name="${_repo[0]}:${_tag}" '($2 == name) {print $1}')

    if [ ! -z "${_ids}" ]; then
        for v in ${_ids}; do
            exec_command "Removing docker container: ${v} ..." \
                docker rm --force "${v}"
        done
    fi
}

# remove docker image if exist
#
function remove_docker_images() {
    local _id=$(get_docker_imageid ${1})

    if [ ! -z "${_id}" ]; then
        remove_docker_containers "${1}"
        exec_command "Removing docker image: ${1} ..." \
            docker rmi --force "${_id}"
    fi
}

# build dockerFile based on template
# 
function build_docker_file() {
    # update base platform
    if [ ! -z "${image_base_name}" ]; then
        sed -i 's#_===BASE_PLATFORM===_#'"${image_base_name}"'#g' "${1}"
    fi

    # update exposed ports
    if [ ! -z "${container_ports_exposed}" ]; then
        local var=""
        for v in ${container_ports_exposed//,/ }
        do
            # get value with trimmed leading and trailing whitespace
            #var+=$(echo "${var}" | awk '{gsub(/^ +| +$/,"")} {print $0}')" ";
            var+=$(echo ${v} | xargs)" "
        done
        # remove last whitespace from variable
        var=${var::-1}
        sed -i 's#_===EXPOSE_PORTS===_#'"${var}"'#g' "${1}"
    else
        sed -i 's#^EXPOSE.*##g' "${1}"
    fi

    # update exposed volumes
    if [ ! -z "${container_volume_exposed}" ]; then
        local var=""
        for v in ${container_volume_exposed//,/ }; do
            var+=$(echo ${v} | xargs)" "
        done
        var=${var::-1}
        sed -i 's#_===EXPOSE_VOLUME===_#'"${var}"'#g' "${1}"
    else
        sed -i 's#^VOLUME.*##g' "${1}"
    fi
}

# build docker image
#
function build_docker_image() {
    local _cnfPath=${1}

    if [ ! -f "${_cnfPath}/${docker_cfgFile}" ] && [ ! -f "${script_path}/${_cnfPath}/${docker_cfgFile}" ]; then
        exit_fail "Cannot find valid docker configure file in directory ${_confPath}..."
    elif [ -f "${script_path}/${_cnfPath}/${docker_cfgFile}" ]; then
        _cnfPath="${script_path}/${_cnfPath}"
    fi
    source "${_cnfPath}/${docker_cfgFile}" 2>/dev/null

    if [ ! -z ${image_repo_name} ]; then

        if [ ! -f "${_cnfPath}/${docker_tplFile}" ]; then
            exit_fail "Cannot find valid docker template file in directory ${_confPath}..."
        else
            exec_command "Preparing configure file for ${image_repo_name} ..." \
            cp "${_cnfPath}/${docker_tplFile}" "${_cnfPath}/Dockerfile"; \
            build_docker_file "${_cnfPath}/Dockerfile";
        fi

        if [ ! -z $(get_docker_imageid "<none>:<none>") ]; then
            remove_docker_images "<none>:<none>"
        fi

        if [ ! -z $(get_docker_imageid "${image_repo_name}") ]; then
            remove_docker_images "${image_repo_name}"
        fi

        # change to configure directory and build
        pushd ${_cnfPath} > /dev/null
            if [ ${debug} = true ]; then
                print_info "Building image: ${image_repo_name} ..."
                docker build -t ${image_repo_name} .
            else
                exec_command "Building image: ${image_repo_name} ..." \
                    docker build -t ${image_repo_name} .
            fi
        popd > /dev/null
    fi
}

## Main -----------------------------------------------------------------------
parse_commandline "$@"

