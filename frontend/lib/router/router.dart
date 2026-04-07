import 'package:frontend/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/lateral_screen.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/ajustes_screen.dart';
import '../screens/register_screen.dart';


const _publicRoutes = ["/login", "/register", "/"];

final appRouter = GoRouter(
  initialLocation: '/',

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isPublic = _publicRoutes.contains(state.matchedLocation);

    if(user == null && !isPublic) return '/login';

    if(user != null && isPublic) return '/home';

    return null;

  },

  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/lateral', builder:(context, state) => const LateralScreen()),
    GoRoute(path: '/ajustes', builder: (contex, state) => const AjustesScreen()),
  ],
);
