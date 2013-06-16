#!/bin/bash

getMonth() {
	listPosts | cut -d / -f 2- | cut -c 1-7 | sort -ru
}

archive() {
	echo '<div style="white-space: pre; font-family: monospace;">'
	cal
	echo '</div>'
}