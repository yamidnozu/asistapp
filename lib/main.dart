import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/institution_provider.dart';
import 'providers/user_provider.dart';
import 'providers/estudiantes_by_grupo_paginated_provider.dart';
import 'providers/estudiantes_sin_asignar_paginated_provider.dart';
import 'providers/institution_admins_paginated_provider.dart';
import 'providers/horario_provider.dart';
import 'providers/asistencia_provider.dart';
import 'providers/grupo_provider.dart';
import 'providers/materia_provider.dart';
import 'providers/periodo_academico_provider.dart';
import 'managers/app_lifecycle_manager.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'utils/app_router.dart';
import 'services/auth_service.dart';
import 'services/asistencia_service.dart';
import 'services/institution_service.dart';
import 'services/academic/grupo_service.dart';
import 'services/academic/materia_service.dart';
import 'services/academic/horario_service.dart';
import 'services/academic/periodo_service.dart';
import 'services/user_service.dart' as user_service;

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
  late AppRouter _appRouter;
  late final AuthService _authService;
  late final InstitutionService _institutionService;
  late final GrupoService _grupoService;
  late final MateriaService _materiaService;
  late final HorarioService _horarioService;
  late final PeriodoService _periodoService;
  late final AsistenciaService _asistenciaService;
  late final user_service.UserService _userService;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();

    _lifecycleManager = AppLifecycleManager();
    _authService = AuthService();
    _institutionService = InstitutionService();
    _grupoService = GrupoService();
    _materiaService = MateriaService();
    _horarioService = HorarioService();
    _periodoService = PeriodoService();
    _asistenciaService = AsistenciaService();
    _userService = user_service.UserService();
    _authProvider = AuthProvider(authService: _authService);

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
        ChangeNotifierProvider(create: (_) => _authProvider),
        ChangeNotifierProvider(create: (_) => InstitutionProvider(institutionService: _institutionService)),
        ChangeNotifierProvider(create: (_) => HorarioProvider(horarioService: _horarioService)),
        ChangeNotifierProvider(create: (_) => AsistenciaProvider(asistenciaService: _asistenciaService)),
        ChangeNotifierProvider(create: (_) => GrupoProvider(grupoService: _grupoService)),
        ChangeNotifierProvider(create: (_) => MateriaProvider(materiaService: _materiaService)),
        ChangeNotifierProvider(create: (_) => PeriodoAcademicoProvider(periodoService: _periodoService)),
        ChangeNotifierProvider(create: (_) => UserProvider(userService: _userService)),
        ChangeNotifierProvider(create: (_) => EstudiantesByGrupoPaginatedProvider(grupoService: _grupoService)),
        ChangeNotifierProvider(create: (_) => EstudiantesSinAsignarPaginatedProvider(grupoService: _grupoService)),
        ChangeNotifierProvider(create: (_) => InstitutionAdminsPaginatedProvider(userService: _userService)),
        ChangeNotifierProvider(create: (_) => _lifecycleManager),
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