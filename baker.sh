#!/bin/bash

source config.sh
source library.sh
source posts.sh
source layout.sh

case "$1" in
    bake)
        rm -rf $OUTPUT_DIR/{$STYLESHEET_DIR,$IMAGE_DIR,*.html}
        cp -r "$THEME_DIR/$STYLESHEET_DIR" "$OUTPUT_DIR"; cp -r "$THEME_DIR/$IMAGE_DIR" "$OUTPUT_DIR"
        declare -A base=([SITE_NAME]="$SITE_NAME" [AUTHOR]="$AUTHOR" [title]="home")
        declare -A indexVars
        i=0
        IFS=$'\n'
        for src in "$(ls "$POST_DIR" | grep "\.md$" | sort -r)"; do
            dest="$(basename $src $POST_EXT)$OUTPUT_EXT"
            headline "$POST_DIR/$src -> $OUTPUT_DIR/$dest"
            pageVars="$(toString "$(declare -p base)" "([link]=$dest)" "$(getPost "$POST_DIR/$src")")"
            indexVars[post.${i}]="$pageVars"
            doLayout "$(header "$POST_DIR/$src" layout)" "$pageVars" > "$OUTPUT_DIR/$dest"
            (( i++ ))
        done
        headline "creating index"
        doLayout "index" "$(toString "$(declare -p base)" "$(declare -p indexVars)")" > "$OUTPUT_DIR/index$OUTPUT_EXT"
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
