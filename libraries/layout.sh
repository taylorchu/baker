# get meta from file heading
# $1: file
# $2: key
header() {
    grep -m 1 -o "^$2: .\+" "$1" | cut -f 2- -d " "
}

# get content of the file
# $1: file
body() {
    grep -q "^---$" "$1" && sed "1,/^---$/d" "$1" || cat "$1"
}

# list tag by the same name
# $1: tag
# $2: template string
listTagContextByName() {
    tagContext "$(grep -o "{% $1 [a-z]\+ %}" <<<"$2")" | sort -u
}

# get tag offset and tag
# $1: template string
listStartEndControlTag() {
    grep -oba "{% \(foreach [a-z]\+\|if \(! \)\?[a-z]\+\|endif\|endforeach\) %}" <<<"$1"
}

# check if the tag is start tag
# $1: template string
isStartTag() {
    grep -q "^{% \(foreach [a-z]\+\|if \(! \)\?[a-z]\+\) %}$" <<<"$1"
}

# get tag name from tag
# $1: tag
tagName() {
    sed "s/^{% \([a-z]\+\) .*$/\1/" <<<"$1"
}

# get tag context from tag
# $1: tag
tagContext() {
    sed "s/^{% [a-z]\+ \(.*\) %}$/\1/" <<<"$1"
}

# get end tag from start tag
# $1: start tag
endTagOf() {
    grep -q "^{% foreach [a-z]\+ %}$" <<<"$1" && echo "{% endforeach %}"
    grep -q "^{% if \(! \)\?[a-z]\+ %}$" <<<"$1" && echo "{% endif %}"
}

stackPush() {
    stack=("${stack[@]}" "$1")
}

stackPop() {
    local i=$(( ${#stack[@]} - 1 ))
    (( $i < 0 )) && return
    unset stack[$i]
}

stackPeek() {
    local i=$(( ${#stack[@]} - 1 ))
    (( $i < 0 )) && return
    echo "${stack[$i]}"
}

# match end tag
# $1: template string
checkTag() {
    local IFS=$'\n'
    local stack=()
    local startOffset=0
    local startTag=""
    local instance
    for instance in $(listStartEndControlTag "$1"); do
        local offset="$(cut -d : -f 1 <<< "$instance")"
        local tag="$(cut -d : -f 2 <<< "$instance")"

        if isStartTag "$tag"; then
            if [[ "${#stack[@]}" == 0 ]]; then
                startOffset="$offset"
                startTag="$tag"
            fi
            stackPush "$tag"
        else
            endTag="$(endTagOf "$(stackPeek)")"
            stackPop
            if [[ "$endTag" != "$tag" ]]; then
                debug "template error: expecting '$endtag' instead of '$tag'"
                debug "---"
                debug "$1"
                debug "---"
                continue
            fi
            [[ "${#stack[@]}" == 0 ]] && echo "$startTag:$((startOffset + ${#startTag} )):$(( $offset - $startOffset - ${#startTag} ))"
        fi
    done
}

# $1: tag
# $2: template string
# $3: context
doForeach() {
    local context="$(tagContext "$1")"
    eval "declare -A vars=$3"
    local i=0
    while [[ "${vars[${context}.${i}]}" ]]; do
        #debug "run $i times"
        doTag "$2" "$(toString "$3" "${vars[${context}.${i}]}")"
        (( i++ ))
    done
}


# $1: tag
# $2: template string
# $3: context
doIf() {
    local context="$(tagContext "$1")"
    eval "declare -A vars=$3"
    if [[ "$context" =~ ^! ]]; then
        context="${context##*!}"
        [[ "vars[$context]" != false ]] || doTag "$2" "$3"
    else
        [[ "vars[$context]" != false ]] && doTag "$2" "$3"
    fi
}

# $1: template string
# $2: context
doTag() {
    local IFS=$'\n'
    local lastStartOffset=0
    local instance
    for instance in $(checkTag "$1"); do
        #debug "$instance"
        local tag="$(cut -d : -f 1 <<< "$instance")"
        local endTag="$(endTagOf "$tag")"
        local tagName="$(tagName "$tag")"
        local start="$(cut -d : -f 2 <<< "$instance")"
        local length="$(cut -d : -f 3 <<< "$instance")"
        doReplacement "${1:$lastStartOffset:$(( $start - ${#tag} - $lastStartOffset ))}" "$2"
        if [[ "$tagName" == foreach ]]; then
            doForeach "$tag" "${1:$start:$length}" "$2"
        elif [[ "$tagName" == if ]]; then
            doIf "$tag" "${1:$start:$length}" "$2"
        fi
        lastStartOffset="$(( $start + $length + ${#endTag} ))"
    done
    doReplacement "${1:$lastStartOffset}" "$2"
}

# replace {% include %} and {{ var }}
# $1: template string
# $2: context
doReplacement() {
    eval "declare -A vars=$2"
    local result="$1"
    # {{ var }}
    local i
    for i in "${!vars[@]}"; do
        local from="{{ $i }}"
        local to="${vars[$i]}"
        result="${result//$from/$to}"
    done

    # {% include %}
    for i in $(listTagContextByName include "$1"); do
        local from="{% include $i %}"
        local to="$(doInclude "$i" "$2")"
        result="${result//$from/$to}"
    done

    # {% call %}
    for i in $(listTagContextByName call "$1"); do
        local from="{% call $i %}"
        local to="$($i)"
        result="${result//$from/$to}"
    done
    echo -n "$result"
}


# $1: file name
# $2: context
doTemplate() {
    local layout="$(header "$1" layout)"
    # next level for layout
    local result="$(doTag "$(body "$1")" "$2")"
    if [[ -z "$layout" ]]; then
        echo "$result"
    else
        doLayout "$layout" "$(appendTo "$2" content "$result")"
    fi
}

# $1: include layout name
# $2: context
doInclude() {
    local includes="$THEME_DIR/$INCLUDE_DIR/$1$INCLUDE_EXT"
    if [[ ! -f "$includes" ]]; then
        debug "include not found: $includes"
        return
    fi
    doTemplate "$includes" "$2"
}

# process layout
# $1: layout name
# $2: context
doLayout() {
    local layouts="$THEME_DIR/$LAYOUT_DIR/$1$LAYOUT_EXT"
    if [[ ! -f "$layouts" ]]; then
        debug "layout not found: $layouts"
        return
    fi
    doTemplate "$layouts" "$2"
}
