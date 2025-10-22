import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Mostrar loading mientras se verifica el estado
        if (userProvider.isLoading) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay usuario autenticado, mostrar pantalla de bienvenida
        if (userProvider.currentUser != null) {
          return const WelcomeScreen();
        }

        // Si no hay usuario, mostrar pantalla de login
        return const LoginScreen();
      },
    );
  }
}