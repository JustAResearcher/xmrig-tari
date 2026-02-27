@echo off
title Tari Miner (rx/tari)
setlocal

:: ================================================================
::  Tari CPU Miner - uses xmrig-tari with rx/tari algorithm
::  Bridge: 192.168.68.78:18180 (change to public IP if remote)
:: ================================================================

set BRIDGE=192.168.68.78:18180
set MINER=xmrig-tari.exe
set CONFIG=config_tari.json

:: Download miner if not present
if not exist "%MINER%" (
    echo Downloading xmrig-tari...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/JustAResearcher/xmrig-tari/releases/latest/download/xmrig-tari.exe' -OutFile '%MINER%'"
    if not exist "%MINER%" (
        echo ERROR: Download failed. Get it manually from:
        echo https://github.com/JustAResearcher/xmrig-tari/releases/latest
        pause
        exit /b 1
    )
    echo Download complete.
)

:: Create config if not present
if not exist "%CONFIG%" (
    echo Creating %CONFIG%...
    (
        echo {
        echo     "pools": [
        echo         {
        echo             "url": "%BRIDGE%",
        echo             "user": "default",
        echo             "pass": "x",
        echo             "coin": "TARI",
        echo             "algo": "rx/tari",
        echo             "daemon": true,
        echo             "daemon-poll-interval": 1000
        echo         }
        echo     ],
        echo     "cpu": {
        echo         "enabled": true,
        echo         "huge-pages": true,
        echo         "huge-pages-jit": true,
        echo         "yield": false,
        echo         "asm": true
        echo     },
        echo     "donate-level": 0,
        echo     "donate-over-proxy": 0,
        echo     "print-time": 10,
        echo     "randomx": {
        echo         "mode": "auto",
        echo         "1gb-pages": true,
        echo         "rdmsr": true,
        echo         "wrmsr": true
        echo     }
        echo }
    ) > "%CONFIG%"
)

echo.
echo  ========================================
echo   Tari Miner - rx/tari
echo   Bridge: %BRIDGE%
echo   Press Ctrl+C to stop
echo  ========================================
echo.

:: Launch miner (run as admin for MSR/hugepages boost)
%MINER% --config %CONFIG%

pause
