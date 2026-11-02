import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Garante que os plugins (GPS, SQLite...) estejam prontos antes do app.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLocalizacoes());
}
