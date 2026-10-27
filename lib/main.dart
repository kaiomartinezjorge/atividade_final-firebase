import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:atividade_final/firebase_options.dart';
import 'package:atividade_final/screen/auth_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Nook - Leitores & Cia.',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C3D2E), // Paleta fiel à logo do Book Nook
          primary: const Color(0xFF5C3D2E),
          secondary: const Color(0xFF8D5B4C),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
