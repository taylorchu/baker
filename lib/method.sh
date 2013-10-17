no_draft() {
	[[ "$(header draft <"$1")" == true ]] && return 1 || return 0
}

list_page() {
	find "$PAGE_DIR" -name "*.md" | list_filter no_draft | sort
}

list_post() {
	find "$POST_DIR" -name "*.md" | list_filter no_draft | sort
}

get_tag() {
	header tags <"$1" | split
}

list_tag() {
	list_post | list_expand get_tag | sort -u
}

# $1 = map
# $2 = in
# $3 = out
safe_template() {
	[[ -f "$2" ]] || error "layout not found: $2"
	template "$1" < "$2" > "$3"
}

baker_prepare() {
	[[ -d .baker ]] || mkdir .baker
	[[ -f .baker/status ]] || touch .baker/status

	: > .baker/status_new
	[[ -d "$OUTPUT_DIR" ]] || mkdir "$OUTPUT_DIR"
	cp -r "$PUBLIC_DIR"/* "$OUTPUT_DIR"
	cp -r "$CONTENT_DIR" "$OUTPUT_DIR"

	local need_full_bake=false
	need_bake "$LAYOUT_DIR" && need_full_bake=true
	need_bake "$INCLUDE_DIR" && need_full_bake=true
	need_bake "$PUBLIC_DIR" && need_full_bake=true
	need_bake "$BINDING" && need_full_bake=true
	$need_full_bake && headline full bake &&  : > .baker/status
}

baker_finish() {
	sort -u -k 2 .baker/status_new > .baker/status
	[[ -f "$DEBUG" ]] && error "see '$DEBUG'"
}

# $1 = file
need_bake() {
	local md5
	[[ -d  "$1" ]] && md5="$(ls -lR "$1" | md5sum | sed "s|-|$1|g")" || md5="$(md5sum "$1")"
	echo "$md5" >> .baker/status_new
	! grep -q "^$md5$" .baker/status
}

bake_posts() {
	local post
	while IFS= read -r post; do
		need_bake "$post" || continue
		(
		echo "$post"
		safe_template "$(map_merge "$1" "$(post_binding "$post")")" \
			"$LAYOUT_DIR/$(header layout <"$post").html" \
			"$OUTPUT_DIR/$(md_to_url "$post")"
		) &
	done < <(list_post)
	wait
}

bake_pages() {
	local page
	while IFS= read -r page; do
		need_bake "$page" || continue
		(
		echo "$page"
		safe_template "$(map_merge "$1" "$(page_binding "$page")")" \
			"$LAYOUT_DIR/$(header layout <"$page").html" \
			"$OUTPUT_DIR/$(md_to_url "$page")"
		) &
	done < <(list_page)
	wait
}

bake_tags() {
	need_bake "$POST_DIR" || return
	local tag
	while IFS= read -r tag; do
		(
		echo "$tag"
		safe_template "$(map_set \
			tag "$tag" \
			posts "$(tag_binding "$tag")" <<<"$1")" \
			"$LAYOUT_DIR/tag.html" \
			"$OUTPUT_DIR/$tag.html"
		) &
	done < <(list_tag)
	wait
}

md_to_url() {
	[[ "$1" =~ ^(.*/)?([^/]+)\.md$ ]] && echo "${BASH_REMATCH[2]}.html"
}

# $1 = file
next_post() {
	list_post | tac | list_next "$1"
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
	list_post | tac | list_prev "$1"
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
		summary "$(body <"$1" | head -n 5 | markdown)" \
		tags "$(get_tag "$1" | list_to_map)" \
		prev.url "$(prev_post_url "$1")" \
		prev.title "$(prev_post_title "$1")" \
		next.url "$(next_post_url "$1")" \
		next.title "$(next_post_title "$1")" \
		content "$(body <"$1" | markdown)"
}

page_binding() {
	: | map_set \
		title "$(header title < "$1")" \
		url "$(md_to_url "$1")" \
		meta "$(header meta < "$1")" \
		content "$(body <"$1" | markdown)"
}

post_has_tag() {
	get_tag "$2" | grep -q "$1"
}

tag_binding() {
	list_post | list_filter post_has_tag "$1" | tac | list_to_map_callback post_binding
}

post_collection_binding() {
	list_post | tac | list_to_map_callback post_binding
}

page_collection_binding() {
	list_page | tac | list_to_map_callback page_binding
}

bake_index() {
	local bake_index=false
	need_bake "$POST_DIR" && bake_index=true
	need_bake "$PAGE_DIR" && bake_index=true
	$bake_index || return

	local post_collection="$(post_collection_binding)"
	(
	echo index
	local page_collection="$(page_collection_binding)"
	local tag_list="$(list_tag | list_to_map)"
	safe_template "$(map_set posts "$post_collection" pages "$page_collection" tags "$tag_list" <<<"$1")" \
		"$LAYOUT_DIR/index.html" "$OUTPUT_DIR/index.html"
	) &
	(
	echo rss
	safe_template "$(map_set posts "$post_collection" <<<"$1")" \
		"$LAYOUT_DIR/rss.html" "$OUTPUT_DIR/rss.xml"
	) &

	wait
}

bake() {
	baker_prepare
	local binding="$(< "$BINDING")"
	is_map <<<"$binding" || error "invalid format: $BINDING"

	headline building index
	timer bake_index "$binding"

	headline building posts
	timer bake_posts "$binding"

	headline building pages
	timer bake_pages "$binding"

	headline building tags
	timer bake_tags "$binding"

	baker_finish
}
