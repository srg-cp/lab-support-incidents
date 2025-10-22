import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../utils/date_formatter.dart';
import '../services/auth_service.dart';
import '../widgets/custom_modal.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Usuarios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          // Lista de usuarios (solo admin y support, no estudiantes)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _authService.getNonStudentUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorView(
                    message: 'Error al cargar usuarios',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];

                if (users.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No hay usuarios',
                    message: 'Aún no se han creado usuarios en el sistema.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    return _buildUserCard(userData, users[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String userId) {
    final String name = userData['name'] ?? 'Sin nombre';
    final String email = userData['email'] ?? 'Sin email';
    final String role = userData['role'] ?? 'student';
    final DateTime? createdAt = userData['createdAt']?.toDate();
    final DateTime? lastLogin = userData['lastLogin']?.toDate();

    Color roleColor;
    String roleText;
    IconData roleIcon;

    switch (role) {
      case 'admin':
        roleColor = AppColors.danger;
        roleText = 'Administrador';
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'support':
        roleColor = AppColors.warning;
        roleText = 'Soporte';
        roleIcon = Icons.support_agent;
        break;
      default:
        roleColor = AppColors.lightBlue;
        roleText = 'Estudiante';
        roleIcon = Icons.school;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Icon(roleIcon, color: roleColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleUserAction(value, userId, userData),
                  itemBuilder: (context) => [
                    // Solo mostrar "Cambiar Rol" si no es el usuario actual
                    if (userId != _authService.currentUser?.uid)
                      const PopupMenuItem(
                        value: 'edit_role',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Cambiar Rol'),
                          ],
                        ),
                      ),
                    if (role != 'admin' && userId != _authService.currentUser?.uid) // No permitir eliminar admins ni al usuario actual
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Creado: ${createdAt != null ? DateFormatter.formatDate(createdAt) : 'N/A'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(width: 16),
                Icon(Icons.login, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Último acceso: ${lastLogin != null ? DateFormatter.formatDate(lastLogin) : 'Nunca'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, String userId, Map<String, dynamic> userData) {
    switch (action) {
      case 'edit_role':
        _showEditRoleDialog(userId, userData['role']);
        break;
      case 'delete':
        _showDeleteUserDialog(userId, userData['name']);
        break;
    }
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'support';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Usuario'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el email';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la contraseña';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                  helperText: 'Los estudiantes se registran automáticamente con Google',
                ),
                items: const [
                  DropdownMenuItem(value: 'support', child: Text('Soporte')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _createUser(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  passwordController.text,
                  selectedRole,
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(String userId, String currentRole) {
    // Si el usuario actual es estudiante, no permitir cambio de rol
    if (currentRole == 'student') {
      CustomModal.show(
        context,
        type: ModalType.warning,
        title: 'Acción no permitida',
        message: 'No se puede cambiar el rol de un estudiante. Los estudiantes se registran automáticamente con Google.',
      );
      return;
    }

    // Si es el usuario actual, no permitir cambio de rol
    if (userId == _authService.currentUser?.uid) {
      CustomModal.show(
        context,
        type: ModalType.warning,
        title: 'Acción no permitida',
        message: 'No puedes cambiar tu propio rol. Solicita a otro administrador que realice este cambio.',
      );
      return;
    }

    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Rol'),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          decoration: const InputDecoration(
            labelText: 'Nuevo rol',
            border: OutlineInputBorder(),
            helperText: 'Solo se pueden asignar roles de administración',
          ),
          items: const [
            DropdownMenuItem(value: 'support', child: Text('Soporte')),
            DropdownMenuItem(value: 'admin', child: Text('Administrador')),
          ],
          onChanged: (value) {
            selectedRole = value!;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateUserRole(userId, selectedRole);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que quieres eliminar a $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createUser(String name, String email, String password, String role) async {
    setState(() => _isLoading = true);

    try {
      await _authService.createUserWithEmailPassword(email, password, name, role);
      
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.success,
          title: 'Usuario Creado',
          message: 'El usuario $name ha sido creado exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error',
          message: 'No se pudo crear el usuario: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    setState(() => _isLoading = true);

    try {
      await _authService.updateUserRole(userId, newRole);
      
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.success,
          title: 'Rol Actualizado',
          message: 'El rol del usuario ha sido actualizado exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error',
          message: 'No se pudo actualizar el rol: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);

    try {
      await _authService.deleteUser(userId);
      
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.success,
          title: 'Usuario Eliminado',
          message: 'El usuario ha sido eliminado exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error',
          message: 'No se pudo eliminar el usuario: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}