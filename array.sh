# $@: variable strings
toString() {
    declare -A _var
    for arg in "$@"; do
        local i
        eval "declare -A _var2=${arg#*=}"
        for i in "${!_var2[@]}"; do
            _var[$i]="${_var2[$i]}"
        done
    done
    local r="$(declare -p _var)"
    echo "'${r#*\'}"
}

# $1 variable name, declared
toArray() {
    #echo "$(toString "${@:2}")"
    eval "declare -A _var=$(toString "${@:2}")"
    local i
    for i in "${!_var[@]}"; do
        eval "${1}[$i]=${_var[$i]}"
    done
}

appendTo() {
    eval "declare -A _var=$1"
    _var[$2]="$3"
    local r="$(declare -p _var)"
    echo "'${r#*\'}"
}
