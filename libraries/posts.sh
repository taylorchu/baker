#!/bin/bash

# $1: file name
getPost() {
    title="$(header "$1" title)"
    date="$(header "$1" date)"
    content="$(body "$1" | ./Markdown.pl)"
    declare -A vars=([title]="$title" [date]="$date" [content]="$content")
    declare -p vars | clean
}
