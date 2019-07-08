#!/bin/bash

# function include_dependencies {
#     my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
#     source "${my_dir}/lib_color.sh"
#     source "${my_dir}/lib_helpers.sh"
#
# }
#
# include_dependencies  # we need to do that via a function to have local scope of my_dir

function get_sudo_exists {
    # we need this for travis - there is no sudo command !
    if [[ -f /usr/bin/sudo ]]; then
        echo "True"
    else
        echo "False"
    fi
}

function get_sudo_command {
    # we need this for travis - there is no sudo command !
    if [[ $(get_sudo_exists) == "True" ]]; then
        local sudo_command="sudo"
        echo ${sudo_command}
    else
        local sudo_command=""
        echo ${sudo_command}
    fi

}

function set_lib_bash_permissions {
    local sudo_command=$(get_sudo_command)
    ${sudo_command} chmod -R 0755 /usr/lib/lib_bash
    ${sudo_command} chmod -R +x /usr/lib/lib_bash/*.sh
    ${sudo_command} chown -R root /usr/lib/lib_bash || ${sudo_command} chown -R ${USER} /usr/lib/lib_bash  # there is no user root on travis
    ${sudo_command} chgrp -R root /usr/lib/lib_bash || ${sudo_command} chgrp -R ${USER} /usr/lib/lib_bash  # there is no user root on travis
}

function is_lib_bash_installed {
        if [[ -d "/usr/lib/lib_bash" ]]; then
            echo "True"
        else
            echo "False"
        fi
}


function is_lib_bash_to_update {
    local git_remote_hash=$(git --no-pager ls-remote --quiet https://github.com/bitranox/lib_bash.git | grep HEAD | awk '{print $1;}' )
    local git_local_hash=$( $(get_sudo_command) cat /usr/lib/lib_bash/.git/refs/heads/master)
    if [[ "${git_remote_hash}" == "${git_local_hash}" ]]; then
        echo "False"
    else
        echo "True"
    fi
}

function install_lib_bash {
    echo "installing lib_bash"
    $(get_sudo_command) git clone https://github.com/bitranox/lib_bash.git /usr/lib/lib_bash > /dev/null 2>&1
    set_lib_bash_permissions
}

function update_lib_bash {
    if [[ $(is_lib_bash_to_update) == "True" ]]; then
        clr_green "lib_bash needs to update"
        (
            # create a subshell to preserve current directory
            cd /usr/lib/lib_bash
            local sudo_command=$(get_sudo_command)
            ${sudo_command} git fetch --all  > /dev/null 2>&1
            ${sudo_command} git reset --hard origin/master  > /dev/null 2>&1
            set_lib_bash_permissions
        )
        clr_green "lib_bash update complete"
    else
        clr_green "lib_bash is up to date"
        exit 0
    fi
}

function restart_calling_script {
    local caller_command=("$@")
    if [ ${#caller_command[@]} -eq 0 ]; then
        # no parameters passed
        exit 0
    else
        # parameters passed, running the new Version of the calling script
        "${caller_command[@]}"
        # exit this old instance with error code 100
        exit 100
    fi

}

function source_lib_color {
    # this is needed, otherwise "${@}" will be passed to lib_color
    source /usr/lib/lib_bash/lib_color.sh
}


if [[ $(is_lib_bash_installed) == "True" ]]; then
    source_lib_color
    update_lib_bash
    restart_calling_script  "${@}"  # needs caller name and parameters
else
    install_lib_bash
fi
