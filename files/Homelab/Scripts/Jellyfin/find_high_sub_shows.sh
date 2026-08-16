#!/bin/bash

# Path to the directory containing show files.
movies_path="/mnt/shared_storage/Shows"

# The minimum number of subtitle tracks to be considered "excessive".
min_subtitle_tracks=27

# Check if mkvmerge is installed.
if ! command -v mkvmerge &> /dev/null
then
    echo "mkvmerge could not be found. Please install mkvtoolnix."
    exit 1
fi

echo "Scanning for shows with more than $min_subtitle_tracks subtitle tracks in '$movies_path'..."
echo "----------------------------------------------------------------------"

# Find all show files (MKV, MP4, M4V) and process each one.
find "$movies_path" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m4v" \) -print0 | while IFS= read -r -d $'\0' file; do
    # Use mkvmerge -i to get a concise list of tracks.
    # The 'grep' command counts the lines that contain "Track ID" and "subtitles".
    subtitle_count=$(mkvmerge -i "$file" 2>/dev/null | grep -c "Track ID.*: subtitles")

    # Compare the subtitle count with the minimum threshold.
    if (( subtitle_count > min_subtitle_tracks )); then
        # Print the filename and the number of subtitle tracks found.
        echo "File: $file"
        echo "Subtitle tracks: $subtitle_count"
        echo "----------------------------------------------------------------------"
    fi
done

echo "Scan complete."
