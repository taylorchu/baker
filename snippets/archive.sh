#!/bin/bash

getMonth() {
	listPosts | cut -d / -f 2- | cut -c 1-7 | sort -ru
}

archive() {
	echo "<ul>"
	for month in $(getMonth); do
		echo "<li>$month</li>"
	done
	echo "</ul>"
}