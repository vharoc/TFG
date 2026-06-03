import 'package:go_router/go_router.dart';
import '../services/auth_services.dart';
import '../screens/ajustes_screen.dart';
import '../screens/estadisticas_screen.dart';
import '../screens/home_screen.dart';
import '../screens/lateral_screen.dart';
import '../screens/login_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/register_screen.dart';
import '../screens/verify_email_screen.dart';

const _publicRoutes = ["/login", "/register", "/"];

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final auth = AuthService.instance;
    final user = auth.currentUser;
    final loc = state.matchedLocation;

    // Sin sesión → solo rutas públicas
    if (user == null) {
      return _publicRoutes.contains(loc) ? null : '/login';
    }

    // Sesión activa pero correo sin verificar
    if (!auth.isEmailVerified) {
      return loc == '/verify-email' ? null : '/verify-email';
    }

    // Sesión activa y verificada → no volver a pantallas de entrada
    if (_publicRoutes.contains(loc) || loc == '/verify-email') return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, state) => const LoginScreen()),
    GoRoute(path: '/login', builder: (_, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, state) => const RegisterScreen()),
    GoRoute(path: '/verify-email', builder: (_, state) => const VerifyEmailScreen()),
    GoRoute(
      path: '/home',
      builder: (_, state) =>
          HomeScreen(chatId: state.uri.queryParameters['chatId']),
    ),
    GoRoute(path: '/lateral', builder: (_, state) => const LateralScreen()),
    GoRoute(path: '/ajustes', builder: (_, state) => const AjustesScreen()),
    GoRoute(path: '/estadisticas', builder: (_, state) => const EstadisticasScreen()),
    GoRoute(path: '/perfil', builder: (_, state) => const PerfilScreen()),
  ],
);
