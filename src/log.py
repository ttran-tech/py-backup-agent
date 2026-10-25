from pathlib import Path

from common import get_timestamp
from setting import LOG_DIR

import logging

class LogCollector(logging.Handler):
    def __init__(self):
        super().__init__()
        self.records = []

    def emit(self, record):
        self.records.append(record)

def create_logfile(module_name:str, application:str, backup_type:str) -> Path:
    log_path = LOG_DIR / f"{get_timestamp()}_{module_name}_{application}_{backup_type}.log"
    Path(log_path).touch()
    return log_path

def write_log(log_path:Path, log_content:str):
    log_path.write_text(log_content, encoding="utf-8")