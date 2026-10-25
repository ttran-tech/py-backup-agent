param (
    [string]$ModuleName
)

$moduleBaseDir = ".\\modules"

function Test-Checksum {
    param(
        [string]$sourceFile,
        [string]$destFile
    )
    return (Get-FileHash -Path $sourceFile -Algorithm SHA256).Hash -eq (Get-FileHash -Path $destFile -Algorithm SHA256).Hash
}


if ($ModuleName -eq "") {
    Write-Host "Usage: .\Build-Module.ps1 [-ModuleName]"
}
else {
    Write-Host "Received module name: $ModuleName"
    $outputDir = ".\\deploy\\$ModuleName"
    $outputFile = "$outputDir\\$ModuleName.pyd"

    # Check if pyd file already exist in the packages
    if (Test-Path -Path $outputFile -PathType Leaf) {
        Write-Host "Found $outputFile"
        Write-Host "Delete $outputFile"
        Remove-Item -Path $outputFile -Force
        Write-Host "Done."
    }

    Write-Host "Start compiling pyd file..."

    $env:PYTHONPATH = (Resolve-Path ./modules).Path
    $nuitkaSrcDir = "$moduleBaseDir\\$moduleName"
    python -m nuitka --mode=package $nuitkaSrcDir --output-dir="$outputDir" --remove-output --no-pyi-file

    if (Test-Path -Path "$outputDir\\*.pyd") {
        Write-Host "Compile Successfully."
        $targetFile = Get-ChildItem -Path $outputDir -Filter "*.pyd" -Name
        Rename-Item -Path "$outputDir\\$targetFile" -NewName "$ModuleName.pyd"
        Write-Host "Rename completed."
    }
    
    if (-not(Test-Path "$moduleBaseDir\\$ModuleName\\*.jsonc" )) {
        $ouputConfigFile = "$outputDir\\config.jsonc"
        $configFile = "$moduleBaseDir\\$ModuleName\\config.jsonc"
        if (-not(Test-Path -Path $ouputConfigFile -PathType Leaf) -or -not(Test-Checksum -sourceFile $configFile -destFile $ouputConfigFile)) {
            Copy-Item -Path $configFile -Destination $outputDir
        }
    }

}
