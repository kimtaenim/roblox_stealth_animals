@echo off
chcp 65001 > nul
title Stealth Animals 시작
rem 이 파일이 있는 폴더(프로젝트 폴더)에서 실행
cd /d "%~dp0"

rem ---------------------------------------------------------------
rem 1. 최신 코드 받기 (실패해도 계속 진행)
rem ---------------------------------------------------------------
echo [1/3] GitHub에서 최신 코드 받는 중...
git pull
if errorlevel 1 echo    ! git pull 실패. 예전 코드로 계속합니다. 위 메시지를 Claude에게 보여 주세요.

rem ---------------------------------------------------------------
rem 2. Rojo 서버 켜기 (src 폴더만 있으면 됨, 게임 파일과 상관없음)
rem ---------------------------------------------------------------
echo.
echo [2/3] Rojo 서버 켜는 중... (새 창이 열려요. 작업하는 동안 닫지 마세요)
start "Rojo 서버 - 닫지 마세요" cmd /k rojo serve

rem ---------------------------------------------------------------
rem 3. Studio 열기: 폴더에 게임 파일이 있으면 그 파일로, 없으면 Studio만
rem ---------------------------------------------------------------
echo.
echo [3/3] Roblox Studio 여는 중...
set "PLACE="
if exist "StealthAnimals.rbxl" set "PLACE=StealthAnimals.rbxl"
if not defined PLACE for %%f in (*.rbxl *.rbxlx) do if not defined PLACE set "PLACE=%%f"

if defined PLACE (
    echo    %PLACE% 파일을 엽니다.
    start "" "%PLACE%"
) else (
    set "STUDIO="
    for /f "delims=" %%s in ('dir /b /s "%LOCALAPPDATA%\Roblox\Versions\RobloxStudioBeta.exe" 2^>nul') do set "STUDIO=%%s"
    call :openStudio
)

echo.
echo 준비 끝! Studio에서 플러그인 탭 - Rojo - Connect 를 누르세요.
timeout /t 8 > nul
exit /b 0

:openStudio
if defined STUDIO (
    echo    이 폴더에 게임 파일이 없어서 Studio만 엽니다.
    echo    새 Baseplate를 연 뒤 "파일 - 다른 이름으로 저장"으로 이 폴더에 저장해 두면 다음부터 바로 열려요:
    echo      %CD%
    start "" "%STUDIO%"
) else (
    echo    Roblox Studio를 찾지 못했어요. 시작 메뉴에서 직접 열어 주세요.
)
exit /b 0
