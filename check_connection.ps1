# Script kiem tra ket noi truc tiep (khong qua Proxy)
param()

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  KIEM TRA KET NOI TRUC TIEP CHO AGY (NO PROXY)      " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

$endpoints = @(
    @{ Host = "accounts.google.com"; Desc = "Google Login / OAuth2" },
    @{ Host = "oauth2.googleapis.com"; Desc = "Token Exchange / Refresh" },
    @{ Host = "antigravity.google"; Desc = "Antigravity Platform" },
    @{ Host = "cloudcode-pa.googleapis.com"; Desc = "Antigravity Agent API" },
    @{ Host = "generativelanguage.googleapis.com"; Desc = "Gemini API Backend" },
    @{ Host = "aicode.googleapis.com"; Desc = "AI Code Assist API" },
    @{ Host = "aiplatform.googleapis.com"; Desc = "Vertex AI API" },
    @{ Host = "www.googleapis.com"; Desc = "Google APIs Gateway" },
    @{ Host = "www.gstatic.com"; Desc = "Google Static Assets" }
)

$allPass = $true

foreach ($item in $endpoints) {
    $hostName = $item.Host
    $desc = $item.Desc
    Write-Host -NoNewline ("Testing {0,-35} ({1,-22})... " -f $hostName, $desc)

    $tcp = Test-NetConnection -ComputerName $hostName -Port 443 -WarningAction SilentlyContinue
    if ($tcp.TcpTestSucceeded) {
        Write-Host "[ PASS ]" -ForegroundColor Green
    } else {
        Write-Host "[ BLOCKED ]" -ForegroundColor Red
        $allPass = $false
    }
}

Write-Host "-----------------------------------------------------" -ForegroundColor Cyan
if ($allPass) {
    Write-Host "Ket luan: Ket noi mang tot! Ban co the cai dat va su dung agy." -ForegroundColor Green
} else {
    Write-Host "Ket luan: Co mot so domain bi chan! Vui long kiem tra lai Firewall/DNS hoac dung Proxy." -ForegroundColor Yellow
}
Write-Host "=====================================================" -ForegroundColor Cyan
