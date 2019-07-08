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

function install_or_update_lib_bash {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    local sudo_command=$(get_sudo_command)
    ${sudo_command} chmod -R +x "${my_dir}"/*.sh
    "${my_dir}/install_or_update_lib_bash.sh" "${@}" || exit 0              # exit old instance after updates
}

function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    local sudo_command=$(get_sudo_command)
    ${sudo_command} chmod -R +x "${my_dir}"/*.sh
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
}


function set_lib_bash_wine_permissions {
    local sudo_command=$(get_sudo_command)
    ${sudo_command} chmod -R 0755 /usr/lib/lib_bash_wine
    ${sudo_command} chmod -R +x /usr/lib/lib_bash_wine/*.sh
    ${sudo_command} chown -R root /usr/lib/lib_bash_wine || ${sudo_command} chown -R ${USER} /usr/lib/lib_bash_wine || clr_bold clr_red "giving up set owner" # there is no user root on travis  # there is no user root on travis
    ${sudo_command} chgrp -R root /usr/lib/lib_bash_wine || ${sudo_command} chgrp -R ${USER} /usr/lib/lib_bash_wine || clr_bold clr_red "giving up set group" # there is no user root on travis # there is no user root on travis
}

function is_lib_bash_wine_installed {
        if [[ -d "/usr/lib/lib_bash_wine" ]]; then
            echo "True"
        else
            echo "False"
        fi
}


function is_lib_bash_wine_to_update {
    local git_remote_hash=$(git --no-pager ls-remote --quiet https://github.com/bitranox/lib_bash_wine.git | grep HEAD | awk '{print $1;}' )
    local git_local_hash=$( $(get_sudo_command) cat /usr/lib/lib_bash_wine/.git/refs/heads/master)
    if [[ "${git_remote_hash}" == "${git_local_hash}" ]]; then
        echo "False"
    else
        echo "True"
    fi
}

function install_lib_bash_wine {
    clr_green "installing lib_bash_wine"
    $(get_sudo_command) git clone https://github.com/bitranox/lib_bash_wine.git /usr/lib/lib_bash_wine > /dev/null 2>&1
    set_lib_bash_wine_permissions
}



function update_lib_bash_wine {
    if [[ $(is_lib_bash_wine_to_update) == "True" ]]; then
        clr_green "lib_bash_wine needs to update"
        (
            # create a subshell to preserve current directory
            cd /usr/lib/lib_bash_wine
            local sudo_command=$(get_sudo_command)
            ${sudo_command} git fetch --all  > /dev/null 2>&1
            ${sudo_command} git reset --hard origin/master  > /dev/null 2>&1
            set_lib_bash_wine_permissions
        )
        clr_green "lib_bash_wine update complete"
    else
        clr_green "lib_bash_wine is up to date"
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

install_or_update_lib_bash "${@}"
include_dependencies

if [[ $(is_lib_bash_wine_installed) == "True" ]]; then
    update_lib_bash_wine
    restart_calling_script  "${@}"  # needs caller name and parameters
else
    install_lib_bash_wine
fi
