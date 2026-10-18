from setting import load_setting
from error import ErrorCode, get_error_message
import requests, logging

logger = logging.getLogger(__name__)

def send_message(message:str):
    """
    Send log messages to the discord channel

    Args
        message (str): A string message to send to discord channel. 
    """
    webhook = load_setting("webhookURL")
    payload = {
        "content": message,
        "username": "Backup Agent"
    }
    response = requests.post(webhook, payload)
    if response.status_code == 204:
        logger.info(get_error_message(ErrorCode.DISCORD_PAYLOAD_SENT_SUCCESS))
    else:
        logger.error(get_error_message(ErrorCode.DISCORD_PAYLOAD_SENT_FAILED, status_code=response.status_code))