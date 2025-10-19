class IncidentTypes {
  static const List<Map<String, dynamic>> types = [
    {'label': 'Pantallazo azul', 'icon': 'desktop_windows'},
    {'label': 'No prende el monitor', 'icon': 'tv_off'},
    {'label': 'No prende la computadora', 'icon': 'power_off'},
    {'label': 'Teclado no funciona', 'icon': 'keyboard'},
    {'label': 'Mouse no funciona', 'icon': 'mouse'},
    {'label': 'Sin internet', 'icon': 'wifi_off'},
    {'label': 'Lentitud extrema', 'icon': 'hourglass_empty'},
    {'label': 'Software no abre', 'icon': 'apps'},
    {'label': 'Audio no funciona', 'icon': 'volume_off'},
    {'label': 'Puerto USB no funciona', 'icon': 'usb'},
    {'label': 'Pantalla rayada o dañada', 'icon': 'broken_image'},
    {'label': 'Otro problema', 'icon': 'more_horiz'},
  ];

  static List<String> get labels => types.map((e) => e['label'] as String).toList();
}