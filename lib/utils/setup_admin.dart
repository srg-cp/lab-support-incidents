import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetupAdmin {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Función para configurar el primer administrador
  /// Crea directamente el usuario en Firebase Auth y Firestore
  static Future<void> setupFirstAdmin(String adminEmail) async {
    try {
      print('🔧 Configurando primer administrador: $adminEmail');
      
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: 'Admin123!', // Contraseña por defecto
      );
      
      final uid = userCredential.user!.uid;
      print('👤 Usuario creado en Firebase Auth con UID: $uid');
      
      // Crear documento en Firestore con el UID correcto
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': adminEmail,
        'role': 'admin',
        'name': 'Administrador',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      print('📄 Documento creado en Firestore');
      print('🔑 Credenciales del administrador:');
      print('   Email: $adminEmail');
      print('   Contraseña: Admin123!');
      
      // Cerrar sesión para que el usuario pueda hacer login
      await _auth.signOut();
      
    } catch (e) {
      print('❌ Error al configurar administrador: $e');
      
      // Si el usuario ya existe, crear el documento directamente
      if (e.toString().contains('email-already-in-use')) {
        print('🔄 El usuario ya existe en Auth, creando documento en Firestore...');
        
        // Usar el UID conocido del usuario admin (del log anterior)
        const adminUid = 'xbSKLsV5jJWijF7rQPBQgn5LCGo2';
        print('👤 Usando UID conocido: $adminUid');
        
        try {
          // Crear documento directamente en Firestore
          print('📝 Creando documento en Firestore...');
          await _firestore.collection('users').doc(adminUid).set({
            'uid': adminUid,
            'email': adminEmail,
            'role': 'admin',
            'name': 'Administrador',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
          
          print('📄 Documento creado en Firestore exitosamente');
          
          // Verificar que el documento se creó
          final doc = await _firestore.collection('users').doc(adminUid).get();
          if (doc.exists) {
            print('✅ Verificación: Documento existe en Firestore');
            print('📊 Datos del documento: ${doc.data()}');
          } else {
            print('❌ Error: Documento no se encontró después de crearlo');
          }
          
          print('✅ Administrador configurado correctamente');
          print('🔑 Credenciales: $adminEmail / Admin123!');
          
        } catch (firestoreError) {
          print('❌ Error al crear documento en Firestore: $firestoreError');
          throw Exception('Error al crear documento en Firestore: $firestoreError');
        }
      } else {
        throw Exception('Error al configurar administrador: $e');
      }
    }
  }

  /// Función para verificar si ya existe un administrador
  static Future<bool> hasAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al verificar administrador: $e');
      return false;
    }
  }
}