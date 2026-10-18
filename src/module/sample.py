from error import ErrorCode, get_error_message
from pathlib import Path
import subprocess
import logging

logger = logging.getLogger(__name__)

def get_timestamp() -> str:
    from datetime import datetime
    return datetime.now().strftime("%Y%m%d_%H%M%S")

def run(params):
    app_name = params.get("appName")
    location = params.get("location")
    src_path = Path(params.get("sourcePath"))
    dest_path = Path(params.get("destPath"))
    target_dirname = params.get("targetDirName")

    backup_name = f"{get_timestamp()}_{location}_{app_name}_{target_dirname}"
    dest_path = dest_path / backup_name

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
    if result.returncode >= 8:
        logger.error(f"Robocopy failed with exit code {result.returncode}")
    else:
        logger.info(f"Backup {app_name} at {location} SUCCESSFUL.")
    return result