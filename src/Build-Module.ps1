param (
    [string]$ModuleName
)

$moduleBaseDir = ".\\modules"

if ($ModuleName -eq "") {
    Write-Host "Usage: .\Build-Module.ps [-ModuleName]"
}
else {
    Write-Host "Received module name: $ModuleName"
    $outputDir = ".\\packages\\$ModuleName"
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

    $ouputConfigFile = "$outputDir\\config.json"
    $configFile = "$moduleBaseDir\\$ModuleName\\config.json"
    
    if (-not(Test-Path -Path $ouputConfigFile -PathType Leaf)) {
        Copy-Item -Path $configFile -Destination $outputDir
    }
}
