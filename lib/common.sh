headline() {
    tput setaf 4
    echo -n " :: "
    tput sgr0
    echo "$*"
}

debug() {
    echo "$*" >> baker.log
}

require() {
    type "$1" >/dev/null 2>&1 && return
    tput setaf 1
    echo -n " :: "
    tput sgr0
    echo "baker requires $1"
    exit 1
}
