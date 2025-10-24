class ComputerComponent {
  final String brand;
  final String serialNumber;
  final String model;

  ComputerComponent({
    required this.brand,
    required this.serialNumber,
    required this.model,
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'serialNumber': serialNumber,
      'model': model,
    };
  }

  factory ComputerComponent.fromMap(Map<String, dynamic> map) {
    return ComputerComponent(
      brand: map['brand'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      model: map['model'] ?? '',
    );
  }

  ComputerComponent copyWith({
    String? brand,
    String? serialNumber,
    String? model,
  }) {
    return ComputerComponent(
      brand: brand ?? this.brand,
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
    );
  }
}

class Computer {
  final String id;
  final String labName;
  final int computerNumber;
  final ComputerComponent cpu;
  final ComputerComponent monitor;
  final ComputerComponent mouse;
  final ComputerComponent keyboard;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isActive;
  final String? notes;

  Computer({
    required this.id,
    required this.labName,
    required this.computerNumber,
    required this.cpu,
    required this.monitor,
    required this.mouse,
    required this.keyboard,
    required this.createdAt,
    this.lastUpdated,
    this.isActive = true,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labName': labName,
      'computerNumber': computerNumber,
      'cpu': cpu.toMap(),
      'monitor': monitor.toMap(),
      'mouse': mouse.toMap(),
      'keyboard': keyboard.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'isActive': isActive,
      'notes': notes,
    };
  }

  factory Computer.fromMap(Map<String, dynamic> map) {
    return Computer(
      id: map['id'] ?? '',
      labName: map['labName'] ?? '',
      computerNumber: map['computerNumber'] ?? 0,
      cpu: ComputerComponent.fromMap(map['cpu'] ?? {}),
      monitor: ComputerComponent.fromMap(map['monitor'] ?? {}),
      mouse: ComputerComponent.fromMap(map['mouse'] ?? {}),
      keyboard: ComputerComponent.fromMap(map['keyboard'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastUpdated: map['lastUpdated'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
      isActive: map['isActive'] ?? true,
      notes: map['notes'],
    );
  }

  Computer copyWith({
    String? id,
    String? labName,
    int? computerNumber,
    ComputerComponent? cpu,
    ComputerComponent? monitor,
    ComputerComponent? mouse,
    ComputerComponent? keyboard,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isActive,
    String? notes,
  }) {
    return Computer(
      id: id ?? this.id,
      labName: labName ?? this.labName,
      computerNumber: computerNumber ?? this.computerNumber,
      cpu: cpu ?? this.cpu,
      monitor: monitor ?? this.monitor,
      mouse: mouse ?? this.mouse,
      keyboard: keyboard ?? this.keyboard,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  String get displayName => 'PC $computerNumber - Lab $labName';
  
  List<ComputerComponent> get allComponents => [cpu, monitor, mouse, keyboard];
  
  bool get hasCompleteInfo {
    return allComponents.every((component) => 
        component.brand.isNotEmpty && 
        component.serialNumber.isNotEmpty && 
        component.model.isNotEmpty);
  }
}