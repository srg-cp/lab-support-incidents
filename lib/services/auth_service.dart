import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Configuración del Client ID para web (necesario para Flutter Web)
    clientId: '63833424445-grc16ame64r65bgmscndh8adbguqo5hc.apps.googleusercontent.com',
    // // Agregar configuración específica para depuración
    // signInOption: SignInOption.standard,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in con Google (solo para estudiantes @virtual.upt.pe)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Solo cerrar sesión de Google Sign In si es necesario
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('cancelled');
      }

      // Verificar que el email no sea nulo
      if (googleUser.email.isEmpty) {
        await _googleSignIn.signOut();
        throw Exception('No se pudo obtener el email del usuario');
      }

      // Verificar dominio institucional
      if (!googleUser.email.endsWith('@virtual.upt.pe')) {
        await _googleSignIn.signOut();
        throw Exception('Debes usar tu correo institucional @virtual.upt.pe');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Verificar que tenemos al menos el accessToken
      if (googleAuth.accessToken == null) {
        await _googleSignIn.signOut();
        throw Exception('Error al obtener credenciales de Google. Access Token nulo.');
      }
      
      // En web, el idToken puede ser null, pero podemos continuar con accessToken
      if (googleAuth.idToken == null && kIsWeb) {
        // Continuar con Access Token únicamente
      } else if (googleAuth.idToken == null) {
        await _googleSignIn.signOut();
        throw Exception('Error al obtener ID Token de Google.');
      }
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Error al autenticar con Firebase');
      }
      
      print('✅ Usuario autenticado con Google, UID: ${userCredential.user!.uid}');
      print('📧 Email: ${userCredential.user!.email}');
      
      // Crear o actualizar documento de usuario de forma asíncrona
      // Solo para estudiantes con email institucional
      if (userCredential.user!.email != null && userCredential.user!.email!.endsWith('@virtual.upt.pe')) {
        _createOrUpdateUser(userCredential.user!, 'student').then((_) {
          print('✅ Documento de estudiante procesado correctamente');
        }).catchError((e) {
          print('❌ Error al crear/actualizar documento de estudiante: $e');
          // No afecta el login exitoso
        });
      } else {
        print('🚫 Email no institucional - no se creará documento automáticamente');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('Esta cuenta ya existe con un método de autenticación diferente');
        case 'invalid-credential':
          throw Exception('Credenciales inválidas');
        case 'operation-not-allowed':
          throw Exception('Operación no permitida');
        case 'user-disabled':
          throw Exception('Usuario deshabilitado');
        case 'user-not-found':
          throw Exception('Usuario no encontrado');
        case 'wrong-password':
          throw Exception('Contraseña incorrecta');
        case 'network-request-failed':
          throw Exception('Error de conexión. Verifica tu internet.');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      await _googleSignIn.signOut();
      
      // Manejar errores específicos de Google Sign In
      if (e.toString().contains('sign_in_canceled')) {
        throw Exception('cancelled');
      } else if (e.toString().contains('ClientID not set')) {
        throw Exception('Error de configuración: Client ID no configurado. Contacta al administrador.');
      } else if (e.toString().contains('network_error')) {
        throw Exception('Error de conexión. Verifica tu internet.');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Error al iniciar sesión con Google. Inténtalo de nuevo.');
      } else if (e.toString().contains('account_exists_with_different_credential')) {
        throw Exception('Esta cuenta ya existe con un método de autenticación diferente');
      } else if (e.toString().contains('invalid_credential')) {
        throw Exception('Credenciales inválidas. Verifica tu configuración.');
      }
      
      rethrow;
    }
  }

  // Sign in con email y contraseña (para admin/soporte)
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Actualizar último login
      await _updateLastLogin(userCredential.user!.uid);
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }



  // ESTA FUNCIÓN NO DEBERÍA EXISTIR - ELIMINAR
  // Los usuarios deben ser creados explícitamente, no automáticamente
  Future<void> _ensureUserDocument(User user) async {
    // FUNCIÓN PROBLEMÁTICA - NO USAR
    throw Exception('Esta función no debe ser utilizada. Los usuarios deben ser creados explícitamente.');
  }

  // Crear documento de usuario directamente (para creación manual)
  Future<void> _createUserDocumentDirectly(User user, String name, String role) async {
    try {
      print('📝 Creando documento directamente para UID: ${user.uid}');
      
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'name': name, // Usar el nombre proporcionado directamente
        'role': role,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };
      
      print('📋 Datos a guardar: $userData');
      
      await userDoc.set(userData);
      
      print('✅ Documento creado exitosamente');
      
      // Verificar que el documento se creó
      final verificationDoc = await userDoc.get();
      if (verificationDoc.exists) {
        print('✅ Verificación exitosa: El documento existe en Firestore');
        print('📄 Datos guardados: ${verificationDoc.data()}');
      } else {
        throw Exception('El documento no se pudo verificar después de crearlo');
      }
    } catch (e) {
      print('❌ Error en _createUserDocumentDirectly: $e');
      rethrow;
    }
  }

  // Crear o actualizar usuario en Firestore
  Future<void> _createOrUpdateUser(User user, String role, {bool throwOnError = false}) async {
    try {
      print('🔄 Iniciando _createOrUpdateUser para UID: ${user.uid}');
      print('📧 Email: ${user.email}');
      print('👤 Rol: $role');
      
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        print('📝 Creando nuevo documento de usuario...');
        
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
          'role': role,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        };
        
        print('📋 Datos a guardar: $userData');
        
        await userDoc.set(userData);
        
        print('✅ Documento de usuario creado exitosamente');
        
        // Verificar que el documento se creó correctamente (sin lanzar excepción si falla)
        try {
          final verificationDoc = await userDoc.get();
          if (verificationDoc.exists) {
            print('✅ Verificación exitosa: El documento existe en Firestore');
            print('📄 Datos guardados: ${verificationDoc.data()}');
          } else {
            print('⚠️ Advertencia: No se pudo verificar la creación del documento');
          }
        } catch (e) {
          print('⚠️ Advertencia: Error al verificar la creación del documento: $e');
        }
      } else {
        print('📄 Usuario ya existe, actualizando último login...');
        // Actualizar último login (sin lanzar excepción si falla)
        try {
          await _updateLastLogin(user.uid);
          print('✅ Último login actualizado');
        } catch (e) {
          print('⚠️ Advertencia: Error al actualizar último login: $e');
        }
      }
    } catch (e) {
      print('❌ Error en _createOrUpdateUser: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      
      if (throwOnError) {
        // Para creación manual de usuarios, propagar el error
        rethrow;
      }
      // Para autenticación automática (Google OAuth), no interrumpir el flujo
      // El usuario podrá autenticarse aunque haya problemas con el documento
    }
  }

  // Actualizar último login
  Future<void> _updateLastLogin(String uid) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();
      
      if (docSnapshot.exists) {
        await userDoc.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('✅ Último login actualizado para UID: $uid');
      } else {
        print('⚠️ Documento no existe para UID: $uid, no se puede actualizar último login');
        // El documento debería existir en este punto, pero si no existe,
        // no intentamos crearlo aquí para evitar conflictos
      }
    } catch (e) {
      print('❌ Error al actualizar último login para UID $uid: $e');
      // No hacer rethrow para no interrumpir el flujo de autenticación
    }
  }

  // Obtener rol del usuario
  Future<String> getUserRole(String uid) async {
    print('🔍 Obteniendo rol para UID: $uid');
    
    final doc = await _firestore.collection('users').doc(uid).get();
    
    if (doc.exists) {
      final userData = doc.data();
      final role = userData?['role'];
      
      if (role == null) {
        print('⚠️ Documento existe pero no tiene rol definido');
        throw Exception('Usuario sin rol definido en la base de datos');
      }
      
      print('📄 Documento encontrado');
      print('📋 Datos del usuario: $userData');
      print('👤 Rol obtenido: $role');
      
      return role;
    }
    
    print('❌ No se encontró documento para UID: $uid');
    
    // NO reparar automáticamente - lanzar error para usuarios no autorizados
    final currentAuthUser = _auth.currentUser;
    if (currentAuthUser != null && currentAuthUser.uid == uid) {
      print('🚫 Usuario no autorizado - no existe en base de datos');
      
      // Solo permitir estudiantes con email institucional
      if (currentAuthUser.email != null && currentAuthUser.email!.endsWith('@virtual.upt.pe')) {
        print('🔧 Creando estudiante con email institucional...');
        try {
          await _createOrUpdateUser(currentAuthUser, 'student');
          print('✅ Estudiante creado exitosamente');
          return 'student';
        } catch (e) {
          print('❌ Error al crear estudiante: $e');
          throw Exception('Error al crear estudiante: $e');
        }
      } else {
        throw Exception('Usuario no autorizado. Debe ser creado por un administrador.');
      }
    }
    
    throw Exception('Usuario no encontrado en la base de datos.');
  }

  // Verificar documento de usuario - NO CREAR AUTOMÁTICAMENTE
  Future<bool> verifyAndRepairUserDocument() async {
    final user = currentUser;
    if (user == null) {
      print('❌ No hay usuario autenticado');
      return false;
    }

    try {
      print('🔍 Verificando documento para usuario: ${user.uid}');
      
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        print('🚫 Documento faltante - NO SE CREARÁ AUTOMÁTICAMENTE');
        
        // SOLO permitir estudiantes con email institucional
        if (user.email != null && user.email!.endsWith('@virtual.upt.pe')) {
          print('🔧 Creando estudiante con email institucional...');
          await _createOrUpdateUser(user, 'student');
          print('✅ Documento de estudiante creado exitosamente');
          return true;
        } else {
          print('🚫 Usuario no autorizado - debe ser creado por administrador');
          return false;
        }
      } else {
        print('✅ Documento ya existe');
        return true;
      }
    } catch (e) {
      print('❌ Error al verificar documento: $e');
      return false;
    }
  }

  // IMPORTANTE: Solo se pueden crear usuarios con roles 'admin' o 'support'
  // Los estudiantes se registran automáticamente con Google usando @virtual.upt.pe
  Future<UserCredential> createUserWithEmailPassword(
    String email, 
    String password, 
    String name, 
    String role
  ) async {
    try {
      print('🚀 Iniciando creación de usuario con email y contraseña');
      print('📧 Email: $email');
      print('👤 Nombre: $name');
      print('🔑 Rol: $role');
      
      // Validación: No permitir crear estudiantes manualmente
      if (role == 'student') {
        throw Exception('No se pueden crear estudiantes manualmente. Los estudiantes se registran automáticamente con Google.');
      }
      
      // Validación: Solo permitir roles válidos
      if (!['admin', 'support'].contains(role)) {
        throw Exception('Rol inválido. Solo se permiten roles: admin, support');
      }
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Error: No se pudo crear el usuario en Firebase Auth');
      }
      
      print('✅ Usuario creado en Firebase Auth con UID: ${userCredential.user!.uid}');
      
      // Crear documento en Firestore directamente (sin updateDisplayName que causa problemas)
      try {
        await _createUserDocumentDirectly(userCredential.user!, name, role);
        print('✅ Documento de Firestore creado exitosamente');
        
        // IMPORTANTE: Cerrar sesión del usuario recién creado para evitar conflictos
        // El usuario debe hacer login manualmente después de ser creado
        await _auth.signOut();
        print('🚪 Usuario desconectado después de creación exitosa');
        
        return userCredential;
      } catch (firestoreError) {
        print('❌ Error al crear documento en Firestore: $firestoreError');
        
        // Si falla la creación del documento, eliminar el usuario de Auth también
        try {
          await userCredential.user!.delete();
          print('🗑️ Usuario eliminado de Auth debido a error en Firestore');
        } catch (deleteError) {
          print('⚠️ No se pudo eliminar usuario de Auth: $deleteError');
        }
        
        throw Exception('Error al crear el documento del usuario en Firestore: $firestoreError');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('El email ya está en uso');
        case 'invalid-email':
          throw Exception('Email inválido');
        case 'weak-password':
          throw Exception('La contraseña es muy débil');
        case 'operation-not-allowed':
          throw Exception('Operación no permitida');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      print('❌ Error general en createUserWithEmailPassword: $e');
      rethrow;
    }
  }

  // Obtener todos los usuarios (solo para admin)
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  // Obtener solo estudiantes (solo para admin)
  Stream<QuerySnapshot> getStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots();
  }

  // Obtener usuarios que no son estudiantes (admin y support)
  Stream<QuerySnapshot> getNonStudentUsers() {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['admin', 'support'])
        .snapshots();
  }

  // Actualizar rol de usuario (solo para admin)
  Future<void> updateUserRole(String uid, String newRole) async {
    // Validación: No permitir asignar rol "student" manualmente
    if (newRole == 'student') {
      throw Exception('No se puede asignar el rol "student" manualmente. Los estudiantes se registran automáticamente con Google.');
    }
    
    // Validación: Solo permitir roles válidos
    if (!['admin', 'support'].contains(newRole)) {
      throw Exception('Rol inválido. Solo se permiten roles: admin, support');
    }
    
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar usuario (solo para admin)
  Future<void> deleteUser(String uid) async {
    // Eliminar documento de Firestore
    await _firestore.collection('users').doc(uid).delete();
    
    // Nota: Para eliminar completamente el usuario de Firebase Auth,
    // necesitarías usar Firebase Admin SDK desde Cloud Functions
  }

  // Verificar si el usuario actual es admin
  Future<bool> isCurrentUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    
    final role = await getUserRole(user.uid);
    return role == 'admin';
  }

  // Verificar integridad de todos los usuarios (solo para admin)
  Future<Map<String, dynamic>> verifyAllUsersIntegrity() async {
    try {
      print('🔍 Iniciando verificación de integridad de usuarios...');
      
      // Obtener todos los documentos de usuarios en Firestore
      final firestoreUsers = await _firestore.collection('users').get();
      final firestoreUids = firestoreUsers.docs.map((doc) => doc.id).toSet();
      
      print('📄 Usuarios en Firestore: ${firestoreUids.length}');
      
      // Nota: No podemos obtener todos los usuarios de Firebase Auth sin Admin SDK
      // Este método se enfoca en verificar que los documentos existentes estén completos
      
      int validUsers = 0;
      int repairedUsers = 0;
      List<String> errors = [];
      
      for (final doc in firestoreUsers.docs) {
        try {
          final userData = doc.data();
          final uid = doc.id;
          
          // Verificar campos requeridos
          final requiredFields = ['uid', 'email', 'name', 'role', 'createdAt'];
          bool needsRepair = false;
          
          for (final field in requiredFields) {
            if (!userData.containsKey(field) || userData[field] == null) {
              needsRepair = true;
              break;
            }
          }
          
          if (needsRepair) {
            print('🔧 Reparando documento para UID: $uid');
            
            // Intentar reparar con datos básicos
            final updates = <String, dynamic>{};
            
            if (!userData.containsKey('uid') || userData['uid'] == null) {
              updates['uid'] = uid;
            }
            if (!userData.containsKey('role') || userData['role'] == null) {
              // NUNCA asignar rol automáticamente en reparación
              final email = userData['email'] as String?;
              print('🚫 Documento sin rol encontrado para email: $email');
              print('🚫 NO se asignará rol automáticamente - debe ser creado por administrador');
              // Saltar este documento - debe ser creado manualmente por admin
              continue;
            }
            if (!userData.containsKey('createdAt') || userData['createdAt'] == null) {
              updates['createdAt'] = FieldValue.serverTimestamp();
            }
            if (!userData.containsKey('lastLogin') || userData['lastLogin'] == null) {
              updates['lastLogin'] = FieldValue.serverTimestamp();
            }
            
            if (updates.isNotEmpty) {
              await _firestore.collection('users').doc(uid).update(updates);
              repairedUsers++;
              print('✅ Documento reparado para UID: $uid');
            }
          } else {
            validUsers++;
          }
        } catch (e) {
          errors.add('Error procesando UID ${doc.id}: $e');
          print('❌ Error procesando UID ${doc.id}: $e');
        }
      }
      
      final result = {
        'totalUsers': firestoreUids.length,
        'validUsers': validUsers,
        'repairedUsers': repairedUsers,
        'errors': errors,
        'success': errors.isEmpty,
      };
      
      print('📊 Resultado de verificación: $result');
      return result;
      
    } catch (e) {
      print('❌ Error en verificación de integridad: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}