// Excepciones personalizadas
class IncidentLimitException implements Exception {
  final String message;
  IncidentLimitException(this.message);
  
  @override
  String toString() => message;
}

class ComputerConflictException implements Exception {
  final String message;
  ComputerConflictException(this.message);
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => message;
}

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    // Manejar excepciones personalizadas
    if (error is IncidentLimitException) {
      return error.message;
    } else if (error is ComputerConflictException) {
      return error.message;
    } else if (error is ValidationException) {
      return error.message;
    }
    
    // Manejar errores de Firebase
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
  
  // Método para determinar el tipo de modal según el error
  static String getErrorType(dynamic error) {
    if (error is IncidentLimitException || error is ComputerConflictException) {
      return 'warning'; // Advertencia, no error crítico
    }
    return 'danger'; // Error crítico
  }
}