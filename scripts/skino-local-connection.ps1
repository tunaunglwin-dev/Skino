param(
    [switch]$OpenFirewall
)

$ErrorActionPreference = "Stop"

function Write-Section($Text) {
    Write-Host ""
    Write-Host "== $Text ==" -ForegroundColor Cyan
}

$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend-laravel"
$ai = Join-Path $root "ai-service-python"

Write-Section "Skino local connection"
Write-Host "Use this for home-router Wi-Fi or mobile hotspot testing."
Write-Host "Phone and laptop must be on the same network."

Write-Section "Laptop IP choices"
$addresses = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -notlike "127.*" -and
        $_.IPAddress -notlike "169.254.*" -and
        $_.PrefixOrigin -ne "WellKnown"
    } |
    Sort-Object InterfaceAlias, IPAddress

if (-not $addresses) {
    Write-Host "No LAN IPv4 address found. Connect laptop to Wi-Fi/hotspot first." -ForegroundColor Red
    exit 1
}

foreach ($address in $addresses) {
    $apiUrl = "http://$($address.IPAddress):8000/api"
    Write-Host "$($address.InterfaceAlias): $apiUrl" -ForegroundColor Green
}

Write-Section "Server commands"
Write-Host "Terminal 1:"
Write-Host "cd `"$ai`""
Write-Host ".\.venv\Scripts\Activate.ps1"
Write-Host "uvicorn app.main:app --host 127.0.0.1 --port 5000 --reload"
Write-Host ""
Write-Host "Terminal 2:"
Write-Host "cd `"$backend`""
Write-Host "php artisan config:clear"
Write-Host "php artisan serve --host=0.0.0.0 --port=8000"

Write-Section "Local health checks"
try {
    $laravel = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health" -TimeoutSec 4
    Write-Host "Laravel local: OK ($($laravel.service))" -ForegroundColor Green
} catch {
    Write-Host "Laravel local: not reachable yet. Start Terminal 2 command." -ForegroundColor Yellow
}

try {
    $python = Invoke-RestMethod -Uri "http://127.0.0.1:5000/health" -TimeoutSec 4
    Write-Host "Python AI local: OK ($($python.service))" -ForegroundColor Green
} catch {
    Write-Host "Python AI local: not reachable yet. Start Terminal 1 command." -ForegroundColor Yellow
}

if ($OpenFirewall) {
    Write-Section "Firewall"
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if (-not $isAdmin) {
        Write-Host "Run PowerShell as Administrator to open firewall automatically." -ForegroundColor Yellow
    } else {
        if (-not (Get-NetFirewallRule -DisplayName "Skino Laravel 8000" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "Skino Laravel 8000" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 | Out-Null
        }
        Write-Host "Firewall rule for TCP 8000 is ready." -ForegroundColor Green
    }
}

Write-Section "Phone test"
Write-Host "1. Open one green API URL above in your phone browser with /health:"
Write-Host "   Example: http://YOUR_LAPTOP_IP:8000/api/health"
Write-Host "2. If it shows skino-laravel, paste this in Skino Settings:"
Write-Host "   http://YOUR_LAPTOP_IP:8000/api"
Write-Host "3. Tap Test, then Save."
