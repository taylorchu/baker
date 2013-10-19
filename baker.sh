#!/bin/bash
source config.sh

# include
while IFS= read -r sh; do
    source "$sh"
done < <(find "$LIBRARY_DIR" "$SNIPPET_DIR" -name "*.sh")

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
title: ${*:2}
date: $(date +"%Y-%m-%d %H:%M")
tags:
layout: post
draft: true
---

EOF
        [[ "$EDITOR" ]] && $EDITOR "$POST_DIR/$title.md"
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
title: ${*:2}
date: $(date +"%Y-%m-%d %H:%M")
meta: 
layout: page
draft: true
---

EOF
        [[ "$EDITOR" ]] && $EDITOR "$PAGE_DIR/$title.md"
        ;;
    video)
        headline video
        if ! type ffmpeg &>/dev/null; then
            echo "ffmpeg not found"
            exit 1
        fi
        if [[ "$2" =~ ^(.*/)?([^/]+)\.[^.]+$ ]]; then
            filename="$(slug "${BASH_REMATCH[2]}")"
            ffmpeg -i "$2" -vcodec h264 -acodec aac -strict -2 "$CONTENT_DIR/$filename.mp4" -loglevel warning && \
            ffmpeg -ss 00:00:01 -i "$CONTENT_DIR/$filename.mp4" -vframes 1 "$CONTENT_DIR/$filename.jpg" -loglevel warning && \
            echo '!'"[video]($filename)"
        fi
        ;;
    audio)
        headline audio
        if ! type ffmpeg &>/dev/null; then
            echo "ffmpeg not found"
            exit 1
        fi
        if [[ "$2" =~ ^(.*/)?([^/]+)\.[^.]+$ ]]; then
            filename="$(slug "${BASH_REMATCH[2]}")"
            ffmpeg -i "$2" -acodec mp3 "$CONTENT_DIR/$filename.mp3" -loglevel warning && \
            echo '!'"[audio]($filename)"
        fi
        ;;
    *)
        cat <<EOF
baker
    post [title]        create new post
    page [title]        create new post
    bake [--force]      ship static page
    video [file]        create video markdown
    audio [file]        create audio markdown
EOF
        ;;
esac
