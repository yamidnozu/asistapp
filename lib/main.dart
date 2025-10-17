import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/catalog_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/assignment.dart';
import 'ui/widgets/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseStorage.instance; // Initialize Firebase Storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(AssignmentAdapter());
  Hive.registerAdapter(ScheduleAdapter());
  Hive.registerAdapter(EvidenceAdapter());
  
  // Initialize providers that need async setup
  final assignmentProvider = AssignmentProvider();
  await assignmentProvider.init();
  
  runApp(MyApp(assignmentProvider: assignmentProvider));
}

class MyApp extends StatefulWidget {
  final AssignmentProvider assignmentProvider;

  const MyApp({super.key, required this.assignmentProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
      redirect: (context, state) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final isLoggedIn = userProvider.isLoggedIn;

        if (!isLoggedIn && state.uri.path != '/') {
          return '/';
        }
        if (isLoggedIn && state.uri.path == '/') {
          return '/home';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => widget.assignmentProvider),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
      ],
      child: MaterialApp.router(
        title: 'Task Monitoring',
        theme: ThemeData.dark(), // Tema oscuro básico
        routerConfig: _router,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              ErrorLoggerWidget(),
            ],
          );
        },
      ),
    );
  }
}