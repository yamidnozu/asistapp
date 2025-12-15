import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'providers/settings_provider.dart';
import 'providers/acudiente_provider.dart';
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
import 'services/push_notification_service.dart';

/// Helper para verificar si estamos en plataforma móvil
/// v1.5.2 - Release a prueba cerrada (alpha track)
bool get isMobilePlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase solo en plataformas móviles (no en Windows)
  if (isMobilePlatform) {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase Core inicializado correctamente');
      // Inicializar PushNotificationService después de Firebase Core
      await PushNotificationService.initializeFirebase();
    } catch (e) {
      debugPrint('⚠️ Error inicializando Firebase: $e');
    }
  } else {
    debugPrint('ℹ️ Firebase deshabilitado en plataforma no móvil');
  }

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
        ChangeNotifierProvider(
            create: (_) =>
                InstitutionProvider(institutionService: _institutionService)),
        ChangeNotifierProvider(
            create: (_) => HorarioProvider(horarioService: _horarioService)),
        ChangeNotifierProvider(
            create: (_) =>
                AsistenciaProvider(asistenciaService: _asistenciaService)),
        ChangeNotifierProvider(
            create: (_) => GrupoProvider(grupoService: _grupoService)),
        ChangeNotifierProvider(
            create: (_) => MateriaProvider(materiaService: _materiaService)),
        ChangeNotifierProvider(
            create: (_) =>
                PeriodoAcademicoProvider(periodoService: _periodoService)),
        ChangeNotifierProvider(
            create: (_) => UserProvider(userService: _userService)),
        ChangeNotifierProvider(
            create: (_) => EstudiantesByGrupoPaginatedProvider(
                grupoService: _grupoService)),
        ChangeNotifierProvider(
            create: (_) => EstudiantesSinAsignarPaginatedProvider(
                grupoService: _grupoService)),
        ChangeNotifierProvider(
            create: (_) =>
                InstitutionAdminsPaginatedProvider(userService: _userService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AcudienteProvider()),
        ChangeNotifierProvider(create: (_) => _lifecycleManager),
      ],
      child: Builder(
        builder: (context) {
          _appRouter = AppRouter(
            authProvider: _authProvider,
          );

          // Register lifecycle callbacks for data refresh
          final lifecycleManager =
              Provider.of<AppLifecycleManager>(context, listen: false);
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final grupoProvider =
              Provider.of<GrupoProvider>(context, listen: false);
          final materiaProvider =
              Provider.of<MateriaProvider>(context, listen: false);
          final periodoProvider =
              Provider.of<PeriodoAcademicoProvider>(context, listen: false);
          final horarioProvider =
              Provider.of<HorarioProvider>(context, listen: false);

          lifecycleManager.addLifecycleCallback('data_refresh', () async {
            debugPrint('AppLifecycleManager: Refreshing data...');
            final token = authProvider.accessToken;
            if (token != null) {
              debugPrint(
                  'AppLifecycleManager: Token available, refreshing periodos...');
              await periodoProvider.loadPeriodosActivos(token);
              debugPrint(
                  'AppLifecycleManager: Periodos refreshed, refreshing grupos...');
              await grupoProvider.loadGrupos(token);
              debugPrint(
                  'AppLifecycleManager: Grupos refreshed, refreshing materias...');
              await materiaProvider.loadMaterias(token);
              debugPrint(
                  'AppLifecycleManager: Materias refreshed, checking for horario refresh...');
              if (horarioProvider.selectedGrupoId != null &&
                  horarioProvider.selectedPeriodoId != null) {
                debugPrint(
                    'AppLifecycleManager: Refreshing horarios for selected group/period...');
                await horarioProvider.loadHorarios(token,
                    grupoId: horarioProvider.selectedGrupoId,
                    periodoId: horarioProvider.selectedPeriodoId);
                debugPrint('AppLifecycleManager: Horarios refreshed');
              } else {
                debugPrint(
                    'AppLifecycleManager: No selected group/period for horario refresh');
              }
              debugPrint('AppLifecycleManager: Data refresh completed');
            } else {
              debugPrint('AppLifecycleManager: No token available for refresh');
            }
          });

          final settings = Provider.of<SettingsProvider>(context);

          final useDark = settings.themeMode == ThemeMode.dark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: AppColors.instance.transparent,
            statusBarIconBrightness:
                useDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: AppColors.instance.black,
            systemNavigationBarIconBrightness:
                useDark ? Brightness.light : Brightness.dark,
          ));

          return MaterialApp.router(
            title: 'AsistApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            routerConfig: _appRouter.router,
            builder: (context, child) {
              final textColor = Theme.of(context).colorScheme.onSurface;
              return DefaultTextStyle(
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: textColor,
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
