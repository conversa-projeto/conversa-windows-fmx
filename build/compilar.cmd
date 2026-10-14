@echo off
rem ---------------------------------------------------------------------------------------------
rem Compila a nova base (Win64): app\Conversa.dproj e testes\ConversaTestes.dproj.
rem
rem Exige Delphi 12 com compilacao por linha de comando (Professional ou superior). Na edicao
rem Community o MSBuild responde "does not support command line compiling" e SAI COM CODIGO 0:
rem por isso este script confere o log e o exe gerado, nunca so o codigo de saida.
rem
rem Uso: build\compilar.cmd [Debug^|Release]
rem (mensagens sem acento de proposito: o cmd nao garante UTF-8)
rem ---------------------------------------------------------------------------------------------
setlocal
set "CONFIG=%~1"
if "%CONFIG%"=="" set "CONFIG=Debug"
set "RAIZ=%~dp0.."
if "%BDS%"=="" set "BDS=C:\Program Files (x86)\Embarcadero\Studio\23.0"

if not exist "%BDS%\bin\rsvars.bat" (
  echo Delphi nao encontrado em "%BDS%". Defina a variavel BDS.
  exit /b 2
)
call "%BDS%\bin\rsvars.bat"
if not exist "%RAIZ%\bin" mkdir "%RAIZ%\bin"

call :compilar "%RAIZ%\app\Conversa.dproj" "%RAIZ%\bin\Win64\%CONFIG%\Conversa.exe" || exit /b 1
call :compilar "%RAIZ%\testes\ConversaTestes.dproj" "%RAIZ%\bin\Win64\%CONFIG%\ConversaTestes.exe" || exit /b 1
echo.
echo Tudo compilado (%CONFIG%, Win64).
exit /b 0

:compilar
set "PROJ=%~1"
set "EXE=%~2"
set "LOGPROJ=%RAIZ%\bin\%~n1-%CONFIG%.log"
rem apaga o exe anterior: se nao aparecer um novo, a compilacao falhou (mesmo com codigo 0)
if exist "%EXE%" del /q "%EXE%"
echo Compilando %~nx1 (%CONFIG%, Win64)...
msbuild "%PROJ%" /t:Build /p:Config=%CONFIG% /p:Platform=Win64 /nologo /v:minimal /fl "/flp:LogFile=%LOGPROJ%;Verbosity=normal"
findstr /i /c:"does not support command line compiling" "%LOGPROJ%" >nul
if not errorlevel 1 (
  echo Esta edicao do Delphi nao compila por linha de comando. Compile pelo IDE.
  exit /b 3
)
findstr /r /i /c:"error E[0-9][0-9]*" "%LOGPROJ%" >nul
if not errorlevel 1 goto :falhou
findstr /i /c:"Fatal:" /c:"error MSB" /c:"error F" "%LOGPROJ%" >nul
if not errorlevel 1 goto :falhou
if not exist "%EXE%" (
  echo O executavel nao foi gerado: %EXE%
  echo Veja o log: %LOGPROJ%
  exit /b 1
)
echo   ok: %EXE%
exit /b 0

:falhou
echo Erros de compilacao. Veja o log: %LOGPROJ%
findstr /r /i /c:"error E[0-9][0-9]*" /c:"Fatal:" "%LOGPROJ%"
exit /b 1
