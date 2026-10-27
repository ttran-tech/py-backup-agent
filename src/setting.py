from pathlib import Path
from typing import Any
from error import ErrorCode, get_error_message
import sys, json

# Setup BASE directory from either the executable file (build) or from this file (dev)
if getattr(sys, "frozen", False):
    BASE_DIR = Path(sys.executable).resolve().parent
elif sys.argv[0]:
    BASE_DIR = Path(sys.argv[0]).resolve().parent
else:
    BASE_DIR = Path(__file__).resolve().parent

MODULE_DIR = BASE_DIR / "modules"
PACKAGE_DIR = BASE_DIR / "deploy"
LOG_DIR = BASE_DIR / "logs"

MODULE_EXTENSION = "pyd"
BASE_FILES = ["base.json", "base.py"]

def print_file_info():
    print(f"BASE DIR: {BASE_DIR}")
    print(f"MODULE DIR {MODULE_DIR}")
    print(f"PACKAGE DIR {PACKAGE_DIR}")
    print(f"LOG DIR {LOG_DIR}")

def check_deploy_environment():
    if not PACKAGE_DIR.exists() or not PACKAGE_DIR.is_dir():
        Path(PACKAGE_DIR).mkdir(exist_ok=True)

    if not LOG_DIR.exists() or not LOG_DIR.is_dir():
        Path(LOG_DIR).mkdir(exist_ok=True)

def load_setting(key:str) -> Any:
    """
        Load a setting from json file base on a specific key

        Agrs:
            key (str): A key from the json file to pull the setting.
        
        Return:
            Any: return a value based on the provided key.
    """
    setting_json = BASE_DIR / "setting.json"
    if setting_json.exists():
        with setting_json.open('r', encoding='utf-8') as file:
            setting = json.load(file)
        if key in setting:
            return setting.get(key)
        raise KeyError(get_error_message(ErrorCode.SETTING_KEY_NOT_FOUND, key=key, file="setting.json"))
    raise FileNotFoundError(get_error_message(ErrorCode.SETTING_FILE_NOT_FOUND, file="setting.json"))