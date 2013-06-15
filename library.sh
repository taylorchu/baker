important() {
    tput setaf 4
    echo -n " :: "
    tput sgr0
    echo "$*"
}

debug() {
    echo "$*" 1>&2
}

# convert string to hook
slug() {
    tr -d [:cntrl:][:punct:] <<< "$*" | tr -s [:space:] - | tr -s [:upper:] [:lower:]
}
