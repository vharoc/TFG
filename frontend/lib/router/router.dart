import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_,__) => const LoginScreen()),
    GoRoute(path: '/login', builder: (_,__) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_,__) => const RegisterScreen()),
  ],
);