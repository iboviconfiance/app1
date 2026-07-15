import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/dashboard_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProxyProvider<AuthProvider, CourseProvider>(
          create: (context) => CourseProvider(context.read<AuthProvider>().api),
          update: (context, auth, previous) => previous ?? CourseProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (context) => DashboardProvider(context.read<AuthProvider>().api),
          update: (context, auth, previous) => previous ?? DashboardProvider(auth.api),
        ),
      ],
      child: const KlasPlusApp(),
    ),
  );
}
