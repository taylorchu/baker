_h() {
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^(#{1,6})(.+)$ ]]; then
			echo "<h${#BASH_REMATCH[1]}>${BASH_REMATCH[2]}</h${#BASH_REMATCH[1]}>"
		else
			echo "$line"
		fi
	done
}

_hr() {
	sed 's|^-\{3,\}$|<hr/>|g'
}

_code() {
	sed 's|`\([^`]\+\)`|<code>\1</code>|g'
}

_img() {
	sed 's|!\[\([^]]\+\)\](\([^)]\+\))|<img src="\2" alt="\1"/>|g'
}

_a() {
	sed 's|\[\([^]]\+\)\](\([^)]\+\))|<a href="\2">\1</a>|g'
}

_em() {
	sed -e 's|\*\([^*]\+\)\*|<em>\1</em>|g' -e 's|_\([^_]\+\)_|<em>\1</em>|g'
}

_strong() {
	sed -e 's|\*\*\([^*]\+\)\*\*|<strong>\1</strong>|g' -e 's|__\([^_]\+\)__|<strong>\1</strong>|g'
}

_wrap() {
	local in_tag=false
	local line
	while IFS= read -r line; do
		if [[ "$line" ]]; then
			if $in_tag; then
				echo "<br/>"
				echo -n "$line"
			else
				echo -n "<p>$line"
			 	in_tag=true
			fi
		else
			if $in_tag; then
				echo "</p>"
				in_tag=false
			fi
			echo
		fi
	done
	$in_tag && echo "</p>"
}

_p() {
	local in="$(cat)"
	local rep="$in"
	local plain=0
	local plaintext
	local in_other_tag=0
	local offset
	local tag
	while IFS=: read -r offset tag; do
		if [[ "$tag" == "<hr/>" ]]; then
			continue
		elif [[ "$tag" =~ ^\</ ]]; then
			# end
			((in_other_tag--))

			(( in_other_tag == 0 )) && plain=$((offset + ${#tag}))
		else
			# start
			if (( in_other_tag == 0 )); then
				plaintext="$(trim <<< "${in:plain:((offset - plain))}")"
				[[ "$plaintext" ]] && rep="${rep//"$plaintext"/$(_wrap <<<"$plaintext")}"
			fi
			
			((in_other_tag++))
		fi
	done < <(regex_offset \
		'</\?ol>'\
		'</\?ul>'\
		'</\?pre>' \
		'</\?blockquote>' \
		'</\?h[1-6]>' \
		'<hr/>' \
		<<< "$in"
		)
	plaintext="$(trim <<< "${in:plain}")"
	[[ "$plaintext" ]] && rep="${rep//"$plaintext"/$(_wrap <<<"$plaintext")}"
	echo "$rep"
}

_blockquote() {
	local in_tag=false
	local tag_buf=""
	local newline=$'\n'
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^\&gt\;\ (.*) ]]; then
			if ! $in_tag; then
			 	echo -n "<blockquote>"
			 	in_tag=true
			fi
			tag_buf+="${BASH_REMATCH[1]}$newline"
		else
			if $in_tag; then
				_markdown <<< "$tag_buf"
				echo "</blockquote>"
				in_tag=false
				tag_buf=""
			fi
			echo "$line"
		fi
	done
	$in_tag && _markdown <<< "$tag_buf" && echo "</blockquote>"
}

_pre() {
	local in_tag=false
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^(\ {4}|\	)(.*) ]]; then
			if ! $in_tag; then
			 	echo -n "<pre><code>"
			 	in_tag=true
			fi
			echo "${BASH_REMATCH[2]}"
		else
			if $in_tag; then
				echo "</code></pre>"
				in_tag=false
			fi
			echo "$line"
		fi
	done
	$in_tag && echo "</code></pre>"
}

_ol() {
	local in_tag=false
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^[0-9]+\.\ (.*)$ ]]; then
			if ! $in_tag; then
			 	echo "<ol>"
			 	in_tag=true
			fi
			echo "<li>${BASH_REMATCH[1]}</li>"
		else
			if $in_tag; then
				echo "</ol>"
				in_tag=false
			fi
			echo "$line"
		fi
	done
	$in_tag && echo "</ol>"
}

_ul() {
	local in_tag=false
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^[-+*]\ (.*)$ ]]; then
			if ! $in_tag; then
			 	echo "<ul>"
			 	in_tag=true
			fi
			echo "<li>${BASH_REMATCH[1]}</li>"
		else
			if $in_tag; then
				echo "</ul>"
				in_tag=false
			fi
			echo "$line"
		fi
	done
	$in_tag && echo "</ul>"
}

_audio() {
	sed "s|!\[audio\](\([^)]\+\))|<div id=\"\1\"></div><script>jwplayer(\"\1\").setup({file: \"$CONTENT_DIR/\1.mp3\", height: 30});</script>|g"
}

_video() {
	sed \
	-e 's|!\[video\](\([a-zA-Z0-9-]\{11\}\))|<div id="\1"></div><script>jwplayer("\1").setup({file: "http://www.youtube.com/watch?v=\1", image: "http://img.youtube.com/vi/\1/hqdefault.jpg"});</script>|g' \
	-e "s|!\[video\](\([^)]\+\))|<div id=\"\1\"></div><script>jwplayer(\"\1\").setup({file: \"$CONTENT_DIR/\1.mp4\", image: \"$CONTENT_DIR/\1.jpg\"});</script>|g"
}

_iframe() {
	sed 's|!\[iframe\](\([^)]\+\))(\([^)]\+\))(\([^)]\+\))|<iframe style="width: \1; height: \2; border-width: 0; overflow: hidden" src="\3"></iframe>|g'
}

_markdown() {
	_ul | _ol | _blockquote | _pre | _strong | _em | _iframe | _audio | _video | _img | _a | _code | _hr | _h | _p
}

markdown() {
	html_escape | _markdown
}