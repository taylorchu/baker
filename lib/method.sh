# $1 = binding

no_draft() {
	local line
	while IFS= read -r line; do
		[[ "$(header draft <"$line")" == true ]] || echo "$line"
	done
}

list_page() {
	find "$PAGE_DIR" -name "*.md" | no_draft | sort
}

list_post() {
	find "$POST_DIR" -name "*.md" | no_draft | sort
}

# $1 = map
# $2 = in
# $3 = out
safe_template() {
	[[ -f "$2" ]] || error "layout not found: $2"
	template "$1" < "$2" > "$3"
}

bake_pages() {
	local page
	while IFS= read -r page; do
		(
		need_bake "$page" || continue
		echo "$page"
		safe_template "$(map_set \
			title "$(header title < "$page")" \
			meta "$(header meta < "$page")" \
			content "$(body <"$page" | markdown )" \
			<<< "$1")" \
			"$LAYOUT_DIR/$(header layout <"$page").html" \
			"$OUTPUT_DIR/$(md_to_url "$page")"
		update_status "$page"
		) &
	done < <(list_page)
	wait
}

baker_prepare() {
	[[ -d .baker ]] || mkdir .baker
	[[ -f .baker/status ]] || touch .baker/status
	[[ -d "$OUTPUT_DIR" ]] || mkdir "$OUTPUT_DIR"
	cp -r "$PUBLIC_DIR"/* "$OUTPUT_DIR"
}

# $1 = file
need_bake() {
	! grep -q "^$(md5sum "$1")$" .baker/status
}

# $1 = dir
check_collection() {
	local i=0
	local line
	while IFS= read -r line; do
		need_bake "$line" && return 0
		((i++))
	done
	(( $i < $(grep " $1/" .baker/status | wc -l) )) && return 0
	return 1
}

need_bake_post() {
	list_post | check_collection "$POST_DIR"
}

need_bake_page() {
	list_page | check_collection "$PAGE_DIR"
}

# $1 = file
update_status() {
	echo "$(grep -v "  $1$" .baker/status)" > .baker/status
	md5sum "$1" >> .baker/status
}

bake_posts() {
	local post
	while IFS= read -r post; do
		(
		need_bake "$post" || continue
		echo "$post"
		safe_template "$(map_set \
			title "$(header title < "$post")" \
			date "$(header date < "$post")" \
			prev.url "$(prev_post_url "$post")" \
			prev.title "$(prev_post_title "$post")" \
			next.url "$(next_post_url "$post")" \
			next.title "$(next_post_title "$post")" \
			content "$(body <"$post" | markdown )" \
			<<< "$1")" \
			"$LAYOUT_DIR/$(header layout <"$post").html" \
			"$OUTPUT_DIR/$(md_to_url "$post")"
		update_status "$post"
		) &
	done < <(list_post)
	wait
}

md_to_url() {
	[[ "$1" =~ ^(.*/)?([^/]+)\.md$ ]] && echo "${BASH_REMATCH[2]}.html"
}

# $1 = file
next_post() {
	list_post | tac | grep "$1$" -A 1 | grep -v "$1$"
}

next_post_title() {
	local post="$(next_post "$1")"
	[[ -f "$post" ]] && header title < "$post"
}

next_post_url() {
	md_to_url "$(next_post "$1")"
}

# $1 = file
prev_post() {
	list_post | tac | grep "$1$" -B 1 | grep -v "$1$"
}

prev_post_title() {
	local post="$(prev_post "$1")"
	[[ -f "$post" ]] && header title < "$post"
}

prev_post_url() {
	md_to_url "$(prev_post "$1")"
}

# $1 = file
post_binding() {
	local date="$(header date < "$1")"
	: | map_set \
		title "$(header title < "$1")" \
		url "$(md_to_url "$1")" \
		date "$date" \
		rss.date "$(date -R -d "$date")" \
		summary "$(body <"$1" | summary)"
}

# $1 = function
filter() {
	local list
	local i=0
	local line
	while IFS= read -r line; do
		if [[ "$list" ]]; then
			list="$(map_set "$i" "$($1 "$line")" <<<"$list")"
		else
			list="$(: | map_set "$i" "$($1 "$line")")"
		fi
		((i++))
	done
	echo "$list"
}

post_collection_binding() {
	list_post | tac | filter post_binding
}

page_collection_binding() {
	list_page | tac | filter page_binding
}

page_binding() {
	: | map_set \
		title "$(header title < "$1")" \
		url "$(md_to_url "$1")"
}

bake_index() {
	need_bake_post || need_bake_page || return

	local post_collection="$(post_collection_binding)"
	local page_collection="$(page_collection_binding)"
	(
	echo index
	safe_template "$(map_set posts "$post_collection" pages "$page_collection" <<<"$1")" \
		"$LAYOUT_DIR/index.html" "$OUTPUT_DIR/index.html"
	) &
	(
	echo rss
	safe_template "$(map_set posts "$post_collection" pages "$page_collection" <<<"$1")" \
		"$LAYOUT_DIR/rss.html" "$OUTPUT_DIR/rss.xml"
	) &

	wait
}

summary() {
	local len
	[[ "$1" =~ ^[0-9]+$ ]] && len=$1 || len=100
	local rep=""
	local newline=$'\n'
	local line
	while IFS= read -r line; do
		rep+="$line$newline"
		(( ${#rep} < $len )) || break
	done
	markdown <<< "$rep"
}

bake() {
	baker_prepare
	local binding="$(< "$BINDING")"
	is_map <<<"$binding" || error "invalid format: $BINDING"

	headline buiding index
	timer bake_index "$binding"

	headline buiding posts
	timer bake_posts "$binding"

	headline buiding pages
	timer bake_pages "$binding"

	[[ -f "$DEBUG" ]] && error "see '$DEBUG'"
}
