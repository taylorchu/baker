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
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^-{3,}$ ]]; then
			echo "<hr/>"
		else
			echo "$line"
		fi
	done
}

_code() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^\`(.+)\`$ ]]; then
			local value="<code>${BASH_REMATCH[1]}</code>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o '`[^`]\+`' <<< "$in")
	echo "$rep"
}

_img() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^\!\[(.+)\]\((.+)\)$ ]]; then
			local value="<img src=\"${BASH_REMATCH[2]}\" alt=\"${BASH_REMATCH[1]}\"/>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o '!\[[^]]\+\]([^)]\+)' <<< "$in")
	echo "$rep"
}

_a() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^\[(.+)\]\((.+)\)$ ]]; then
			local value="<a href=\"${BASH_REMATCH[2]}\">${BASH_REMATCH[1]}</a>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o '\[[^]]\+\]([^)]\+)' <<< "$in")
	echo "$rep"
}

_em() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^[*_](.+)[*_]$ ]]; then
			local value="<em>${BASH_REMATCH[1]}</em>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o -e '\*[^*]\+\*' -e '_[^_]\+_' <<< "$in")
	echo "$rep"
}

_strong() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^[*_]{2}(.+)[*_]{2}$ ]]; then
			local value="<strong>${BASH_REMATCH[1]}</strong>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o -e '\*\*[^*]\+\*\*' -e '__[^_]\+__' <<< "$in")
	echo "$rep"
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

			(( in_other_tag == 0 )) && plain=$(( $offset + ${#tag}))
		else
			# start
			if (( in_other_tag == 0 )); then
				plaintext="$(trim <<< "${in:$plain:$(($offset - $plain))}")"
				[[ "$plaintext" ]] && rep="${rep//"$plaintext"/$(_wrap <<<"$plaintext")}"
			fi
			
			((in_other_tag++))
		fi
	done < <(grep -b -o \
			-e '</\?ol>'\
			-e '</\?ul>'\
			-e '</\?pre>' \
			-e '</\?blockquote>' \
			-e '</\?h[1-6]>' \
			-e '<hr/>' \
			<<< "$in"
		)
	plaintext="$(trim <<< "${in:$plain}")"
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
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^\!\[audio\]\((.+)\)$ ]]; then
			local file="$CONTENT_DIR/${BASH_REMATCH[1]}.mp3"
			if [[ -f "$file" ]]; then
				local value="<div id=\"${BASH_REMATCH[1]}\"></div><script>jwplayer(\"${BASH_REMATCH[1]}\").setup({file: \"$file\", width: 480, height: 30});</script>"
				rep="${rep//"$line"/$value}"
			else
				rep="${rep//"$line"/}"
			fi
		fi
	done < <(grep -o '!\[audio\]([^)]\+)' <<< "$in")
	echo "$rep"
}

_video() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS= read -r line; do
		if [[ "$line" =~ ^\!\[video\]\((.+)\)$ ]]; then
			local file="$CONTENT_DIR/${BASH_REMATCH[1]}.mp4"
			local preview="$CONTENT_DIR/${BASH_REMATCH[1]}.jpg"
			if [[ -f "$file" ]]; then
				local value="<div id=\"${BASH_REMATCH[1]}\"></div><script>jwplayer(\"${BASH_REMATCH[1]}\").setup({file: \"$file\", image: \"$preview\"});</script>"
				rep="${rep//"$line"/$value}"
			else
				rep="${rep//"$line"/}"
			fi
		fi
	done < <(grep -o '!\[video\]([^)]\+)' <<< "$in")
	echo "$rep"
}

_markdown() {
	_ul | _ol | _blockquote | _pre | _strong | _em | _audio | _video | _img | _a | _code | _hr | _h | _p
}

markdown() {
	html_escape | _markdown
}