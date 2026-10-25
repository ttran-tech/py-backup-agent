from typing import Dict
from pathlib import Path
import subprocess
import logging
import sys

MODULE_DIR = Path(__compiled__.containing_dir).resolve() # type: ignore

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

def run(params:Dict, service) -> Dict:
    module_name = params.get("module")
    app_name = params.get("application")
    location = params.get("location")
    backup_type = params.get("type")

    timestamp = service.get_timestamp()

    # Setup logging
    logger = logging.Logger(str(module_name))
    logger.setLevel(logging.INFO)

    # Setup log folders
    log_dir = MODULE_DIR / "logs"
    if not log_dir.exists() or not log_dir.is_dir():
        Path(log_dir).mkdir()
    log_path = log_dir /f"{timestamp}_{module_name}_{app_name}_{backup_type}.log"

    handler = logging.FileHandler(log_path)
    handler.setFormatter(
        logging.Formatter("%(asctime)s - %(levelname)s: %(message)s", datefmt="[%Y-%m-%d %H:%M:%S]")
    )
    logger.addHandler(handler)

    # Setup backup location
    src_path = Path(str(params.get("sourcePath")))
    dest_path = Path(str(params.get("destPath")))
    target_dirname = params.get("targetDirectory")
    error_message = ""
    backup_name = f"{timestamp}_{location}_{app_name}_{target_dirname}"
    dest_path = dest_path / backup_name

    service.send_message(f"Start backup job for **{app_name}** at **{location}**. Backup type: *{backup_type}*")
    logger.info(f"Start backup job for {app_name} at {location}. Backup type: {backup_type}")
    
    command = [
        "Robocopy",
        str(src_path),
        str(dest_path),
        "/e",   # copy sub-directories, include empty one
        "/R:3",  # retry count (3 times)
        "/w:5",  # waiting time between each retry in seconds
        "/Z",   # the copy file can be interrupted, allow robocopy to continue where it left off
        "/NP"   # no show percentate  
    ]

    print(" ".join(command))
    result = subprocess.run(command, text=True, errors="replace", check=False)
    exit_code = result.returncode
    if exit_code >= 8:
        error_message = f"{EXIT_CODES[exit_code]} Exit code: {exit_code}"
        service.send_message(f"**{app_name}** at **{location}**: Robocopy failed to execute. *{error_message}* | Status: [FAILED]")
        logger.error(f"{app_name} at {location}: Robocopy failed to execute. {error_message}")
    else:
        service.send_message(f"Backup job for **{app_name}** at **{location}** has finished successfully.")
        logger.info(f"Backup job for {app_name} at {location} has finished | Status: [SUCCESS]")
    return {
        "application": app_name,
        "success": (False if exit_code >= 8 else True),
        "error_message": error_message,
    }