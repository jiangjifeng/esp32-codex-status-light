@echo off
setlocal

if not defined IDF_TOOLS_PATH set "IDF_TOOLS_PATH=C:\Espressif\tools"
if not defined IDF_EXPORT_PS1 set "IDF_EXPORT_PS1=C:\Espressif\frameworks\esp-idf-v6.0.2\export.ps1"
if not defined IDF_PYTHON_DIR set "IDF_PYTHON_DIR=%LOCALAPPDATA%\Programs\Python\Python312"
set "PROJECT_DIR=%~dp0hello_world"

powershell -NoExit -ExecutionPolicy Bypass -Command "$env:Path='%IDF_PYTHON_DIR%;%IDF_PYTHON_DIR%\Scripts;' + $env:Path; $env:IDF_TOOLS_PATH='%IDF_TOOLS_PATH%'; . '%IDF_EXPORT_PS1%'; Set-Location '%PROJECT_DIR%'"
