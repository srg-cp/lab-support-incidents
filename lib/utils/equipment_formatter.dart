class EquipmentFormatter {
  static const int teacherPCIndex = 0;
  static const int projectorIndex = 999;

  /// Convierte un número de equipo a su representación de texto
  static String formatEquipmentNumber(int equipmentNumber) {
    if (equipmentNumber == teacherPCIndex) {
      return 'PC Docente';
    } else if (equipmentNumber == projectorIndex) {
      return 'Proyector';
    } else {
      return 'PC $equipmentNumber';
    }
  }

  /// Convierte una lista de números de equipo a texto
  static String formatEquipmentNumbers(List<dynamic> equipmentNumbers) {
    if (equipmentNumbers.isEmpty) return 'Sin equipos';
    
    return equipmentNumbers
        .map((num) => formatEquipmentNumber(int.tryParse(num.toString()) ?? 0))
        .join(', ');
  }

  /// Obtiene el primer equipo de una lista para mostrar en resúmenes
  static String formatFirstEquipment(List<dynamic> equipmentNumbers) {
    if (equipmentNumbers.isEmpty) return 'Sin equipos';
    
    final firstNumber = int.tryParse(equipmentNumbers.first.toString()) ?? 0;
    return formatEquipmentNumber(firstNumber);
  }

  /// Verifica si un número corresponde a un equipo especial
  static bool isSpecialEquipment(int equipmentNumber) {
    return equipmentNumber == teacherPCIndex || equipmentNumber == projectorIndex;
  }

  /// Verifica si una lista contiene equipos especiales
  static bool hasSpecialEquipment(List<dynamic> equipmentNumbers) {
    return equipmentNumbers.any((num) {
      final number = int.tryParse(num.toString()) ?? 0;
      return isSpecialEquipment(number);
    });
  }
}