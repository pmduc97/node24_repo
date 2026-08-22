# Script kiem tra ket noi qua Proxy
param(
    [string]$ProxyUrl
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  KIEM TRA KET NOI QUA PROXY CHO AGY                 " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

if (-not $ProxyUrl) {
    if ($env:HTTPS_PROXY) {
        $ProxyUrl = $env:HTTPS_PROXY
    } elseif ($env:HTTP_PROXY) {
        $ProxyUrl = $env:HTTP_PROXY
    } else {
        $ProxyUrl = Read-Host "Nhap dia chi Proxy cua ban (vi du: http://proxy.company.com:8080)"
    }
}

if (-not $ProxyUrl) {
    Write-Host "[ERROR] Chua nhap dia chi Proxy!" -ForegroundColor Red
    exit 1
}

Write-Host "Dang kiem tra qua Proxy: $ProxyUrl`n" -ForegroundColor Yellow

$endpoints = @(
    @{ Url = "https://accounts.google.com"; Desc = "Google Login / OAuth2" },
    @{ Url = "https://oauth2.googleapis.com"; Desc = "Token Exchange / Refresh" },
    @{ Url = "https://antigravity.google"; Desc = "Antigravity Platform" },
    @{ Url = "https://cloudcode-pa.googleapis.com"; Desc = "Antigravity Agent API" },
    @{ Url = "https://generativelanguage.googleapis.com"; Desc = "Gemini API Backend" },
    @{ Url = "https://aicode.googleapis.com"; Desc = "AI Code Assist API" },
    @{ Url = "https://aiplatform.googleapis.com"; Desc = "Vertex AI API" },
    @{ Url = "https://www.googleapis.com"; Desc = "Google APIs Gateway" },
    @{ Url = "https://www.gstatic.com/generate_204"; Desc = "Google Static Assets" }
)

$allPass = $true

foreach ($item in $endpoints) {
    $url = $item.Url
    $desc = $item.Desc
    Write-Host -NoNewline ("Testing {0,-45} ({1,-22})... " -f $url, $desc)

    try {
        $response = Invoke-WebRequest -Uri $url -Proxy $ProxyUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Host "[ PASS ]" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response) {
            Write-Host "[ PASS (HTTP $($_.Exception.Response.StatusCode.value__)) ]" -ForegroundColor Green
        } else {
            Write-Host "[ FAILED ]" -ForegroundColor Red
            Write-Host "        Loi: $($_.Exception.Message)" -ForegroundColor DarkGray
            $allPass = $false
        }
    }
}

Write-Host "-----------------------------------------------------" -ForegroundColor Cyan
if ($allPass) {
    Write-Host "Ket luan: Proxy hoat dong tot voi cac domain can thiet!" -ForegroundColor Green
    Write-Host "`nDe chay agy voi Proxy nay tren PowerShell, hay chay lenh:" -ForegroundColor Cyan
    Write-Host "  `$env:HTTP_PROXY = `"$ProxyUrl`""
    Write-Host "  `$env:HTTPS_PROXY = `"$ProxyUrl`""
    Write-Host "  agy"
} else {
    Write-Host "Ket luan: Proxy khong ket noi duoc toi mot so domain! Vui long kiem tra whitelist tren Proxy." -ForegroundColor Yellow
}
Write-Host "=====================================================" -ForegroundColor Cyan
