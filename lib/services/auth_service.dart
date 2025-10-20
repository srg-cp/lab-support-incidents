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
    // Agregar configuración específica para depuración
    signInOption: SignInOption.standard,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in con Google (solo para estudiantes @virtual.upt.pe)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('🔐 Iniciando proceso de autenticación con Google...');
        print('🔐 Verificando disponibilidad de Google Play Services...');
      }
      
      // Verificar si Google Sign In está disponible
      final bool isAvailable = await _googleSignIn.isSignedIn();
      if (kDebugMode) {
        print('🔐 Google Sign In disponible: $isAvailable');
      }
      
      // Cerrar sesión previa si existe
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      if (kDebugMode) {
        print('🔐 Sesiones previas cerradas');
        print('🔐 Iniciando Google Sign In...');
      }
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) {
          print('🔐 Usuario canceló el login de Google');
        }
        throw Exception('cancelled');
      }

      if (kDebugMode) {
        print('🔐 Usuario seleccionado: ${googleUser.email}');
        print('🔐 ID del usuario: ${googleUser.id}');
        print('🔐 Nombre del usuario: ${googleUser.displayName}');
      }

      // Verificar que el email no sea nulo
      if (googleUser.email.isEmpty) {
        if (kDebugMode) {
          print('🔐 Error: Email del usuario está vacío');
        }
        await _googleSignIn.signOut();
        throw Exception('No se pudo obtener el email del usuario');
      }

      // Verificar dominio institucional
      if (!googleUser.email.endsWith('@virtual.upt.pe')) {
        if (kDebugMode) {
          print('🔐 Dominio no válido: ${googleUser.email}');
        }
        await _googleSignIn.signOut();
        throw Exception('Debes usar tu correo institucional @virtual.upt.pe');
      }

      if (kDebugMode) {
        print('🔐 Obteniendo credenciales de Google...');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (kDebugMode) {
        print('🔐 Access Token presente: ${googleAuth.accessToken != null}');
        print('🔐 ID Token presente: ${googleAuth.idToken != null}');
        if (googleAuth.accessToken != null) {
          print('🔐 Access Token (primeros 20 chars): ${googleAuth.accessToken!.substring(0, 20)}...');
        }
        if (googleAuth.idToken != null) {
          print('🔐 ID Token (primeros 20 chars): ${googleAuth.idToken!.substring(0, 20)}...');
        }
      }
      
      // Verificar que tenemos los tokens necesarios
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        if (kDebugMode) {
          print('🔐 Error: Tokens de Google nulos');
          print('🔐 Access Token: ${googleAuth.accessToken}');
          print('🔐 ID Token: ${googleAuth.idToken}');
        }
        await _googleSignIn.signOut();
        throw Exception('Error al obtener credenciales de Google. Tokens nulos.');
      }
      
      if (kDebugMode) {
        print('🔐 Creando credenciales de Firebase...');
      }
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('🔐 Autenticando con Firebase...');
      }

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        if (kDebugMode) {
          print('🔐 Error: Usuario de Firebase es nulo');
        }
        throw Exception('Error al autenticar con Firebase');
      }
      
      if (kDebugMode) {
        print('🔐 Creando/actualizando usuario en Firestore...');
      }
      
      // Crear o actualizar documento de usuario
      await _createOrUpdateUser(userCredential.user!, 'student');
      
      if (kDebugMode) {
        print('🔐 ¡Autenticación exitosa!');
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
      if (kDebugMode) {
        print('🔐 Error en signInWithGoogle: $e');
        print('🔐 Tipo de error: ${e.runtimeType}');
      }
      
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

  // Crear o actualizar usuario en Firestore
  Future<void> _createOrUpdateUser(User user, String role) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Crear nuevo usuario
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
        'role': role,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Actualizar último login
      await _updateLastLogin(user.uid);
    }
  }

  // Actualizar último login
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Obtener rol del usuario
  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'student';
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}