#!/bin/bash

# Cada función es ahora responsable de obtener su propia información,
# haciendo el script más robusto.

title() {
	local TITLE=$(playerctl metadata title 2>/dev/null)
	if [[ -z "$TITLE" ]]; then
		echo "Nothing Playing"
	else
		echo "$TITLE"
	fi
}

artist() {
	local ARTIST=$(playerctl metadata artist 2>/dev/null)
	local TITLE=$(playerctl metadata title 2>/dev/null)

	if [[ "$TITLE" = "Advertisement" ]]; then
		echo "Spotify Free"
	else
		[[ -z "$ARTIST" ]] && echo "" || echo "by $ARTIST"
	fi
}

player_status() {
	local STATUS=$(playerctl status 2>/dev/null)
	if [[ "$STATUS" = "Playing" ]]; then
		echo "󰏤"
	elif [[ "$STATUS" = "Paused" ]]; then
		echo "󰐊"
	else
		echo "󰐊"
	fi
}

player_status_text() {
	local STATUS=$(playerctl -p $PLAYERS status 2>/dev/null)
	local PLAYER_NAME=$(playerctl -p $PLAYERS -l 2>/dev/null | head -n 1)
	local PLAYER_NAME_SPLIT=($(echo $PLAYER_NAME | tr "." "\n"))
	PLAYER_NAME_SPLIT=${PLAYER_NAME_SPLIT[0]}

	[[ "$STATUS" = "Playing" ]] && echo "Now Playing - via ${PLAYER_NAME_SPLIT^}" || echo "Music"
}

position() {
	local POSITION=$(playerctl -p $PLAYERS position 2>/dev/null | sed 's/..\{6\}$//')
	local DURATION=$(playerctl -p $PLAYERS metadata mpris:length 2>/dev/null | sed 's/.\{6\}$//')
	
	if [[ $POSITION -gt 0 ]]; then
		printf "%0d:%02d" $((POSITION % 3600 / 60)) $((POSITION % 60))
		printf " / "
		printf "%0d:%02d" $((DURATION % 3600 / 60)) $((DURATION % 60))
	else
		echo ""
	fi
}

case $1 in
	"artist") artist;;
	"title") title;;
	"player_status") player_status;;
	"player_status_text") player_status_text;;
	"position") position;;
esac
