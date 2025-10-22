// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/support_home_screen.dart';
import 'services/auth_service.dart';
import 'providers/incident_provider.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error inicializando Firebase: $e');
    // Continuar con la app aunque Firebase falle
  }
  
  runApp(const LabIncidentsApp());
}

class LabIncidentsApp extends StatelessWidget {
  const LabIncidentsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
      ],
      child: MaterialApp(
        title: 'UPT Lab Incidents',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primaryBlue,
          scaffoldBackgroundColor: AppColors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            primary: AppColors.primaryBlue,
            secondary: AppColors.accentGold,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Usuario autenticado, determinar rol y redirigir
          return FutureBuilder<String>(
            future: AuthService().getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              }
              
              if (roleSnapshot.hasError) {
                print('Error al cargar rol de usuario: ${roleSnapshot.error}');
                
                // Verificar si es un error de usuario no autorizado o documento no encontrado
                final errorMessage = roleSnapshot.error.toString();
                if (errorMessage.contains('Usuario no autorizado') || 
                    errorMessage.contains('Usuario no encontrado') ||
                    errorMessage.contains('No se encontró documento')) {
                  // Cerrar sesión para usuarios sin documento en Firestore
                  print('🚫 Usuario sin documento en Firestore - cerrando sesión y redirigiendo al login');
                  AuthService().signOut();
                  return const LoginScreen();
                } else {
                  // Para otros errores, mostrar pantalla de error sin cerrar sesión
                  print('⚠️ Error temporal al cargar rol - mostrando pantalla de error');
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text('Error al cargar información del usuario'),
                          const SizedBox(height: 8),
                          Text('$errorMessage'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Cerrar sesión y volver al login
                              AuthService().signOut();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text('Volver al Login'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
              
              final role = roleSnapshot.data;
              
              // Si no hay rol definido, mostrar error sin cerrar sesión
              if (role == null || role.isEmpty) {
                print('🚫 Rol nulo o vacío - mostrando error');
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text('Usuario sin rol definido'),
                        const SizedBox(height: 8),
                        const Text('Contacta al administrador para asignar un rol'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            AuthService().signOut();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text('Cerrar Sesión'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              print('🏠 AuthWrapper - Usuario autenticado: ${snapshot.data!.email}');
              print('👤 AuthWrapper - Rol obtenido: $role');
              print('🚀 AuthWrapper - Navegando a pantalla según rol...');
              
              switch (role) {
                case 'admin':
                  print('📱 Navegando a AdminHomeScreen');
                  return const AdminHomeScreen();
                case 'support':
                  print('📱 Navegando a SupportHomeScreen');
                  return const SupportHomeScreen();
                case 'student':
                  print('📱 Navegando a StudentHomeScreen');
                  return const StudentHomeScreen();
                default:
                  print('🚫 Rol inválido: $role - cerrando sesión');
                  AuthService().signOut();
                  return const LoginScreen();
              }
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}