append() {
	cat
	while [[ "$1" ]]; do
		echo "$1"
		shift
	done
}

# $1 = key
# $2 = value
map_set() {
	if [[ ! "$1" ]]; then
		cat
		return
	fi
	local escape="$(newline_escape <<<"$2")"
	map_delete "$1" | append "$1: ${escape%%??}" | map_set "${@:3}"
}

# $1 = key
map_get() {
	grep "^$1: " | cut -d ' ' -f 2- | newline_unescape
}

# $1 = key
map_delete() {
	grep -v "^$1: "
}

map_keys() {
	local line
	while IFS= read -r line; do
		[[ "$line" =~ ^([^\ ]+):\  ]] && echo "${BASH_REMATCH[1]}"
	done
}

map_len() {
	wc -l
}

is_map() {
	local line
	while IFS= read -r line; do
		[[ "$line" =~ ^[^\ ]+:\  ]] || return 1
	done
	return 0
}