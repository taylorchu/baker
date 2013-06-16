#!/bin/bash

# get meta from file heading
# $1: file
# $2: key
header() {
    grep -m 1 -o "^$2: .\+" "$1" | cut -f 2- -d " "
}

clean() {
    local str="$(cat -)"
    echo "'${str#*\'}"
}

# get content of the file
# $1: file
body() {
    grep -q "^---$" "$1" && sed "1,/^---$/d" "$1" || cat "$1"
}

# $1: file name
title="$(header "$1" title)"
date="$(header "$1" date)"
content="$(body "$1" | ./Markdown.pl)"
declare -A vars=([title]="$title" [date]="$date" [content]="$content")
declare -p vars | clean
