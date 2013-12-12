# $1 = item per page
paginate() {
	local buf=""
	local pages
	local i=0
	local count=0
	local line
	while IFS= read -r line; do
		buf="$(map_set "$i" "$line" <<<"$buf")"
		if (( $i % $1 == $1 - 1 )); then
			pages="$(map_set "$count" "$buf"<<<"$pages")"
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
