import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/institution_provider.dart';
import 'providers/user_provider.dart';
import 'providers/horario_provider.dart';
import 'managers/app_lifecycle_manager.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar configuración de la aplicación
  await AppConfig.initialize();

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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  late final AppLifecycleManager _lifecycleManager;
  late final AuthProvider _authProvider;
  late final InstitutionProvider _institutionProvider;
  late final HorarioProvider _horarioProvider;
  late AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    _lifecycleManager = AppLifecycleManager();
    _authProvider = AuthProvider();
    _institutionProvider = InstitutionProvider();
    _horarioProvider = HorarioProvider();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _institutionProvider),
        ChangeNotifierProvider.value(value: _horarioProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider.value(value: _lifecycleManager),
      ],
      child: Builder(
        builder: (context) {

          _appRouter = AppRouter(
            authProvider: _authProvider,
          );

          return MaterialApp.router(
            title: 'AsistApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.defaultTheme,
            routerConfig: _appRouter.router,
            builder: (context, child) {
              return DefaultTextStyle(
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: AppColors.instance.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}