_stack=()

# $1 = ele
stack_push() {
	_stack+=($1)
}

stack_pop() {
	(( ${#_stack[@]} > 0 )) && unset _stack[${#_stack[@]}-1]
}

stack_peek() {
	(( ${#_stack[@]} > 0 )) && echo "${_stack[${#_stack[@]}-1]}"
}

stack_len() {
	echo "${#_stack[@]}"
}

stack_new() {
	_stack=()
}