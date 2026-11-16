import 'package:flutter/material.dart';

import 'app.dart';
import 'core/session.dart';
import 'core/settings.dart';
import 'core/system.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  SystemBridge.init();
  runApp(const ShenApp());
  await Session.instance.start();
}
