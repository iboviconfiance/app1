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
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_courses_screen.dart';
import 'screens/admin/admin_exercises_screen.dart';
import 'screens/admin/admin_subjects_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_exams_screen.dart';
import 'screens/admin/teacher_analytics_screen.dart';

class KlasPlusApp extends StatefulWidget {
  const KlasPlusApp({super.key});

  @override
  State<KlasPlusApp> createState() => _KlasPlusAppState();
}

class _KlasPlusAppState extends State<KlasPlusApp> {
  GoRouter? _router;

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: auth.isAuthenticated ? '/dashboard' : '/welcome',
      refreshListenable: auth,
      redirect: (context, state) {
        // Attendre l'initialisation depuis SharedPreferences avant tout redirect
        if (!auth.initialized) return null;

        final loggedIn = auth.isAuthenticated;
        final authRoutes = ['/welcome', '/login', '/register', '/forgot-password'];

        if (!loggedIn && !authRoutes.contains(state.matchedLocation)) return '/welcome';
        if (loggedIn && authRoutes.contains(state.matchedLocation)) return '/dashboard';

        // Protection des routes admin
        if (state.matchedLocation.startsWith('/admin')) {
          final role = auth.user?['role'];
          if (role != 'admin' && role != 'teacher') return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

        GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
        GoRoute(path: '/admin/courses', builder: (_, __) => const AdminCoursesScreen()),
        GoRoute(path: '/admin/exercises', builder: (_, __) => const AdminExercisesScreen()),
        GoRoute(path: '/admin/subjects', builder: (_, __) => const AdminSubjectsScreen()),
        GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
        GoRoute(path: '/admin/exams', builder: (_, __) => const AdminExamsScreen()),
        GoRoute(path: '/admin/analytics', builder: (_, __) => const TeacherAnalyticsScreen()),

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
    final auth = context.watch<AuthProvider>();

    // ── Splash branded : masque le flicker GoRouter pendant l'init ──────────
    // On affiche un splash qui ressemble à l'app (fond de couleur primaire)
    // plutôt qu'un écran blanc avec un spinner, ce qui élimine visuellement
    // le "blank screen" perçu pendant la résolution de session.
    if (!auth.initialized) {
      return MaterialApp(
        title: 'KLAS+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo texte
                const Text(
                  'KLAS+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Crée le router une seule fois une fois auth initialisé
    _router ??= _buildRouter(auth);

    return MaterialApp.router(
      title: 'KLAS+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router!,
    );
  }
}
