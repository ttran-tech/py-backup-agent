param (
    [Parameter(Mandatory=$True)]
    [string]$ModuleName,
    [string]$Application,
    [string]$Location,
    [string]$Server,

    [string]$BackupType
    [bool]
)

New-Variable -Name BASE_DIR -Value ".\\modules" -Option Constant

function New-ModuleDir() {
    param (
        [string]$ModuleName
    )

    $newModulePath = "$BASE_DIR\\$ModuleName"
    
    if (-not(Test-Path -Path $newModulePath)) {
        return (New-Item -Path $newModulePath -ItemType Directory -Force).FullName
        #return $newModulePath
    }
    else {
        throw [System.InvalidOperationException]::new("Module already exists.")
    }
}

function New-InitFile() {
    param (
        [string]$ModulePath,
        [string]$ModuleName
    )
    $initPath = "$ModulePath\\__init__.py"
    Set-Content -Path $initPath -Value "from .$ModuleName import run"
}

function New-ModuleFile() {
    param (
        [string]$ModulePath,
        [string]$ModuleName
    )
    $template =
    @"
from typing import Dict
from pathlib import Path
import logging

MODULE_DIR = Path(__compiled__.containing_dir).resolve() # type: ignore
logger = None

def init_log(params:Dict, service):
    global logger
    module_name = params.get("module")
    app_name = params.get("application")
    location = params.get("location")
    backup_type = params.get("type")

    timestamp = service.get_timestamp()

    # Setup logging
    logger = logging.Logger(str(module_name))
    logger.setLevel(logging.INFO)

    # Setup log folder
    log_dir = MODULE_DIR / "logs"
    if not log_dir.exists() or not log_dir.is_dir():
        Path(log_dir).mkdir()
    log_path = log_dir / f"{timestamp}_{module_name}_{app_name}_{backup_type}.log"

    # Setup file handler
    handler = logging.FileHandler(log_path)
    handler.setFormatter(
        logging.Formatter("%(asctime)s - %(levelname)s: %(message)s", datefmt="[%Y-%m-%d %H:%M:%S]")
    )
    logger.addHandler(handler)

####################################################################################################
# Add module code below:
# def custom_module():
#   pass

def run(params:Dict, service) -> Dict | None:
    """ 
        This function is called by BackupAgent to execute a custom backup job.
    
        Args:
            params (Dict): Parameters defined in config.jsonc.
            service (ModuleService): a set of shared functions from BackupAgent that can be called from run() (or pass to another functions).
                Current ModuleService:
                    service.send_message(message:str):  send a message to Discord webhook.
                    service.get_timestamp() -> str:     get current time stamp.     
    """
    init_log(params, service)

    # Add module code below
"@
    $moduleFilePath = "$ModulePath\\$ModuleName.py"
    Set-Content -Path $moduleFilePath -Value $template
}

function New-ConfigFile() {
    param (
        [string]$ModulePath,
        [string]$ModuleName
    )
    $template =
    @"
{
    "version": 1.0,
    "module": "$ModuleName",        // require
    "application" : "$Application", // Application Name (required)
    "location" : "$Location",       // Office Location  (required)
    "server" : "$Server",           // Server Name      (required)
    "type" : "$BackupType",         // Backup Type: SQL, persistent (Required)
    
    // Define others module's parameters here
}
"@
    $configFilePath = "$ModulePath\\config.jsonc"
    Set-Content -Path $configFilePath -Value $template
}

function Invoke-Main() {
    param (
        [string]$ModuleName
    )
    try {
        $modulePath = (New-ModuleDir -ModuleName $moduleName)
        # Generate __init__.py
        New-InitFile -ModulePath $modulePath -ModuleName $moduleName

        # Generate module.py
        New-ModuleFile -ModulePath $modulePath -ModuleName $moduleName

        # Generate config.json
        New-ConfigFile -ModulePath $modulePath -ModuleName $moduleName

        Write-Host "A new module has been created successfully at: $modulePath"
    }
    catch [System.InvalidOperationException] {
        Write-Host "Error: $($_.Exception.Message)"
        Exit 1
    }
}

if ($ModuleName -ne "") {
    Invoke-Main -ModuleName $ModuleName
}
else {
    Write-Host "Usage: .\New-Module.ps1 -ModuleName [ModuleName] -Application [AppName] -Location [Location] -Server [ServerName] [[-BackupType]]"
    Exit 1
}