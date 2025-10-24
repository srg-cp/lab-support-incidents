import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/computer_model.dart';

class ComputerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las computadoras de un laboratorio
  Stream<QuerySnapshot> getComputersByLab(String labName) {
    return _firestore
        .collection('computers')
        .where('labName', isEqualTo: labName)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Obtener todas las computadoras activas (para conteos en tiempo real)
  Stream<QuerySnapshot> getComputersStream() {
    return _firestore
        .collection('computers')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Obtener una computadora específica
  Future<DocumentSnapshot> getComputer(String computerId) {
    return _firestore.collection('computers').doc(computerId).get();
  }

  // Obtener computadora por laboratorio y número
  Future<Computer?> getComputerByLabAndNumber(String labName, int computerNumber) async {
    try {
      final query = await _firestore
          .collection('computers')
          .where('labName', isEqualTo: labName)
          .where('computerNumber', isEqualTo: computerNumber)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Computer.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error al obtener computadora: $e');
      return null;
    }
  }

  // Agregar nueva computadora
  Future<String> addComputer(Computer computer) async {
    try {
      // Verificar que no exista otra computadora con el mismo número en el lab
      final existing = await getComputerByLabAndNumber(
        computer.labName, 
        computer.computerNumber
      );
      
      if (existing != null) {
        throw Exception('Ya existe una computadora con el número ${computer.computerNumber} en el laboratorio ${computer.labName}');
      }

      // Verificar números de serie únicos
      await _validateUniqueSerialNumbers(computer);

      final docRef = await _firestore.collection('computers').add(computer.toMap());
      
      // Actualizar el ID del documento
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar computadora
  Future<void> updateComputer(String computerId, Computer computer) async {
    try {
      await _validateUniqueSerialNumbers(computer, excludeComputerId: computerId);
      
      await _firestore.collection('computers').doc(computerId).update({
        ...computer.toMap(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar computadora (marcar como inactiva)
  Future<void> deleteComputer(String computerId) async {
    try {
      await _firestore.collection('computers').doc(computerId).update({
        'isActive': false,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Obtener el siguiente número disponible para una computadora en un lab
  Future<int> getNextComputerNumber(String labName) async {
    try {
      final query = await _firestore
          .collection('computers')
          .where('labName', isEqualTo: labName)
          .where('isActive', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        return 1; // Primera computadora
      }

      // Encontrar el número más alto en el cliente
      int maxNumber = 0;
      for (final doc in query.docs) {
        final computer = Computer.fromMap(doc.data());
        if (computer.computerNumber > maxNumber) {
          maxNumber = computer.computerNumber;
        }
      }

      return maxNumber + 1;
    } catch (e) {
      print('Error al obtener siguiente número: $e');
      return 1;
    }
  }

  // Validar que los números de serie sean únicos
  Future<void> _validateUniqueSerialNumbers(Computer computer, {String? excludeComputerId}) async {
    final serialNumbers = [
      computer.cpu.serialNumber,
      computer.monitor.serialNumber,
      computer.mouse.serialNumber,
      computer.keyboard.serialNumber,
    ];

    for (final serialNumber in serialNumbers) {
      if (serialNumber.isEmpty) continue;

      final query = _firestore
          .collection('computers')
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();
      
      for (final doc in snapshot.docs) {
        if (excludeComputerId != null && doc.id == excludeComputerId) continue;
        
        final existingComputer = Computer.fromMap(doc.data());
        final existingSerials = [
          existingComputer.cpu.serialNumber,
          existingComputer.monitor.serialNumber,
          existingComputer.mouse.serialNumber,
          existingComputer.keyboard.serialNumber,
        ];

        if (existingSerials.contains(serialNumber)) {
          throw Exception('El número de serie $serialNumber ya está registrado en otra computadora');
        }
      }
    }
  }

  // Buscar computadoras por número de serie
  Future<List<Computer>> searchBySerialNumber(String serialNumber) async {
    try {
      final snapshot = await _firestore
          .collection('computers')
          .where('isActive', isEqualTo: true)
          .get();

      final computers = <Computer>[];
      
      for (final doc in snapshot.docs) {
        final computer = Computer.fromMap(doc.data());
        final serials = [
          computer.cpu.serialNumber,
          computer.monitor.serialNumber,
          computer.mouse.serialNumber,
          computer.keyboard.serialNumber,
        ];

        if (serials.any((s) => s.toLowerCase().contains(serialNumber.toLowerCase()))) {
          computers.add(computer);
        }
      }

      return computers;
    } catch (e) {
      print('Error en búsqueda: $e');
      return [];
    }
  }

  // Obtener estadísticas de computadoras por laboratorio
  Future<Map<String, int>> getComputerCountByLab() async {
    try {
      final snapshot = await _firestore
          .collection('computers')
          .where('isActive', isEqualTo: true)
          .get();

      final counts = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final computer = Computer.fromMap(doc.data());
        counts[computer.labName] = (counts[computer.labName] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {};
    }
  }

  // Obtener conteos de equipos por tipo y laboratorio
  Future<Map<String, Map<String, int>>> getEquipmentCountsByLab() async {
    try {
      final snapshot = await _firestore
          .collection('computers')
          .where('isActive', isEqualTo: true)
          .get();

      final counts = <String, Map<String, int>>{};
      
      for (final doc in snapshot.docs) {
        final computer = Computer.fromMap(doc.data());
        final labName = computer.labName;
        final equipmentType = computer.equipmentType.name;
        
        if (!counts.containsKey(labName)) {
          counts[labName] = {'student': 0, 'teacher': 0, 'projector': 0};
        }
        
        counts[labName]![equipmentType] = (counts[labName]![equipmentType] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error al obtener conteos de equipos: $e');
      return {};
    }
  }
}