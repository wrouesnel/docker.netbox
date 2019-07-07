#!/bin/bash
# Script to pull a copy of the infrasot database to the local machine.

local_dbbackup="db_copy"

shutdown_hooks=()

function log() {
    echo "LOG;" "$*"
}

function warn() {
    echo "WARN:" "$*"
}

function fatal() {
    echo "FATAL:" "$*" 1>&2
    exit 1
}

function success_or_fatal() {
    local msg="$*"
    if [ $? -ne 0 ] ; then
        fatal "$msg"
    fi
}

function atexit() {
    val="$*"
    shutdown_hooks+=("$val")
}

function _shutdown() {
    log "Running shutdown hooks..."
    for ((i=${#shutdown_hooks[0]}-1; i >=0 ; i--)); do
        if [ ! -z "${shutdown_hooks[$i]}" ]; then
            log "Executing shutdown hook command:" "${shutdown_hooks[$i]}"
        fi
        eval "${shutdown_hooks[$i]}"
    done
}

function check_prereqs() {
    for bin in "${prereqs[@]}" ; do
        binpath="$(which "$bin")"
        if [ ! -x "$binpath" ]; then
            fatal "Binary dependency $bin with path $binpath is not executable."
        fi
    done
    return
}

# Install the global shutdown handler
trap "_shutdown" INT TERM EXIT

# Check for pre-requisites
prereqs=( \
    "curl" \
    "keyring" \
)

target_container="$1"
shift
target_user="$2"
shift

check_prereqs "${prereqs[@]}"

# Check if vault is logged in
admin_password=$(keyring get "container_admin_$target_container" "$target_user" )
success_or_fatal "Failed to read container admin password from Keyring."

if ! curl --basic --netrc-file <(cat <<<"machine $target_container login $infrasotdb_admin_user password $admin_password") -L "https://${target_container}/container/api/binary-backup" > "${local_dbbackup}.tar" ; then
    fatal "Failed to download live database."
fi

log "Database backup successful and saved to: $(readlink "$local_dbbackup" )"

exit 0
