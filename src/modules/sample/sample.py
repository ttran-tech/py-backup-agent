from error import ErrorCode, get_error_message
from typing import Dict
from pathlib import Path
import subprocess
import logging

logger = logging.getLogger(__name__)

EXIT_CODES = {
    0:  "No files copied. Source and destination are synchronized.",
    1:  "One or more files copied successfully.",
    2:  "Extra files or directories detected at destination.",
    3:  "Files copied; extra files or directories detected.",
    4:  "Mismatched files or directories detected.",
    5:  "Files copied; mismatched files or directories detected.",
    6:  "Extra and mismatched files or directories detected.",
    7:  "Files copied; extra and mismatched files or directories detected.",
    8:  "Some files or directories could not be copied.",
    9:  "Copy errors occurred, some files copied successfully.",
    10: "Copy errors occurred, extra files or directories detected.",
    11: "Copy errors occurred, files copied and extra files detected.",
    12: "Copy errors occurred, mismatched files or directories detected.",
    13: "Copy errors occurred, files copied and mismatches detected.",
    14: "Copy errors occurred, extra and mismatched files detected.",
    15: "Copy errors occurred, files copied, extra and mismatched files detected.",
    16: "Fatal Error: Serious failure. No files copied."
}

def get_timestamp() -> str:
    from datetime import datetime
    return datetime.now().strftime("%Y%m%d_%H%M%S")

def run(params) -> Dict:
    app_name = params.get("application")
    location = params.get("location")
    backup_type = params.get("type")
    src_path = Path(params.get("sourcePath"))
    dest_path = Path(params.get("destPath"))
    target_dirname = params.get("targetDirectory")
    error_message = ""

    backup_name = f"{get_timestamp()}_{location}_{app_name}_{target_dirname}"
    dest_path = dest_path / backup_name

    logger.info(f"Start backup job for {app_name} at {location}. Backup type: {backup_type}")
    
    command = [
        "Robocopy",
        str(src_path),
        str(dest_path),
        "/e",   # copy sub-directories, include empty one
        "/R:3",  # retry count (3 times)
        "/w:5",  # waiting time between each retry in seconds
        "/Z_",   # the copy file can be interrupted, allow robocopy to continue where it left off
        "/NP"   # no show percentate  
    ]

    print(" ".join(command))
    result = subprocess.run(command, text=True, errors="replace", check=False)
    exit_code = result.returncode
    if exit_code >= 8:
        error_message = f"{EXIT_CODES[exit_code]}. Exit code: {exit_code}"
        logger.error(f"{app_name} at {location}: Robocopy failed to execute. {error_message}")
    else:
        logger.info(f"Backup job for {app_name} at {location} has finished successfully.")
    return {
        "application": app_name,
        "success": (False if exit_code >= 8 else True),
        "error_message": error_message,
    }