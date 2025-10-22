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
      // Verificar si Google Sign In está disponible
      final bool isAvailable = await _googleSignIn.isSignedIn();
      
      // Cerrar sesión previa si existe
      await _googleSignIn.signOut();
      await _auth.signOut();
      
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
      
      // Crear o actualizar documento de usuario
      await _createOrUpdateUser(userCredential.user!, 'student');
      
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