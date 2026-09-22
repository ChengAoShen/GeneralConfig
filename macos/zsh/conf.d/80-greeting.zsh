# Laptop only. The server gets a bare prompt -- a banner on every
# `ssh host cmd` is noise, and it draws an image the remote
# terminal may not speak.

[[ $TERM != dumb ]] && (( $+commands[fastfetch] )) && fastfetch
