#!/bin/bash

# Path to the directory containing movie files.
movies_path="/mnt/shared_storage/Media/Shows"

# The minimum number of subtitle tracks to be considered "excessive".
min_subtitle_tracks=27

# Language code for the subtitle track to keep.
language_to_keep="rum"

# Check if mkvmerge is installed.
if ! command -v mkvmerge &> /dev/null; then
    echo "Error: mkvmerge could not be found. Please install mkvtoolnix."
    exit 1
fi

echo "Starting scan and processing of shows with over $min_subtitle_tracks subtitle tracks in '$movies_path'..."
echo "----------------------------------------------------------------------"

# Find all movie files (MKV, MP4, M4V) and process each one.
find "$movies_path" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m4v" \) -print0 | while IFS= read -r -d $'\0' original_file; do
    echo "Checking file: $original_file"

    # Use mkvmerge -i to get a concise list of tracks and count subtitle tracks.
    # We redirect stderr to /dev/null to suppress potential warnings from mkvmerge.
    subtitle_count=$(mkvmerge -i "$original_file" 2>/dev/null | grep -c "Track ID.*: subtitles")

    # Compare the subtitle count with the minimum threshold.
    if (( subtitle_count > min_subtitle_tracks )); then
        echo "   -> File found with $subtitle_count subtitle tracks (over $min_subtitle_tracks)."
        echo "   -> Initiating processing for: $original_file"

        # Define the temporary output file name.
        # We append a unique suffix to ensure it doesn't conflict with the original.
        temp_file="${original_file}.new_remux"

        # Run the mkvmerge command to create a new file.
        # It keeps video (0) and audio (1) tracks, and only the specified subtitle language.
        mkvmerge -o "$temp_file" \
                 --video-tracks 0 \
                 --audio-tracks 1 \
                 --subtitle-tracks "$language_to_keep" \
                 "$original_file"

        # Check if the mkvmerge command was successful.
        if [ $? -eq 0 ]; then
            echo "   -> Remuxing completed successfully for $original_file."
            echo "   -> Deleting original file and renaming the new one."
            
            # Remove the original file.
            rm "$original_file"
            
            # Rename the new file to the original name.
            mv "$temp_file" "$original_file"
            
            echo "   -> Process completed for $original_file. File was updated."
        else
            echo "   -> Remuxing error for $original_file. Original file was NOT deleted."
            echo "   -> You can check the temporary file: $temp_file"
        fi
    else
        echo "   -> File $original_file has $subtitle_count subtitle tracks (under $min_subtitle_tracks). Skipping."
    fi
    echo "----------------------------------------------------------------------"
done

echo "Scan and processing complete."
