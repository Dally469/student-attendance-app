import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/screens/home.screen.dart';
import 'package:attendance/screens/login.dart';
import 'package:attendance/screens/splash.screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavigation {
  AppNavigation._();

  // Root navigator key for main app navigation
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Shell navigator key for nested navigation
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routerNeglect: true, // Prevents route killing

    // Global redirect to handle auth state
    redirect: (BuildContext context, GoRouterState state) {
      // Add your auth logic here
      return null;
    },

    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return Material(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: splash,
            builder: (context, state) => Splash(key: state.pageKey),
          ),
          GoRoute(
            path: '/login',
            name: login,
            builder: (context, state) => LoginPage(key: state.pageKey),
          ),
          GoRoute(
            path: '/home',
            name: home,
            builder: (context, state) => Home(key: state.pageKey),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Material(
      child: Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    ),
  );

  // Navigation helper methods

  static void navigateToProfile(BuildContext context, String clientId) {
    context.safeGoNamed('/clientProfile?clientId=$clientId');
  }

  static void navigateToRefreshRequest(BuildContext context) {
    context.safeGoNamed(myRequests,
        params: {'refresh': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static void navigateToRefreshHome(BuildContext context) {
    context.safeGoNamed(home,
        params: {'refresh': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.safeGoNamed('/home');
    }
  }

  static Future<bool> handleWillPop(BuildContext context) async {
    // Check the current route name
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == '/home') {
      // Disable back press if the route is '/home'
      return false;
    }

    if (context.canPop()) {
      context.pop();
      return false;
    }
    return true;
  }
}

// Extension for easier navigation
extension NavigationExtension on BuildContext {
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      go('/home');
    }
  }

  void safeGoNamed(String name, {Map<String, String>? params}) {
    try {
      if (params != null) {
        goNamed(name, queryParameters: params);
      } else {
        goNamed(name);
      }
    } catch (e) {
      go('/home');
    }
  }
}
