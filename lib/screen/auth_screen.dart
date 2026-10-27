import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:atividade_final/screen/login_screen.dart';
import 'package:atividade_final/screen/livros_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se o snapshot tem dados armazenados, o usuário está logado
        if (snapshot.hasData) {
          return const LivrosScreen();
        }
        // Se não tiver dados de usuário autenticado
        return const LoginScreen();
      },
    );
  }
}
