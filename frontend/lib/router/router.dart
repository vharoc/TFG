import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/lateral_screen.dart';
import '../services/auth_services.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/ajustes_screen.dart';
import '../screens/estadisticas_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/register_screen.dart';

const _publicRoutes = ["/login", "/register", "/"];

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = AuthService.instance.currentUser;
    final isPublic = _publicRoutes.contains(state.matchedLocation);
    if (user == null && !isPublic) return '/login';
    if (user != null && isPublic) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, state) => const LoginScreen()),
    GoRoute(path: '/login', builder: (_, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, state) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, state) => const HomeScreen()),
    GoRoute(path: '/lateral', builder: (_, state) => const LateralScreen()),
    GoRoute(path: '/ajustes', builder: (_, state) => const AjustesScreen()),
    GoRoute(path: '/estadisticas', builder: (_, state) => const EstadisticasScreen()),
    GoRoute(path: '/perfil', builder: (_, state) => const PerfilScreen()),
  ],
);
