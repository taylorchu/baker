html_escape() {
    local in="$(cat)"
    in="${in//&/&amp;}"
    in="${in//</&lt;}"
    in="${in//>/&gt;}"
    in="${in//\'/&apos;}"
    in="${in//\"/&quot;}"
    echo "$in"
}