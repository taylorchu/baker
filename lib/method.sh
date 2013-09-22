# $1 = binding

list_page() {
	find "$PAGE_DIR" -name "*.md" | sort
}

list_post() {
	find "$POST_DIR" -name "*.md" | sort
}

bake_pages() {
	local page
	while IFS=$\n read -r page; do
		need_bake "$page" || continue

		echo "$page"
		template "$(map_set \
			title "$(header title < "$page")" \
			meta "$(header meta < "$page")" \
			content "$(body <"$page" | ./Markdown.pl )" \
			<<< "$1")" \
			< "$LAYOUT_DIR/$(header layout <"$page").html" \
			> "$OUTPUT_DIR/$(md_to_url "$page")"
		update_status "$page"
	done < <(list_page)
}

baker_prepare() {
	[[ -d .baker ]] || mkdir .baker
	[[ -f .baker/status ]] || touch .baker/status
	[[ -d "$OUTPUT_DIR" ]] || mkdir "$OUTPUT_DIR"
	cp -r "$PUBLIC_DIR"/* "$OUTPUT_DIR"
}

# $1 = file
need_bake() {
	grep -q "^$(md5sum "$1")$" .baker/status && return 1 || return 0
}

need_bake_index() {
	local post
	while IFS=$\n read -r post; do
		need_bake "$post" && return 0
	done < <(list_post)
	return 1
}

# $1 = file
update_status() {
	echo "$(grep -v "  $1$" .baker/status)" > .baker/status
	md5sum "$1" >> .baker/status
}

bake_posts() {
	local post
	while IFS=$\n read -r post; do
		need_bake "$post" || continue

		echo "$post"
		template "$(map_set \
			title "$(header title < "$post")" \
			date "$(header date < "$post")" \
			prev.url "$(prev_post_url "$post")" \
			prev.title "$(prev_post_title "$post")" \
			next.url "$(next_post_url "$post")" \
			next.title "$(next_post_title "$post")" \
			content "$(body <"$post" | ./Markdown.pl )" \
			<<< "$1")" \
			< "$LAYOUT_DIR/$(header layout <"$post").html" \
			> "$OUTPUT_DIR/$(md_to_url "$post")"
		update_status "$post"
	done < <(list_post)
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
post_json() {
	map_set \
		title "$(header title < "$1")" \
		url "$(md_to_url "$1")" \
		date "$(header date < "$1")" \
		summary "$(body <"$1" | summary)" \
		<<<"{}"
}

post_collection_json() {
	#posts
	local posts="{}"
	local i=0
	local post
	while IFS=$\n read -r post; do
		posts="$(map_set "$i" "$(post_json "$post")" <<<"$posts")"
		((i++))
	done < <(list_post | tac)
	echo "$posts"
}

page_collection_json() {
	#pages
	local pages="{}"
	local i=0
	local page
	while IFS=$\n read -r page; do
		pages="$(map_set "$i" "$(page_json "$page")" <<<"$pages")"
		((i++))
	done < <(list_page | tac)
	echo "$pages"
}

page_json() {
	map_set \
		title "$(header title < "$1")" \
		url "$(md_to_url "$1")" \
		<<<"{}"
}

bake_index() {
	need_bake_index || return

	echo index	
	template "$(map_set posts "$(post_collection_json)" pages "$(page_collection_json)" <<<"$1")" \
		< "$LAYOUT_DIR/index.html" > "$OUTPUT_DIR/index.html"
}

summary() {
	local in="$(grep -v ^$)"
	local len
	[[ "$1" =~ ^[0-9]+$ ]] && len=$1 || len=200
	echo "${in:0:$len}.."
}

bake() {
	baker_prepare
	local binding="$(< "$BINDING")"
	headline buiding index
	bake_index "$binding" | timer

	headline buiding posts
	bake_posts "$binding" | timer

	headline buiding pages
	bake_pages "$binding" | timer
}
