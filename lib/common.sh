headline() {
    tput setaf 4
    echo -n " :: "
    tput sgr0
    echo "$*"
}

debug() {
    echo "$*" >> baker.log
}

error() {
	tput setaf 1
    echo -n " :: "
    tput sgr0
    echo "$*"
    exit 1
}

require() {
    type "$1" >/dev/null 2>&1 && return
    error "baker requires $1"
}
