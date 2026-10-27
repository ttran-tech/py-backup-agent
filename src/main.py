from typing import List, Dict
from types import ModuleType
from pathlib import Path
from datetime import date

from log import LogCollector, create_logfile, write_log
from setting import BASE_DIR, MODULE_EXTENSION, BASE_FILES, PACKAGE_DIR, LOG_DIR
from setting import check_deploy_environment, load_setting, print_file_info
from error import get_error_message, ErrorCode
from discord import send_message
from common import get_timestamp
from service import ModuleService

import json
import sys
import logging
import importlib
import importlib.util
import socket
import os
import concurrent.futures

VERSION = "1.1.0"
AUTHOR = "duy@ttran.tech"

LOCATION = ""
SERVER = ""


backup_results = []

service = ModuleService(
    send_message=send_message,
    get_timestamp=get_timestamp,
)

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
    
def load_module_ex(module_name:str) -> ModuleType | None:
    entry_point = f"{module_name}.{MODULE_EXTENSION}"

    module_path = PACKAGE_DIR / module_name / entry_point
    
    if not module_path.is_file():
        raise FileNotFoundError(get_error_message(ErrorCode.MODULE_FILE_NOT_FOUND, file=module_name))

    #if module_path.name not in BASE_FILES:
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

def generate_summary(backup_results:List) -> str:
    get_machine_info()
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

def get_machine_info():
    global LOCATION
    global SERVER
    LOCATION = load_setting("location")
    SERVER = load_setting("server")

    if LOCATION == "":
        LOCATION = (os.environ.get("LOGONSERVER")).strip("\\") # type: ignore

    if SERVER == "":
        SERVER = socket.gethostname()

def execute_module(config:Dict, module:ModuleType) ->List:
    result_list = []
    module_name = config["module"]
    application = config["application"]
    try:
        # assert module is not None
        result = module.run(config, service)
        result_list.append(result)
        if result["success"]:
            logging.info(get_error_message(ErrorCode.MODULE_EXECUTE_SUCCESS, module_name=module_name))
    except (ModuleNotFoundError, AttributeError, FileNotFoundError, ImportError, Exception) as e:
        logging.error(get_error_message(ErrorCode.MODULE_FAIL_TO_LOAD, file=module_name, error_type=type(e).__name__, error=e))
        result_list.append({
            "application": application,
            "success": False,
            "error_message": ErrorCode.MODULE_FAIL_TO_LOAD,
        })
    return result_list

def print_banner():
    print("    ____             __                  ___                    __ ")
    print("   / __ )____ ______/ /____  ______     /   | ____ ____  ____  / /_")
    print("  / __  / __ `/ ___/ //_/ / / / __ \\   / /| |/ __ `/ _ \\/ __ \\/ __/")
    print(" / /_/ / /_/ / /__/ ,< / /_/ / /_/ /  / ___ / /_/ /  __/ / / / /_  ")
    print("/_____/\\__,_/\\___/_/|_|\\__,_/ .___/  /_/  |_\\__, /\\___/_/ /_/\\__/  ")
    print("                           /_/             /____/                  ")
    print(f"{'─'*50} v{VERSION} | {AUTHOR}")
    
def run():
    # set up logging
    log_path = LOG_DIR / f"{get_timestamp()}_BackupAgent.log"
    logging.basicConfig(filename=log_path, level=logging.INFO, format="%(asctime)s - %(levelname)s: %(message)s", datefmt="[%Y-%m-%d %H:%M:%S]")
    enabled_configs = []
    configs = load_config()
    for config in configs:
        enable = int(config["enable"])
        if bool(enable):
            enabled_configs.append(config)
    module_registry = {}
    # To avoid race condition when BackupAgent tries to load the same module for the same backup job,
    # load and register the module to the module_registry to ensure a module is only loaded once.
    for config in enabled_configs:
        module_name = config["module"]
        if module_name not in module_registry.keys():
            try:
                module_registry[module_name] = load_module_ex(module_name=module_name)
            except ModuleNotFoundError as e:
                logging.error(get_error_message(ErrorCode.MODULE_FAIL_TO_LOAD, file=module_name, error_type=type(e).__name__, error=e))
                module_registry[module_name] = None

    # for config in configs:
    #     backup_results.extend(execute_module(config=config))
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        futures = [executor.submit(execute_module, config, module_registry[config["module"]]) for config in enabled_configs]
        for future in concurrent.futures.as_completed(futures):
            backup_results.extend(future.result())
    summary_message = generate_summary(backup_results)
    send_message(summary_message)


if __name__ == '__main__':
    print_banner()
    #print_file_info()
    check_deploy_environment()
    print(" [i] Backup is in process...")
    run()
    print(" [i] Backup completed.")