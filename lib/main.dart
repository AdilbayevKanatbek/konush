import 'package:flutter/material.dart';
import 'package:konush/src/app/app.dart';
import 'package:konush/src/app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const KonushApp());
}
