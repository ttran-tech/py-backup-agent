from pathlib import Path
from typing import Any
from error import ErrorCode, get_error_message
import sys, json

# Setup BASE directory from either the executable file (build) or from this file (dev)
if getattr(sys, "frozen", False):
    BASE_DIR = Path(sys.executable).resolve().parent
else:
    BASE_DIR = Path(__file__).resolve().parent

CONFIG_DIR = BASE_DIR / "config"
MODULE_DIR = BASE_DIR / "module"

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