import 'package:flutter/foundation.dart';
import '../models/yapp.dart';

class YappProvider extends ChangeNotifier {
  final List<Yapp> _yapps = [];

  List<Yapp> get yapps => List.unmodifiable(_yapps);

  void addYapp(Yapp yapp) {
    _yapps.add(yapp);
    notifyListeners();
  }

  void removeYapps(List<String> idsToRemove) {
    _yapps.removeWhere((y) => idsToRemove.contains(y.id));
    notifyListeners();
  }

  void renameYapp(String id, String newName) {
    final index = _yapps.indexWhere((y) => y.id == id);
    if (index != -1) {
      _yapps[index].name = newName;
      notifyListeners();
    }
  }

  String generateDefaultName() {
    // e.g. "yapp#${_yapps.length + 1}"
    return "yapp#${_yapps.length + 1}";
  }
}
