@echo off
setlocal enabledelayedexpansion

echo =============================================
echo    CAI DAT ANTIGRAVITY CLI (AGY) - WINDOWS   
echo =============================================

set "SOURCE_AGY=%~dp0bin\agy.exe"
if not exist "%SOURCE_AGY%" (
    echo [ERROR] Khong tim thay file agy.exe trong thu muc bin!
    pause
    exit /b 1
)

set "TARGET_DIR=%LOCALAPPDATA%\agy\bin"
set "TARGET_AGY=%TARGET_DIR%\agy.exe"

echo.
echo [1/3] Tao thu muc cai dat: %TARGET_DIR%
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

echo [2/3] Sao chep agy.exe...
copy /Y "%SOURCE_AGY%" "%TARGET_AGY%" >nul
if errorlevel 1 (
    echo [ERROR] Sao chep that bai!
    pause
    exit /b 1
)
echo       -^> Da sao chep thanh cong!

echo [3/3] Cau hinh PATH (User)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$target='%LOCALAPPDATA%\agy\bin'; $p=[Environment]::GetEnvironmentVariable('Path','User'); if (($p -split ';') -notcontains $target) { [Environment]::SetEnvironmentVariable('Path', ($p.TrimEnd(';') + ';' + $target), 'User') }"

echo.
echo =============================================
echo          CAI DAT HOAN TAT THANH CONG!        
echo =============================================
echo.
echo De bat dau su dung:
echo 1. Mo mot cua so Command Prompt / PowerShell MOI.
echo 2. Go lenh: agy
echo 3. Dang nhap tai khoan theo huong dan.
echo.
pause
