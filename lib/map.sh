# $1 = key
# $2 = value
# $3 = map
map_set() {
	local args=()
	while [[ "$1" ]]; do
		args+=(-s "$2" -i "$1")
		shift 2
	done
	jshon "${args[@]}"
}

# $1 = key
# $2 = map
map_get() {
	jshon -Q -e "$1" -u
}

# $1 = key
# $2 = map
map_delete() {
	jshon -d "$1"
}

map_keys() {
	jshon -k
}

map_len() {
	jshon -l
}

is_map() {
	[[ "$(jshon -Q -t <<<"$1")" == "object" ]] && return 0 || return 1
}