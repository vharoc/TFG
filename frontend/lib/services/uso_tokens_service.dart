import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_services.dart';

/// Uso de tokens del día para un usuario.
class UsoTokens {
  final int tokensUsados;
  final int limite;

  const UsoTokens({required this.tokensUsados, required this.limite});

  const UsoTokens.vacio()
      : tokensUsados = 0,
        limite = UsoTokensService.limiteDiario;

  /// Fracción gastada (0.0 – 1.0), recortada a 1.0 como máximo.
  double get fraccion =>
      limite <= 0 ? 0 : (tokensUsados / limite).clamp(0.0, 1.0);

  int get porcentaje => (fraccion * 100).round();

  bool get limiteAlcanzado => tokensUsados >= limite;

  int get restantes => (limite - tokensUsados).clamp(0, limite);
}

/// Lleva la cuenta diaria de tokens de IA gastados por usuario en Firestore.
/// El contador se guarda en `users/{uid}/uso/diario` como `{ fecha, tokens }`
/// y se resetea solo al cambiar de día natural (00:00 hora del dispositivo):
/// si la fecha guardada no es la de hoy, el uso se considera 0.
class UsoTokensService {
  UsoTokensService._();
  static final UsoTokensService instance = UsoTokensService._();

  /// Límite diario de tokens por usuario. Empieza bajo para validar el bloqueo;
  /// subir este valor cuando el comportamiento esté comprobado.
  static const int limiteDiario = 20000;

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

  /// Clave de día natural local en formato YYYY-MM-DD.
  static String _hoy() {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  /// Estado de uso del día actual. Si el documento es de otro día, cuenta 0.
  Future<UsoTokens> estado() async {
    final snap = await _docRef.get();
    final data = snap.data();
    final usados = (data != null && data['fecha'] == _hoy())
        ? ((data['tokens'] as num?)?.toInt() ?? 0)
        : 0;
    return UsoTokens(tokensUsados: usados, limite: limiteDiario);
  }

  /// True si el usuario ya agotó su cupo de hoy (no debería poder enviar más).
  Future<bool> limiteAlcanzado() async {
    final e = await estado();
    return e.limiteAlcanzado;
  }

  /// Suma [tokens] al gasto de hoy. Si el documento es de un día anterior,
  /// arranca de cero. Atómico mediante transacción para no perder cuenta.
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
