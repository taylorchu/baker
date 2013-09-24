trim() {
	local in="$(cat)"
	[[ "$in" =~ ^[:cntrl:]*(.*)[:cntrl:]*$ ]] && echo "${BASH_REMATCH[1]}"
}

# convert string to hook
slug() {
    tr -d [:cntrl:][:punct:] <<< "$*" | tr -s [:space:] - | tr [:upper:] [:lower:]
}

html_escape() {
    local in="$(cat)"
    in="${in//&/&amp;}"
    in="${in//</&lt;}"
    in="${in//>/&gt;}"
    in="${in//\'/&apos;}"
    in="${in//\"/&quot;}"
    echo "$in"
}