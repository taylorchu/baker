#!/bin/bash

source config.sh

# include
for ext in $(find "$LIBRARY_DIR" "$SNIPPET_DIR" -name "*.sh"); do
    source "$ext"
done

prepareOutputDir() {
    rm -rf "$OUTPUT_DIR"/*
    cp -r "$THEME_DIR"/{"$STYLESHEET_DIR","$IMAGE_DIR","$JAVASCRIPT_DIR"} "$OUTPUT_DIR" 
}

createEachPost() {
    local base="([SITE_NAME]='$SITE_NAME' [AUTHOR]='$AUTHOR')"
    local src
    for src in $(find "$POST_DIR" -name "*.md"); do
        dest="$(basename $src $POST_EXT)$OUTPUT_EXT"
        headline "$src -> $OUTPUT_DIR/$dest"
        doLayout "$(header "$src" layout)" "$(toString "$base" "([link]=$dest)" "$(getPost "$src")")" > "$OUTPUT_DIR/$dest"
    done
}

createIndex() {
    headline "creating index"
    local base="([SITE_NAME]='$SITE_NAME' [AUTHOR]='$AUTHOR' [title]='home')"
    declare -A indexVars
    local i=0
    local src
    for src in $(find "$POST_DIR" -name "*.md" | sort -r); do
        indexVars[post.${i}]="$(toString "$base" "([link]=$dest)" "$(getPost "$src")")"
        (( i++ ))
    done  
    doLayout "index" "$(toString "$base" "$(declare -p indexVars)")" > "$OUTPUT_DIR/index$OUTPUT_EXT" 
}

case "$1" in
    bake)
        prepareOutputDir
        createEachPost
        createIndex
    ;;
    new)
        if [[ -z "${*:2}" ]]; then
            echo "we need a title"
            exit 1
        fi

        title="$(date +%Y-%m-%d)-$(slug ${*:2})"
        headline "$title is ready in '$POST_DIR'"
        cat > "$POST_DIR/$title$POST_EXT" <<EOF
---
layout: post
title: ${*:2}
date: $(date +"%Y-%m-%d %H:%M")
categories:
---

EOF

    ;;
    *)
        cat <<EOF
baker
    new [new post title]    create new post
    bake                    ship static page
EOF
    ;;
esac
