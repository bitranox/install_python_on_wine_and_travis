#!/bin/bash


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

function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    local sudo_command=$(get_sudo_command)
    ${sudo_command} chmod -R +x "${my_dir}"/*.sh
    source "${my_dir}/install_lib_bash.sh"
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir


function install_lib_bash_wine_if_not_exist {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    if [[ ! -d "${my_dir}/lib_bash_wine" ]]; then
        git clone https://github.com/bitranox/lib_bash_wine.git ${my_dir}/lib_bash_wine > /dev/null 2>&1
        chmod -R +x ${my_dir}/lib_bash_wine/*.sh
    fi
}

function update_lib_bash_wine_if_exist {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    if [[ -d "${my_dir}/lib_bash_wine" ]]; then
        cd lib_bash_wine
        local git_remote_hash=$(git --no-pager ls-remote --quiet | grep HEAD | awk '{print $1;}' )
        local git_local_hash=$(git --no-pager log --decorate=short --pretty=oneline -n1 | grep HEAD | awk '{print $1;}' )
        git fetch --all  > /dev/null 2>&1
        git reset --hard origin/master  > /dev/null 2>&1
        chmod -R +x ./*.sh
        cd ..
    fi
}

update_lib_bash_wine_if_exist
install_lib_bash_wine_if_not_exist
