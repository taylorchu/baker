# $1 = key
header() {
	awk '/^---$/ {count++; next} count == 0' | grep "^$1: " | cut -d ' ' -f 2-
}

# $1 = file
body() {
	awk '/^---$/ {count++; next} count > 0'
}


# if: {% if var %} ... {% endif %} 
# foreach: {% foreach var %} ... {% endforeach %}
# include: {% include name%}
# escape_var: {{ name }}
# var: {{{ name }}}
## snippet: {% snippet name %}

# only top level
list_control() {
	local in="$(newline_escape)"
	local plain=0
	stack_new
	local this_offset
	local this_tag
	while IFS=: read -r this_offset this_tag; do
		if [[ "$this_tag" =~ ^\{%\ ([a-z]+)\ ?(.+)?\ %\}$ ]]; then
			case "${BASH_REMATCH[1]}" in
				foreach|if)
					(( $(stack_len) == 0 )) && echo "plain::${in:plain:$((this_offset-plain))}"
					stack_push "$this_offset:${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
					;;
				endif|endforeach)
					local offset
					local tag
					local var
					IFS=: read -r offset tag var <<<"$(stack_peek)"
					local end="${BASH_REMATCH[1]}"
					local start="${end:3}"
					[[ "$tag" == "$start" ]] && stack_pop || debug "not expected tag: $tag"
					
					# 7 = 3 for start/end + 1 space
					# 6 = without 1 space
					(( $(stack_len) == 0 )) && echo "$start:$var:${in:$(($offset+7+${#start}+${#var})):$(($this_offset-$offset-7-${#start}-${#var}))}"
					plain=$((this_offset + 6 + ${#end}))
					;;
			esac
		fi
	done < <(grep -b -o \
		-e '{% foreach [a-z0-9.]\+ %}' \
		-e '{% endforeach %}' \
		-e '{% if \(! \)\?[a-z0-9.]\+ %}' \
		-e '{% endif %}' \
		<<<"$in")
	(( $(stack_len) == 0 )) && echo "plain::${in:$plain}"
}

_if() {
	local var
	local section
	IFS=: read -r var section
	if [[ "$var" =~ (\\!)?\ ?(.+) ]]; then
		#echo ${BASH_REMATCH[@]}
		local value="$(map_get "${BASH_REMATCH[2]}" <<<"$1")"
		[[ ! "$value" ]] && return
		[[ "${BASH_REMATCH[1]}" == "\!" && "$value" != "false" ]] && return
		[[ "${BASH_REMATCH[1]}" == "" && "$value" == "false" ]] && return
		_all "$1" <<<"$section"
	fi
}

_foreach() {
	local var
	local section
	IFS=: read -r var section
	local map="$(map_get "$var" <<<"$1")"
	is_map <<<"$map" || return
	local key
	while IFS= read -r key; do
		local sub_map=$(map_get "$key" <<<"$map")
		local binding="$1"
		local binding_key
		while IFS= read -r binding_key; do
			binding="$(map_set "$binding_key" "$(map_get "$binding_key" <<<"$sub_map")" \
				<<<"$binding")"
		done < <(map_keys <<<"$sub_map")
		_all "$binding" <<<"$section"
	done < <(map_keys <<<"$map")
}

_include() {
	local in="$(cat)"
	local rep="$in"
	local name
	while IFS= read -r name; do
		if [[ "$name" =~ ^\{%\ include\ (.+)\ %\}$ ]]; then
			local value="$(template "$1" < "$INCLUDE_DIR/${BASH_REMATCH[1]}.html")" 
			rep="${rep//"$name"/$value}"
		fi
	done < <(grep -o '{% include [a-z0-9\.]\+ %}' <<<"$in")
	echo "$rep"
}

_escape_var() {
	local in="$(cat)"
	local rep="$in"
	local name
	while IFS= read -r name; do
		if [[ "$name" =~ ^\{\{\ (.+)\ \}\}$ ]]; then
			local value="$(map_get "${BASH_REMATCH[1]}" <<<"$1" | html_escape)"
			[[ "$value" ]] && rep="${rep//"$name"/$value}"
		fi
	done < <(grep -o '{{ [a-z0-9\.]\+ }}' <<<"$in")
	echo "$rep"
}

_var() {
	local in="$(cat)"
	local rep="$in"
	local name
	while IFS= read -r name; do
		if [[ "$name" =~ ^\{\{\{\ (.+)\ \}\}\}$ ]]; then
			local value="$(map_get "${BASH_REMATCH[1]}" <<<"$1")"
			[[ "$value" ]] && rep="${rep//"$name"/$value}"
		fi
	done < <(grep -o '{{{ [a-z0-9\.]\+ }}}' <<<"$in")
	echo "$rep"
}

_all() {
	local rep=""
	local tag
	local var
	local section
	while IFS=: read -r tag var section; do
		case "$tag" in
			if)
				rep+="$(_if "$1" <<<"$var:$section")"
				;;
			foreach)
				rep+="$(_foreach "$1" <<<"$var:$section")"
				;;
			plain)
				rep+="$section"
				;;
		esac
	done < <(list_control)
	_var "$1" <<<"$rep" | _escape_var "$1" | _include "$1" | _snippet "$1" | newline_unescape
}

_snippet() {
	local in="$(cat)"
	local rep="$in"
	local name
	while IFS= read -r name; do
		if [[ "$name" =~ ^\{%\ snippet\ (.+)\ %\}$ ]]; then
			local value="$(${BASH_REMATCH[1]})"
			rep="${rep//"$name"/$value}"
		fi
	done < <(grep -o '{% snippet [a-z0-9\.]\+ %}' <<<"$in")
	echo "$rep"
}

template() {
	local in="$(cat)"
	local map="$1"
	while true; do
		map="$(map_set ... "$(body <<<"$in" | _all "$map")" <<<"$map")"
		local layout="$(header layout <<<"$in")"
		[[ "$layout" ]] || break
		[[ -f "$LAYOUT_DIR/$layout.html" ]] || debug "layout not found: $layout"
		in="$(< "$LAYOUT_DIR/$layout.html")"
	done
	map_get ... <<<"$map"
}