headline() {
    tput setaf 4
    echo -n " :: "
    tput sgr0
    echo "$*"
}

debug() {
    echo "$*" >> baker.log
}

# convert string to hook
slug() {
    tr -d [:cntrl:][:punct:] <<< "$*" | tr -s [:space:] - | tr [:upper:] [:lower:]
}
