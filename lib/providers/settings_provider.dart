import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';

/// Data saver state provider
final dataSaverProvider = StateNotifierProvider<DataSaverNotifier, bool>((ref) {
  return DataSaverNotifier();
});

class DataSaverNotifier extends StateNotifier<bool> {
  DataSaverNotifier() : super(_loadInitial());

  static bool _loadInitial() {
    return HiveService.getDataSaver();
  }

  /// Toggle Data Saver preference
  void toggle() {
    state = !state;
    HiveService.setDataSaver(state);
  }

  /// Set Data Saver preference
  void setEnabled(bool value) {
    state = value;
    HiveService.setDataSaver(value);
  }
}
