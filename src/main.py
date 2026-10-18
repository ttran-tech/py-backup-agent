from setting import load_setting
from log import LogCollector
from typing import List, Dict
from types import ModuleType
from pathlib import Path
from setting import BASE_DIR, CONFIG_DIR, MODULE_DIR, MODULE_EXTENSION
from error import get_error_message, ErrorCode
from discord import send_message
import json
import logging
import importlib
import importlib.util

# Setup logging and log collector
collector = LogCollector()
collector.setLevel(logging.INFO)
collector.setFormatter(
    logging.Formatter(
        fmt="%(asctime)s - %(levelname)s: %(message)s",
        datefmt="[%Y-%m-%d %H:%M:%S]"
    )
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s: %(message)s", datefmt="[%Y-%m-%d %H:%M:%S]")
logging.getLogger().addHandler(collector)

def load_config() -> List[Dict]:
    config = []
    json_files = [file for file in Path(CONFIG_DIR).rglob("*.json") if file.is_file() and file.name != "base.json"]

    for file in json_files:
        try:
            with file.open("r", encoding="utf-8") as f:
                data = json.load(f)
            if not isinstance(data, dict) or not data:
                raise ValueError(get_error_message(ErrorCode.JSON_CONFIG_EMPTY_DICT, data_type=type(data)))
            config.append(data)
        except (OSError, ValueError) as e:
            logging.error(get_error_message(ErrorCode.JSON_CONFIG_LOAD_FILE_FAILED, file=file.relative_to(BASE_DIR), error_type=type(e).__name__, error=e))
    return config


def load_module(module_name:str) -> ModuleType:
    if not module_name.endswith(MODULE_EXTENSION):
        module_name = f"{module_name}.{MODULE_EXTENSION}"

    module_path = MODULE_DIR / module_name

    if not module_path.is_file():
        raise FileNotFoundError(get_error_message(ErrorCode.MODULE_FILE_NOT_FOUND, file=module_name))

    # Create module spec - tell Python where the module is and how to load it
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise ImportError(get_error_message(ErrorCode.MODULE_IMPORT_FAILED, file=module_name))
    
    # Create module object
    module = importlib.util.module_from_spec(spec)

    # Load the module
    spec.loader.exec_module(module)
    return module

def run(configs:List):
    for config in configs:
        module_name = config["moduleName"]
        param = config["parameters"]

        try:
            module = load_module(module_name)
            module.run(param)
        except (ModuleNotFoundError, AttributeError, FileNotFoundError, ImportError) as e:
            logging.error(get_error_message(ErrorCode.MODULE_FAIL_TO_LOAD, file=module_name, error_type=type(e).__name__, error=e))

if __name__ == '__main__':
    configs = load_config()
    run(configs=configs)

    if collector.records:
        messages = [collector.format(record) for record in collector.records]

        messages = "\n".join(messages)
        send_message(messages)