@echo off
echo Obteniendo huellas digitales del keystore...
echo.

REM Buscar keytool (mismo código que create-keystore.bat)
set KEYTOOL_PATH=""

where keytool >nul 2>&1
if %errorlevel% == 0 (
    set KEYTOOL_PATH=keytool
    goto :get_fingerprints
)

if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\keytool.exe" (
        set KEYTOOL_PATH="%JAVA_HOME%\bin\keytool.exe"
        goto :get_fingerprints
    )
)

if exist "%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe" (
    set KEYTOOL_PATH="%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe"
    goto :get_fingerprints
)

for /d %%i in ("C:\Program Files\Java\jdk*") do (
    if exist "%%i\bin\keytool.exe" (
        set KEYTOOL_PATH="%%i\bin\keytool.exe"
        goto :get_fingerprints
    )
)

for /d %%i in ("C:\Program Files (x86)\Java\jdk*") do (
    if exist "%%i\bin\keytool.exe" (
        set KEYTOOL_PATH="%%i\bin\keytool.exe"
        goto :get_fingerprints
    )
)

echo ❌ ERROR: No se pudo encontrar keytool
pause
exit /b 1

:get_fingerprints
echo Usando keytool desde: %KEYTOOL_PATH%
echo.

echo ==========================================
echo HUELLAS DIGITALES PARA FIREBASE
echo ==========================================
echo.

%KEYTOOL_PATH% -list -v -keystore upt-lab-keystore.jks -alias upt-lab-key -storepass upt123456

echo.
echo ==========================================
echo INSTRUCCIONES:
echo ==========================================
echo.
echo 1. Copia las huellas SHA-1 y SHA-256 de arriba
echo 2. Ve a Firebase Console: https://console.firebase.google.com/
echo 3. Selecciona tu proyecto: upt-lab-support-incident-eeba9
echo 4. Ve a Configuración del proyecto (ícono de engranaje)
echo 5. En la pestaña "General", busca tu app Android
echo 6. Haz clic en "Agregar huella digital"
echo 7. Pega las huellas SHA-1 y SHA-256
echo 8. Descarga el nuevo google-services.json
echo.
pause