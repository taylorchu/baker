timer() {
    local t1="$(date +%s%N)"
    "$@"
    local t2="$(date +%s%N)"
    tput setaf 2
    bc <<< "scale=3;$((t2 - t1))/1000000000"
    tput sgr0
}
