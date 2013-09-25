#!/bin/bash
source config.sh

# include
while IFS=$'\n' read -r sh; do
    source "$sh"
done < <(find "$LIBRARY_DIR" "$SNIPPET_DIR" -name "*.sh")

# check required
require jshon

case "$1" in
    bake)
        case "$2" in
            --force)
                rm -rf "$OUTPUT_DIR"/*
                rm -f .baker/status
                ;;
            "")
                # just bake it
                ;;
            *)
                echo "bad cook: $2"
                exit 1
                ;;
        esac 
        bake
        ;;
    post)
        if [[ ! "${*:2}" ]]; then
            echo "we need a title"
            exit 1
        fi
        headline post
        title="$(date +%Y-%m-%d)-$(slug ${*:2})"
        echo "$POST_DIR/$title.md"
        cat > "$POST_DIR/$title.md" <<EOF
layout: post
title: ${*:2}
date: $(date +"%Y-%m-%d %H:%M")
categories:
---

EOF
        ;;
    page)
        if [[ ! "${*:2}" ]]; then
            echo "we need a title"
            exit 1
        fi
        headline page
        title="$(slug ${*:2})"
        if [[ -f "$PAGE_DIR/$title.md" ]]; then
            echo "title exits: ${*:2}"
            exit 1
        fi
        echo "$PAGE_DIR/$title.md"
        cat > "$PAGE_DIR/$title.md" <<EOF
layout: page
title: ${*:2}
meta: 
date: $(date +"%Y-%m-%d %H:%M")
---

EOF
        ;;
    *)
        cat <<EOF
baker
    post [title]        create new post
    page [title]        create new post
    bake [--force]      ship static page
EOF
        ;;
esac
