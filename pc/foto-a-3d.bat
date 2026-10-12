@echo off
REM Doble clic: convierte las fotos nuevas de la carpeta "fotos".
REM O arrastra fotos encima de este archivo para convertir solo esas.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0foto-a-3d.ps1" %*
