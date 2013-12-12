trim() {
    local var
    read  -rd '' var
    echo "$var"
}

# convert string to hook
slug() {
    tr -d [:cntrl:][:punct:] <<< "$*" | tr -s [:space:] - | tr [:upper:] [:lower:]
}

html_escape() {
	sed \
	-e 's|&|\&amp|g' \
	-e 's|<|\&lt;|g' \
	-e 's|>|\&gt;|g' \
	-e 's|'\''|\&apos;|g' \
	-e 's|"|\&quot;|g'
}

split() {
	sed -e 's|, |\n|g' -e 's|,|\n|g'
}

newline_escape() {
	local line
	while IFS= read -r line; do
		echo -n "${line//\\/\\\\}\n"
	done
}

newline_unescape() {
	echo -e "$(cat)"
}

regex_offset() {
	local pat=()
	while [[ "$1" ]]; do
		pat+=(-e "$1")
		shift
	done
	LANG= sed 's|[^\x00-\x7F]\+| |g' | grep -b -o "${pat[@]}"
}
