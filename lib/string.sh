trim() {
	[[ "$(cat)" =~ ^[:cntrl:]*(.*)[:cntrl:]*$ ]] && echo "${BASH_REMATCH[1]}"
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