#!/bin/sh

echo "Moving Completed Download Files..."
if [ "$2" -ne 0 ]; then

    # Skip torrent file
    case "$3" in
        *.torrent)
            echo "Not moving .torrent File..."
            exit
            ;;
    esac

    # Find Download TopLevel Dir
    TOP_LEVEL_DIR="$3"
    while [ "$(dirname "$TOP_LEVEL_DIR")" != "$ARIA2_DOWNLOAD_DIR" ]; do
        if [ "$TOP_LEVEL_DIR" = "/" ] || [ "$TOP_LEVEL_DIR" = "." ]; then
            echo "File $3 is not in $ARIA2_DOWNLOAD_DIR download directory."
            exit
        fi
        TOP_LEVEL_DIR="$(dirname "$TOP_LEVEL_DIR")"
    done


    if [ ! -h "$TOP_LEVEL_DIR" ]; then
        echo "Creating Link..."
        mv "$TOP_LEVEL_DIR" "${ARIA2_DOWNLOAD_DIR}/.." && \
        ln -s "../$(basename "$TOP_LEVEL_DIR")" "$(dirname "$TOP_LEVEL_DIR")"
    fi
fi
