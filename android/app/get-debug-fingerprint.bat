@echo off
setlocal EnableDelayedExpansion
echo Obteniendo huella digital del keystore de DEBUG...
echo.

REM Buscar keytool
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

for /d %%i in ("C:\Program Files\Java\jdk*") do (
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
echo KEYSTORE DE DEBUG (para flutter run)
echo ==========================================
echo.

REM Buscar el keystore de debug de Android
set DEBUG_KEYSTORE=""

if exist "%USERPROFILE%\.android\debug.keystore" (
    set DEBUG_KEYSTORE="%USERPROFILE%\.android\debug.keystore"
    echo Keystore de debug encontrado en: !DEBUG_KEYSTORE!
    echo.
    %KEYTOOL_PATH% -list -v -keystore !DEBUG_KEYSTORE! -alias androiddebugkey -storepass android -keypass android
) else (
    echo ❌ No se encontró el keystore de debug en %USERPROFILE%\.android\debug.keystore
    echo.
    echo Ejecuta 'flutter run' una vez para que se genere automáticamente
)

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
echo 7. Agrega las huellas SHA-1 y SHA-256 del DEBUG
echo 8. Descarga el nuevo google-services.json
echo 9. Reemplaza el archivo en android/app/google-services.json
echo.
echo IMPORTANTE: Necesitas AMBAS huellas digitales en Firebase:
echo - La de RELEASE (que ya tienes): 3E:85:F7:5F:C1:8E:F8:D1:62:34:F0:C0:A6:17:B3:F5:C9:19:79:89
echo - La de DEBUG (nueva): la que aparece arriba
echo.
pause