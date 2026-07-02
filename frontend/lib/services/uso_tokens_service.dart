import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_services.dart';

class UsoTokens {
  final int tokensUsados;
  final int limite;

  const UsoTokens({required this.tokensUsados, required this.limite});

  const UsoTokens.vacio()
      : tokensUsados = 0,
        limite = UsoTokensService.limiteDiario;

  double get fraccion =>
      limite <= 0 ? 0 : (tokensUsados / limite).clamp(0.0, 1.0);

  int get porcentaje => (fraccion * 100).round();

  bool get limiteAlcanzado => tokensUsados >= limite;

  int get restantes => (limite - tokensUsados).clamp(0, limite);
}

/// Cuenta diaria de tokens de IA por usuario, en users/{uid}/uso/diario.
/// Si la fecha guardada no es la de hoy, el uso se considera 0.
class UsoTokensService {
  UsoTokensService._();
  static final UsoTokensService instance = UsoTokensService._();

  static const int limiteDiario = 50000;

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _docRef => _db
      .collection('users')
      .doc(_uid)
      .collection('uso')
      .doc('diario');

  static String _hoy() {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  Future<UsoTokens> estado() async {
    final snap = await _docRef.get();
    final data = snap.data();
    final usados = (data != null && data['fecha'] == _hoy())
        ? ((data['tokens'] as num?)?.toInt() ?? 0)
        : 0;
    return UsoTokens(tokensUsados: usados, limite: limiteDiario);
  }

  Future<bool> limiteAlcanzado() async {
    final e = await estado();
    return e.limiteAlcanzado;
  }

  /// Atómico mediante transacción para no perder cuenta.
  Future<void> registrar(int tokens) async {
    if (tokens <= 0) return;
    final hoy = _hoy();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data();
      final base = (data != null && data['fecha'] == hoy)
          ? ((data['tokens'] as num?)?.toInt() ?? 0)
          : 0;
      tx.set(_docRef, {'fecha': hoy, 'tokens': base + tokens});
    });
  }
}
