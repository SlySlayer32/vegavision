import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/core/di/hive_setup.dart';
import 'package:vegavision/core/di/locator.dart';
import 'package:vegavision/core/error/error_handler.dart';
import 'package:vegavision/core/navigation/navigation_service.dart';
import 'package:vegavision/core/navigation/routes.dart';
import 'package:vegavision/core/theme/theme_service.dart';
import 'package:vegavision/core/permissions/permission_handler.dart';
import 'package:vegavision/core/services/connectivity_service.dart';
import 'package:vegavision/firebase_options.dart';

Future<void> main() async {
  try {
    // Initialize error handling
    AppErrorHandler.initialize();

    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Hive
    await initializeHive();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Setup dependencies
    await setupDependencies();

    // Request initial permissions
    final permissionManager = PermissionManager();
    await permissionManager.requestAllRequiredPermissions();

    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stack');
    AppErrorHandler.handleError(e, stack);
    throw e; // Rethrow to show error screen
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        Provider<ConnectivityService>(
          create: (_) => getIt<ConnectivityService>(),
        ),
        Provider<NavigationService>(create: (_) => getIt<NavigationService>()),
      ],
      child: MaterialApp(
        title: 'VegaVision AI Editor',
        navigatorKey: getIt<NavigationService>().navigatorKey,
        onGenerateRoute: Routes.generateRoute,
        theme: ThemeService.getLightTheme(),
        darkTheme: ThemeService.getDarkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Set up error boundary
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return AppErrorHandler.buildErrorWidget(details);
          };

          // Apply system text scaling
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }
}
