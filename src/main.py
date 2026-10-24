from setting import load_setting
from log import LogCollector
from typing import List, Dict
from types import ModuleType
from pathlib import Path
from setting import BASE_DIR, MODULE_DIR, MODULE_EXTENSION, BASE_FILES, PACKAGE_DIR
from error import get_error_message, ErrorCode
from discord import send_message
from datetime import date
import json
import sys
import logging
import importlib
import importlib.util

LOCATION = ""
SERVER = ""

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

backup_results = []

def load_config() -> List[Dict]:
    config = []
    json_files = [file for file in Path(PACKAGE_DIR).rglob("*.jsonc") if file.is_file() and file.name not in BASE_FILES]

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
    
def load_module_ex(module_name:str):
    entry_point = f"{module_name}.{MODULE_EXTENSION}"

    module_path = PACKAGE_DIR / module_name / entry_point
    print(f"module_path: {module_path}")
    
    if not module_path.is_file():
        raise FileNotFoundError(get_error_message(ErrorCode.MODULE_FILE_NOT_FOUND, file=module_name))

    if module_path.name not in BASE_FILES:
        # Create module spec - tell Python where the module is and how to load it
        spec = importlib.util.spec_from_file_location(module_name, module_path)
        if spec is None or spec.loader is None:
            raise ImportError(get_error_message(ErrorCode.MODULE_IMPORT_FAILED, file=module_name))
        
        # Create module object
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        # Load the module
        spec.loader.exec_module(module)
        return module

def generate_summary(backup_result:List) -> str:
    if backup_results:
        success = sum(r["success"] for r in backup_results)
        failed = len(backup_results) - success
        date_str = date.today().strftime("%d-%m-%Y")
        
        lines = [
            "```",
            f"Backup Summary | Date: {date_str}",
            "",
            f"Location: {LOCATION}",
            f"Server:   {SERVER}",
            "",
        ]
        
        for result in backup_results:
            status = "[OK]" if result["success"] else "[FAILED]"
            error_message = "" if result["success"] else f" ({result['error_message']})"
            lines.append(
                f"{status} {result['application']}{error_message}"
            )
            
        lines.extend([
            "",
            f"Total Jobs: {len(backup_results)}",
            f"Successful: {success}",
            f"Failed: {failed}",
            "",
            f"Overall Status: {'SUCCESS' if failed == 0 else 'FAILED'}",
            "```"
        ])
        return "\n".join(lines)
    return "Failed to generate BACKUP SUMMARY"

def run():
    global LOCATION
    global SERVER
    configs = load_config()
    for config in configs:
        module_name = config["module"]
        LOCATION = config["location"]
        SERVER = config["server"]
        try:
            module = load_module_ex(module_name)
            assert module is not None
            result = module.run(config)
            backup_results.append(result)
        except (ModuleNotFoundError, AttributeError, FileNotFoundError, ImportError) as e:
            logging.error(get_error_message(ErrorCode.MODULE_FAIL_TO_LOAD, file=module_name, error_type=type(e).__name__, error=e))
            backup_results.append({
                "application": config["application"],
                "success": False,
                "error_message": ErrorCode.MODULE_FAIL_TO_LOAD,
            })

if __name__ == '__main__':
    configs = load_config()
    run()

    if collector.records:
        messages = [collector.format(record) for record in collector.records]

        messages = "\n".join(messages)
        send_message(messages)
    summary_message = generate_summary(backup_results)
    send_message(summary_message)