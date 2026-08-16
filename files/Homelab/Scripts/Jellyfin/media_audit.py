#!/usr/bin/env python3
import os
import re
from collections import defaultdict

# 1. Define Staging and Production environments (Target Paths)
PATHS_TO_SCAN = [
    "/mnt/shared_storage/Media/Downloads",
    "/mnt/shared_storage/Media/Movies",
    "/mnt/shared_storage/Media/Shows"
]

# 2. Define Regexes for ETL (Extract, Transform, Load)
# Explicitly search for resolution standards
RES_PATTERN = re.compile(r'(2160p|1080p|720p|4k)', re.IGNORECASE)

# Cut the string starting with the release year (e.g., 2024, 2025, 2026) 
# or at season markers (e.g., S01, S02) to isolate the "Base Title"
TITLE_CUT_PATTERN = re.compile(r'[\.\s\(](?:19|20)\d{2}|S\d{2}', re.IGNORECASE)

def normalize_title(raw_name):
    """Normalize the string to be able to compare 'Crime.101.2026' with 'Crime 101 (2026)'"""
    # Cut everything after year/season
    split_name = TITLE_CUT_PATTERN.split(raw_name)[0]
    # Replace dots with spaces and remove unnecessary spaces
    clean_name = split_name.replace('.', ' ').replace('_', ' ').strip()
    return clean_name.lower()

def audit_media_pipeline():
    # Dictionary of Sets structure to avoid duplicates of identical resolutions
    # Format: { "crime 101": {"1080p", "2160p"} }
    media_state = defaultdict(set)
    artifact_paths = defaultdict(list)

    print(f"[INFO] Initiating VFS Audit across {len(PATHS_TO_SCAN)} paths...\n")

    for target_dir in PATHS_TO_SCAN:
        if not os.path.exists(target_dir):
            print(f"[WARN] Path not found: {target_dir}")
            continue

        # Execute an iterative os.walk() to scan subdirectories.
        # This is critical because Radarr hides the resolution from the
        # main production directory name (e.g., /Movies/Crime 101 (2026)/file.mkv)
        for root, dirs, files in os.walk(target_dir):
            for file_name in files:
                # Parse only video files
                if file_name.endswith(('.mkv', '.mp4', '.avi')):
                    base_title = normalize_title(file_name)
                    
                    # Extract the resolution
                    res_match = RES_PATTERN.search(file_name)
                    if res_match:
                        resolution = res_match.group(1).lower()
                        media_state[base_title].add(resolution)
                        
                        full_path = os.path.join(root, file_name)
                        artifact_paths[base_title].append(f"[{resolution}] {full_path}")

    # 3. Evaluate logic and report storage anomalies
    print("-" * 60)
    print("🚨 STATE DRIFT ANOMALIES DETECTED (MULTI-RESOLUTION) 🚨")
    print("-" * 60)
    
    anomalies_found = False
    for title, resolutions in media_state.items():
        if len(resolutions) > 1:
            anomalies_found = True
            print(f"\n[!] Title Conflicted: '{title.title()}'")
            print(f"    Resolutions Found: {', '.join(resolutions)}")
            print("    Artifact Locations:")
            for path in artifact_paths[title]:
                print(f"      -> {path}")

    if not anomalies_found:
        print("\n[OK] Pipeline is clean. No multi-resolution conflicts detected.")

if __name__ == "__main__":
    audit_media_pipeline()
