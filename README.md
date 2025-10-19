# 🔥 Configuración de Firebase para UPT Lab Incidents

## 📋 Pasos Previos

### 1. Crear Proyecto en Firebase Console
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto llamado "UPT Lab Incidents"
3. Habilita Google Analytics (opcional)

### 2. Configurar Firebase para Android

#### 2.1 Agregar App Android
1. En Firebase Console, haz clic en "Agregar aplicación" → Android
2. Package name: `com.upt.lab_incidents` (o el que prefieras)
3. Descarga el archivo `google-services.json`
4. Coloca el archivo en `android/app/google-services.json`

#### 2.2 Modificar archivos Android

**android/build.gradle** (proyecto):
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/build.gradle**:
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        multiDexEnabled true
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

### 3. Configurar Firebase para iOS

#### 3.1 Agregar App iOS
1. En Firebase Console, haz clic en "Agregar aplicación" → iOS
2. Bundle ID: `com.upt.labIncidents` (o el que prefieras)
3. Descarga el archivo `GoogleService-Info.plist`
4. Abre tu proyecto en Xcode
5. Arrastra el archivo `GoogleService-Info.plist` a `ios/Runner/`

#### 3.2 Modificar archivo iOS

**ios/Runner/Info.plist**:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Tu REVERSED_CLIENT_ID del GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 4. Habilitar Servicios en Firebase Console

#### 4.1 Authentication
1. Ve a **Authentication** → **Sign-in method**
2. Habilita **Google** como proveedor
3. Configura el correo de soporte del proyecto
4. Para Google Sign-In, asegúrate de agregar los SHA-1 y SHA-256 de tu app Android

#### 4.2 Cloud Firestore
1. Ve a **Firestore Database** → **Crear base de datos**
2. Selecciona modo **Producción** o **Prueba**
3. Elige la ubicación más cercana (preferiblemente `southamerica-east1`)

**Reglas de seguridad sugeridas para Firestore:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Incidentes
    match /incidents/{incidentId} {
      // Estudiantes pueden crear y leer sus propios incidentes
      allow create: if request.auth != null 
                    && request.auth.token.email.matches('.*@virtual.upt.pe');
      
      // Cualquier usuario autenticado puede leer
      allow read: if request.auth != null;
      
      // Admin y soporte pueden actualizar
      allow update: if request.auth != null 
                    && (request.auth.token.role == 'admin' 
                        || request.auth.token.role == 'support');
    }
    
    // Usuarios (para roles)
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.auth.token.role == 'admin';
    }
    
    // Laboratorios
    match /labs/{labId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.auth.token.role == 'admin';
    }
  }
}
```

#### 4.3 Storage
1. Ve a **Storage** → **Comenzar**
2. Selecciona ubicación (preferiblemente `southamerica-east1`)

**Reglas de seguridad sugeridas para Storage:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /incidents/{incidentId}/{allPaths=**} {
      // Cualquier usuario autenticado puede subir evidencia
      allow write: if request.auth != null;
      // Cualquier usuario autenticado puede leer
      allow read: if request.auth != null;
    }
    
    match /resolutions/{incidentId}/{allPaths=**} {
      // Solo soporte y admin pueden subir resoluciones
      allow write: if request.auth != null 
                   && (request.auth.token.role == 'admin' 
                       || request.auth.token.role == 'support');
      // Cualquier usuario autenticado puede leer
      allow read: if request.auth != null;
    }
  }
}
```

### 5. Estructura de Datos en Firestore

#### Colección: `incidents`
```json
{
  "id": "auto-generated-id",
  "labName": "A",
  "computerNumbers": [5, 6],
  "incidentType": "Pantallazo azul",
  "description": "Descripción adicional...",
  "status": "pending", // pending | inProgress | resolved
  "reportedBy": {
    "uid": "user-id",
    "name": "Juan Pérez",
    "email": "juan.perez@virtual.upt.pe"
  },
  "reportedAt": "timestamp",
  "assignedTo": {
    "uid": "support-id",
    "name": "Carlos Ruiz"
  },
  "assignedAt": "timestamp",
  "resolvedAt": "timestamp",
  "evidenceUrl": "storage-url",
  "resolutionUrl": "storage-url",
  "resolutionNotes": "Notas de resolución..."
}
```

#### Colección: `users`
```json
{
  "uid": "user-id",
  "email": "usuario@example.com",
  "name": "Nombre Usuario",
  "role": "student", // student | admin | support
  "createdAt": "timestamp",
  "lastLogin": "timestamp"
}
```

#### Colección: `labs`
```json
{
  "name": "A",
  "studentComputers": 20,
  "teacherComputers": 1,
  "totalComputers": 21,
  "lastUpdated": "timestamp"
}
```

### 6. Configurar Roles Personalizados (Custom Claims)

Para establecer roles de usuario, necesitarás usar Firebase Admin SDK desde Cloud Functions o tu backend.

**Ejemplo con Cloud Functions:**

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

exports.setUserRole = functions.https.onCall(async (data, context) => {
  // Verificar que quien llama es admin
  if (context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Solo los administradores pueden asignar roles.'
    );
  }

  const { uid, role } = data;
  
  await admin.auth().setCustomUserClaims(uid, { role });
  
  return { message: `Rol ${role} asignado exitosamente` };
});
```

### 7. Permisos Android (AndroidManifest.xml)

**android/app/src/main/AndroidManifest.xml**:
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

### 8. Permisos iOS (Info.plist)

**ios/Runner/Info.plist**:
```xml
<key>NSCameraUsageDescription</key>
<string>La app necesita acceso a la cámara para tomar fotos de evidencia.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>La app necesita acceso a la galería para seleccionar fotos de evidencia.</string>
<key>NSMicrophoneUsageDescription</key>
<string>La app necesita acceso al micrófono para grabar videos.</string>
```

### 9. Comandos de Instalación

Después de configurar todo lo anterior, ejecuta:

```bash
# Limpiar proyecto
flutter clean

# Obtener dependencias
flutter pub get

# Para Android
cd android
./gradlew clean
cd ..

# Para iOS
cd ios
pod install
cd ..

# Ejecutar la app
flutter run
```

### 10. Inicializar Datos de Prueba

Una vez configurado, puedes crear datos iniciales en Firestore:

1. Ve a Firestore Console
2. Crea la colección `labs` manualmente con los laboratorios A-F
3. Configura el primer usuario admin manualmente usando Firebase Console

### 🔐 Notas de Seguridad

- Nunca compartas tus archivos `google-services.json` o `GoogleService-Info.plist` públicamente
- Mantén las reglas de seguridad de Firestore y Storage restrictivas
- Usa variables de entorno para información sensible
- Habilita App Check para proteger contra abuso de API

### 📱 Testing

Para probar la app:

1. **Estudiante**: Usa una cuenta de Google con dominio @virtual.upt.pe
2. **Admin/Soporte**: Crea usuarios manualmente en Firebase Authentication y asigna roles usando Cloud Functions

### 🚀 Deployment

Para desplegar la app en producción:

1. Genera APK para Android: `flutter build apk --release`
2. Genera IPA para iOS: `flutter build ios --release`
3. Publica en Google Play Store y Apple App Store

---