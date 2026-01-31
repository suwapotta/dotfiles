#!/bin/bash

WATCH_DIR="/.snapshots"
ICON="btrfs-assistant"

if [ ! -r "$WATCH_DIR" ]; then
  notify-send -u critical "Snapper Notify Error" "Cannot read $WATCH_DIR."
  exit 1
fi

inotifywait -m -e create --format '%f' "$WATCH_DIR" | while read -r SNAP_ID; do

  if [[ "$SNAP_ID" =~ ^[0-9]+$ ]]; then

    sleep 1

    INFO_FILE="$WATCH_DIR/$SNAP_ID/info.xml"
    if [ -f "$INFO_FILE" ]; then
      DESC=$(grep -oP '(?<=<description>).*?(?=</description>)' "$INFO_FILE")
      TYPE=$(grep -oP '(?<=<type>).*?(?=</type>)' "$INFO_FILE")
    else
      DESC="Manual/Unknown Snapshot"
      TYPE="single"
    fi

    notify-send -a "Snapper" \
      -i "$ICON" \
      "New Snapshot: #$SNAP_ID ($TYPE)" \
      "$DESC"
  fi
done
