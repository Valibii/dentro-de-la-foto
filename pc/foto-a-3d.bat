@echo off
REM Arrastra una o varias fotos encima de este archivo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0foto-a-3d.ps1" %*
