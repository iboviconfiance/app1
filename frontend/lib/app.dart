import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/school/school_selection_screen.dart';
import 'screens/courses/courses_screen.dart';
import 'screens/courses/course_detail_screen.dart';
import 'screens/exercises/exercises_screen.dart';
import 'screens/exercises/exercise_quiz_screen.dart';
import 'screens/exams/exams_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/work_groups/work_groups_screen.dart';

class KlasPlusApp extends StatefulWidget {
  const KlasPlusApp({super.key});

  @override
  State<KlasPlusApp> createState() => _KlasPlusAppState();
}

class _KlasPlusAppState extends State<KlasPlusApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = GoRouter(
      initialLocation: auth.isAuthenticated ? '/dashboard' : '/welcome',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final authRoutes = ['/welcome', '/login', '/register', '/forgot-password'];
        
        // Wait until AuthProvider loads its state from SharedPreferences
        if (!auth.initialized) return null;

        if (!loggedIn && !authRoutes.contains(state.matchedLocation)) return '/welcome';
        if (loggedIn && authRoutes.contains(state.matchedLocation)) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
        ShellRoute(
          builder: (_, __, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/school', builder: (_, __) => const SchoolSelectionScreen()),
            GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
            GoRoute(path: '/courses/:id', builder: (_, state) => CourseDetailScreen(id: state.pathParameters['id']!)),
            GoRoute(path: '/exercises', builder: (_, __) => const ExercisesScreen()),
            GoRoute(path: '/exercises/:id', builder: (_, state) => ExerciseQuizScreen(id: state.pathParameters['id']!)),
            GoRoute(path: '/exams', builder: (_, __) => const ExamsScreen()),
            GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
            GoRoute(path: '/work-groups', builder: (_, __) => const WorkGroupsScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KLAS+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
