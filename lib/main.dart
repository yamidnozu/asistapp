import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_state_provider.dart';
import 'providers/scroll_state_provider.dart';
import 'providers/institution_provider.dart';
import 'providers/user_provider.dart';
import 'managers/app_lifecycle_manager.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  late final NavigationStateProvider _navigationProvider;
  late final ScrollStateProvider _scrollProvider;
  late final InstitutionProvider _institutionProvider;
  late AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    _lifecycleManager = AppLifecycleManager();
    _authProvider = AuthProvider();
    _navigationProvider = NavigationStateProvider();
    _scrollProvider = ScrollStateProvider();
    _institutionProvider = InstitutionProvider();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appRouter.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {
      _authProvider.recoverFullState();
      if (!_navigationProvider.hasValidState()) {
        _navigationProvider.clearNavigationState();
      }
    }

    if (state == AppLifecycleState.paused) {
      _navigationProvider.refreshStateTimestamp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _navigationProvider),
        ChangeNotifierProvider.value(value: _scrollProvider),
        ChangeNotifierProvider.value(value: _institutionProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider.value(value: _lifecycleManager),
      ],
      child: Builder(
        builder: (context) {

          _appRouter = AppRouter(
            authProvider: _authProvider,
            navigationProvider: _navigationProvider,
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