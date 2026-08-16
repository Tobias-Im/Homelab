#!/bin/bash

# Define the paths for the input and temporary output files.
original_file="/mnt/shared_storage/Movies/Carry-On.2024.1080p.NF.WEB-DL.DDP5.1.Atmos.H.264-playWEB.mkv"
temp_file="/mnt/shared_storage/Movies/Carry-On.2024.1080p.NF.WEB-DL.DDP5.1.Atmos.H.264-playWEB.mkv.new"

echo "Processing: $original_file"
echo "--------------------------------------------------------"

# Run the mkvmerge command to create a new file with only the 'rum' subtitle track.
mkvmerge -o "$temp_file" \
         --video-tracks 0 \
         --audio-tracks 1 \
         --subtitle-tracks rum \
         "$original_file"

# Check if the mkvmerge command was successful.
if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "Remuxing completed successfully. The original file will be deleted and the new one renamed."
    
    # Remove the original file.
    rm "$original_file"
    
    # Rename the new file to the original name.
    mv "$temp_file" "$original_file"
    
    echo "Process completed. The original file was successfully replaced."
else
    echo "--------------------------------------------------------"
    echo "A remuxing error occurred. The original file was NOT deleted."
    echo "You can check the temporary file: $temp_file"
fi
