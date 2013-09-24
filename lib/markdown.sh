_h() {
	local line
	while IFS=$'\n' read -r line; do
		if [[ "$line" =~ ^(#{1,6})(.*)$ ]]; then
			echo "<h${#BASH_REMATCH[1]}>${BASH_REMATCH[2]}</h${#BASH_REMATCH[1]}>"
		else
			echo "$line"
		fi
	done
}

_hr() {
	local line
	while IFS=$'\n' read -r line; do
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
	while IFS=$'\n' read -r line; do
		if [[ "$line" =~ ^\`(.*)\`$ ]]; then
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
	while IFS=$'\n' read -r line; do
		if [[ "$line" =~ ^\!\[(.*)\]\((.*)\)$ ]]; then
			local value="<img src=\"${BASH_REMATCH[2]}\" alt=\"${BASH_REMATCH[1]}\"/>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o '!\[[^[]\+\]([^)]\+)' <<< "$in")
	echo "$rep"
}

_a() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS=$'\n' read -r line; do
		if [[ "$line" =~ ^\[(.*)\]\((.*)\)$ ]]; then
			local value="<a href=\"${BASH_REMATCH[2]}\">${BASH_REMATCH[1]}</a>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o '\[[^[]\+\]([^)]\+)' <<< "$in")
	echo "$rep"
}

_em() {
	local in="$(cat)"
	local rep="$in"
	local line
	while IFS=$'\n' read -r line; do
		if [[ "$line" =~ ^[*_](.*)[*_]$ ]]; then
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
	while IFS=$'\n' read -r line; do
		if [[ "$line" =~ ^[*_]{2}(.*)[*_]{2}$ ]]; then
			local value="<strong>${BASH_REMATCH[1]}</strong>"
			rep="${rep//"$line"/$value}"
		fi
	done < <(grep -o -e '\*\*[^*]\+\*\*' -e '__[^_]\+__' <<< "$in")
	echo "$rep"
}

_p() {
	local in_tag=false
	local tag_buf
	local no_tag_buf
	local newline=$'\n'
	local line
	while IFS=$'\n' read -r line; do
		if ! $in_tag; then
			no_tag_buf=""
			tag_buf="<p>"
			in_tag=true
		fi
		if [[ "$line" ]]; then
			if [[ "$line" =~ \< ]]; then
				echo -n "$no_tag_buf"
				echo "$line"
				in_tag=false
			else
				tag_buf+="$line<br/>"
				no_tag_buf+="$line$newline"
			fi
		else
			[[ "$tag_buf" != "<p>" ]] && echo "$tag_buf</p>"
			in_tag=false
		fi
	done
	$in_tag && [[ "$tag_buf" != "<p>" ]]  && echo "$tag_buf</p>"
}

_pre() {
	local in_tag=false
	local line
	while IFS=$'\n' read -r line; do
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
	while IFS=$'\n' read -r line; do
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
	while IFS=$'\n' read -r line; do
		if [[ "$line" =~ ^[-+]\ (.*)$ ]]; then
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

markdown() {
	html_escape | _ul | _ol | _pre | _strong | _em | _img | _a | _code | _hr | _h | _p
}