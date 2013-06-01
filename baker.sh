#!/bin/bash

source config.sh
source library.sh

case "$1" in
    bake)
        rm -rf $OUTPUT_DIR/{$STYLESHEET_DIR,$IMAGE_DIR,*.html}
        cp -r "$THEME_DIR/$STYLESHEET_DIR" "$OUTPUT_DIR"; cp -r "$THEME_DIR/$IMAGE_DIR" "$OUTPUT_DIR"
        declare -A indexVars=([SITE_NAME]="$SITE_NAME" [AUTHOR]="$AUTHOR" [title]="home")
        i=0
        for src in $(ls "$POST_DIR" | grep "\.md$" | sort -r); do
            dest="$(basename $src $POST_EXT)$OUTPUT_EXT"
            title "$POST_DIR/$src -> $OUTPUT_DIR/$dest"
            layout="$(header "$POST_DIR/$src" layout)"
            title="$(header "$POST_DIR/$src" title)"
            date="$(header "$POST_DIR/$src" date)"
            content="$(body "$POST_DIR/$src" | ./Markdown.pl)"
            declare -A vars=([SITE_NAME]="$SITE_NAME" [AUTHOR]="$AUTHOR" [title]="$title" [date]="$date" [content]="$content" [link]="$dest")
            indexVars[post.${i}]="$(declare -p vars)"
            doLayout "$layout" "$(declare -p vars)" | sed '/^[ ]*$/d' > "$OUTPUT_DIR/$dest"
            (( i++ ))
        done
        title "creating index"
        doLayout "index" "$(declare -p indexVars)" | sed '/^[ ]*$/d' > "$OUTPUT_DIR/index$OUTPUT_EXT"
    ;;
    new)
        if [[ -z "${*:2}" ]]; then
            echo "we need a title"
            exit 1
        fi

        title="$(date +%Y-%m-%d)-$(slug ${*:2})"
        title "$title is ready in '$POST_DIR'"
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
