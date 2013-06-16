#!/bin/bash

source config.sh
source libraries/common.sh
source libraries/posts.sh
source libraries/layout.sh

prepareOutputDir() {
    rm -rf "$OUTPUT_DIR"/*
    cp -r "$THEME_DIR"/{"$STYLESHEET_DIR","$IMAGE_DIR","$JAVASCRIPT_DIR"} "$OUTPUT_DIR" 
}

createEachPost() {
    local base="([SITE_NAME]='$SITE_NAME' [AUTHOR]='$AUTHOR')"
    local src
    for src in $(ls "$POST_DIR" | grep "\.md$"); do
        dest="$(basename $src $POST_EXT)$OUTPUT_EXT"
        headline "$POST_DIR/$src -> $OUTPUT_DIR/$dest"
        doLayout "$(header "$POST_DIR/$src" layout)" "$(toString "$base" "([link]=$dest)" "$(getPost "$POST_DIR/$src")")" > "$OUTPUT_DIR/$dest"
    done
}

createIndex() {
    headline "creating index"
    local base="([SITE_NAME]='$SITE_NAME' [AUTHOR]='$AUTHOR' [title]='home')"
    declare -A indexVars
    local i=0
    local src
    for src in $(ls "$POST_DIR" | grep "\.md$" | sort -r); do
        indexVars[post.${i}]="$(toString "$base" "([link]=$dest)" "$(getPost "$POST_DIR/$src")")"
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
