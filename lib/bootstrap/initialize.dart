
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

Future<void> initialize() async {
  // Initialize Hive local storage.
  await Hive.initFlutter();

  // Open application settings box.
  await Hive.openBox('app_settings');

  // Initialize application dependencies.
  await initDependencies();
}
