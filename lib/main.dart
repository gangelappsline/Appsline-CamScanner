/*import 'package:appsline_cam_scanner/screens/home_screen.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/document_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = DocumentStore.instance;
  await store.initialize();
  runApp(CamScannerApp(store: store));
}

class CamScannerApp extends StatelessWidget {
  const CamScannerApp({required this.store, super.key});

  final DocumentStore store;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17212B);
    const paper = Color(0xFFF8F9FB);
    const accent = Color(0xFF2F6BFF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Escáner',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE8ECF2), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E6EE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E6EE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFFE8EFFF),
          side: const BorderSide(color: Color(0xFFE1E6EE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: AppslineSplash(nextScreen: HomeScreen(store: store),), //HomeScreen(store: store),
    );
  }
}*/

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appsline_cam_scanner/screens/splash_screen.dart';
import 'package:appsline_cam_scanner/screens/home_screen.dart';
import 'package:appsline_cam_scanner/services/document_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = DocumentStore.instance;
  await store.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF040A1C),
    ),
  );
  runApp(AppslineApp(store: store));
}

class AppslineApp extends StatelessWidget {
  const AppslineApp({super.key, required this.store});

  final DocumentStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appsline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2F6BFF),
      ),
      home: AppslineSplash(
        nextScreen: HomeScreen(store: store),
      ),
    );
  }
}


