@echo off
chcp 65001 > nul
title Stealth Animals 게임 파일 GitHub 백업
rem 이 파일이 있는 폴더(프로젝트 폴더)에서 실행
cd /d "%~dp0"

if not exist "StealthAnimals.rbxl" (
    echo StealthAnimals.rbxl 파일이 이 폴더에 없어요:
    echo   %CD%
    echo Studio에서 이 폴더에 StealthAnimals.rbxl 로 저장한 뒤 다시 실행해 주세요.
    pause
    exit /b 1
)

echo Studio에서 Ctrl+S 로 저장했는지 확인하세요. 계속하려면 아무 키나 누르세요.
pause > nul

echo.
echo [1/3] GitHub의 최신 코드와 맞추는 중...
git pull
if errorlevel 1 (
    echo    ! git pull 실패. 위 메시지를 Claude에게 보여 주세요.
    pause
    exit /b 1
)

echo.
echo [2/3] 게임 파일 기록 중...
git add StealthAnimals.rbxl
git diff --cached --quiet
if not errorlevel 1 (
    echo    바뀐 게 없어서 올릴 필요가 없어요. 이미 최신 백업이에요.
    pause
    exit /b 0
)
git commit -m "Studio 게임 파일 백업 %date% %time:~0,5%"

echo.
echo [3/3] GitHub에 올리는 중... (처음이면 GitHub 로그인 창이 뜰 수 있어요)
git push
if errorlevel 1 (
    echo    ! 올리기 실패. 위 메시지를 Claude에게 보여 주세요.
    pause
    exit /b 1
)

echo.
echo 백업 끝! GitHub에 게임 파일이 저장됐어요.
timeout /t 8 > nul
