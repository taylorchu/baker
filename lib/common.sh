headline() {
    tput setaf 4
    echo -n " :: "
    tput sgr0
    echo "$*"
}

rm -f "$DEBUG"
debug() {
    echo "--- $(date '+%Y-%m-%d %H:%M')" >> "$DEBUG"
    echo "$*" >> "$DEBUG"
    echo >> "$DEBUG"
}

error() {
	tput setaf 1
    echo -n " :: "
    tput sgr0
    echo "$*"
    exit 1
}