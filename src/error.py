from enum import IntEnum

class ErrorCode(IntEnum):
    # 0x0000 = No error
    SETTING_KEY_NOT_FOUND = 0x1001
    SETTING_FILE_NOT_FOUND = 0x1002

    JSON_CONFIG_EMPTY_DICT = 0x2001
    JSON_CONFIG_LOAD_FILE_FAILED = 0x2002

    MODULE_FILE_NOT_FOUND = 0x3001
    MODULE_IMPORT_FAILED = 0x3002
    MODULE_FAIL_TO_LOAD = 0x3003

    DISCORD_PAYLOAD_SENT_SUCCESS = 0x5000
    DISCORD_PAYLOAD_SENT_FAILED = 0x5001

_ERROR_MESSAGES = {
    # Setting message
    ErrorCode.SETTING_KEY_NOT_FOUND: "Key \"{key}\" not found in {file}",
    ErrorCode.SETTING_FILE_NOT_FOUND: "Failed to load {file}",

    # Json config message
    ErrorCode.JSON_CONFIG_EMPTY_DICT: "Config must be a non-empty dictionary. Type: {data_type}",
    ErrorCode.JSON_CONFIG_LOAD_FILE_FAILED: "Failed to load config file: {file}. {error_type}: {error}",

    # Module message
    ErrorCode.MODULE_FILE_NOT_FOUND: "Failed to load module: {file}",
    ErrorCode.MODULE_IMPORT_FAILED: "Failed to import module: {file}",
    ErrorCode.MODULE_FAIL_TO_LOAD: "Failed to load module: {file}. {error_type}: {error}",

    # Discord message
    ErrorCode.DISCORD_PAYLOAD_SENT_SUCCESS: "Payload sent successfully",
    ErrorCode.DISCORD_PAYLOAD_SENT_FAILED: "Failed to send payload to Discord: {status_code}"
}

def get_error_message(error_code:ErrorCode, **kwargs) -> str:
    error_message = _ERROR_MESSAGES.get(error_code)
    if error_message is None:
        return f"Unknown error code: {error_code}"
    return error_message.format(**kwargs)