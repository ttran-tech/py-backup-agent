from dataclasses import dataclass
from typing import Callable

@dataclass
class ModuleService:
    send_message: Callable[[str], None]
    get_timestamp: Callable[[], str]