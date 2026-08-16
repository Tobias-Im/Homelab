#!/bin/bash

# Directory where the movies are located
MOVIE_DIR="/mnt/shared_storage/Movies"

# Change to the movie directory
cd "$MOVIE_DIR" || { echo "Error: Cannot change to $MOVIE_DIR"; exit 1; }

echo "Starting movie organization in $MOVIE_DIR..."

# Find all standalone .mkv files in the current directory (non-recursive)
# We exclude files that are already inside a directory.
find . -maxdepth 1 -type f -name "*.mkv" -print0 | while IFS= read -r -d $'\0' MOVIE_FILE_WITH_PATH; do
    # Remove the leading './'
    MOVIE_FILE="${MOVIE_FILE_WITH_PATH#./}"

    # Extract the base name without the extension (.mkv)
    # E.g., 'Argylle.2024.2160p.WEB-DL.DDP5.1.Atmos.DV.HDR.H.265-FLUX'
    BASE_NAME="${MOVIE_FILE%.mkv}"

    # The name of the new directory to create
    NEW_DIR="$BASE_NAME"

    # Check if a directory with the exact name already exists (highly unlikely but good practice)
    if [ -d "$NEW_DIR" ]; then
        echo "Skipping: Directory '$NEW_DIR' already exists."
        continue
    fi

    # Subtitle file search pattern: basename.*.srt
    # We look for all files that start with the base name and end with .srt (e.g., BASE_NAME.rum.srt)
    SUBTITLE_PATTERN="${BASE_NAME}*.srt"

    # Create the new directory
    if mkdir -p -- "$NEW_DIR"; then
        echo "Created directory: $NEW_DIR"

        # 1. Move the movie file
        if mv -- "$MOVIE_FILE" "$NEW_DIR/"; then
            echo "  - Moved movie: $MOVIE_FILE"
        else
            echo "  - ERROR moving movie: $MOVIE_FILE"
        fi

        # 2. Move any matching subtitle files
        # The 'shopt -s nullglob' ensures the loop doesn't run if no files match the pattern.
        shopt -s nullglob
        for SUBTITLE_FILE in $SUBTITLE_PATTERN; do
            if [ -f "$SUBTITLE_FILE" ]; then
                if mv -- "$SUBTITLE_FILE" "$NEW_DIR/"; then
                    echo "  - Moved subtitle: $SUBTITLE_FILE"
                else
                    echo "  - ERROR moving subtitle: $SUBTITLE_FILE"
                fi
            fi
        done
        shopt -u nullglob # Turn off nullglob

    else
        echo "Error: Failed to create directory $NEW_DIR"
    fi

done

echo "Organization complete."
