import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/colors.dart';

class DebugInfoWidget extends StatefulWidget {
  const DebugInfoWidget({Key? key}) : super(key: key);

  @override
  State<DebugInfoWidget> createState() => _DebugInfoWidgetState();
}

class _DebugInfoWidgetState extends State<DebugInfoWidget> {
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final info = StringBuffer();
    
    try {
      info.writeln('🔍 DIAGNÓSTICO DE CONFIGURACIÓN\n');
      
      // Verificar Firebase Auth
      final auth = FirebaseAuth.instance;
      info.writeln('✅ Firebase Auth inicializado');
      info.writeln('Usuario actual: ${auth.currentUser?.email ?? 'Ninguno'}');
      info.writeln('App: ${auth.app.name}');
      info.writeln('');
      
      // Verificar Google Sign In con más detalle
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      info.writeln('✅ Google Sign In inicializado');
      info.writeln('Scopes: ${googleSignIn.scopes}');
      
      // Verificar disponibilidad
      try {
        final isAvailable = await googleSignIn.isSignedIn();
        info.writeln('Disponible: $isAvailable');
      } catch (e) {
        info.writeln('❌ Error verificando disponibilidad: $e');
      }
      
      // Verificar si hay usuario de Google logueado
      try {
        final googleUser = await googleSignIn.signInSilently();
        info.writeln('Usuario Google: ${googleUser?.email ?? 'Ninguno'}');
        if (googleUser != null) {
          info.writeln('ID: ${googleUser.id}');
          info.writeln('Nombre: ${googleUser.displayName}');
        }
      } catch (e) {
        info.writeln('❌ Error en signInSilently: $e');
      }
      
      info.writeln('');
      
      // Información de la plataforma
      info.writeln('📱 INFORMACIÓN DE PLATAFORMA');
      info.writeln('Plataforma: ${Theme.of(context).platform}');
      
      // Test básico de Google Sign In
      info.writeln('');
      info.writeln('🧪 TEST DE GOOGLE SIGN IN');
      try {
        await googleSignIn.signOut(); // Limpiar estado
        info.writeln('✅ SignOut exitoso');
        
        // Intentar obtener cuentas disponibles (solo funciona si está configurado)
        final accounts = await googleSignIn.signInSilently();
        if (accounts == null) {
          info.writeln('ℹ️ No hay cuentas guardadas (normal)');
        } else {
          info.writeln('✅ Cuenta encontrada: ${accounts.email}');
        }
      } catch (e) {
        info.writeln('❌ Error en test: $e');
        info.writeln('Tipo de error: ${e.runtimeType}');
        
        // Análisis específico de errores comunes
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('10')) {
          info.writeln('🔧 POSIBLE SOLUCIÓN: Error 10 - SHA-1 fingerprint no configurado');
          info.writeln('   Ejecuta: cd android && ./gradlew signingReport');
          info.writeln('   Agrega el SHA-1 en Firebase Console');
        } else if (errorStr.contains('12500')) {
          info.writeln('🔧 POSIBLE SOLUCIÓN: Error 12500 - Google Play Services');
          info.writeln('   Actualiza Google Play Services en el dispositivo');
        } else if (errorStr.contains('7')) {
          info.writeln('🔧 POSIBLE SOLUCIÓN: Error 7 - Conexión de red');
          info.writeln('   Verifica la conexión a internet');
        }
      }
      
    } catch (e) {
      info.writeln('❌ Error general: $e');
      info.writeln('Tipo: ${e.runtimeType}');
    }
    
    setState(() {
      _debugInfo = info.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Depuración',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _debugInfo,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _checkConfiguration,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}