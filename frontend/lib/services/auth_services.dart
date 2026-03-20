import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth firebaseAuth =
      FirebaseAuth.instance; // crear instancia de firebase

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String passwd,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: passwd,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String passwd,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: passwd,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String passwd,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: passwd,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswdFromCurrentPasswd({
    required String currentPasswd,
    required String newPasswd,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPasswd,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await firebaseAuth.confirmPasswordReset(
      code: newPasswd,
      newPassword: newPasswd,
    );
  }
}
