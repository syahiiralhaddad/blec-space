import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'services/ble_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BleService.instance.init();
  runApp(const BlecSpaceApp());
}

class BlecSpaceApp extends StatelessWidget {
  const BlecSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLEc Space',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomeScreen(),
    );
  }
}
