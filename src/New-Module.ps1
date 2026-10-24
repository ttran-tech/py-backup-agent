param (
    [string]$ModuleName
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

def run(param:Dict) -> Dict:
    pass
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
    "module": "$ModuleName",  // Mandatory
    "application" : "", // Application Name (required)
    "location" : "",    // Office Location  (required)
    "server" : "",      // Server Name      (required)
    "type" : "",        // Backup Type: SQL, persistent (Required)
    "logPath" : "",     // Path to log file (Optional)
    
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
    Write-Host "Usage: .\New-Module.ps1 [-ModuleName]"
    Exit 1
}