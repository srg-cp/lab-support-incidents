class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('network-request-failed')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('user-not-found')) {
      return 'Usuario no encontrado.';
    } else if (error.toString().contains('wrong-password')) {
      return 'Contraseña incorrecta.';
    } else if (error.toString().contains('email-already-in-use')) {
      return 'Este correo ya está registrado.';
    } else if (error.toString().contains('weak-password')) {
      return 'La contraseña es demasiado débil.';
    } else if (error.toString().contains('invalid-email')) {
      return 'Correo electrónico inválido.';
    } else if (error.toString().contains('permission-denied')) {
      return 'No tienes permisos para realizar esta acción.';
    } else {
      return 'Ha ocurrido un error. Inténtalo de nuevo.';
    }
  }
}