cache_start() {
	local cache="/tmp/baker_cache_${FUNCNAME[1]}_$(slug "$*")"
	if [[ -f "$cache" ]]; then
		cat "$cache"
		return 0
	fi
	exec 4> "$cache"
	exec 3>&1
	exec 1>&4
	return 1
}

cache_end() {
	local cache="/tmp/baker_cache_${FUNCNAME[1]}_$(slug "$*")"
	exec 4>&-
	exec 1>&3-
	cat "$cache"
}

cache_clean() {
	rm -f /tmp/baker_cache_*
}