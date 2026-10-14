@echo off
rem ---------------------------------------------------------------------------------------------
rem Compila (Debug, Win64) e roda os testes DUnitX. Sai com erro se a compilacao falhar ou se
rem algum teste falhar. O resultado em XML (NUnit) fica em bin\Win64\Debug\resultado-testes.xml.
rem
rem Sem licenca de linha de comando: compile testes\ConversaTestes.dproj pelo IDE e rode
rem bin\Win64\Debug\ConversaTestes.exe.
rem ---------------------------------------------------------------------------------------------
setlocal
set "RAIZ=%~dp0.."
call "%~dp0compilar.cmd" Debug
if errorlevel 1 exit /b %ERRORLEVEL%
"%RAIZ%\bin\Win64\Debug\ConversaTestes.exe" --exitbehavior:Continue "--xmlfile:%RAIZ%\bin\Win64\Debug\resultado-testes.xml"
if errorlevel 1 (
  echo.
  echo Ha testes falhando.
  exit /b 1
)
echo.
echo Todos os testes passaram.
exit /b 0
