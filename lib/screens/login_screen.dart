import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../widgets/custom_modal.dart';
import '../services/auth_service.dart';
import '../utils/setup_admin.dart';
import '../providers/activation_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isStudentLogin = true;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Login exitoso - verificar que el usuario esté autenticado
      if (userCredential.user != null && mounted) {
        print('✅ Login con Google exitoso para: ${userCredential.user!.email}');
        
        // NO verificar/reparar automáticamente - los usuarios deben existir previamente
        // Solo los estudiantes con @virtual.upt.pe se crean automáticamente via Google OAuth
        
        // La navegación se manejará automáticamente por el AuthWrapper
        setState(() => _isLoading = false);
        return;
      }
      
    } catch (e) {
      // Solo mostrar modal de error si realmente hay un error de autenticación
      if (mounted && !e.toString().contains('cancelled')) {
        String errorMessage = 'No se pudo iniciar sesión. Inténtalo de nuevo.';
        
        // Personalizar mensaje según el tipo de error
        if (e.toString().contains('@virtual.upt.pe')) {
          errorMessage = 'Debes usar tu correo institucional @virtual.upt.pe';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión. Verifica tu internet.';
        } else if (e.toString().contains('Error al autenticar con Firebase')) {
          errorMessage = 'Error de autenticación con Firebase. Verifica la configuración.';
        } else if (e.toString().contains('Access Token nulo')) {
          errorMessage = 'Error al obtener credenciales de Google. Inténtalo de nuevo.';
        } else if (e.toString().contains('ID Token')) {
          errorMessage = 'Error de configuración de Google Sign-In. Contacta al administrador.';
        } else if (e.toString().contains('ClientID not set')) {
          errorMessage = 'Error de configuración: Google Sign-In no configurado correctamente.';
        }
        
        // Solo mostrar el modal si es un error real de autenticación
        print('❌ Error de autenticación completo: $e');
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error de Autenticación',
          message: errorMessage,
        );
      } else if (e.toString().contains('cancelled')) {
        // Login cancelado por el usuario - no mostrar error
        print('ℹ️ Login cancelado por el usuario');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      final userCredential = result['userCredential'];
      final wasActivated = result['wasActivated'] ?? false;
      
      // Login exitoso - verificar que el usuario esté autenticado
      if (userCredential.user != null && mounted) {
        print('✅ Login con email exitoso para: ${userCredential.user!.email}');
        
        // Si el usuario fue activado, mostrar pantalla de activación brevemente
        if (wasActivated) {
          print('🎉 Usuario activado desde estado pendiente');
          
          // Activar el estado de activación
          if (mounted) {
            Provider.of<ActivationProvider>(context, listen: false).setActivating(true);
          }
          
          // Esperar un momento para que el usuario vea la pantalla de activación
          await Future.delayed(const Duration(seconds: 2));
          
          // Verificar y reparar documento de usuario
          await _authService.verifyAndRepairUserDocument();
          
          // Desactivar el estado de activación
          if (mounted) {
            Provider.of<ActivationProvider>(context, listen: false).setActivating(false);
          }
          
          // La navegación se manejará automáticamente por el AuthWrapper
          return;
        } else {
          // Usuario normal, verificar documento de forma asíncrona
          _authService.verifyAndRepairUserDocument().then((_) {
            print('✅ Documento de usuario verificado/reparado');
          }).catchError((e) {
            print('⚠️ Error al verificar documento de usuario: $e');
            // No mostrar error al usuario, solo loggear
          });
        }
        
        // La navegación se manejará automáticamente por el AuthWrapper
        setState(() => _isLoading = false);
        return;
      }
      
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Credenciales incorrectas. Verifica tu usuario y contraseña.';
        
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'Usuario no encontrado.';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Contraseña incorrecta.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión. Verifica tu internet.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Email inválido.';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Demasiados intentos fallidos. Inténtalo más tarde.';
        }
        
        print('❌ Error de autenticación con email: $e');
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error de Autenticación',
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupFirstAdmin() async {
    final emailController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Configurar Primer Administrador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa el email del administrador:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email del administrador',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.trim().isNotEmpty) {
      if (!mounted) return;
      
      setState(() => _isLoading = true);
      
      try {
        await SetupAdmin.setupFirstAdmin(emailController.text.trim());
        
        if (mounted) {
          // Usar ScaffoldMessenger en lugar de CustomModal para evitar problemas de contexto
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Administrador configurado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Logo UPT
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'UPT',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Sistema de Gestión\nde Incidentes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Universidad Privada de Tacna',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Toggle entre tipos de usuario
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isStudentLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isStudentLogin ? AppColors.primaryBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Estudiante',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isStudentLogin ? AppColors.white : AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isStudentLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isStudentLogin ? AppColors.primaryBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Admin/Soporte',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_isStudentLogin ? AppColors.white : AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (_isStudentLogin) ...[
                  // Login con Google para estudiantes
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.school),
                    label: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Iniciar con Google UPT'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ] else ...[
                  // Login tradicional para admin/soporte
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu usuario';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmailPassword,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Iniciar Sesión'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Botón temporal para configurar primer admin (solo en desarrollo)
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _setupFirstAdmin,
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Configurar Primer Admin'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}