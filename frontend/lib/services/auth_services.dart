import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  User get _requiredUser {
    final user = currentUser;
    if (user == null) {
      throw StateError('No hay usuario autenticado.');
    }
    return user;
  }

  Future<UserCredential> signIn({
    required String email,
    required String passwd,
  }) async {
    return firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: passwd,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String passwd,
  }) async {
    return firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: passwd,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await _requiredUser.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String passwd,
  }) async {
    await reauthenticate(email: email, passwd: passwd);
    await deleteCurrentUser();
  }

  Future<void> reauthenticate({
    required String email,
    required String passwd,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: passwd,
    );

    await _requiredUser.reauthenticateWithCredential(credential);
  }

  Future<void> deleteCurrentUser() async {
    await _requiredUser.delete();
    await firebaseAuth.signOut();
  }

  Future<void> changePassword({
    required String currentPasswd,
    required String newPasswd,
    required String email,
  }) async {
    await reauthenticate(email: email, passwd: currentPasswd);
    await _requiredUser.updatePassword(newPasswd);
  }
}
