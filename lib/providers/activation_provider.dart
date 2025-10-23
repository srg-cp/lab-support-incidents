import 'package:flutter/foundation.dart';

class ActivationProvider extends ChangeNotifier {
  bool _isActivating = false;
  
  bool get isActivating => _isActivating;
  
  void setActivating(bool activating) {
    _isActivating = activating;
    notifyListeners();
  }
}