import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in con Google (solo para estudiantes @virtual.upt.pe)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // Verificar dominio institucional
      if (!googleUser.email.endsWith('@virtual.upt.pe')) {
        await _googleSignIn.signOut();
        throw Exception('Debes usar tu correo institucional @virtual.upt.pe');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Crear o actualizar documento de usuario
      await _createOrUpdateUser(userCredential.user!, 'student');
      
      return userCredential;
    } catch (e) {
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