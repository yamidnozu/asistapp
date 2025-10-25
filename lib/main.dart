import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'managers/app_lifecycle_manager.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/app_wrappers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar la barra de estado
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColors.instance.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.instance.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleManager _lifecycleManager;

  @override
  void initState() {
    super.initState();
    _lifecycleManager = AppLifecycleManager();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _lifecycleManager),
      ],
      child: MaterialApp(
        title: 'AsistApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.defaultTheme,
        home: const LifecycleAwareWrapper(),
        builder: (context, child) {
          return DefaultTextStyle(
            style: TextStyle(
              decoration: TextDecoration.none,
              color: AppColors.instance.white,
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
            ),
            child: Stack(
              children: [
                child!,
                // ErrorLoggerWidget(), // Temporalmente comentado para evitar problemas
              ],
            ),
          );
        },
      ),
    );
  }
}