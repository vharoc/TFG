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
    await reauthenticate(email: email, passwd: passwd);
    await deleteCurrentUser();
  }

  Future<void> reauthenticate({
    required String email,
    required String passwd,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: passwd,
    );

    await currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> deleteCurrentUser() async {
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> changePassword({
    required String currentPasswd,
    required String newPasswd,
    required String email,
  }) async {
    await reauthenticate(email: email, passwd: currentPasswd);
    await currentUser!.updatePassword(newPasswd);
  }
}
