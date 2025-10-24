import 'package:flutter/material.dart';

class IncidentTypes {
  static const List<Map<String, dynamic>> types = [
    // Problemas de computadoras
    {'label': 'Pantallazo azul', 'icon': Icons.desktop_windows, 'category': 'computer'},
    {'label': 'No prende el monitor', 'icon': Icons.tv_off, 'category': 'computer'},
    {'label': 'No prende la computadora', 'icon': Icons.power_off, 'category': 'computer'},
    {'label': 'Teclado no funciona', 'icon': Icons.keyboard, 'category': 'computer'},
    {'label': 'Mouse no funciona', 'icon': Icons.mouse, 'category': 'computer'},
    {'label': 'Sin internet', 'icon': Icons.wifi_off, 'category': 'computer'},
    {'label': 'Lentitud extrema', 'icon': Icons.hourglass_empty, 'category': 'computer'},
    {'label': 'Software no abre', 'icon': Icons.apps, 'category': 'computer'},
    {'label': 'Audio no funciona', 'icon': Icons.volume_off, 'category': 'computer'},
    {'label': 'Puerto USB no funciona', 'icon': Icons.usb, 'category': 'computer'},
    {'label': 'Pantalla rayada o dañada', 'icon': Icons.broken_image, 'category': 'computer'},
    
    // Problemas de proyectores
    {'label': 'Proyector no prende', 'icon': Icons.videocam_off, 'category': 'projector'},
    {'label': 'No hay imagen en proyector', 'icon': Icons.tv_off, 'category': 'projector'},
    {'label': 'Imagen borrosa en proyector', 'icon': Icons.blur_on, 'category': 'projector'},
    {'label': 'Proyector sobrecalentado', 'icon': Icons.whatshot, 'category': 'projector'},
    {'label': 'Cable HDMI/VGA no funciona', 'icon': Icons.cable, 'category': 'projector'},
    {'label': 'Control remoto no funciona', 'icon': Icons.settings_remote, 'category': 'projector'},
    {'label': 'Lámpara del proyector fundida', 'icon': Icons.lightbulb_outline, 'category': 'projector'},
    
    // Problemas generales
    {'label': 'Otro problema', 'icon': Icons.more_horiz, 'category': 'general'},
  ];

  static List<String> get labels => types.map((e) => e['label'] as String).toList();
  
  static List<Map<String, dynamic>> get computerTypes => 
      types.where((type) => type['category'] == 'computer').toList();
      
  static List<Map<String, dynamic>> get projectorTypes => 
      types.where((type) => type['category'] == 'projector').toList();
      
  static List<Map<String, dynamic>> get generalTypes => 
      types.where((type) => type['category'] == 'general').toList();
      
  // Propiedades para uso en las pantallas
  static List<Map<String, dynamic>> get projectorIncidentTypes => 
      [...projectorTypes, ...generalTypes];
      
  static List<Map<String, dynamic>> get computerIncidentTypes => 
      [...computerTypes, ...generalTypes];
      
  static List<Map<String, dynamic>> get allIncidentTypes => types;
}