from enum import IntEnum

class ErrorCode(IntEnum):
    # 0x0000 = No error
    SETTING_KEY_NOT_FOUND = 0x1001
    SETTING_FILE_NOT_FOUND = 0x1002

    DISCORD_PAYLOAD_SENT_SUCCESS = 0x5000
    DISCORD_PAYLOAD_SENT_FAILED = 0x5001

_ERROR_MESSAGES = {
    # Setting message
    ErrorCode.SETTING_KEY_NOT_FOUND: "Key \"{key}\" not found in {file}",
    ErrorCode.SETTING_FILE_NOT_FOUND: "Failed to load {file}",

    # Discord message
    ErrorCode.DISCORD_PAYLOAD_SENT_SUCCESS: "Payload sent successfully",
    ErrorCode.DISCORD_PAYLOAD_SENT_FAILED: "Failed to send payload to Discord: {status_code}"
}

def get_error_message(error_code:ErrorCode, **kwargs) -> str:
    error_message = _ERROR_MESSAGES.get(error_code)
    if error_message is None:
        return f"Unknown error code: {error_code}"
    return error_message.format(**kwargs)