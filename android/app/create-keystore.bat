@echo off
echo Creando keystore para firma consistente...
echo.

REM Buscar keytool en ubicaciones comunes de Java
set KEYTOOL_PATH=""

REM Verificar si keytool está en PATH
where keytool >nul 2>&1
if %errorlevel% == 0 (
    set KEYTOOL_PATH=keytool
    echo ✅ keytool encontrado en PATH
    goto :create_keystore
)

REM Buscar en JAVA_HOME
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\keytool.exe" (
        set KEYTOOL_PATH="%JAVA_HOME%\bin\keytool.exe"
        echo ✅ keytool encontrado en JAVA_HOME: %JAVA_HOME%
        goto :create_keystore
    )
)

REM Buscar en ubicaciones comunes de Android Studio
if exist "%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe" (
    set KEYTOOL_PATH="%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe"
    echo ✅ keytool encontrado en Android SDK
    goto :create_keystore
)

REM Buscar en Program Files
for /d %%i in ("C:\Program Files\Java\jdk*") do (
    if exist "%%i\bin\keytool.exe" (
        set KEYTOOL_PATH="%%i\bin\keytool.exe"
        echo ✅ keytool encontrado en: %%i
        goto :create_keystore
    )
)

REM Buscar en Program Files (x86)
for /d %%i in ("C:\Program Files (x86)\Java\jdk*") do (
    if exist "%%i\bin\keytool.exe" (
        set KEYTOOL_PATH="%%i\bin\keytool.exe"
        echo ✅ keytool encontrado en: %%i
        goto :create_keystore
    )
)

REM Si no se encuentra keytool
echo ❌ ERROR: No se pudo encontrar keytool
echo.
echo keytool es necesario para crear el keystore. Opciones:
echo 1. Instalar Java JDK desde: https://adoptium.net/
echo 2. Instalar Android Studio (incluye Java)
echo 3. Agregar Java al PATH del sistema
echo.
echo Ubicaciones buscadas:
echo - PATH del sistema
echo - JAVA_HOME: %JAVA_HOME%
echo - Android SDK: %LOCALAPPDATA%\Android\Sdk\jre\bin\
echo - Program Files\Java\
echo - Program Files (x86)\Java\
echo.
pause
exit /b 1

:create_keystore
echo.
echo Usando keytool desde: %KEYTOOL_PATH%
echo.

REM Crear keystore con credenciales fijas
%KEYTOOL_PATH% -genkey -v ^
  -keystore upt-lab-keystore.jks ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias upt-lab-key ^
  -storepass upt123456 ^
  -keypass upt123456 ^
  -dname "CN=UPT Lab Support, OU=IT Department, O=Universidad Privada de Tacna, L=Tacna, S=Tacna, C=PE"

if %errorlevel% == 0 (
    echo.
    echo ✅ Keystore creado exitosamente!
    echo Archivo: upt-lab-keystore.jks
    echo Alias: upt-lab-key
    echo Contraseñas: upt123456
    echo.
    echo IMPORTANTE: Este keystore usa credenciales fijas para que la firma sea consistente
    echo entre diferentes builds y desarrolladores del equipo.
    echo.
    echo El archivo se ha creado en: %CD%\upt-lab-keystore.jks
) else (
    echo.
    echo ❌ ERROR: No se pudo crear el keystore
    echo Verifica que Java esté correctamente instalado
)

echo.
pause