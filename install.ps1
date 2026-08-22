# Script cai dat Antigravity CLI (agy) tu dong
$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   CAI DAT ANTIGRAVITY CLI (AGY) - WINDOWS   " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$sourceAgy = Join-Path $PSScriptRoot "bin\agy.exe"
if (-not (Test-Path $sourceAgy)) {
    Write-Host "[ERROR] Khong tim thay file agy.exe trong thu muc bin!" -ForegroundColor Red
    Write-Host "Vui long kiem tra lai thu muc giai nen."
    exit 1
}

$targetDir = "$env:LOCALAPPDATA\agy\bin"
$targetAgy = Join-Path $targetDir "agy.exe"

Write-Host "`n[1/3] Tao thu muc cai dat: $targetDir" -ForegroundColor Yellow
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

Write-Host "[2/3] Sao chep agy.exe vao thu muc dich..." -ForegroundColor Yellow
Copy-Item -Path $sourceAgy -Destination $targetAgy -Force
Write-Host "      -> Da sao chep thanh cong!" -ForegroundColor Green

Write-Host "[3/3] Cau hinh bien moi truong PATH (User)..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$pathEntries = if ($userPath) { $userPath -split ";" | Where-Object { $_ -ne "" } } else { @() }

if ($pathEntries -notcontains $targetDir) {
    $newUserPath = ($pathEntries + $targetDir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, [EnvironmentVariableTarget]::User)
    Write-Host "      -> Da them '$targetDir' vao User PATH!" -ForegroundColor Green
} else {
    Write-Host "      -> Thu muc da ton tai trong User PATH." -ForegroundColor Gray
}

# Cap nhat PATH cho phien PowerShell hien tai
$env:Path = "$env:Path;$targetDir"

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host "         CAI DAT HOAN TAT THANH CONG!        " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "`nDe bat dau su dung:"
Write-Host "1. Mo mot cua so Terminal / PowerShell / CMD MOI."
Write-Host "2. Go lenh: agy"
Write-Host "3. Dang nhap tai khoan theo huong dan tren man hinh.`n"
