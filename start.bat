@echo off
chcp 65001 > nul
title Stealth Animals 시작
rem 이 파일이 있는 폴더(프로젝트 폴더)에서 실행
cd /d "%~dp0"

echo [1/3] GitHub에서 최신 코드 받는 중...
git pull
if errorlevel 1 (
    echo.
    echo git pull 에 실패했어요. 위의 메시지를 Claude에게 보여 주세요.
    pause
    exit /b 1
)

echo.
echo [2/3] Rojo 서버 켜는 중... (새 창이 열려요. 작업하는 동안 닫지 마세요)
start "Rojo 서버 - 닫지 마세요" cmd /k rojo serve

echo.
echo [3/3] Roblox Studio 여는 중...
rem StealthAnimals.rbxl 이 있으면 그걸, 없으면 폴더 안의 아무 .rbxl 파일을 연다
set "PLACE="
if exist "StealthAnimals.rbxl" set "PLACE=StealthAnimals.rbxl"
if not defined PLACE for %%f in (*.rbxl *.rbxlx) do if not defined PLACE set "PLACE=%%f"
if not defined PLACE (
    echo 이 폴더에 게임 파일^(.rbxl^)이 없어요:
    echo   %CD%
    echo Studio에서 게임을 열고 파일 - 다른 이름으로 저장 으로 이 폴더에 StealthAnimals.rbxl 로 저장해 주세요.
    pause
    exit /b 0
)
echo %PLACE% 여는 중...
start "" "%PLACE%"

echo.
echo 준비 끝! Studio가 열리면 플러그인 탭 - Rojo - Connect 를 누르세요.
timeout /t 5 > nul
