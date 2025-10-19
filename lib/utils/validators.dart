class Validators {
  // Validar correo institucional UPT
  static bool isValidUPTEmail(String email) {
    return email.toLowerCase().endsWith('@virtual.upt.pe');
  }

  // Validar email general
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validar contraseña (mínimo 6 caracteres)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Validar que no esté vacío
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
