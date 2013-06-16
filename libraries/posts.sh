#!/bin/bash

# $1: file name
getPost() {
    title="$(header "$1" title)"
    date="$(header "$1" date)"
    content="$(body "$1" | ./Markdown.pl)"
    link="$(basename $1 $POST_EXT)$OUTPUT_EXT"

    declare -A vars=([title]="$title" [date]="$date" [content]="$content" [link]="$link")
    declare -p vars | clean
}
