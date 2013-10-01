# $1 = item per page
paginate() {
	local buf=""
	local pages
	local i=0
	local count=0
	local line
	while IFS= read -r line; do
		if [[ "$buf" ]]; then
			buf="$(map_set "$i" "$line" <<<"$buf")"
		else
			buf="$(: | map_set "$i" "$line")"
		fi
		if (( $i % $1 == $1 - 1 )); then
			if [[ "$pages" ]]; then
				pages="$(map_set "$count" "$buf"<<<"$pages")"
			else
				pages="$(: | map_set "$count" "$buf")"
			fi
			((count++))
			buf=""
		fi
		((i++))
	done
	echo "$pages"
}

page_count() {
	map_len
}

# $1 = current
prev() {
	map_get "$(( $1 - 2 ))"
}

current() {
	map_get "$(( $1 - 1 ))"
}

# $1 = current
next() {
	map_get "$1"
}