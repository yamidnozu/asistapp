import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'ui/widgets/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar la barra de estado
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'AsistApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const AuthWrapper(),
        builder: (context, child) {
          return DefaultTextStyle(
            style: const TextStyle(
              decoration: TextDecoration.none,
              color: Color(0xFFFFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            child: Stack(
              children: [
                child!,
                ErrorLoggerWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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