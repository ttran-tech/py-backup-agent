param(
    [string]$BuildMode
)

function Test-VenvIsActivated() {
    return Test-Path env:VIRTUAL_ENV
}

function Test-FolderIsEmpty() {
    param(
        [string]$path
    )
    return ((Get-ChildItem -Path $path -Force | Measure-Object).Count -eq 0)
}

function Invoke-Main() {
    if (-not(Test-Path -Path ".\\.venv")) {
        Write-Host "Error: Virtual environment not found in src directory."
    }
    else {
        $pythonExec = ".\\.venv\\Scripts\\python.exe" 
        If (-not(Test-VenvIsActivated)) {
            ./.venv/Scripts/Activate.ps1
        }

        Write-Host "venv activated: $(Test-VenvIsActivated)"
        If (Test-VenvIsActivated) {
            $build_dir = ".\\build"

            If (-not(Test-Path -Path $build_dir)) {
                New-Item -Path $build_dir -ItemType Directory
            }
            Else {
                If (-not(Test-FolderIsEmpty($build_dir))) {
                    Remove-Item -Path "$build_dir\\*" -Recurse -Force
                }
            }

            if ($BuildMode -eq "standalone") {
                &$pythonExec -m nuitka --mode=standalone --output-dir=build --output-filename=BackupAgent.exe --include-data-files=setting.json=setting.json --windows-icon-from-ico=icon.ico --remove-output main.py

                Copy-Item ".\\deploy" "$build_dir\\main.dist\\deploy" -Force -Recurse
                New-Item -Path "$build_dir\\main.dist\\logs" -ItemType Directory
            }
            elseif ($BuildMode -eq "onefile") {
                &$pythonExec -m nuitka --mode=onefile --output-dir=build --output-filename=BackupAgent.exe --include-data-files=setting.json=setting.json --windows-icon-from-ico=icon.ico --remove-output main.py

                Copy-Item ".\\deploy" "$build_dir\\deploy" -Force -Recurse
                New-Item -Path "$build_dir\\logs" -ItemType Directory
            }
            else {
                Write-Host "Error: Invalod build mode: $BuildMode"
            }
        }
        deactivate
    }
}

Invoke-Main